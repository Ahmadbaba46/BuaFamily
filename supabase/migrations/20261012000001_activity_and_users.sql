-- =============================================================================
-- Activity tracking and the admin's users list
--
-- * The app reports once per visit that the member opened it (and from which
--   platform, and for the Android app which build). That gives "last seen",
--   "active days" and, later, the admin metrics (daily / monthly active).
-- * admin_users(): every account with what an admin needs to search, filter
--   and sort them: linked person, devices, last seen, activity, posts.
-- =============================================================================

alter table public.profiles
  add column last_seen_at timestamptz,
  add column last_platform text,
  add column app_build int;

-- One row per member per day per platform they used.
create table public.activity_days (
  user_id   uuid not null references auth.users on delete cascade,
  day       date not null,
  platform  text not null default 'web' check (platform in ('android', 'ios', 'web')),
  primary key (user_id, day, platform)
);
create index activity_days_day_idx on public.activity_days (day);
alter table public.activity_days enable row level security;
-- No policies: written by touch_activity(), read by admin functions only.

create function public.touch_activity(p_platform text default 'web', p_build int default null) returns void
language plpgsql security definer set search_path = '' as $$
declare
  platform text := case when p_platform in ('android', 'ios', 'web') then p_platform else 'web' end;
begin
  if auth.uid() is null or not exists (
    select 1 from public.profiles where id = auth.uid() and status in ('active', 'pending')
  ) then
    return;
  end if;
  insert into public.activity_days (user_id, day, platform)
  values (auth.uid(), (now() at time zone 'Africa/Lagos')::date, platform)
  on conflict do nothing;
  update public.profiles
     set last_seen_at = now(),
         last_platform = platform,
         app_build = coalesce(p_build, app_build)
   where id = auth.uid();
end $$;
revoke execute on function public.touch_activity(text, int) from public, anon;
grant execute on function public.touch_activity(text, int) to authenticated;

create function public.admin_users() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can see accounts' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(
      to_jsonb(p)
      || jsonb_build_object(
        'person_name', (select private.person_name(x) from public.persons x where x.id = p.person_id),
        'devices', coalesce((select jsonb_object_agg(platform, n)
                             from (select platform, count(*) n from public.push_tokens t
                                   where t.user_id = p.id group by platform) d), '{}'::jsonb),
        'active_days_30', (select count(distinct day) from public.activity_days a
                           where a.user_id = p.id and a.day > current_date - 30),
        'posts', (select count(*) from public.posts x where x.author_id = p.id),
        'comments', (select count(*) from public.comments x where x.author_id = p.id)
      )
      order by p.created_at)
    from public.profiles p
  ), '[]'::jsonb);
end $$;
revoke execute on function public.admin_users() from public, anon;
