-- =============================================================================
-- Comment notifications say who commented, and open the post itself
--
-- * The commenter's name is part of the notification, so the phone shows
--   "Aisha commented: ..." rather than "New comment: ...".
-- * Notifications about a moment open that moment (/posts/<id>) with its
--   comments, instead of the Home feed.
-- * People who already commented on something hear about new comments too
--   ("Aisha also commented: ..."), so a conversation can carry on.
-- =============================================================================

create or replace function private.notify_comment() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  owner uuid;
  target_link text;
  payload jsonb;
begin
  if new.post_id is not null then
    select author_id, '/posts/' || id into owner, target_link from public.posts where id = new.post_id;
  elsif new.photo_id is not null then
    select uploaded_by,
           '/photo/' || id || case when album_id is not null then '?album=' || album_id else '?post=' || post_id end
      into owner, target_link from public.photos where id = new.photo_id;
  else
    select created_by, '/events/' || id into owner, target_link from public.events where id = new.event_id;
  end if;

  payload := jsonb_build_object(
    'body', left(new.body, 140),
    'name', private.member_name(new.author_id),
    'target', case when new.post_id is not null then 'post'
                   when new.photo_id is not null then 'photo' else 'event' end);

  if owner is not null and owner <> new.author_id then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (owner, 'comment', payload, target_link, new.author_id);
  end if;

  -- Everyone else already in the conversation.
  insert into public.notifications (user_id, kind, data, link, actor_id)
  select distinct c.author_id, 'comment'::public.notification_kind, payload || '{"also": true}', target_link, new.author_id
  from public.comments c
  join public.profiles p on p.id = c.author_id and p.status = 'active'
  where c.id <> new.id
    and c.author_id <> new.author_id
    and c.author_id is distinct from owner
    and c.post_id is not distinct from new.post_id
    and c.photo_id is not distinct from new.photo_id
    and c.event_id is not distinct from new.event_id;
  return new;
end $$;

create or replace function private.notify_post_tag() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, data, link, actor_id, dedupe_key)
  select p.id, 'tagged', jsonb_build_object('post_id', new.post_id), '/posts/' || new.post_id, new.tagged_by,
         'tag:post:' || new.post_id || ':' || p.id
  from public.profiles p
  where p.person_id = new.person_id and p.status = 'active' and p.id <> new.tagged_by
  on conflict (dedupe_key) do nothing;
  return new;
end $$;

-- -----------------------------------------------------------------------------
-- "This is me": admins hear when someone says which person in the tree they
-- are, so they can link the account (that is what turns on "My profile").
-- -----------------------------------------------------------------------------
create function private.notify_account_claim() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.requested_person_id is null or new.requested_person_id is not distinct from old.requested_person_id
     or new.status = 'suspended' or new.person_id is not null then
    return new;
  end if;
  insert into public.notifications (user_id, kind, data, link, actor_id, dedupe_key)
  select a.id, 'account_request',
         jsonb_build_object('name', coalesce(new.display_name, new.email),
                            'person', (select private.person_name(p) from public.persons p where p.id = new.requested_person_id)),
         '/admin?tab=accounts', new.id,
         'claim:' || new.id || ':' || new.requested_person_id || ':' || a.id
  from public.profiles a
  where a.role = 'admin' and a.status = 'active' and a.id <> new.id
  on conflict (dedupe_key) do nothing;
  return new;
end $$;

create trigger profiles_notify_claim after update of requested_person_id on public.profiles
  for each row execute function private.notify_account_claim();

revoke execute on function private.notify_account_claim() from public, anon, authenticated;
