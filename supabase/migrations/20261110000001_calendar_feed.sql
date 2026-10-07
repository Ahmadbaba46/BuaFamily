-- =============================================================================
-- Family calendar feed: a private link per member that Google Calendar, Apple
-- Calendar or Outlook subscribe to, and keep up to date by themselves.
--
-- It holds the family's events (from three months ago on), the birthdays of
-- living relatives whose exact date is known (every year), and the
-- remembrance days of the relatives the member chose to be reminded of. The
-- member can leave birthdays or remembrance days out, get a new link (the old
-- one stops working) or turn it off.
--
-- The link carries a long random token; the 'calendar' Edge Function reads
-- the feed with calendar_feed(token), which only the service role may call.
-- A member who is no longer active gets an empty calendar.
-- =============================================================================

create table public.calendar_feeds (
  user_id              uuid primary key references auth.users on delete cascade,
  token                text not null unique,
  enabled              boolean not null default true,
  include_birthdays    boolean not null default true,
  include_remembrance  boolean not null default true,
  created_at           timestamptz not null default now(),
  -- When a calendar app last fetched it.
  last_fetched_at      timestamptz
);

alter table public.calendar_feeds enable row level security;
create policy calendar_feeds_select on public.calendar_feeds for select to authenticated
  using (user_id = (select auth.uid()));
revoke insert, update, delete on public.calendar_feeds from authenticated, anon;

create function private.new_calendar_token() returns text
language sql volatile set search_path = '' as $$
  select replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
$$;

-- My calendar link's token (turned on, and made if there wasn't one); with
-- p_reset, a new one (the old link stops working).
create function public.calendar_feed_link(p_reset boolean default false) returns text
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  t text;
begin
  if me is null or not public.is_active_member() then
    raise exception 'Only family members have a calendar link' using errcode = '42501';
  end if;
  insert into public.calendar_feeds as f (user_id, token)
  values (me, private.new_calendar_token())
  on conflict (user_id) do update
    set enabled = true,
        token = case when p_reset then private.new_calendar_token() else f.token end
  returning token into t;
  return t;
end $$;

-- What it holds, or turning it off. Null leaves a setting as it is.
create function public.calendar_feed_settings(p_enabled boolean default null, p_birthdays boolean default null,
                                              p_remembrance boolean default null) returns void
language sql security definer set search_path = '' as $$
  update public.calendar_feeds
     set enabled = coalesce(p_enabled, enabled),
         include_birthdays = coalesce(p_birthdays, include_birthdays),
         include_remembrance = coalesce(p_remembrance, include_remembrance)
   where user_id = (select auth.uid());
$$;

-- For the 'calendar' Edge Function: everything in the calendar of whoever
-- holds this token, or null when the link is wrong or turned off.
create function public.calendar_feed(p_token text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  f public.calendar_feeds;
  p public.profiles;
  s public.app_settings;
begin
  select * into f from public.calendar_feeds where token = p_token and enabled;
  if not found or length(coalesce(p_token, '')) < 32 then
    return null;
  end if;
  update public.calendar_feeds set last_fetched_at = now() where user_id = f.user_id;
  select * into p from public.profiles where id = f.user_id;
  select * into s from public.app_settings limit 1;
  if p.status is distinct from 'active' then
    return jsonb_build_object('family_name', s.family_name, 'timezone', s.timezone, 'locale', coalesce(p.locale, 'en'),
                              'events', '[]'::jsonb, 'birthdays', '[]'::jsonb, 'remembrance', '[]'::jsonb);
  end if;
  return jsonb_build_object(
    'family_name', s.family_name,
    'timezone', s.timezone,
    'locale', p.locale,
    'events', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', e.id, 'title', e.title, 'category', e.category, 'details', e.details,
               'starts_at', e.starts_at, 'ends_at', e.ends_at, 'place', e.place, 'address', e.address,
               'updated_at', e.updated_at,
               'rsvp', (select v.response from public.event_rsvps v where v.event_id = e.id and v.user_id = f.user_id))
             order by e.starts_at)
        from (select * from public.events
               where starts_at > now() - interval '90 days'
               order by starts_at limit 500) e), '[]'::jsonb),
    'birthdays', case when not f.include_birthdays then '[]'::jsonb else coalesce((
      select jsonb_agg(jsonb_build_object('person_id', x.id, 'name', private.person_name(x), 'birth_date', x.birth_date))
        from public.persons x
       where x.is_living and x.birth_date is not null and not x.birth_date_approx
         and x.id is distinct from p.person_id), '[]'::jsonb) end,
    'remembrance', case when not f.include_remembrance then '[]'::jsonb else coalesce((
      select jsonb_agg(jsonb_build_object('person_id', x.id, 'name', private.person_name(x), 'death_date', x.death_date))
        from public.remembrance_reminders r
        join public.persons x on x.id = r.person_id
       where r.user_id = f.user_id and not x.is_living and x.death_date is not null and not x.death_date_approx),
      '[]'::jsonb) end
  );
end $$;

revoke execute on function private.new_calendar_token() from public, anon, authenticated;
revoke execute on function public.calendar_feed_link(boolean) from public, anon;
revoke execute on function public.calendar_feed_settings(boolean, boolean, boolean) from public, anon;
revoke execute on function public.calendar_feed(text) from public, anon, authenticated;
grant execute on function public.calendar_feed(text) to service_role;
