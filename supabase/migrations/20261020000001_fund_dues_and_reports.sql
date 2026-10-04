-- =============================================================================
-- Welfare fund: dues and reports.
--
-- Dues plans ("Monthly dues ₦2,000") apply to every active member from when
-- they joined (or a start date the committee sets), unless exempted.
-- Payments are ordinary contributions marked with the plan; what is owed is
-- (periods since starting × amount) − confirmed payments, so paying ahead or
-- in part just works. Members see their own standing; the committee sees
-- everyone's, reminds those who owe, and records cash collected for members.
--
-- fund_report() gives any period's statement: opening and closing balance,
-- money in and out by cause / dues / general fund, month by month. The
-- committee also gets every transaction and the dues standing.
-- =============================================================================

alter type public.notification_kind add value if not exists 'dues_reminder';

create table public.fund_dues_plans (
  id           uuid primary key default gen_random_uuid(),
  title        text not null check (length(btrim(title)) > 0),
  amount       numeric(14,2) not null check (amount > 0),
  period       text not null default 'monthly' check (period in ('monthly', 'quarterly', 'yearly')),
  starts_on    date not null default date_trunc('month', current_date)::date,
  active       boolean not null default true,
  auto_remind  boolean not null default true,
  created_by   uuid default auth.uid() references auth.users on delete set null,
  created_at   timestamptz not null default now()
);

-- Per-member exceptions: exempt, or a different start date.
create table public.fund_dues_members (
  plan_id    uuid not null references public.fund_dues_plans on delete cascade,
  user_id    uuid not null references auth.users on delete cascade,
  exempt     boolean not null default false,
  starts_on  date,
  note       text,
  primary key (plan_id, user_id)
);
create index fund_dues_members_user_idx on public.fund_dues_members (user_id);

alter table public.fund_contributions
  add column dues_plan_id uuid references public.fund_dues_plans on delete set null,
  add column recorded_by uuid references auth.users on delete set null,
  add constraint fund_contributions_one_purpose check (cause_id is null or dues_plan_id is null);
create index fund_contributions_dues_idx on public.fund_contributions (dues_plan_id, user_id, status);

alter table public.fund_dues_plans   enable row level security;
alter table public.fund_dues_members enable row level security;

create policy fund_dues_plans_select on public.fund_dues_plans for select to authenticated
  using (public.is_active_member());
create policy fund_dues_plans_write on public.fund_dues_plans for all to authenticated
  using (public.is_committee()) with check (public.is_committee());

create policy fund_dues_members_select on public.fund_dues_members for select to authenticated
  using (user_id = (select auth.uid()) or public.is_committee());
create policy fund_dues_members_write on public.fund_dues_members for all to authenticated
  using (public.is_committee()) with check (public.is_committee());

create trigger zz_log_change after insert or update or delete on public.fund_dues_plans
  for each row execute function private.log_change();
create trigger zz_log_change after insert or update or delete on public.fund_dues_members
  for each row execute function private.log_change();

-- -----------------------------------------------------------------------------
-- Standing: one row per active plan and active member.
-- -----------------------------------------------------------------------------
create function private.dues_rows(p_today date)
returns table (plan_id uuid, user_id uuid, exempt boolean, starts_on date, periods_due int, paid numeric,
               pending numeric, owed numeric, owed_periods int, paid_through date, next_due date,
               last_paid_at timestamptz, period_start boolean)
language sql stable security definer set search_path = '' as $$
  with base as (
    select pl.id as plan_id, pl.amount, date_trunc('month', pl.starts_on)::date as plan_start,
           case pl.period when 'monthly' then 1 when 'quarterly' then 3 else 12 end as len,
           p.id as user_id, coalesce(dm.exempt, false) as exempt,
           greatest(coalesce(dm.starts_on, (p.created_at at time zone 'Africa/Lagos')::date), pl.starts_on) as mstart
    from public.fund_dues_plans pl
    cross join public.profiles p
    left join public.fund_dues_members dm on dm.plan_id = pl.id and dm.user_id = p.id
    where pl.active and p.status = 'active'
  ), idx as (
    select b.*,
           ((extract(year from b.mstart) * 12 + extract(month from b.mstart))
            - (extract(year from b.plan_start) * 12 + extract(month from b.plan_start)))::int / b.len as start_idx,
           ((extract(year from p_today) * 12 + extract(month from p_today))
            - (extract(year from b.plan_start) * 12 + extract(month from b.plan_start)))::int as today_months
    from base b
  ), money as (
    select i.*,
           case when i.today_months < 0 then -1 else i.today_months / i.len end as today_idx,
           coalesce((select sum(c.amount) from public.fund_contributions c
                     where c.dues_plan_id = i.plan_id and c.user_id = i.user_id and c.status = 'confirmed'), 0) as paid,
           coalesce((select sum(c.amount) from public.fund_contributions c
                     where c.dues_plan_id = i.plan_id and c.user_id = i.user_id and c.status = 'pending'), 0) as pending,
           (select max(c.created_at) from public.fund_contributions c
            where c.dues_plan_id = i.plan_id and c.user_id = i.user_id and c.status = 'confirmed') as last_paid_at
    from idx i
  ), due as (
    select m.*, greatest(m.today_idx - m.start_idx + 1, 0) as periods_due, floor(m.paid / m.amount)::int as paid_periods
    from money m
  )
  select d.plan_id, d.user_id, d.exempt, d.mstart, d.periods_due, d.paid, d.pending,
         case when d.exempt then 0 else greatest(d.periods_due * d.amount - d.paid, 0) end,
         case when d.exempt then 0 else ceil(greatest(d.periods_due * d.amount - d.paid, 0) / d.amount)::int end,
         case when d.paid_periods > 0
              then (d.plan_start + make_interval(months => (d.start_idx + d.paid_periods - 1) * d.len))::date end,
         (d.plan_start + make_interval(months => (d.start_idx + d.paid_periods) * d.len))::date,
         d.last_paid_at,
         extract(day from p_today) = 1 and d.today_months >= 0 and d.today_months % d.len = 0
  from due d;
$$;

-- Your standing (or, for the committee with p_everyone, everyone's).
create function public.fund_dues_status(p_everyone boolean default false) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_active_member() then
    return '[]'::jsonb;
  end if;
  if p_everyone and not public.is_committee() then
    raise exception 'Only the fund committee can see everyone''s dues' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'plan_id', r.plan_id, 'user_id', r.user_id, 'name', private.member_name(r.user_id),
             'person_id', a.person_id, 'exempt', r.exempt, 'starts_on', r.starts_on,
             'periods_due', r.periods_due, 'paid', r.paid, 'pending', r.pending, 'owed', r.owed,
             'owed_periods', r.owed_periods, 'paid_through', r.paid_through, 'next_due', r.next_due,
             'last_paid_at', r.last_paid_at)
           order by private.member_name(r.user_id))
    from private.dues_rows((now() at time zone 'Africa/Lagos')::date) r
    join public.profiles a on a.id = r.user_id
    where p_everyone or r.user_id = (select auth.uid())
  ), '[]'::jsonb);
end $$;

-- Reminders: at the start of each period (plans with auto_remind), or now
-- for one plan when the committee asks (once a day at most).
create function private.dues_reminders(p_day date default null, p_plan uuid default null, p_now boolean default false)
returns int
language plpgsql security definer set search_path = '' as $$
declare
  today date := coalesce(p_day, (now() at time zone 'Africa/Lagos')::date);
  n int;
begin
  insert into public.notifications (user_id, kind, data, link, dedupe_key)
  select r.user_id, 'dues_reminder',
         jsonb_build_object('plan_id', pl.id, 'title', pl.title, 'amount', pl.amount, 'owed', r.owed,
                            'periods', r.owed_periods, 'period', pl.period),
         '/fund',
         'dues:' || pl.id || ':' || today || ':' || r.user_id
  from private.dues_rows(today) r
  join public.fund_dues_plans pl on pl.id = r.plan_id
  where r.owed > 0
    and (p_plan is null or pl.id = p_plan)
    and (p_now or (pl.auto_remind and r.period_start))
  on conflict (dedupe_key) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;

create function public.fund_dues_remind(p_plan uuid) returns int
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_committee() then
    raise exception 'Only the fund committee can send reminders' using errcode = '42501';
  end if;
  return private.dues_reminders(null, p_plan, true);
end $$;

-- The committee records money collected for a member (cash at a meeting,
-- a transfer they saw): confirmed at once.
create function public.fund_record_for(
  p_user uuid, p_amount numeric, p_method text default 'cash',
  p_cause uuid default null, p_plan uuid default null
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  new_id uuid;
begin
  if not public.is_committee() then
    raise exception 'Only the fund committee can record payments for others' using errcode = '42501';
  end if;
  insert into public.fund_contributions
    (user_id, amount, method, cause_id, dues_plan_id, status, reviewed_by, reviewed_at, recorded_by, show_name)
  values (p_user, p_amount, p_method, p_cause, p_plan, 'confirmed', auth.uid(), now(), auth.uid(), true)
  returning id into new_id;
  return new_id;
end $$;

-- Recorded already confirmed: tell the member, not the committee.
create or replace function private.notify_fund_contribution() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  cause_title text := coalesce((select title from public.fund_causes where id = new.cause_id),
                               (select title from public.fund_dues_plans where id = new.dues_plan_id));
begin
  if tg_op = 'INSERT' and new.status = 'pending' then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    select a.id, 'fund_contribution',
           jsonb_build_object('contribution_id', new.id, 'amount', new.amount, 'cause', cause_title),
           '/fund', new.user_id
    from public.profiles a
    where a.status = 'active' and (a.role = 'admin' or a.is_treasurer) and a.id <> new.user_id;
  elsif new.status = 'confirmed' and (tg_op = 'INSERT' or old.status <> 'confirmed') then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (new.user_id, 'fund_confirmed',
            jsonb_build_object('contribution_id', new.id, 'amount', new.amount, 'cause', cause_title),
            '/fund', coalesce(new.reviewed_by, auth.uid()));
  end if;
  return new;
end $$;

-- -----------------------------------------------------------------------------
-- Statement for a period (dates inclusive, Nigerian days). Contributions
-- count on the day they were paid, once confirmed; payouts on the day paid.
-- -----------------------------------------------------------------------------
-- Confirmed money in and money out, each dated by the Nigerian day.
create function private.fund_in_rows()
returns table (id uuid, d date, user_id uuid, amount numeric, method text, cause_id uuid, plan_id uuid)
language sql stable security definer set search_path = '' as $$
  select c.id, (c.created_at at time zone 'Africa/Lagos')::date, c.user_id, c.amount, c.method, c.cause_id, c.dues_plan_id
  from public.fund_contributions c where c.status = 'confirmed';
$$;
create function private.fund_out_rows()
returns table (id uuid, d date, amount numeric, note text, cause_id uuid)
language sql stable security definer set search_path = '' as $$
  select p.id, p.paid_on, p.amount, p.note, p.cause_id from public.fund_payouts p;
$$;
revoke execute on function private.fund_in_rows() from public, anon, authenticated;
revoke execute on function private.fund_out_rows() from public, anon, authenticated;

create function public.fund_report(p_from date, p_to date) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  s public.fund_settings;
  committee boolean := public.is_committee();
  opening numeric;
  money_in numeric;
  money_out numeric;
begin
  if not public.is_active_member() then
    raise exception 'Members only' using errcode = '42501';
  end if;
  if p_to < p_from or p_to - p_from > 3660 then
    raise exception 'Choose a period of up to ten years' using errcode = '22023';
  end if;
  select * into s from public.fund_settings;

  opening := s.opening_balance
    + coalesce((select sum(amount) from private.fund_in_rows() where d < p_from), 0)
    - coalesce((select sum(amount) from private.fund_out_rows() where d < p_from), 0);
  money_in := coalesce((select sum(amount) from private.fund_in_rows() where d between p_from and p_to), 0);
  money_out := coalesce((select sum(amount) from private.fund_out_rows() where d between p_from and p_to), 0);

  return jsonb_build_object(
    'from', p_from, 'to', p_to, 'family', (select family_name from public.app_settings),
    'opening', opening, 'in', money_in, 'out', money_out, 'closing', opening + money_in - money_out,
    'payments', (select count(*) from private.fund_in_rows() where d between p_from and p_to),
    'contributors', (select count(distinct user_id) from private.fund_in_rows() where d between p_from and p_to),
    'sources', coalesce((
      select jsonb_agg(x order by (x ->> 'in')::numeric + (x ->> 'out')::numeric desc)
      from (
        select jsonb_build_object('kind', k.kind, 'id', k.id, 'title', k.title,
                                  'in', coalesce(k.money_in, 0), 'out', coalesce(k.money_out, 0)) as x
        from (
          select 'cause' as kind, fc.id, fc.title,
                 (select sum(amount) from private.fund_in_rows() i where i.cause_id = fc.id and i.d between p_from and p_to) as money_in,
                 (select sum(amount) from private.fund_out_rows() o where o.cause_id = fc.id and o.d between p_from and p_to) as money_out
          from public.fund_causes fc
          union all
          select 'dues', dp.id, dp.title,
                 (select sum(amount) from private.fund_in_rows() i where i.plan_id = dp.id and i.d between p_from and p_to), null
          from public.fund_dues_plans dp
          union all
          select 'general', null, null,
                 (select sum(amount) from private.fund_in_rows() i
                  where i.cause_id is null and i.plan_id is null and i.d between p_from and p_to),
                 (select sum(amount) from private.fund_out_rows() o where o.cause_id is null and o.d between p_from and p_to)
        ) k
        where coalesce(k.money_in, 0) + coalesce(k.money_out, 0) > 0
      ) y
    ), '[]'::jsonb),
    'months', (
      select jsonb_agg(jsonb_build_object(
               'month', m::date,
               'in', coalesce((select sum(amount) from private.fund_in_rows()
                               where d >= greatest(m::date, p_from) and d <= least((m + interval '1 month')::date - 1, p_to)), 0),
               'out', coalesce((select sum(amount) from private.fund_out_rows()
                                where d >= greatest(m::date, p_from) and d <= least((m + interval '1 month')::date - 1, p_to)), 0))
             order by m)
      from generate_series(date_trunc('month', p_from::timestamp), p_to::timestamp, interval '1 month') m
    ),
    'transactions', case when committee then coalesce((
      select jsonb_agg(t order by t ->> 'date', t ->> 'kind')
      from (
        select jsonb_build_object('date', i.d, 'kind', 'in', 'amount', i.amount, 'method', i.method,
                                  'name', private.member_name(i.user_id),
                                  'title', coalesce((select title from public.fund_causes where id = i.cause_id),
                                                    (select title from public.fund_dues_plans where id = i.plan_id))) as t
        from private.fund_in_rows() i where i.d between p_from and p_to
        union all
        select jsonb_build_object('date', o.d, 'kind', 'out', 'amount', o.amount, 'name', o.note,
                                  'title', (select title from public.fund_causes where id = o.cause_id))
        from private.fund_out_rows() o where o.d between p_from and p_to
      ) z
    ), '[]'::jsonb) end,
    'dues', case when committee then coalesce((
      select jsonb_agg(jsonb_build_object(
               'plan_id', dp.id, 'title', dp.title, 'amount', dp.amount, 'period', dp.period,
               'members', (select count(*) from private.dues_rows(p_to) r where r.plan_id = dp.id and not r.exempt),
               'owing', (select count(*) from private.dues_rows(p_to) r where r.plan_id = dp.id and r.owed > 0),
               'owed', (select coalesce(sum(r.owed), 0) from private.dues_rows(p_to) r where r.plan_id = dp.id),
               'collected', coalesce((select sum(amount) from private.fund_in_rows() i
                                      where i.plan_id = dp.id and i.d between p_from and p_to), 0)))
      from public.fund_dues_plans dp where dp.active
    ), '[]'::jsonb) end
  );
end $$;

revoke execute on function private.dues_rows(date) from public, anon, authenticated;
revoke execute on function private.dues_reminders(date, uuid, boolean) from public, anon, authenticated;
revoke execute on function public.fund_dues_status(boolean) from public, anon;
revoke execute on function public.fund_dues_remind(uuid) from public, anon;
revoke execute on function public.fund_record_for(uuid, numeric, text, uuid, uuid) from public, anon;
revoke execute on function public.fund_report(date, date) from public, anon;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    -- 06:40 in Nigeria; only acts on the first day of a period.
    perform cron.schedule('bua-dues-reminders', '40 5 * * *', 'select private.dues_reminders()');
  end if;
end $$;

-- Backups and restores include the dues tables (before contributions, which refer to them).
create or replace function private.backup_data() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  t       text;
  chunk   jsonb;
  result  jsonb := jsonb_build_object('format', 'bua-family-backup', 'version', 1, 'taken_at', now());
begin
  foreach t in array array[
    'persons', 'unions', 'parent_child', 'person_education', 'person_occupations', 'person_skills',
    'person_contacts', 'person_health', 'profiles', 'app_settings',
    'posts', 'post_people', 'albums', 'photos', 'photo_people', 'events', 'event_rsvps', 'comments',
    'memories', 'stories', 'blood_requests', 'fund_settings', 'fund_causes', 'fund_dues_plans',
    'fund_dues_members', 'fund_contributions', 'fund_payouts', 'mentors', 'mentee_requests', 'opportunities',
    'polls', 'poll_options'
  ] loop
    execute format('select coalesce(jsonb_agg(to_jsonb(x)), ''[]'') from public.%I x', t) into chunk;
    result := result || jsonb_build_object(t, chunk);
  end loop;
  return result;
end $$;

create or replace function public.admin_restore(p_data jsonb, p_overwrite boolean default false, p_dry_run boolean default true)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  -- Parents before children, so references resolve.
  tables text[] := array[
    'persons', 'unions', 'parent_child', 'person_education', 'person_occupations', 'person_skills',
    'person_contacts', 'person_health', 'albums', 'posts', 'post_people', 'photos', 'photo_people',
    'events', 'event_rsvps', 'comments', 'memories', 'stories', 'blood_requests', 'fund_settings',
    'fund_causes', 'fund_dues_plans', 'fund_dues_members', 'fund_contributions', 'fund_payouts', 'mentors',
    'mentee_requests', 'opportunities', 'polls', 'poll_options'
  ];
  users     text[] := (select coalesce(array_agg(id::text), '{}') from auth.users);
  t         text;
  r         jsonb;
  c         text;
  optional  text[];
  required  text[];
  all_cols  text[];
  pk_cols   text[];
  pk        text;
  cols      text;
  ycols     text;
  ucols     text;
  uycols    text;
  n         int;
  added     int;
  updated   int;
  skipped   int;
  missing   boolean;
  result    jsonb := '{}';
begin
  if not public.is_admin() then
    raise exception 'Only admins can restore backups' using errcode = '42501';
  end if;
  if p_data ->> 'format' is distinct from 'bua-family-backup' then
    raise exception 'This is not a Bua Family backup' using errcode = '22023';
  end if;

  perform set_config('bua.restoring', 'on', true);
  if not p_dry_run then
    insert into private.restore_points (id, taken_at, data) values (true, now(), private.backup_data())
    on conflict (id) do update set taken_at = excluded.taken_at, data = excluded.data;
  end if;

  begin
    foreach t in array tables loop
      continue when jsonb_typeof(p_data -> t) is distinct from 'array';

      -- Columns that point at accounts: optional ones are cleared when the
      -- account is gone; rows whose required account is gone are skipped.
      select coalesce(array_agg(a.attname::text) filter (where not a.attnotnull), '{}'),
             coalesce(array_agg(a.attname::text) filter (where a.attnotnull), '{}')
        into optional, required
      from pg_constraint k
      join pg_attribute a on a.attrelid = k.conrelid and a.attnum = any (k.conkey)
      where k.contype = 'f' and k.conrelid = format('public.%I', t)::regclass
        and k.confrelid = 'auth.users'::regclass;

      select coalesce(array_agg(a.attname::text order by a.attnum), '{}')
        into all_cols
      from pg_attribute a
      where a.attrelid = format('public.%I', t)::regclass and a.attnum > 0 and not a.attisdropped;

      select coalesce(array_agg(a.attname::text), '{}')
        into pk_cols
      from pg_index i
      join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any (i.indkey)
      where i.indrelid = format('public.%I', t)::regclass and i.indisprimary;
      pk := (select string_agg(format('x.%1$I = y.%1$I', k), ' and ') from unnest(pk_cols) k);

      added := 0; updated := 0; skipped := 0;
      for r in select * from jsonb_array_elements(p_data -> t) loop
        missing := false;
        foreach c in array required loop
          missing := missing or not (r ->> c = any (users));
        end loop;
        if missing then
          skipped := skipped + 1;
          continue;
        end if;
        foreach c in array optional loop
          if r ->> c is not null and not (r ->> c = any (users)) then
            r := jsonb_set(r, array[c], 'null');
          end if;
        end loop;

        -- Only the columns the backup has, so newer columns keep their defaults.
        select string_agg(format('%I', k), ', ' order by array_position(all_cols, k)),
               string_agg(format('y.%I', k), ', ' order by array_position(all_cols, k)),
               string_agg(format('%I', k), ', ' order by array_position(all_cols, k)) filter (where k <> all (pk_cols)),
               string_agg(format('y.%I', k), ', ' order by array_position(all_cols, k)) filter (where k <> all (pk_cols))
          into cols, ycols, ucols, uycols
        from jsonb_object_keys(r) k
        where k = any (all_cols);
        continue when cols is null;

        begin
          execute format('insert into public.%1$I (%2$s) select %3$s from jsonb_populate_record(null::public.%1$I, $1) y
                          on conflict do nothing', t, cols, ycols)
            using r;
          get diagnostics n = row_count;
          if n > 0 then
            added := added + 1;
          elsif p_overwrite and ucols is not null then
            execute format(
              'update public.%1$I x set (%2$s) = row(%3$s)
               from jsonb_populate_record(null::public.%1$I, $1) y
               where %4$s and not (to_jsonb(x) @> (to_jsonb(y) - $2))',
              t, ucols, uycols, pk)
              using r, array(select k from unnest(all_cols) k where not r ? k) || array['updated_at', 'updated_by'];
            get diagnostics n = row_count;
            updated := updated + n;
          end if;
        exception when others then
          skipped := skipped + 1;
        end;
      end loop;
      result := result || jsonb_build_object(t, jsonb_build_object('added', added, 'updated', updated, 'skipped', skipped));
    end loop;

    if p_dry_run then
      raise exception using errcode = 'BU001', message = 'dry run';
    end if;
  exception when sqlstate 'BU001' then
    null;  -- rolled back; the counts stay
  end;

  perform set_config('bua.restoring', 'off', true);
  return result;
end $$;
