-- =============================================================================
-- Pay dues and causes in the app, through Korapay (card or bank transfer).
--
-- 1. The member taps "Pay now". The 'korapay' Edge Function makes a payment
--    (online_payment_start) and opens Korapay's checkout page.
-- 2. Korapay tells the Edge Function when it's paid (webhook), or the app
--    asks it to check. Either way the function asks Korapay itself whether
--    the payment went through (never trusting the message alone), then
--    online_payment_paid records the contribution, already confirmed.
--
-- The payer pays Korapay's fee, so the fund receives the full amount.
-- Payouts are not made from here: Korapay only accepts payout requests from
-- whitelisted IP addresses, which Supabase can't offer; the treasurer pays
-- out in the Korapay dashboard and records it as before.
--
-- The secret key is kept in Vault (admin_set_korapay), read only by the Edge
-- Function. Online payments are switched on by the committee.
-- =============================================================================

alter table public.fund_settings add column online_payments boolean not null default false;
alter table public.fund_contributions add column gateway_reference text unique;

create table public.online_payments (
  reference        text primary key,
  user_id          uuid not null references auth.users on delete cascade,
  amount           numeric(14,2) not null check (amount >= 100),
  cause_id         uuid references public.fund_causes on delete set null,
  dues_plan_id     uuid references public.fund_dues_plans on delete set null,
  show_name        boolean not null default true,
  status           text not null default 'started' check (status in ('started', 'paid', 'failed')),
  fee              numeric(14,2),
  contribution_id  uuid references public.fund_contributions on delete set null,
  created_at       timestamptz not null default now(),
  paid_at          timestamptz,
  constraint online_payments_one_purpose check (cause_id is null or dues_plan_id is null)
);
create index online_payments_user_idx on public.online_payments (user_id, created_at desc);
create index online_payments_cause_idx on public.online_payments (cause_id);
create index online_payments_dues_idx on public.online_payments (dues_plan_id);
create index online_payments_contribution_idx on public.online_payments (contribution_id);

alter table public.online_payments enable row level security;
create policy online_payments_select on public.online_payments for select to authenticated
  using (user_id = (select auth.uid()) or public.is_committee());
revoke insert, update, delete on public.online_payments from authenticated, anon;

-- -----------------------------------------------------------------------------
-- Admin: the Korapay secret key.
-- -----------------------------------------------------------------------------
create function public.admin_set_korapay(p_secret_key text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can set up payments' using errcode = '42501';
  end if;
  if btrim(coalesce(p_secret_key, '')) !~ '^sk_(test|live)_[A-Za-z0-9_]+$' then
    raise exception 'That is not a Korapay secret key (it starts with sk_test_ or sk_live_)' using errcode = '22023';
  end if;
  perform private.vault_put('korapay_secret_key', btrim(p_secret_key), 'Korapay secret key for online payments');
end $$;

-- What the committee sees on the payments card.
create function public.korapay_status() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  key text;
begin
  if not public.is_committee() then
    raise exception 'Only the committee can see payment settings' using errcode = '42501';
  end if;
  key := private.vault_get('korapay_secret_key');
  return jsonb_build_object(
    'key_saved', key is not null,
    'mode', case when key like 'sk_live_%' then 'live' when key like 'sk_test_%' then 'test' end,
    'enabled', coalesce((select online_payments from public.fund_settings), false),
    'paid_30d', (select count(*) from public.online_payments where status = 'paid' and paid_at > now() - interval '30 days'),
    'amount_30d', (select coalesce(sum(amount), 0) from public.online_payments
                   where status = 'paid' and paid_at > now() - interval '30 days'),
    'last_paid_at', (select max(paid_at) from public.online_payments)
  );
end $$;

-- -----------------------------------------------------------------------------
-- For the Edge Function only (service_role).
-- -----------------------------------------------------------------------------
create function public.korapay_config() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'secret_key', private.vault_get('korapay_secret_key'),
    'enabled', coalesce((select online_payments from public.fund_settings), false),
    'family_name', (select family_name from public.app_settings));
$$;

-- A new payment for p_user: checks it may be made, and returns its reference
-- with what Korapay needs to know about the payer.
create function public.online_payment_start(
  p_user uuid, p_amount numeric, p_cause uuid default null, p_plan uuid default null, p_show_name boolean default true
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  ref text := 'bua-' || replace(gen_random_uuid()::text, '-', '');
  purpose text;
begin
  if not coalesce((select online_payments from public.fund_settings), false) then
    raise exception 'Paying in the app is not switched on' using errcode = '55000';
  end if;
  if not exists (select 1 from public.profiles where id = p_user and status = 'active') then
    raise exception 'Only family members can pay' using errcode = '42501';
  end if;
  if p_amount is null or p_amount < 100 or p_amount > 10000000 then
    raise exception 'The amount must be between ₦100 and ₦10,000,000' using errcode = '22023';
  end if;
  if p_cause is not null and p_plan is not null then
    raise exception 'A payment is for one cause or one dues plan' using errcode = '22023';
  end if;
  if p_cause is not null then
    select title into purpose from public.fund_causes where id = p_cause and status = 'open';
    if purpose is null then
      raise exception 'This cause is not open' using errcode = '22023';
    end if;
  elsif p_plan is not null then
    select title into purpose from public.fund_dues_plans where id = p_plan;
    if purpose is null then
      raise exception 'Dues plan not found' using errcode = '22023';
    end if;
  end if;
  insert into public.online_payments (reference, user_id, amount, cause_id, dues_plan_id, show_name)
  values (ref, p_user, round(p_amount, 2), p_cause, p_plan, coalesce(p_show_name, true));
  return jsonb_build_object(
    'reference', ref,
    'amount', round(p_amount, 2),
    'name', private.member_name(p_user),
    'email', coalesce((select email from auth.users where id = p_user), (select email from public.profiles where id = p_user)),
    'purpose', purpose);
end $$;

-- Korapay confirmed the payment: record it as a confirmed contribution (once).
create function public.online_payment_paid(p_reference text, p_amount numeric, p_fee numeric default null) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  p public.online_payments;
  new_id uuid;
  purpose text;
begin
  select * into p from public.online_payments where reference = p_reference for update;
  if not found then
    raise exception 'Unknown payment %', p_reference using errcode = 'P0002';
  end if;
  if p.status = 'paid' then
    return p.contribution_id;
  end if;
  if p_amount is null or p_amount < p.amount then
    raise exception 'Paid % but % was expected', p_amount, p.amount using errcode = '22023';
  end if;
  insert into public.fund_contributions
    (user_id, amount, method, cause_id, dues_plan_id, show_name, status, reviewed_at, gateway_reference)
  values (p.user_id, p.amount, 'transfer', p.cause_id, p.dues_plan_id, p.show_name, 'confirmed', now(), p.reference)
  returning id into new_id;
  update public.online_payments
     set status = 'paid', paid_at = now(), fee = p_fee, contribution_id = new_id
   where reference = p_reference;
  -- The committee hears about it (nothing to confirm).
  purpose := coalesce((select title from public.fund_causes where id = p.cause_id),
                      (select title from public.fund_dues_plans where id = p.dues_plan_id));
  insert into public.notifications (user_id, kind, data, link, actor_id)
  select a.id, 'fund_contribution',
         jsonb_build_object('contribution_id', new_id, 'amount', p.amount, 'cause', purpose, 'online', true,
                            'name', private.member_name(p.user_id)),
         '/fund', p.user_id
  from public.profiles a
  where a.status = 'active' and (a.role = 'admin' or a.is_treasurer) and a.id <> p.user_id;
  return new_id;
end $$;

create function public.online_payment_failed(p_reference text) returns void
language sql security definer set search_path = '' as $$
  update public.online_payments set status = 'failed' where reference = p_reference and status = 'started';
$$;

revoke execute on function public.admin_set_korapay(text) from public, anon;
revoke execute on function public.korapay_status() from public, anon;
revoke execute on function public.korapay_config() from public, anon, authenticated;
revoke execute on function public.online_payment_start(uuid, numeric, uuid, uuid, boolean) from public, anon, authenticated;
revoke execute on function public.online_payment_paid(text, numeric, numeric) from public, anon, authenticated;
revoke execute on function public.online_payment_failed(text) from public, anon, authenticated;
grant execute on function public.korapay_config() to service_role;
grant execute on function public.online_payment_start(uuid, numeric, uuid, uuid, boolean) to service_role;
grant execute on function public.online_payment_paid(text, numeric, numeric) to service_role;
grant execute on function public.online_payment_failed(text) to service_role;

-- -----------------------------------------------------------------------------
-- The fund overview says whether members can pay in the app.
-- -----------------------------------------------------------------------------
create or replace function public.fund_overview() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  s public.fund_settings;
begin
  if not public.is_active_member() then
    return null;
  end if;
  select * into s from public.fund_settings;
  return jsonb_build_object(
    'balance', s.opening_balance
      + coalesce((select sum(amount) from public.fund_contributions where status = 'confirmed'), 0)
      - coalesce((select sum(amount) from public.fund_payouts), 0),
    'treasurers', coalesce((select jsonb_agg(private.member_name(id) order by created_at)
                            from public.profiles where status = 'active' and is_treasurer), '[]'::jsonb),
    'updated_at', greatest(s.updated_at,
                           (select max(reviewed_at) from public.fund_contributions),
                           (select max(created_at) from public.fund_payouts)),
    'bank_name', s.bank_name,
    'account_number', s.account_number,
    'account_name', s.account_name,
    'opening_balance', s.opening_balance,
    'online_payments', s.online_payments and private.vault_get('korapay_secret_key') is not null,
    'pending', case when public.is_committee()
                    then (select count(*) from public.fund_contributions where status = 'pending') end
  );
end $$;
