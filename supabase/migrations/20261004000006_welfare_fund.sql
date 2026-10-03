-- =============================================================================
-- Family welfare fund
--
-- Money is never handled in the app: members pay the family account or the
-- treasurer, then record the contribution here, and a treasurer confirms it.
--
--   * The "committee" is admins plus members an admin marks as treasurer.
--   * Causes (school fees, hospital bills, reunion...) are opened by the
--     committee. Any member can ask for support; the request stays private to
--     them and the committee until it is opened.
--   * Contribution amounts are private to the contributor and the committee.
--     Everyone sees the balance, each cause's progress, how many contributed,
--     and the names of contributors who chose to be listed.
--   * Receipts go into a private 'receipts' bucket.
-- =============================================================================

alter type public.notification_kind add value if not exists 'fund_contribution';
alter type public.notification_kind add value if not exists 'fund_confirmed';
alter type public.notification_kind add value if not exists 'fund_request';

-- Treasurers (set by admins; members cannot set it themselves).
alter table public.profiles add column is_treasurer boolean not null default false;

create function public.is_committee() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles
                 where id = auth.uid() and status = 'active' and (role = 'admin' or is_treasurer));
$$;
revoke execute on function public.is_committee() from public, anon;

create function public.admin_set_treasurer(p_user_id uuid, p_on boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can choose treasurers' using errcode = '42501';
  end if;
  update public.profiles set is_treasurer = p_on where id = p_user_id;
end $$;
revoke execute on function public.admin_set_treasurer(uuid, boolean) from public, anon;

-- -----------------------------------------------------------------------------
-- Tables
-- -----------------------------------------------------------------------------
create table public.fund_settings (
  id               boolean primary key default true check (id),
  bank_name        text,
  account_number   text,
  account_name     text,
  -- Money already in the fund before the app was used.
  opening_balance  numeric(14,2) not null default 0,
  updated_at       timestamptz not null default now()
);
insert into public.fund_settings default values;

create table public.fund_causes (
  id             uuid primary key default gen_random_uuid(),
  title          text not null check (length(btrim(title)) > 0),
  description    text,
  target_amount  numeric(14,2) check (target_amount > 0),
  closes_on      date,
  urgent         boolean not null default false,
  -- proposed = someone asked for support; only they and the committee see it.
  status         text not null default 'open' check (status in ('proposed', 'open', 'closed', 'declined')),
  created_by     uuid default auth.uid() references auth.users on delete set null,
  created_at     timestamptz not null default now()
);
create index fund_causes_status_idx on public.fund_causes (status, created_at desc);
create index fund_causes_created_by_idx on public.fund_causes (created_by);

create table public.fund_contributions (
  id            uuid primary key default gen_random_uuid(),
  cause_id      uuid references public.fund_causes on delete set null,
  user_id       uuid not null default auth.uid() references auth.users on delete cascade,
  amount        numeric(14,2) not null check (amount > 0),
  method        text not null check (method in ('transfer', 'cash', 'mobile')),
  receipt_path  text,
  show_name     boolean not null default true,
  status        text not null default 'pending' check (status in ('pending', 'confirmed', 'rejected')),
  reviewed_by   uuid references auth.users on delete set null,
  reviewed_at   timestamptz,
  created_at    timestamptz not null default now()
);
create index fund_contributions_cause_idx on public.fund_contributions (cause_id, status);
create index fund_contributions_user_idx on public.fund_contributions (user_id);
create index fund_contributions_reviewed_by_idx on public.fund_contributions (reviewed_by);

-- Support paid out of the fund, recorded by the committee.
create table public.fund_payouts (
  id           uuid primary key default gen_random_uuid(),
  cause_id     uuid references public.fund_causes on delete set null,
  amount       numeric(14,2) not null check (amount > 0),
  note         text,
  paid_on      date not null default current_date,
  recorded_by  uuid default auth.uid() references auth.users on delete set null,
  created_at   timestamptz not null default now()
);
create index fund_payouts_cause_idx on public.fund_payouts (cause_id);
create index fund_payouts_recorded_by_idx on public.fund_payouts (recorded_by);

-- -----------------------------------------------------------------------------
-- Row level security
-- -----------------------------------------------------------------------------
alter table public.fund_settings      enable row level security;
alter table public.fund_causes        enable row level security;
alter table public.fund_contributions enable row level security;
alter table public.fund_payouts       enable row level security;

create policy fund_settings_select on public.fund_settings for select to authenticated
  using (public.is_active_member());
create policy fund_settings_update on public.fund_settings for update to authenticated
  using (public.is_committee()) with check (public.is_committee());

create policy fund_causes_select on public.fund_causes for select to authenticated
  using (
    (public.is_active_member() and status in ('open', 'closed'))
    or created_by = (select auth.uid())
    or public.is_committee()
  );
create policy fund_causes_insert on public.fund_causes for insert to authenticated
  with check (
    public.is_active_member()
    and created_by = (select auth.uid())
    and (status = 'proposed' or public.is_committee())
  );
create policy fund_causes_update on public.fund_causes for update to authenticated
  using (public.is_committee()) with check (public.is_committee());
create policy fund_causes_delete on public.fund_causes for delete to authenticated
  using (public.is_committee() or (created_by = (select auth.uid()) and status = 'proposed'));

create policy fund_contributions_select on public.fund_contributions for select to authenticated
  using (user_id = (select auth.uid()) or public.is_committee());
create policy fund_contributions_insert on public.fund_contributions for insert to authenticated
  with check (
    public.is_active_member()
    and user_id = (select auth.uid())
    and status = 'pending' and reviewed_by is null and reviewed_at is null
  );
create policy fund_contributions_update on public.fund_contributions for update to authenticated
  using (public.is_committee()) with check (public.is_committee());
create policy fund_contributions_delete on public.fund_contributions for delete to authenticated
  using ((user_id = (select auth.uid()) and status = 'pending') or public.is_committee());

create policy fund_payouts_select on public.fund_payouts for select to authenticated
  using (public.is_committee());
create policy fund_payouts_insert on public.fund_payouts for insert to authenticated
  with check (public.is_committee() and recorded_by = (select auth.uid()));
create policy fund_payouts_delete on public.fund_payouts for delete to authenticated
  using (public.is_committee());

-- -----------------------------------------------------------------------------
-- What every member may see: balance and per-cause progress.
-- -----------------------------------------------------------------------------
create function private.member_name(p_user uuid) returns text
language sql stable set search_path = '' as $$
  select coalesce(private.person_name(p), a.display_name)
  from public.profiles a left join public.persons p on p.id = a.person_id
  where a.id = p_user;
$$;

create function public.fund_overview() returns jsonb
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
    'pending', case when public.is_committee()
                    then (select count(*) from public.fund_contributions where status = 'pending') end
  );
end $$;

create function public.fund_cause_totals()
returns table (cause_id uuid, raised numeric, contributors int, names text[])
language sql stable security definer set search_path = '' as $$
  select c.cause_id, sum(c.amount), count(distinct c.user_id)::int,
         array_remove(array_agg(distinct case when c.show_name then private.member_name(c.user_id) end), null)
  from public.fund_contributions c
  where c.status = 'confirmed' and c.cause_id is not null and public.is_active_member()
  group by c.cause_id;
$$;

revoke execute on function private.member_name(uuid) from public, anon, authenticated;
revoke execute on function public.fund_overview() from public, anon;
revoke execute on function public.fund_cause_totals() from public, anon;

-- -----------------------------------------------------------------------------
-- Triggers: review stamps and notifications
-- -----------------------------------------------------------------------------
create function private.fund_contribution_before() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'UPDATE' and new.status is distinct from old.status then
    new.reviewed_by := auth.uid();
    new.reviewed_at := now();
  end if;
  return new;
end $$;
create trigger fund_contributions_before before update on public.fund_contributions
  for each row execute function private.fund_contribution_before();

create function private.notify_fund_contribution() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  cause_title text := (select title from public.fund_causes where id = new.cause_id);
begin
  if tg_op = 'INSERT' then
    -- Tell the committee there is something to confirm.
    insert into public.notifications (user_id, kind, data, link, actor_id)
    select a.id, 'fund_contribution',
           jsonb_build_object('contribution_id', new.id, 'amount', new.amount, 'cause', cause_title),
           '/fund', new.user_id
    from public.profiles a
    where a.status = 'active' and (a.role = 'admin' or a.is_treasurer) and a.id <> new.user_id;
  elsif new.status = 'confirmed' and old.status <> 'confirmed' then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (new.user_id, 'fund_confirmed',
            jsonb_build_object('contribution_id', new.id, 'amount', new.amount, 'cause', cause_title),
            '/fund', new.reviewed_by);
  end if;
  return new;
end $$;
create trigger fund_contributions_notify after insert or update on public.fund_contributions
  for each row execute function private.notify_fund_contribution();

create function private.notify_fund_request() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'proposed' then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    select a.id, 'fund_request',
           jsonb_build_object('cause_id', new.id, 'title', new.title, 'amount', new.target_amount),
           '/fund', new.created_by
    from public.profiles a
    where a.status = 'active' and (a.role = 'admin' or a.is_treasurer) and a.id is distinct from new.created_by;
  end if;
  return new;
end $$;
create trigger fund_causes_notify after insert on public.fund_causes
  for each row execute function private.notify_fund_request();

create trigger fund_settings_touch before update on public.fund_settings
  for each row execute function public.touch_updated_at();

revoke execute on function private.fund_contribution_before() from public, anon, authenticated;
revoke execute on function private.notify_fund_contribution() from public, anon, authenticated;
revoke execute on function private.notify_fund_request() from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Receipts: private bucket; contributors upload into their own folder and
-- only they and the committee can open them.
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('receipts', 'receipts', false, 10485760,
        array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'application/pdf'])
on conflict (id) do nothing;

create policy receipts_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'receipts' and public.is_active_member()
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy receipts_select on storage.objects for select to authenticated
  using (bucket_id = 'receipts'
         and ((storage.foldername(name))[1] = (select auth.uid())::text or public.is_committee()));
create policy receipts_delete on storage.objects for delete to authenticated
  using (bucket_id = 'receipts' and (storage.foldername(name))[1] = (select auth.uid())::text);
