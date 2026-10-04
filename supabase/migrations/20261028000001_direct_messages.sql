-- =============================================================================
-- Direct messages between two family members.
--
-- One conversation per pair (dm_threads, the two ids in order), its messages
-- in dm_messages. Only the two people can read it: not admins, not backups,
-- not the activity log. A conversation starts through dm_open(), only
-- between approved members. Deleting an account removes its conversations.
-- =============================================================================

alter type public.notification_kind add value if not exists 'direct_message';

create table public.dm_threads (
  id               uuid primary key default gen_random_uuid(),
  user_a           uuid not null references auth.users on delete cascade,
  user_b           uuid not null references auth.users on delete cascade,
  created_at       timestamptz not null default now(),
  last_message_at  timestamptz,
  last_message     text,
  last_message_by  uuid references auth.users on delete set null,
  a_read_at        timestamptz,
  b_read_at        timestamptz,
  constraint dm_threads_ordered check (user_a < user_b),
  constraint dm_threads_pair unique (user_a, user_b)
);
create index dm_threads_b_idx on public.dm_threads (user_b);

create table public.dm_messages (
  id          uuid primary key default gen_random_uuid(),
  thread_id   uuid not null references public.dm_threads on delete cascade,
  author_id   uuid not null default auth.uid() references auth.users on delete cascade,
  body        text not null check (length(btrim(body)) between 1 and 4000),
  created_at  timestamptz not null default now()
);
create index dm_messages_thread_idx on public.dm_messages (thread_id, created_at);

alter table public.dm_threads enable row level security;
alter table public.dm_messages enable row level security;

create function public.in_dm_thread(p_thread uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.dm_threads t
                 where t.id = p_thread and (select auth.uid()) in (t.user_a, t.user_b));
$$;

create policy dm_threads_select on public.dm_threads for select to authenticated
  using ((select auth.uid()) in (user_a, user_b));
revoke insert, update, delete on public.dm_threads from authenticated, anon;

create policy dm_messages_select on public.dm_messages for select to authenticated
  using (public.in_dm_thread(thread_id));
create policy dm_messages_insert on public.dm_messages for insert to authenticated
  with check (public.is_active_member() and author_id = (select auth.uid()) and public.in_dm_thread(thread_id));
revoke update, delete on public.dm_messages from authenticated, anon;

-- The conversation with p_user: the existing one, or a new one.
create function public.dm_open(p_user uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  a uuid;
  b uuid;
  thread uuid;
begin
  if me is null or not public.is_active_member() then
    raise exception 'Only family members can send messages' using errcode = '42501';
  end if;
  if p_user is null or p_user = me
     or not exists (select 1 from public.profiles where id = p_user and status = 'active') then
    raise exception 'You can only message another family member' using errcode = '22023';
  end if;
  a := least(me, p_user);
  b := greatest(me, p_user);
  insert into public.dm_threads (user_a, user_b) values (a, b)
  on conflict (user_a, user_b) do nothing;
  select id into thread from public.dm_threads where user_a = a and user_b = b;
  return thread;
end $$;

-- Keep the conversation's summary current and tell the other person.
create function private.on_dm_message() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  t public.dm_threads;
  other uuid;
begin
  update public.dm_threads
     set last_message_at = new.created_at, last_message = left(new.body, 200), last_message_by = new.author_id,
         a_read_at = case when new.author_id = user_a then new.created_at else a_read_at end,
         b_read_at = case when new.author_id = user_b then new.created_at else b_read_at end
   where id = new.thread_id
  returning * into t;
  other := case when new.author_id = t.user_a then t.user_b else t.user_a end;
  insert into public.notifications (user_id, kind, data, link, actor_id)
  values (other, 'direct_message',
          jsonb_build_object('thread_id', t.id, 'name', private.member_name(new.author_id), 'body', left(new.body, 160)),
          '/messages/' || t.id, new.author_id);
  return new;
end $$;
create trigger dm_messages_after after insert on public.dm_messages
  for each row execute function private.on_dm_message();

-- "I've read it."
create function public.dm_mark_read(p_thread uuid) returns void
language sql security definer set search_path = '' as $$
  update public.dm_threads
     set a_read_at = case when user_a = (select auth.uid()) then now() else a_read_at end,
         b_read_at = case when user_b = (select auth.uid()) then now() else b_read_at end
   where id = p_thread and (select auth.uid()) in (user_a, user_b);
$$;

revoke execute on function public.in_dm_thread(uuid) from public, anon;
revoke execute on function public.dm_open(uuid) from public, anon;
revoke execute on function public.dm_mark_read(uuid) from public, anon;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.dm_messages;
    alter publication supabase_realtime add table public.dm_threads;
  end if;
end $$;
