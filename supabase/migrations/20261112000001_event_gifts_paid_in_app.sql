-- =============================================================================
-- Wedding and naming gifts paid in the app (Korapay), like dues and causes.
--
-- 1. A member taps "Pay in the app" on an event's contributions; the
--    'korapay' Edge Function starts the payment (online_payment_start_event).
-- 2. Once Korapay confirms it, online_payment_paid records the gift as sent
--    and paid in the app; the host and the committee are told.
-- 3. The money is in the family's Korapay account, not the welfare fund's.
--    The treasurer passes it on to the host from the Korapay dashboard and
--    taps "Sent to host" (event_payout_done): those gifts become received,
--    the givers are thanked and the host is told.
--
-- Gifts paid in the app can't be changed or taken back (amount, how, status);
-- the giver can still change the note or hide their name. A paid event can't
-- be deleted while its payments are on record.
-- =============================================================================

alter type public.notification_kind add value if not exists 'event_gift_passed_on';

alter table public.event_gifts add column paid_in_app boolean not null default false;

alter table public.online_payments
  add column event_id uuid references public.event_collections on delete restrict,
  add column event_gift_id uuid references public.event_gifts on delete set null,
  add column note text check (length(note) <= 500),
  -- When the treasurer passed the money on to the host.
  add column passed_on_at timestamptz,
  add column passed_on_by uuid references auth.users on delete set null,
  add constraint online_payments_event_only check (event_id is null or (cause_id is null and dues_plan_id is null));
create index online_payments_event_idx on public.online_payments (event_id);
create index online_payments_event_gift_idx on public.online_payments (event_gift_id);
create index online_payments_passed_on_by_idx on public.online_payments (passed_on_by);

-- Gifts paid in the app stay.
alter policy event_gifts_remove on public.event_gifts
  using (not paid_in_app
         and ((giver_id = (select auth.uid()) and status <> 'received') or public.runs_collection(event_id)));

-- Only the payment functions record or settle gifts paid in the app.
create or replace function private.event_gift_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  system boolean := coalesce(current_setting('bua.event_payout', true), '') = 'on'
                    or coalesce(current_setting('bua.restoring', true), '') = 'on'
                    or auth.uid() is null;
  runs boolean := system or public.runs_collection(new.event_id);
begin
  if tg_op = 'INSERT' and new.paid_in_app and not system then
    raise exception 'Gifts paid in the app are recorded by the payment' using errcode = '42501';
  end if;
  if tg_op = 'UPDATE' then
    new.event_id := old.event_id;
    new.giver_id := old.giver_id;
    new.created_at := old.created_at;
    if not system then
      new.paid_in_app := old.paid_in_app;
      if old.paid_in_app then
        new.amount := old.amount;
        new.method := old.method;
        new.item := old.item;
        new.status := old.status;
      end if;
    end if;
    if not runs and old.status = 'received' then
      raise exception 'This gift has been received; ask the host to change it' using errcode = '42501';
    end if;
  end if;
  if new.status = 'received' and (tg_op = 'INSERT' or old.status <> 'received') then
    if not runs then
      raise exception 'Only the host marks a gift received' using errcode = '42501';
    end if;
    new.received_at := coalesce(new.received_at, now());
    new.received_by := coalesce(new.received_by, auth.uid());
  elsif new.status <> 'received' then
    new.received_at := null;
    new.received_by := null;
  end if;
  new.updated_at := now();
  return new;
end $$;

-- The list members see, now saying which gifts were paid in the app.
create function public.event_gift_rows(p_event uuid)
returns table (id uuid, giver_id uuid, amount numeric, item text, method text, note text, anonymous boolean,
               status text, created_at timestamptz, received_at timestamptz, paid_in_app boolean)
language plpgsql stable security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  runs boolean := public.runs_collection(p_event);
  shown boolean := coalesce((select show_amounts from public.event_collections where event_id = p_event), false);
begin
  if not public.is_active_member() then
    return;
  end if;
  return query
  select g.id,
         case when g.anonymous and not runs and g.giver_id <> me then null else g.giver_id end,
         case when shown or runs or g.giver_id = me then g.amount end,
         g.item, g.method,
         case when runs or g.giver_id = me then g.note end,
         g.anonymous, g.status, g.created_at, g.received_at, g.paid_in_app
    from public.event_gifts g
   where g.event_id = p_event
   order by g.created_at;
end $$;

-- -----------------------------------------------------------------------------
-- For the 'korapay' Edge Function (service_role).
-- -----------------------------------------------------------------------------
create function public.online_payment_start_event(
  p_user uuid, p_amount numeric, p_event uuid, p_anonymous boolean default false, p_note text default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  ref text := 'bua-' || replace(gen_random_uuid()::text, '-', '');
  title text;
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
  select e.title into title
    from public.event_collections c join public.events e on e.id = c.event_id
   where c.event_id = p_event and c.open;
  if title is null then
    raise exception 'Contributions for this event are closed' using errcode = '22023';
  end if;
  insert into public.online_payments (reference, user_id, amount, event_id, show_name, note)
  values (ref, p_user, round(p_amount, 2), p_event, not coalesce(p_anonymous, false),
          nullif(btrim(coalesce(p_note, '')), ''));
  return jsonb_build_object(
    'reference', ref,
    'amount', round(p_amount, 2),
    'name', private.member_name(p_user),
    'email', coalesce((select email from auth.users where id = p_user), (select email from public.profiles where id = p_user)),
    'purpose', title,
    'event_id', p_event);
end $$;

-- Korapay confirmed the payment: a fund contribution, or a gift for an event (once).
create or replace function public.online_payment_paid(p_reference text, p_amount numeric, p_fee numeric default null) returns uuid
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
    return coalesce(p.contribution_id, p.event_gift_id);
  end if;
  if p_amount is null or p_amount < p.amount then
    raise exception 'Paid % but % was expected', p_amount, p.amount using errcode = '22023';
  end if;

  if p.event_id is not null then
    perform set_config('bua.event_payout', 'on', true);
    insert into public.event_gifts (event_id, giver_id, amount, method, note, anonymous, status, paid_in_app)
    values (p.event_id, p.user_id, p.amount, 'transfer', p.note, not p.show_name, 'sent', true)
    returning id into new_id;
    perform set_config('bua.event_payout', 'off', true);
    update public.online_payments
       set status = 'paid', paid_at = now(), fee = p_fee, event_gift_id = new_id
     where reference = p_reference;
    purpose := (select title from public.events where id = p.event_id);
    -- The committee holds it for the host.
    insert into public.notifications (user_id, kind, data, link, actor_id)
    select a.id, 'fund_contribution',
           jsonb_build_object('event_gift_id', new_id, 'amount', p.amount, 'cause', purpose, 'online', true,
                              'event', true, 'name', private.member_name(p.user_id)),
           '/fund', p.user_id
    from public.profiles a
    where a.status = 'active' and (a.role = 'admin' or a.is_treasurer) and a.id <> p.user_id;
    return new_id;
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

-- -----------------------------------------------------------------------------
-- The committee: what to pass on to hosts, and "sent to host".
-- -----------------------------------------------------------------------------
create function public.event_payouts_due()
returns table (event_id uuid, title text, starts_at timestamptz, receiver_id uuid, amount numeric, payments int)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_committee() then
    raise exception 'Only the committee can see this' using errcode = '42501';
  end if;
  return query
  select c.event_id, e.title, e.starts_at, c.receiver_id, sum(p.amount), count(*)::int
    from public.online_payments p
    join public.event_collections c on c.event_id = p.event_id
    join public.events e on e.id = c.event_id
   where p.status = 'paid' and p.passed_on_at is null
   group by c.event_id, e.title, e.starts_at, c.receiver_id
   order by e.starts_at;
end $$;

-- The treasurer sent the host what was paid in the app for p_event. Returns the amount.
create function public.event_payout_done(p_event uuid) returns numeric
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  total numeric;
  c public.event_collections;
begin
  if not public.is_committee() then
    raise exception 'Only the committee can record this' using errcode = '42501';
  end if;
  select * into c from public.event_collections where event_id = p_event;
  if not found then
    raise exception 'No contributions on this event' using errcode = 'P0002';
  end if;
  perform set_config('bua.event_payout', 'on', true);
  with done as (
    update public.online_payments
       set passed_on_at = now(), passed_on_by = me
     where event_id = p_event and status = 'paid' and passed_on_at is null
    returning amount, event_gift_id
  ), gifts as (
    update public.event_gifts g
       set status = 'received', received_at = now(), received_by = me
     where g.id in (select event_gift_id from done) and g.status <> 'received'
    returning g.id
  )
  select sum(d.amount) into total from done d;
  perform set_config('bua.event_payout', 'off', true);
  if coalesce(total, 0) > 0 and c.receiver_id is distinct from me then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (c.receiver_id, 'event_gift_passed_on',
            jsonb_build_object('event_id', p_event, 'title', (select title from public.events where id = p_event),
                               'amount', total, 'name', private.member_name(me)),
            '/events/' || p_event, me);
  end if;
  return coalesce(total, 0);
end $$;

revoke execute on function public.event_gift_rows(uuid) from public, anon;
revoke execute on function public.online_payment_start_event(uuid, numeric, uuid, boolean, text) from public, anon, authenticated;
grant execute on function public.online_payment_start_event(uuid, numeric, uuid, boolean, text) to service_role;
revoke execute on function public.event_payouts_due() from public, anon;
revoke execute on function public.event_payout_done(uuid) from public, anon;
