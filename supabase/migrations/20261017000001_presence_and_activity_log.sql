-- =============================================================================
-- Who is online, and who did what.
--
-- presence:      one row per member, refreshed every minute while the app is
--                open (and on every page change): platform, page, since when.
-- activity_log:  what members did: changes to family data (by triggers), pages
--                opened, sign-ins and sign-outs. Read by admins only.
-- Private conversations (mentorship) are logged without their content.
-- =============================================================================

create table public.presence (
  user_id     uuid primary key references auth.users on delete cascade,
  platform    text not null default 'web',
  page        text,
  started_at  timestamptz not null default now(),
  seen_at     timestamptz not null default now()
);
alter table public.presence enable row level security;
create policy presence_select on public.presence for select to authenticated using (public.is_admin());
revoke insert, update, delete on public.presence from authenticated, anon;

create table public.activity_log (
  id        bigint generated always as identity primary key,
  at        timestamptz not null default now(),
  user_id   uuid references auth.users on delete set null,
  action    text not null,   -- insert | update | delete | view | open | sign_in | sign_out
  entity    text not null,   -- the table, or 'page' / 'session'
  target    text,            -- the row's id, or the page's path
  detail    jsonb not null default '{}',
  platform  text
);
create index activity_log_at_idx on public.activity_log (at desc);
create index activity_log_user_idx on public.activity_log (user_id, at desc);
alter table public.activity_log enable row level security;
-- No policies: written by the functions below, read through admin_activity().
revoke all on public.activity_log from authenticated, anon;

-- Changes to family data, by whoever is signed in. Only a few fields are
-- kept: enough to say what it was and to open it.
create function private.log_change() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  who uuid := auth.uid();
  r jsonb := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  quiet text[] := array['updated_at', 'updated_by', 'last_message_at', 'last_message', 'last_message_by',
                        'mentor_read_at', 'asker_read_at', 'last_seen_at', 'last_platform', 'app_build'];
  private_ boolean := tg_table_name in ('mentor_asks', 'mentor_messages');
  label text;
begin
  if who is null then
    return null;   -- the system (reminders, imports by cron), not a person
  end if;
  if tg_op = 'UPDATE' and (to_jsonb(old) - quiet) = (to_jsonb(new) - quiet) then
    return null;   -- nothing anyone would call a change
  end if;
  label := case
    when private_ then null
    when tg_table_name = 'persons' then nullif(concat_ws(' ', r ->> 'first_name', r ->> 'last_name'), '')
    when tg_table_name = 'profiles' then r ->> 'display_name'
    else coalesce(r ->> 'title', r ->> 'question', r ->> 'patient_name', r ->> 'field', r ->> 'areas',
                  left(coalesce(r ->> 'body', r ->> 'caption', r ->> 'message', r ->> 'note'), 80))
  end;
  insert into public.activity_log (user_id, action, entity, target, detail, platform)
  values (who, lower(tg_op), tg_table_name, coalesce(r ->> 'id', r ->> 'code'),
          case when private_ then '{}'::jsonb else jsonb_strip_nulls(jsonb_build_object(
            'label', label,
            'kind', r ->> 'kind', 'status', r ->> 'status', 'role', r ->> 'role',
            'response', r ->> 'response', 'amount', r -> 'amount',
            'post_id', r ->> 'post_id', 'photo_id', r ->> 'photo_id', 'event_id', r ->> 'event_id',
            'poll_id', r ->> 'poll_id', 'album_id', r ->> 'album_id', 'cause_id', r ->> 'cause_id',
            'request_id', r ->> 'request_id',
            'person_id', coalesce(r ->> 'person_id', r ->> 'target_person_id', r ->> 'patient_person_id',
                                  r ->> 'child_id', r ->> 'partner1_id'))) end,
          (select p.platform from public.presence p where p.user_id = who));
  return null;
end $$;

do $$
declare
  t text;
begin
  foreach t in array array[
    'persons', 'unions', 'parent_child', 'change_requests', 'albums', 'posts', 'photos', 'events', 'event_rsvps',
    'likes', 'comments', 'blood_requests', 'blood_offers', 'memories', 'fund_causes', 'fund_contributions',
    'fund_payouts', 'mentors', 'mentee_requests', 'mentor_asks', 'mentor_messages', 'opportunities', 'polls',
    'poll_votes', 'stories', 'invites', 'app_settings'
  ] loop
    execute format('create trigger zz_log_change after insert or update or delete on public.%I
                      for each row execute function private.log_change()', t);
  end loop;
end $$;

-- Accounts: only approvals, roles and links, not every "last seen".
create trigger zz_log_change after update on public.profiles
  for each row when (old.status is distinct from new.status or old.role is distinct from new.role
                     or old.person_id is distinct from new.person_id or old.is_treasurer is distinct from new.is_treasurer)
  execute function private.log_change();

-- "I'm here, on this page." Every minute while the app is open, and on each
-- page change. A gap of over two minutes starts a new visit.
create function public.touch_presence(p_page text default null, p_platform text default 'web') returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  plat text := case when p_platform in ('android', 'ios', 'web') then p_platform else 'web' end;
  pg text := left(nullif(btrim(p_page), ''), 200);
  prev public.presence;
  fresh boolean;
begin
  if me is null or not public.is_active_member() then
    return;
  end if;
  select * into prev from public.presence where user_id = me;
  fresh := prev.user_id is null or prev.seen_at < now() - interval '2 minutes';
  insert into public.presence (user_id, platform, page, started_at, seen_at)
  values (me, plat, pg, now(), now())
  on conflict (user_id) do update
     set platform = excluded.platform,
         page = coalesce(excluded.page, public.presence.page),
         started_at = case when fresh then now() else public.presence.started_at end,
         seen_at = now();
  if fresh then
    insert into public.activity_log (user_id, action, entity, platform) values (me, 'open', 'session', plat);
  end if;
  if pg is not null and (fresh or pg is distinct from prev.page) then
    insert into public.activity_log (user_id, action, entity, target, platform) values (me, 'view', 'page', pg, plat);
  end if;
end $$;

-- The app went to the background or closed.
create function public.leave_presence() returns void
language sql security definer set search_path = '' as $$
  update public.presence set seen_at = least(seen_at, now() - interval '3 minutes') where user_id = (select auth.uid());
$$;

-- Signing in and out.
create function public.log_session(p_action text, p_platform text default 'web') returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or p_action not in ('sign_in', 'sign_out') then
    return;
  end if;
  insert into public.activity_log (user_id, action, entity, platform)
  values (auth.uid(), p_action, 'session', case when p_platform in ('android', 'ios', 'web') then p_platform else 'web' end);
  if p_action = 'sign_out' then
    perform public.leave_presence();
  end if;
end $$;

-- Admin: who has the app open now (seen in the last 2 minutes), and who
-- was here earlier within p_minutes.
create function public.admin_online(p_minutes int default 1440) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can see who is online' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'user_id', p.user_id, 'name', private.member_name(p.user_id), 'person_id', a.person_id,
             'platform', p.platform, 'page', p.page, 'started_at', p.started_at, 'seen_at', p.seen_at,
             'online', p.seen_at > now() - interval '2 minutes')
           order by p.seen_at desc)
    from public.presence p join public.profiles a on a.id = p.user_id
    where p.seen_at > now() - make_interval(mins => least(greatest(p_minutes, 2), 43200))
  ), '[]'::jsonb);
end $$;

-- Admin: the activity log, newest first, filtered; page with p_before (an id).
create function public.admin_activity(
  p_user uuid default null, p_entities text[] default null, p_actions text[] default null,
  p_from timestamptz default null, p_to timestamptz default null, p_search text default null,
  p_before bigint default null, p_limit int default 50
) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  q text := nullif(btrim(p_search), '');
begin
  if not public.is_admin() then
    raise exception 'Only admins can see the activity log' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', x.id, 'at', x.at, 'user_id', x.user_id, 'name', x.name, 'person_id', x.person_id,
             'action', x.action, 'entity', x.entity, 'target', x.target, 'detail', x.detail, 'platform', x.platform)
           order by x.id desc)
    from (
      select l.*, private.member_name(l.user_id) as name, a.person_id
      from public.activity_log l
      left join public.profiles a on a.id = l.user_id
      where (p_user is null or l.user_id = p_user)
        and (p_entities is null or l.entity = any (p_entities))
        and (p_actions is null or l.action = any (p_actions))
        and (p_from is null or l.at >= p_from)
        and (p_to is null or l.at < p_to)
        and (p_before is null or l.id < p_before)
        and (q is null or l.detail ->> 'label' ilike '%' || q || '%' or l.target ilike '%' || q || '%'
             or private.member_name(l.user_id) ilike '%' || q || '%')
      order by l.id desc
      limit least(greatest(coalesce(p_limit, 50), 1), 200)
    ) x
  ), '[]'::jsonb);
end $$;

revoke execute on function public.touch_presence(text, text) from public, anon;
revoke execute on function public.leave_presence() from public, anon;
revoke execute on function public.log_session(text, text) from public, anon;
revoke execute on function public.admin_online(int) from public, anon;
revoke execute on function public.admin_activity(uuid, text[], text[], timestamptz, timestamptz, text, bigint, int)
  from public, anon;
