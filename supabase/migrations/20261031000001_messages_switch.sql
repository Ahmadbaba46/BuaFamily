-- =============================================================================
-- Admins can turn private messages off for the whole family.
--
-- While they're off nobody (admins included) can start a conversation, send a
-- message or read one; the conversations are kept and come back when messages
-- are turned on again. Group chats will follow the same switch.
-- =============================================================================

alter table public.app_settings add column messages_enabled boolean not null default true;

create function public.messages_enabled() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select messages_enabled from public.app_settings limit 1), true);
$$;
revoke execute on function public.messages_enabled() from public, anon;

alter policy dm_threads_select on public.dm_threads
  using (public.messages_enabled() and (select auth.uid()) in (user_a, user_b));
alter policy dm_messages_select on public.dm_messages
  using (public.messages_enabled() and public.in_dm_thread(thread_id));
alter policy dm_messages_insert on public.dm_messages
  with check (public.messages_enabled() and public.is_active_member()
              and author_id = (select auth.uid()) and public.in_dm_thread(thread_id));

create or replace function public.dm_open(p_user uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  a uuid;
  b uuid;
  thread uuid;
begin
  if not public.messages_enabled() then
    raise exception 'Messages are turned off by the family admins' using errcode = '42501';
  end if;
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
