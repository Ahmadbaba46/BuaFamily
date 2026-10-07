-- =============================================================================
-- Private messages, more like WhatsApp.
--
-- * Ticks: sent (saved), delivered (the other person's app has received it:
--   dm_mark_delivered, called when their app loads or hears of new messages)
--   and read (they opened the conversation: dm_mark_read).
-- * Photos and voice notes: files in the private 'dm' bucket under
--   <conversation>/<sender>/..., readable only by the two people. The
--   message's body holds a photo's caption, or 📷 / 🎤 when there is none.
-- * Replies quote an earlier message of the same conversation.
-- * Delete for everyone: the sender can remove a message; it shows as
--   deleted to both (dm_delete_message).
-- * "typing…" uses Realtime broadcast in the app; nothing is stored.
-- =============================================================================

alter table public.dm_messages
  add column kind text not null default 'text' check (kind in ('text', 'photo', 'voice')),
  add column media_path text,
  add column duration_ms int check (duration_ms is null or duration_ms between 0 and 3600000),
  add column reply_to uuid references public.dm_messages on delete set null,
  add column deleted_at timestamptz,
  add constraint dm_messages_media check (deleted_at is not null or (kind = 'text') = (media_path is null));
create index dm_messages_reply_idx on public.dm_messages (reply_to);

alter table public.dm_threads
  add column last_message_kind text,
  add column a_delivered_at timestamptz,
  add column b_delivered_at timestamptz;

-- A file must be in this conversation's folder, under the sender's own name.
alter policy dm_messages_insert on public.dm_messages
  with check (public.messages_enabled() and public.is_active_member()
              and author_id = (select auth.uid()) and public.in_dm_thread(thread_id)
              and not public.dm_blocked(thread_id) and deleted_at is null
              and (media_path is null
                   or (split_part(media_path, '/', 1) = thread_id::text
                       and split_part(media_path, '/', 2) = (select auth.uid())::text)));

-- A reply must quote a message of the same conversation.
create function private.dm_message_before() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.reply_to is not null and not exists (
       select 1 from public.dm_messages m where m.id = new.reply_to and m.thread_id = new.thread_id) then
    new.reply_to := null;
  end if;
  return new;
end $$;
create trigger dm_messages_before before insert on public.dm_messages
  for each row execute function private.dm_message_before();

-- Keep the conversation's summary current and tell the other person.
create or replace function private.on_dm_message() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  t public.dm_threads;
  other uuid;
  preview text := case when new.kind = 'text' or new.body not in ('📷', '🎤') then new.body else '' end;
begin
  update public.dm_threads
     set last_message_at = new.created_at, last_message = left(preview, 200), last_message_by = new.author_id,
         last_message_kind = new.kind,
         a_read_at = case when new.author_id = user_a then new.created_at else a_read_at end,
         b_read_at = case when new.author_id = user_b then new.created_at else b_read_at end,
         a_delivered_at = case when new.author_id = user_a then new.created_at else a_delivered_at end,
         b_delivered_at = case when new.author_id = user_b then new.created_at else b_delivered_at end
   where id = new.thread_id
  returning * into t;
  other := case when new.author_id = t.user_a then t.user_b else t.user_a end;
  insert into public.notifications (user_id, kind, data, link, actor_id)
  values (other, 'direct_message',
          jsonb_build_object('thread_id', t.id, 'name', private.member_name(new.author_id),
                             'body', left(preview, 160), 'message_kind', new.kind),
          '/messages/' || t.id, new.author_id);
  return new;
end $$;

-- My app has received what was sent to me.
create function public.dm_mark_delivered() returns void
language sql security definer set search_path = '' as $$
  update public.dm_threads
     set a_delivered_at = case when user_a = (select auth.uid()) then now() else a_delivered_at end,
         b_delivered_at = case when user_b = (select auth.uid()) then now() else b_delivered_at end
   where (select auth.uid()) in (user_a, user_b)
     and last_message_by is distinct from (select auth.uid())
     and last_message_at > coalesce(case when user_a = (select auth.uid()) then a_delivered_at else b_delivered_at end,
                                    '-infinity'::timestamptz);
$$;

-- "I've read it" (which also means it was delivered).
create or replace function public.dm_mark_read(p_thread uuid) returns void
language sql security definer set search_path = '' as $$
  update public.dm_threads
     set a_read_at = case when user_a = (select auth.uid()) then now() else a_read_at end,
         b_read_at = case when user_b = (select auth.uid()) then now() else b_read_at end,
         a_delivered_at = case when user_a = (select auth.uid()) then now() else a_delivered_at end,
         b_delivered_at = case when user_b = (select auth.uid()) then now() else b_delivered_at end
   where id = p_thread and (select auth.uid()) in (user_a, user_b);
$$;

-- Delete for everyone: only the sender, and only their own message.
create function public.dm_delete_message(p_message uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  m public.dm_messages;
begin
  select * into m from public.dm_messages where id = p_message for update;
  if not found or m.author_id is distinct from auth.uid() then
    raise exception 'You can only delete your own messages' using errcode = '42501';
  end if;
  if m.deleted_at is not null then
    return;
  end if;
  update public.dm_messages set deleted_at = now(), body = '🚫', media_path = null, duration_ms = null
   where id = p_message;
  update public.dm_threads set last_message = '', last_message_kind = 'deleted'
   where id = m.thread_id and last_message_at = m.created_at;
end $$;

revoke execute on function private.dm_message_before() from public, anon, authenticated;
revoke execute on function public.dm_mark_delivered() from public, anon;
revoke execute on function public.dm_delete_message(uuid) from public, anon;

-- -----------------------------------------------------------------------------
-- Photos and voice notes: the private 'dm' bucket.
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('dm', 'dm', false, 10485760,
        array['image/jpeg', 'image/png', 'image/webp', 'audio/mp4', 'audio/aac', 'audio/m4a', 'audio/x-m4a',
              'audio/ogg', 'audio/webm', 'audio/mpeg'])
on conflict (id) do nothing;

create policy dm_files_select on storage.objects for select to authenticated
  using (bucket_id = 'dm' and public.messages_enabled()
         and exists (select 1 from public.dm_threads t
                     where t.id::text = (storage.foldername(name))[1]
                       and (select auth.uid()) in (t.user_a, t.user_b)));
create policy dm_files_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'dm' and public.messages_enabled() and public.is_active_member()
              and (storage.foldername(name))[2] = (select auth.uid())::text
              and exists (select 1 from public.dm_threads t
                          where t.id::text = (storage.foldername(name))[1]
                            and (select auth.uid()) in (t.user_a, t.user_b)
                            and not public.blocked_between(t.user_a, t.user_b)));
create policy dm_files_remove on storage.objects for delete to authenticated
  using (bucket_id = 'dm' and (storage.foldername(name))[2] = (select auth.uid())::text);
