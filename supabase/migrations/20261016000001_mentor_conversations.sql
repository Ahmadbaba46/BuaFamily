-- =============================================================================
-- Mentorship conversations: a mentor and the person who asked can write to
-- each other under the ask. Only the two of them can read it.
-- =============================================================================

alter type public.notification_kind add value if not exists 'mentor_reply';

alter table public.mentor_asks
  add column last_message_at timestamptz,
  add column last_message    text,
  add column last_message_by uuid references auth.users on delete set null,
  add column mentor_read_at  timestamptz,
  add column asker_read_at   timestamptz;

-- Older asks have no summary yet; the app falls back to the ask itself.

create table public.mentor_messages (
  id          uuid primary key default gen_random_uuid(),
  ask_id      uuid not null references public.mentor_asks on delete cascade,
  author_id   uuid not null default auth.uid() references auth.users on delete cascade,
  body        text not null check (length(btrim(body)) between 1 and 4000),
  created_at  timestamptz not null default now()
);
create index mentor_messages_ask_idx on public.mentor_messages (ask_id, created_at);

alter table public.mentor_messages enable row level security;

create function public.in_mentor_ask(p_ask uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.mentor_asks a
                 where a.id = p_ask and (select auth.uid()) in (a.mentor_user_id, a.from_user_id));
$$;

create policy mentor_messages_select on public.mentor_messages for select to authenticated
  using (public.in_mentor_ask(ask_id));
create policy mentor_messages_insert on public.mentor_messages for insert to authenticated
  with check (public.is_active_member() and author_id = (select auth.uid()) and public.in_mentor_ask(ask_id));
create policy mentor_messages_delete on public.mentor_messages for delete to authenticated
  using (author_id = (select auth.uid()));
revoke update on public.mentor_messages from authenticated, anon;

-- Keep the ask's summary current and tell the other person.
create function private.on_mentor_message() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  a public.mentor_asks;
  other uuid;
begin
  update public.mentor_asks
     set last_message_at = new.created_at, last_message = left(new.body, 200), last_message_by = new.author_id,
         mentor_read_at = case when new.author_id = mentor_user_id then new.created_at else mentor_read_at end,
         asker_read_at = case when new.author_id = from_user_id then new.created_at else asker_read_at end
   where id = new.ask_id
  returning * into a;
  other := case when new.author_id = a.mentor_user_id then a.from_user_id else a.mentor_user_id end;
  insert into public.notifications (user_id, kind, data, link, actor_id)
  values (other, 'mentor_reply',
          jsonb_build_object('ask_id', a.id, 'name', private.member_name(new.author_id), 'body', left(new.body, 160),
                             'from_mentor', new.author_id = a.mentor_user_id),
          '/mentors/ask/' || a.id, new.author_id);
  return new;
end $$;
create trigger mentor_messages_after after insert on public.mentor_messages
  for each row execute function private.on_mentor_message();

-- New asks: start the summary, and link the mentor straight to the conversation.
create or replace function private.notify_mentor_ask() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.mentor_asks
     set last_message_at = new.created_at, last_message = left(new.message, 200), last_message_by = new.from_user_id,
         asker_read_at = new.created_at
   where id = new.id;
  insert into public.notifications (user_id, kind, data, link, actor_id)
  values (new.mentor_user_id, 'mentor_request',
          jsonb_build_object('ask_id', new.id, 'body', left(new.message, 160), 'name', private.member_name(new.from_user_id)),
          '/mentors/ask/' || new.id, new.from_user_id);
  return new;
end $$;

-- "I've read it": the mentor or the asker.
create function public.mark_mentor_ask_read(p_ask uuid) returns void
language sql security definer set search_path = '' as $$
  update public.mentor_asks
     set mentor_read_at = case when mentor_user_id = (select auth.uid()) then now() else mentor_read_at end,
         asker_read_at = case when from_user_id = (select auth.uid()) then now() else asker_read_at end
   where id = p_ask and (select auth.uid()) in (mentor_user_id, from_user_id);
$$;
revoke execute on function public.mark_mentor_ask_read(uuid) from public, anon;
revoke execute on function public.in_mentor_ask(uuid) from public, anon;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.mentor_messages;
  end if;
end $$;
