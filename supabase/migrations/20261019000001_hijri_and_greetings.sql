-- =============================================================================
-- Islamic (Hijri) dates and greetings.
--
-- private.hijri() is the same tabular method as the app (models/hijri.dart).
-- Admins set hijri_offset (-2..2 days) to follow the moon sighting announced
-- in Nigeria. Each morning, on Ramadan's first day, both Eids and the Islamic
-- new year, everyone gets a greeting; the day before Ramadan and the Eids, a
-- "expected tomorrow" notice.
-- =============================================================================

alter type public.notification_kind add value if not exists 'occasion';

alter table public.app_settings
  add column hijri_offset smallint not null default 0 check (hijri_offset between -2 and 2),
  add column islamic_greetings boolean not null default true;

create function private.hijri(p_day date, p_offset int default 0)
returns table (year int, month int, day int)
language plpgsql immutable set search_path = '' as $$
declare
  d date := p_day + p_offset;
  y int := extract(year from d);
  m int := extract(month from d);
  a int := (14 - m) / 12;
  yy int := y + 4800 - a;
  mm int := m + 12 * a - 3;
  jd int := extract(day from d)::int + (153 * mm + 2) / 5 + 365 * yy + yy / 4 - yy / 100 + yy / 400 - 32045;
  l int := jd - 1948440 + 10632;
  n int := (l - 1) / 10631;
  j int;
begin
  l := l - 10631 * n + 354;
  j := ((10985 - l) / 5316) * ((50 * l) / 17719) + (l / 5670) * ((43 * l) / 15238);
  l := l - ((30 - j) / 15) * ((17719 * j) / 50) - (j / 16) * ((15238 * j) / 43) + 29;
  month := (24 * l) / 709;
  day := l - (709 * month) / 24;
  year := 30 * n + j - 30;
  return next;
end $$;

-- The morning greeting (or the evening-before notice). p_day for tests.
create function private.islamic_greetings(p_day date default null) returns int
language plpgsql security definer set search_path = '' as $$
declare
  s public.app_settings;
  today date;
  h record;
  t record;
  code text;
  eve boolean := false;
  n int;
begin
  select * into s from public.app_settings;
  if not coalesce(s.islamic_greetings, true) then
    return 0;
  end if;
  today := coalesce(p_day, (now() at time zone coalesce(s.timezone, 'Africa/Lagos'))::date);
  select * into h from private.hijri(today, s.hijri_offset);
  select * into t from private.hijri(today + 1, s.hijri_offset);
  code := case
    when h.month = 9 and h.day = 1 then 'ramadan'
    when h.month = 10 and h.day = 1 then 'eid_al_fitr'
    when h.month = 12 and h.day = 10 then 'eid_al_adha'
    when h.month = 1 and h.day = 1 then 'islamic_new_year'
  end;
  if code is null then
    eve := true;
    code := case
      when t.month = 9 and t.day = 1 then 'ramadan'
      when t.month = 10 and t.day = 1 then 'eid_al_fitr'
      when t.month = 12 and t.day = 10 then 'eid_al_adha'
    end;
  end if;
  if code is null then
    return 0;
  end if;

  insert into public.notifications (user_id, kind, data, link, dedupe_key)
  select p.id, 'occasion',
         jsonb_build_object('occasion', code, 'eve', eve, 'hijri_year', case when eve then t.year else h.year end,
                            'family', s.family_name),
         '/reminders',
         'occasion:' || code || ':' || (case when eve then t.year else h.year end) || ':' || eve || ':' || p.id
  from public.profiles p
  where p.status = 'active'
  on conflict (dedupe_key) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;

revoke execute on function private.hijri(date, int) from public, anon, authenticated;
revoke execute on function private.islamic_greetings(date) from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    -- 06:35 in Nigeria.
    perform cron.schedule('bua-islamic-greetings', '35 5 * * *', 'select private.islamic_greetings()');
  end if;
end $$;
