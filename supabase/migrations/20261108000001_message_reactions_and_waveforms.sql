-- =============================================================================
-- Messages: reactions, and the shape of each voice note.
--
-- * waveform: up to 120 levels (0–100) measured while recording, drawn as the
--   voice note's bars, as on WhatsApp.
-- * dm_reactions: one emoji per person per message (choosing another replaces
--   it; choosing it again removes it). Only the two people see them; the
--   sender of the message is told ("Musa reacted ❤️").
-- =============================================================================

alter table public.dm_messages
  add column waveform smallint[] check (waveform is null or cardinality(waveform) <= 120);

create table public.dm_reactions (
  message_id  uuid not null references public.dm_messages on delete cascade,
  user_id     uuid not null default auth.uid() references auth.users on delete cascade,
  -- Filled from the message (whatever the app sends).
  thread_id   uuid not null references public.dm_threads on delete cascade,
  emoji       text not null check (length(emoji) between 1 and 16),
  created_at  timestamptz not null default now(),
  primary key (message_id, user_id)
);
create index dm_reactions_thread_idx on public.dm_reactions (thread_id);
create index dm_reactions_user_idx on public.dm_reactions (user_id);

alter table public.dm_reactions enable row level security;
create policy dm_reactions_select on public.dm_reactions for select to authenticated
  using (public.messages_enabled() and public.in_dm_thread(thread_id));
create policy dm_reactions_insert on public.dm_reactions for insert to authenticated
  with check (public.messages_enabled() and public.is_active_member() and user_id = (select auth.uid())
              and public.in_dm_thread(thread_id) and not public.dm_blocked(thread_id));
create policy dm_reactions_update on public.dm_reactions for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and public.in_dm_thread(thread_id) and not public.dm_blocked(thread_id));
create policy dm_reactions_remove on public.dm_reactions for delete to authenticated
  using (user_id = (select auth.uid()));

-- The conversation comes from the message; deleted messages take no reactions.
create function private.dm_reaction_before() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  m public.dm_messages;
begin
  select * into m from public.dm_messages where id = new.message_id;
  if not found or m.deleted_at is not null then
    raise exception 'This message can''t take reactions' using errcode = '55000';
  end if;
  new.thread_id := m.thread_id;
  return new;
end $$;
create trigger dm_reactions_before before insert or update on public.dm_reactions
  for each row execute function private.dm_reaction_before();

-- Tell the message's sender (not for reacting to your own).
create function private.dm_reaction_notify() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  author uuid := (select author_id from public.dm_messages where id = new.message_id);
begin
  if author is distinct from new.user_id and (tg_op = 'INSERT' or new.emoji is distinct from old.emoji) then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (author, 'direct_message',
            jsonb_build_object('thread_id', new.thread_id, 'name', private.member_name(new.user_id),
                               'body', new.emoji, 'message_kind', 'reaction'),
            '/messages/' || new.thread_id, new.user_id);
  end if;
  return new;
end $$;
create trigger dm_reactions_notify after insert or update on public.dm_reactions
  for each row execute function private.dm_reaction_notify();

revoke execute on function private.dm_reaction_before() from public, anon, authenticated;
revoke execute on function private.dm_reaction_notify() from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.dm_reactions;
  end if;
end $$;
