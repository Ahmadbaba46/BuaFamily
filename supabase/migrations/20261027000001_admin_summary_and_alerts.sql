-- =============================================================================
-- For admins: a weekly summary, and alerts when something needs a hand.
--
-- Weekly summary (Monday morning): what happened in the last seven days and
-- what is waiting for them. Admins can turn it off for themselves (it's a
-- notification kind they can mute), or for everyone (app_settings).
--
-- Alerts (checked every 15 minutes), never muted:
--   * a blood request with no offer two hours after it was made;
--   * suggestions or new accounts waiting over three days (once a day);
--   * the welfare fund below the level admins set (once each time it drops
--     below; to admins and treasurers).
-- =============================================================================

alter type public.notification_kind add value if not exists 'weekly_summary';
alter type public.notification_kind add value if not exists 'admin_alert';

alter table public.app_settings
  add column weekly_summary boolean not null default true,
  add column fund_alert_below numeric check (fund_alert_below is null or fund_alert_below >= 0);

-- When the fund-low alert last went out (null again once the fund recovers).
create table private.alert_marks (
  key  text primary key,
  at   timestamptz
);

create function private.fund_balance() returns numeric
language sql stable security definer set search_path = '' as $$
  select (select coalesce(sum(amount), 0) from public.fund_contributions where status::text = 'confirmed')
       - (select coalesce(sum(amount), 0) from public.fund_payouts);
$$;

create function private.weekly_summary(p_day date default null) returns int
language plpgsql security definer set search_path = '' as $$
declare
  tz text := 'Africa/Lagos';
  today date := coalesce(p_day, (now() at time zone tz)::date);
  t1 timestamptz := today::timestamp at time zone tz;
  t0 timestamptz := t1 - interval '7 days';
  summary jsonb;
  n int;
begin
  if not coalesce((select weekly_summary from public.app_settings), true) then
    return 0;
  end if;
  summary := jsonb_build_object(
    'from', (today - 7)::text,
    'to', (today - 1)::text,
    'active', (select count(distinct user_id) from public.activity_days where day >= today - 7 and day < today),
    'new_accounts', (select count(*) from public.profiles where created_at >= t0 and created_at < t1),
    'people_added', (select count(*) from public.persons where created_at >= t0 and created_at < t1),
    'moments', (select count(*) from public.posts where created_at >= t0 and created_at < t1),
    'photos', (select count(*) from public.photos where created_at >= t0 and created_at < t1),
    'comments', (select count(*) from public.comments where created_at >= t0 and created_at < t1),
    'money_in', (select coalesce(sum(amount), 0) from public.fund_contributions
                 where status::text = 'confirmed' and coalesce(reviewed_at, created_at) >= t0
                   and coalesce(reviewed_at, created_at) < t1),
    'money_out', (select coalesce(sum(amount), 0) from public.fund_payouts where created_at >= t0 and created_at < t1),
    'events_coming', (select count(*) from public.events where starts_at >= t1 and starts_at < t1 + interval '7 days'),
    'waiting_suggestions', (select count(*) from public.change_requests where status = 'pending'),
    'waiting_accounts', (select count(*) from public.profiles where status = 'pending'),
    'open_blood', (select count(*) from public.blood_requests where status = 'open'));
  insert into public.notifications (user_id, kind, data, link, dedupe_key)
  select a.id, 'weekly_summary', summary, '/admin/metrics', 'weekly:' || today || ':' || a.id
  from public.profiles a
  where a.role = 'admin' and a.status = 'active'
  on conflict (dedupe_key) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;

create function private.admin_alerts(p_now timestamptz default null) returns int
language plpgsql security definer set search_path = '' as $$
declare
  now_ timestamptz := coalesce(p_now, now());
  today date := (now_ at time zone 'Africa/Lagos')::date;
  total int := 0;
  n int;
  suggestions int;
  accounts int;
  balance numeric;
  threshold numeric := (select fund_alert_below from public.app_settings);
  mark timestamptz;
begin
  -- Blood requests nobody has offered for, two hours on (not ones from long ago).
  insert into public.notifications (user_id, kind, data, link, dedupe_key)
  select a.id, 'admin_alert',
         jsonb_build_object('alert', 'blood_no_offer', 'request_id', r.id, 'blood_group', r.blood_group,
                            'patient', coalesce(nullif(btrim(r.patient_name), ''), private.person_name(pp), ''),
                            'hospital', r.hospital,
                            'hours', floor(extract(epoch from now_ - r.created_at) / 3600)::int),
         '/blood', 'alert:blood:' || r.id || ':' || a.id
  from public.blood_requests r
  left join public.persons pp on pp.id = r.patient_person_id
  cross join public.profiles a
  where r.status = 'open'
    and r.created_at <= now_ - interval '2 hours' and r.created_at > now_ - interval '2 days'
    and not exists (select 1 from public.blood_offers o where o.request_id = r.id)
    and a.role = 'admin' and a.status = 'active'
  on conflict (dedupe_key) do nothing;
  get diagnostics n = row_count;
  total := total + n;

  -- Waiting over three days: once a day, from eight in the morning.
  if extract(hour from now_ at time zone 'Africa/Lagos') >= 8 then
    suggestions := (select count(*) from public.change_requests
                    where status = 'pending' and created_at <= now_ - interval '3 days');
    accounts := (select count(*) from public.profiles
                 where status = 'pending' and created_at <= now_ - interval '3 days');
    if suggestions + accounts > 0 then
      insert into public.notifications (user_id, kind, data, link, dedupe_key)
      select a.id, 'admin_alert',
             jsonb_build_object('alert', 'waiting', 'suggestions', suggestions, 'accounts', accounts),
             case when suggestions = 0 then '/admin?tab=accounts' else '/admin' end,
             'alert:waiting:' || today || ':' || a.id
      from public.profiles a
      where a.role = 'admin' and a.status = 'active'
      on conflict (dedupe_key) do nothing;
      get diagnostics n = row_count;
      total := total + n;
    end if;
  end if;

  -- The fund dropped below the level admins set: tell them once, until it recovers.
  balance := private.fund_balance();
  if threshold is not null and balance < threshold then
    insert into private.alert_marks as m (key, at) values ('fund_low', now_)
    on conflict (key) do update set at = excluded.at where m.at is null
    returning m.at into mark;
    if mark is not null then
      insert into public.notifications (user_id, kind, data, link, dedupe_key)
      select a.id, 'admin_alert',
             jsonb_build_object('alert', 'fund_low', 'balance', balance, 'threshold', threshold),
             '/fund', 'alert:fund:' || extract(epoch from mark)::bigint || ':' || a.id
      from public.profiles a
      where a.status = 'active' and (a.role = 'admin' or a.is_treasurer)
      on conflict (dedupe_key) do nothing;
      get diagnostics n = row_count;
      total := total + n;
    end if;
  else
    update private.alert_marks set at = null where key = 'fund_low' and at is not null;
  end if;
  return total;
end $$;

revoke execute on function private.fund_balance() from public, anon, authenticated;
revoke execute on function private.weekly_summary(date) from public, anon, authenticated;
revoke execute on function private.admin_alerts(timestamptz) from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    -- Monday 07:00 in Nigeria.
    perform cron.schedule('bua-weekly-summary', '0 6 * * 1', 'select private.weekly_summary()');
    perform cron.schedule('bua-admin-alerts', '*/15 * * * *', 'select private.admin_alerts()');
  end if;
end $$;
