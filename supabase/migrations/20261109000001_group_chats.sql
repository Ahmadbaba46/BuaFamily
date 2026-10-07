-- =============================================================================
-- Group chats, with everything private messages have: photos, voice notes
-- (with their waveform), replies, reactions, delete for everyone, "typing…"
-- (Realtime broadcast in the app) and ticks (two grey once every member's
-- phone has it, two blue once every member has read it).
--
-- * Anyone in the family can start a group and is its first admin. Group
--   admins add and remove members, make others admin, rename it, change its
--   photo and description, and can let only admins send. Members can leave;
--   if the last admin leaves, the longest-standing member becomes admin.
-- * Only current members read a group, and only what was sent since they
--   joined: not family admins, not backups. Leaving or being removed keeps
--   the row (left_at), so nothing here deletes rows.
-- * "Musa added Bello" and the like are messages of kind 'event' (written
--   only by the functions here); the app words them in the reader's language.
-- * The family admins' messages switch turns groups off too.
-- * Photos and voice notes go in the private 'dm' bucket under
--   g/<group>/<sender>/...; the group photo the same way.
-- * A member can mute a group: no notifications from it.
-- =============================================================================

alter type public.notification_kind add value if not exists 'group_message';
alter type public.notification_kind add value if not exists 'group_added';

create table public.chat_groups (
  id                 uuid primary key default gen_random_uuid(),
  name               text not null check (length(btrim(name)) between 1 and 80),
  about              text check (length(about) <= 500),
  photo_path         text,
  only_admins_send   boolean not null default false,
  created_by         uuid default auth.uid() references auth.users on delete set null,
  created_at         timestamptz not null default now(),
  last_message_at    timestamptz,
  last_message       text,
  last_message_by    uuid references auth.users on delete set null,
  last_message_kind  text,
  -- When the last message is a notice ("Musa added Bello"), what it says.
  last_event         jsonb
);
create index chat_groups_created_by_idx on public.chat_groups (created_by);
create index chat_groups_last_message_by_idx on public.chat_groups (last_message_by);

create table public.chat_group_members (
  group_id      uuid not null references public.chat_groups on delete cascade,
  user_id       uuid not null references auth.users on delete cascade,
  role          text not null default 'member' check (role in ('admin', 'member')),
  added_by      uuid references auth.users on delete set null,
  joined_at     timestamptz not null default now(),
  -- Set when they leave or are removed; cleared if they are added again.
  left_at       timestamptz,
  read_at       timestamptz,
  delivered_at  timestamptz,
  muted         boolean not null default false,
  primary key (group_id, user_id)
);
create index chat_group_members_user_idx on public.chat_group_members (user_id);
create index chat_group_members_added_by_idx on public.chat_group_members (added_by);

create table public.group_messages (
  id           uuid primary key default gen_random_uuid(),
  group_id     uuid not null references public.chat_groups on delete cascade,
  author_id    uuid not null default auth.uid() references auth.users on delete cascade,
  body         text not null check (length(btrim(body)) between 1 and 4000),
  kind         text not null default 'text' check (kind in ('text', 'photo', 'voice', 'event')),
  media_path   text,
  duration_ms  int check (duration_ms is null or duration_ms between 0 and 3600000),
  waveform     smallint[] check (waveform is null or cardinality(waveform) <= 120),
  reply_to     uuid references public.group_messages on delete set null,
  -- For kind 'event': {"type": "created" | "added" | "removed" | "left" |
  -- "renamed" | "photo" | "only_admins", "user": <who it was about>, ...}.
  event        jsonb,
  deleted_at   timestamptz,
  deleted_by   uuid references auth.users on delete set null,
  -- The moment itself (not the transaction's), so the notices a function
  -- writes together keep their order.
  created_at   timestamptz not null default clock_timestamp(),
  constraint group_messages_media check (deleted_at is not null or (kind in ('text', 'event')) = (media_path is null)),
  constraint group_messages_event check ((kind = 'event') = (event is not null))
);
create index group_messages_group_idx on public.group_messages (group_id, created_at);
create index group_messages_author_idx on public.group_messages (author_id);
create index group_messages_reply_idx on public.group_messages (reply_to);
create index group_messages_deleted_by_idx on public.group_messages (deleted_by);

create table public.group_reactions (
  message_id  uuid not null references public.group_messages on delete cascade,
  user_id     uuid not null default auth.uid() references auth.users on delete cascade,
  -- Filled from the message (whatever the app sends).
  group_id    uuid not null references public.chat_groups on delete cascade,
  emoji       text not null check (length(emoji) between 1 and 16),
  created_at  timestamptz not null default now(),
  primary key (message_id, user_id)
);
create index group_reactions_group_idx on public.group_reactions (group_id);
create index group_reactions_user_idx on public.group_reactions (user_id);

-- -----------------------------------------------------------------------------
-- Who is in, who runs it
-- -----------------------------------------------------------------------------
create function public.in_group(p_group uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.chat_group_members m
                 where m.group_id = p_group and m.user_id = (select auth.uid()) and m.left_at is null);
$$;

create function public.group_admin(p_group uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.chat_group_members m
                 where m.group_id = p_group and m.user_id = (select auth.uid()) and m.left_at is null
                   and m.role = 'admin');
$$;

-- A message I may read: in a group I'm in, sent since I (last) joined.
create function public.group_message_visible(p_group uuid, p_at timestamptz) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.chat_group_members m
                 where m.group_id = p_group and m.user_id = (select auth.uid()) and m.left_at is null
                   and m.joined_at <= p_at);
$$;

alter table public.chat_groups enable row level security;
alter table public.chat_group_members enable row level security;
alter table public.group_messages enable row level security;
alter table public.group_reactions enable row level security;

create policy chat_groups_select on public.chat_groups for select to authenticated
  using (public.messages_enabled() and public.in_group(id));
revoke insert, update, delete on public.chat_groups from authenticated, anon;

create policy chat_group_members_select on public.chat_group_members for select to authenticated
  using (public.messages_enabled() and public.in_group(group_id));
revoke insert, update, delete on public.chat_group_members from authenticated, anon;

create policy group_messages_select on public.group_messages for select to authenticated
  using (public.messages_enabled() and public.group_message_visible(group_id, created_at));
-- A file must be in this group's folder, under the sender's own name; when
-- only admins may send, only admins can.
create policy group_messages_insert on public.group_messages for insert to authenticated
  with check (public.messages_enabled() and public.is_active_member()
              and author_id = (select auth.uid()) and public.in_group(group_id)
              and kind <> 'event' and event is null and deleted_at is null and deleted_by is null
              and (media_path is null
                   or (split_part(media_path, '/', 1) = 'g'
                       and split_part(media_path, '/', 2) = group_id::text
                       and split_part(media_path, '/', 3) = (select auth.uid())::text))
              and (public.group_admin(group_id)
                   or not (select g.only_admins_send from public.chat_groups g where g.id = group_id)));
revoke update, delete on public.group_messages from authenticated, anon;

create policy group_reactions_select on public.group_reactions for select to authenticated
  using (public.messages_enabled() and public.in_group(group_id));
create policy group_reactions_insert on public.group_reactions for insert to authenticated
  with check (public.messages_enabled() and public.is_active_member() and user_id = (select auth.uid())
              and public.in_group(group_id));
create policy group_reactions_update on public.group_reactions for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and public.in_group(group_id));
create policy group_reactions_remove on public.group_reactions for delete to authenticated
  using (user_id = (select auth.uid()));

-- -----------------------------------------------------------------------------
-- Messages: replies stay in the group; the group's summary; notifications
-- -----------------------------------------------------------------------------
create function private.group_message_before() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.reply_to is not null and not exists (
       select 1 from public.group_messages m
        where m.id = new.reply_to and m.group_id = new.group_id and m.kind <> 'event') then
    new.reply_to := null;
  end if;
  return new;
end $$;
create trigger group_messages_before before insert on public.group_messages
  for each row execute function private.group_message_before();

create function private.on_group_message() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  g public.chat_groups;
  preview text := case when new.kind = 'event' then ''
                        when new.kind = 'text' or new.body not in ('📷', '🎤') then new.body else '' end;
begin
  update public.chat_groups
     set last_message_at = new.created_at, last_message = left(preview, 200), last_message_by = new.author_id,
         last_message_kind = new.kind, last_event = new.event
   where id = new.group_id
  returning * into g;
  -- The sender has read (and has) what they sent.
  update public.chat_group_members
     set read_at = new.created_at, delivered_at = new.created_at
   where group_id = new.group_id and user_id = new.author_id and left_at is null;

  if new.kind <> 'event' then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    select m.user_id, 'group_message',
           jsonb_build_object('group_id', g.id, 'group', g.name, 'name', private.member_name(new.author_id),
                              'body', left(preview, 160), 'message_kind', new.kind),
           '/groups/' || g.id, new.author_id
      from public.chat_group_members m
     where m.group_id = g.id and m.left_at is null and not m.muted and m.user_id <> new.author_id;
  end if;
  return new;
end $$;
create trigger group_messages_after after insert on public.group_messages
  for each row execute function private.on_group_message();

-- "Musa added Bello" and the like.
create function private.group_event(p_group uuid, p_actor uuid, p_event jsonb) returns void
language sql security definer set search_path = '' as $$
  insert into public.group_messages (group_id, author_id, body, kind, event)
  values (p_group, p_actor, coalesce(p_event ->> 'type', 'event'), 'event', p_event);
$$;

-- Adds (or re-adds) active members who aren't in it; tells each of them.
create function private.group_add_members(p_group uuid, p_users uuid[]) returns int
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  u uuid;
  g public.chat_groups;
  n int := 0;
begin
  select * into g from public.chat_groups where id = p_group;
  for u in
    select distinct x from unnest(coalesce(p_users, '{}')) x
     where x is not null and x <> me
       and exists (select 1 from public.profiles p where p.id = x and p.status = 'active')
       and not exists (select 1 from public.chat_group_members m
                        where m.group_id = p_group and m.user_id = x and m.left_at is null)
       and not public.blocked_between(me, x)
  loop
    insert into public.chat_group_members as m (group_id, user_id, role, added_by, joined_at)
    values (p_group, u, 'member', me, now())
    on conflict (group_id, user_id) do update
      set role = 'member', added_by = me, joined_at = now(), left_at = null,
          read_at = null, delivered_at = null, muted = false;
    perform private.group_event(p_group, me, jsonb_build_object('type', 'added', 'user', u));
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (u, 'group_added',
            jsonb_build_object('group_id', p_group, 'group', g.name, 'name', private.member_name(me)),
            '/groups/' || p_group, me);
    n := n + 1;
  end loop;
  return n;
end $$;

create function private.group_check(p_group uuid, p_admin boolean) returns void
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.messages_enabled() then
    raise exception 'Messages are turned off by the family admins' using errcode = '42501';
  end if;
  if auth.uid() is null or not public.is_active_member() then
    raise exception 'Only family members can use groups' using errcode = '42501';
  end if;
  if not public.in_group(p_group) then
    raise exception 'You are not in this group' using errcode = '42501';
  end if;
  if p_admin and not public.group_admin(p_group) then
    raise exception 'Only group admins can do this' using errcode = '42501';
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- What members do
-- -----------------------------------------------------------------------------
create function public.group_create(p_name text, p_members uuid[], p_about text default null) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  new_id uuid;
begin
  if not public.messages_enabled() then
    raise exception 'Messages are turned off by the family admins' using errcode = '42501';
  end if;
  if me is null or not public.is_active_member() then
    raise exception 'Only family members can start a group' using errcode = '42501';
  end if;
  insert into public.chat_groups (name, about, created_by)
  values (btrim(p_name), nullif(btrim(coalesce(p_about, '')), ''), me)
  returning id into new_id;
  insert into public.chat_group_members (group_id, user_id, role, added_by, joined_at)
  values (new_id, me, 'admin', me, now());
  perform private.group_event(new_id, me, jsonb_build_object('type', 'created', 'name', btrim(p_name)));
  perform private.group_add_members(new_id, p_members);
  return new_id;
end $$;

create function public.group_add(p_group uuid, p_users uuid[]) returns int
language plpgsql security definer set search_path = '' as $$
begin
  perform private.group_check(p_group, true);
  return private.group_add_members(p_group, p_users);
end $$;

create function public.group_remove(p_group uuid, p_user uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform private.group_check(p_group, true);
  if p_user = auth.uid() then
    raise exception 'Leave the group instead' using errcode = '22023';
  end if;
  update public.chat_group_members set left_at = now()
   where group_id = p_group and user_id = p_user and left_at is null;
  if found then
    perform private.group_event(p_group, auth.uid(), jsonb_build_object('type', 'removed', 'user', p_user));
  end if;
end $$;

create function public.group_leave(p_group uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
begin
  if not public.in_group(p_group) then
    return;
  end if;
  perform private.group_event(p_group, me, jsonb_build_object('type', 'left', 'user', me));
  update public.chat_group_members set left_at = now() where group_id = p_group and user_id = me;
  -- Someone must be able to run it.
  if not exists (select 1 from public.chat_group_members
                  where group_id = p_group and left_at is null and role = 'admin') then
    update public.chat_group_members set role = 'admin'
     where (group_id, user_id) = (select group_id, user_id from public.chat_group_members
                                   where group_id = p_group and left_at is null
                                   order by joined_at limit 1);
  end if;
end $$;

create function public.group_set_admin(p_group uuid, p_user uuid, p_admin boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform private.group_check(p_group, true);
  if not p_admin and p_user = auth.uid()
     and (select count(*) from public.chat_group_members
           where group_id = p_group and left_at is null and role = 'admin') < 2 then
    raise exception 'Make someone else admin first' using errcode = '22023';
  end if;
  update public.chat_group_members set role = case when p_admin then 'admin' else 'member' end
   where group_id = p_group and user_id = p_user and left_at is null;
end $$;

-- Group admins: name, description, who may send. Null leaves a field as it is.
create function public.group_update(p_group uuid, p_name text default null, p_about text default null,
                                    p_only_admins boolean default null) returns void
language plpgsql security definer set search_path = '' as $$
declare
  g public.chat_groups;
begin
  perform private.group_check(p_group, true);
  select * into g from public.chat_groups where id = p_group for update;
  update public.chat_groups
     set name = coalesce(nullif(btrim(p_name), ''), name),
         about = case when p_about is null then about else nullif(btrim(p_about), '') end,
         only_admins_send = coalesce(p_only_admins, only_admins_send)
   where id = p_group;
  if nullif(btrim(p_name), '') is not null and btrim(p_name) <> g.name then
    perform private.group_event(p_group, auth.uid(), jsonb_build_object('type', 'renamed', 'name', btrim(p_name)));
  end if;
  if p_only_admins is not null and p_only_admins <> g.only_admins_send then
    perform private.group_event(p_group, auth.uid(), jsonb_build_object('type', 'only_admins', 'on', p_only_admins));
  end if;
end $$;

-- Group admins: the group's photo (uploaded first to g/<group>/<me>/...), or none.
create function public.group_set_photo(p_group uuid, p_path text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform private.group_check(p_group, true);
  if p_path is not null and (split_part(p_path, '/', 1) <> 'g' or split_part(p_path, '/', 2) <> p_group::text
                             or split_part(p_path, '/', 3) <> auth.uid()::text) then
    raise exception 'Upload the photo to the group''s folder first' using errcode = '22023';
  end if;
  update public.chat_groups set photo_path = p_path where id = p_group;
  perform private.group_event(p_group, auth.uid(), jsonb_build_object('type', 'photo', 'removed', p_path is null));
end $$;

create function public.group_mute(p_group uuid, p_muted boolean) returns void
language sql security definer set search_path = '' as $$
  update public.chat_group_members set muted = p_muted
   where group_id = p_group and user_id = (select auth.uid()) and left_at is null;
$$;

-- "I've read it" (which also means my phone has it).
create function public.group_mark_read(p_group uuid) returns void
language sql security definer set search_path = '' as $$
  update public.chat_group_members set read_at = now(), delivered_at = now()
   where group_id = p_group and user_id = (select auth.uid()) and left_at is null;
$$;

-- Delete for everyone: the sender, or a group admin.
create function public.group_delete_message(p_message uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  m public.group_messages;
begin
  select * into m from public.group_messages where id = p_message for update;
  if not found or m.kind = 'event'
     or not (m.author_id = auth.uid() and public.in_group(m.group_id) or public.group_admin(m.group_id)) then
    raise exception 'You can only delete your own messages' using errcode = '42501';
  end if;
  if m.deleted_at is not null then
    return;
  end if;
  update public.group_messages
     set deleted_at = now(), deleted_by = auth.uid(), body = '🚫', media_path = null, duration_ms = null,
         waveform = null
   where id = p_message;
  update public.chat_groups set last_message = '', last_message_kind = 'deleted'
   where id = m.group_id and last_message_at = m.created_at;
end $$;

-- My phone has what was sent to me: private conversations and groups (the
-- app and the background push handler already call this).
create or replace function public.dm_mark_delivered() returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
begin
  update public.dm_threads
     set a_delivered_at = case when user_a = me then now() else a_delivered_at end,
         b_delivered_at = case when user_b = me then now() else b_delivered_at end
   where me in (user_a, user_b)
     and last_message_by is distinct from me
     and last_message_at > coalesce(case when user_a = me then a_delivered_at else b_delivered_at end,
                                    '-infinity'::timestamptz);
  update public.chat_group_members m
     set delivered_at = now()
    from public.chat_groups g
   where g.id = m.group_id and m.user_id = me and m.left_at is null
     and g.last_message_by is distinct from me
     and g.last_message_at > coalesce(m.delivered_at, '-infinity'::timestamptz);
end $$;

-- -----------------------------------------------------------------------------
-- Reactions
-- -----------------------------------------------------------------------------
create function private.group_reaction_before() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  m public.group_messages;
begin
  select * into m from public.group_messages where id = new.message_id;
  if not found or m.deleted_at is not null or m.kind = 'event' then
    raise exception 'This message can''t take reactions' using errcode = '55000';
  end if;
  new.group_id := m.group_id;
  return new;
end $$;
create trigger group_reactions_before before insert or update on public.group_reactions
  for each row execute function private.group_reaction_before();

create function private.group_reaction_notify() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  author uuid := (select author_id from public.group_messages where id = new.message_id);
begin
  if author is distinct from new.user_id and (tg_op = 'INSERT' or new.emoji is distinct from old.emoji)
     and exists (select 1 from public.chat_group_members m
                  where m.group_id = new.group_id and m.user_id = author and m.left_at is null and not m.muted) then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (author, 'group_message',
            jsonb_build_object('group_id', new.group_id,
                               'group', (select name from public.chat_groups where id = new.group_id),
                               'name', private.member_name(new.user_id), 'body', new.emoji,
                               'message_kind', 'reaction'),
            '/groups/' || new.group_id, new.user_id);
  end if;
  return new;
end $$;
create trigger group_reactions_notify after insert or update on public.group_reactions
  for each row execute function private.group_reaction_notify();

-- -----------------------------------------------------------------------------
-- Reporting a group message (kind 'message', like a private one)
-- -----------------------------------------------------------------------------
create or replace function public.report_content(p_kind text, p_target uuid, p_reason text, p_note text default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  owner uuid;
  snap jsonb;
  link text;
  new_id uuid;
begin
  if me is null or not public.is_active_member() then
    raise exception 'Only family members can report' using errcode = '42501';
  end if;
  if p_reason not in ('child_safety', 'abuse', 'spam', 'other') then
    raise exception 'Choose a reason' using errcode = '22023';
  end if;

  -- What it is, whose it is, and a copy of it; only what the reporter can see.
  case p_kind
    when 'post' then
      select p.author_id, jsonb_build_object('body', left(p.body, 2000)), '/posts/' || p.id
        into owner, snap, link from public.posts p where p.id = p_target;
    when 'photo' then
      select ph.uploaded_by, jsonb_build_object('caption', ph.caption, 'storage_path', ph.storage_path), '/photo/' || ph.id
        into owner, snap, link from public.photos ph where ph.id = p_target;
    when 'comment' then
      select c.author_id, jsonb_build_object('body', left(c.body, 2000)),
             case when c.post_id is not null then '/posts/' || c.post_id
                  when c.photo_id is not null then '/photo/' || c.photo_id
                  else '/events/' || c.event_id end
        into owner, snap, link from public.comments c where c.id = p_target;
    when 'profile' then
      select pr.id, jsonb_build_object('name', private.person_name(pe)), '/person/' || pe.id
        into owner, snap, link
        from public.persons pe left join public.profiles pr on pr.person_id = pe.id where pe.id = p_target;
      if snap is null then
        raise exception 'Not found' using errcode = 'P0002';
      end if;
    when 'member' then
      select pr.id, jsonb_build_object('name', private.member_name(pr.id)),
             case when pr.person_id is not null then '/person/' || pr.person_id end
        into owner, snap, link from public.profiles pr where pr.id = p_target;
    when 'message' then
      select m.author_id, jsonb_build_object('body', left(m.body, 2000), 'sent_at', m.created_at), null
        into owner, snap, link
        from public.dm_messages m join public.dm_threads t on t.id = m.thread_id
       where m.id = p_target and me in (t.user_a, t.user_b);
      if snap is null then
        select m.author_id,
               jsonb_build_object('body', left(m.body, 2000), 'sent_at', m.created_at, 'group', g.name), null
          into owner, snap, link
          from public.group_messages m join public.chat_groups g on g.id = m.group_id
         where m.id = p_target and m.kind <> 'event' and public.group_message_visible(m.group_id, m.created_at);
      end if;
    else
      raise exception 'Unknown kind %', p_kind using errcode = '22023';
  end case;
  if snap is null then
    raise exception 'Not found' using errcode = 'P0002';
  end if;
  if owner = me then
    raise exception 'You can''t report your own' using errcode = '22023';
  end if;

  insert into public.reports (reporter_id, kind, target_id, target_user, reason, note, snapshot, link)
  values (me, p_kind, p_target, owner, p_reason, nullif(btrim(coalesce(p_note, '')), ''),
          snap || jsonb_build_object('author', private.member_name(owner)), link)
  on conflict (reporter_id, kind, target_id) where status = 'open'
  do update set reason = excluded.reason, note = coalesce(excluded.note, public.reports.note)
  returning id into new_id;

  insert into public.notifications (user_id, kind, data, link, dedupe_key)
  select a.id, 'content_report',
         jsonb_build_object('report_id', new_id, 'kind', p_kind, 'reason', p_reason),
         '/admin/reports', 'report:' || new_id || ':' || a.id
  from public.profiles a
  where a.role = 'admin' and a.status = 'active' and a.id <> me
  on conflict (dedupe_key) do nothing;
  return new_id;
end $$;

-- -----------------------------------------------------------------------------
-- Photos and voice notes: g/<group>/<sender>/... in the 'dm' bucket.
-- -----------------------------------------------------------------------------
create policy group_files_select on storage.objects for select to authenticated
  using (bucket_id = 'dm' and (storage.foldername(name))[1] = 'g' and public.messages_enabled()
         and exists (select 1 from public.chat_group_members m
                     where m.group_id::text = (storage.foldername(name))[2]
                       and m.user_id = (select auth.uid()) and m.left_at is null));
create policy group_files_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'dm' and (storage.foldername(name))[1] = 'g' and public.messages_enabled()
              and public.is_active_member()
              and (storage.foldername(name))[3] = (select auth.uid())::text
              and exists (select 1 from public.chat_group_members m
                          where m.group_id::text = (storage.foldername(name))[2]
                            and m.user_id = (select auth.uid()) and m.left_at is null));
create policy group_files_remove on storage.objects for delete to authenticated
  using (bucket_id = 'dm' and (storage.foldername(name))[1] = 'g'
         and (storage.foldername(name))[3] = (select auth.uid())::text);

revoke execute on function public.in_group(uuid) from public, anon;
revoke execute on function public.group_admin(uuid) from public, anon;
revoke execute on function public.group_message_visible(uuid, timestamptz) from public, anon;
revoke execute on function private.group_message_before() from public, anon, authenticated;
revoke execute on function private.on_group_message() from public, anon, authenticated;
revoke execute on function private.group_event(uuid, uuid, jsonb) from public, anon, authenticated;
revoke execute on function private.group_add_members(uuid, uuid[]) from public, anon, authenticated;
revoke execute on function private.group_check(uuid, boolean) from public, anon, authenticated;
revoke execute on function private.group_reaction_before() from public, anon, authenticated;
revoke execute on function private.group_reaction_notify() from public, anon, authenticated;
revoke execute on function public.group_create(text, uuid[], text) from public, anon;
revoke execute on function public.group_add(uuid, uuid[]) from public, anon;
revoke execute on function public.group_remove(uuid, uuid) from public, anon;
revoke execute on function public.group_leave(uuid) from public, anon;
revoke execute on function public.group_set_admin(uuid, uuid, boolean) from public, anon;
revoke execute on function public.group_update(uuid, text, text, boolean) from public, anon;
revoke execute on function public.group_set_photo(uuid, text) from public, anon;
revoke execute on function public.group_mute(uuid, boolean) from public, anon;
revoke execute on function public.group_mark_read(uuid) from public, anon;
revoke execute on function public.group_delete_message(uuid) from public, anon;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.chat_groups;
    alter publication supabase_realtime add table public.chat_group_members;
    alter publication supabase_realtime add table public.group_messages;
    alter publication supabase_realtime add table public.group_reactions;
  end if;
end $$;
