-- =============================================================================
-- Editing and removing what the family has added.
--
-- 1. Who made something stays who made it: an edit can't hand a post, an event
--    or a payout to someone else, or move a comment to another post.
-- 2. Comments, opportunities, memories and payouts can now be edited (by who
--    wrote them, an admin, or the committee for payouts). Posts and comments
--    say when they were edited.
-- 3. People going to an event hear when its date or place changes.
-- 4. A cause or dues plan with money on record can't be deleted: close it.
-- 5. Family admins see every group (names and members, never messages), can
--    remove someone from a group and delete a group; group admins can delete
--    their own group.
-- 6. Admins can remove a reported message (private or in a group).
-- =============================================================================

alter type public.notification_kind add value if not exists 'event_changed';

alter table public.posts add column edited_at timestamptz;
alter table public.comments add column edited_at timestamptz;

-- -----------------------------------------------------------------------------
-- Who made it stays who made it. Columns named with a leading '?' may be
-- cleared (an account being deleted), never pointed at someone else.
-- -----------------------------------------------------------------------------
create function private.keep_columns() returns trigger
language plpgsql set search_path = '' as $$
declare
  arg text;
  c text;
  o jsonb := to_jsonb(old);
  n jsonb := to_jsonb(new);
  patch jsonb := '{}';
begin
  if coalesce(current_setting('bua.restoring', true), '') = 'on' then
    return new;
  end if;
  foreach arg in array tg_argv loop
    c := ltrim(arg, '?');
    if n -> c is distinct from o -> c and not (arg like '?%' and jsonb_typeof(n -> c) = 'null') then
      patch := patch || jsonb_build_object(c, o -> c);
    end if;
  end loop;
  if patch = '{}' then
    return new;
  end if;
  return jsonb_populate_record(new, patch);
end $$;

create trigger posts_keep before update on public.posts
  for each row execute function private.keep_columns('?author_id', 'created_at');
create trigger comments_keep before update on public.comments
  for each row execute function private.keep_columns('?author_id', 'post_id', 'photo_id', 'event_id', 'created_at');
create trigger events_keep before update on public.events
  for each row execute function private.keep_columns('?created_by', 'created_at');
create trigger albums_keep before update on public.albums
  for each row execute function private.keep_columns('?created_by', 'created_at');
create trigger photos_keep before update on public.photos
  for each row execute function private.keep_columns('?uploaded_by', 'storage_path', 'created_at');
create trigger polls_keep before update on public.polls
  for each row execute function private.keep_columns('?created_by', 'created_at');
create trigger opportunities_keep before update on public.opportunities
  for each row execute function private.keep_columns('?posted_by', 'created_at');
create trigger memories_keep before update on public.memories
  for each row execute function private.keep_columns('?author_id', 'created_at');
create trigger blood_requests_keep before update on public.blood_requests
  for each row execute function private.keep_columns('?requested_by', 'created_at');
create trigger stories_keep before update on public.stories
  for each row execute function private.keep_columns('?added_by', 'audio_path', 'created_at');
create trigger fund_payouts_keep before update on public.fund_payouts
  for each row execute function private.keep_columns('?recorded_by', 'created_at');

-- "Edited" on posts and comments.
create function private.mark_edited() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.body is distinct from old.body and coalesce(current_setting('bua.restoring', true), '') <> 'on' then
    new.edited_at := now();
  end if;
  return new;
end $$;
create trigger posts_edited before update on public.posts
  for each row execute function private.mark_edited();
create trigger comments_edited before update on public.comments
  for each row execute function private.mark_edited();

-- -----------------------------------------------------------------------------
-- Who may edit
-- -----------------------------------------------------------------------------
create policy comments_update on public.comments for update to authenticated
  using (author_id = (select auth.uid()))
  with check (author_id = (select auth.uid()) and length(btrim(body)) > 0);
create policy opportunities_update on public.opportunities for update to authenticated
  using (posted_by = (select auth.uid()) or public.is_admin())
  with check (public.is_active_member());
create policy memories_update on public.memories for update to authenticated
  using (author_id = (select auth.uid()) or public.is_admin())
  with check (public.is_active_member());
create policy fund_payouts_update on public.fund_payouts for update to authenticated
  using (public.is_committee())
  with check (public.is_committee());

-- -----------------------------------------------------------------------------
-- An event moved: those going (or maybe) hear about it.
-- -----------------------------------------------------------------------------
create function private.notify_event_changed() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.starts_at is not distinct from old.starts_at
     and new.ends_at is not distinct from old.ends_at
     and new.place is not distinct from old.place
     and new.address is not distinct from old.address then
    return new;
  end if;
  insert into public.notifications (user_id, kind, data, link, actor_id)
  select r.user_id, 'event_changed',
         jsonb_build_object('event_id', new.id, 'title', new.title, 'starts_at', new.starts_at,
                            'place', new.place,
                            'moved', new.starts_at is distinct from old.starts_at,
                            'name', private.member_name(auth.uid())),
         '/events/' || new.id, auth.uid()
  from public.event_rsvps r
  join public.profiles p on p.id = r.user_id and p.status = 'active'
  where r.event_id = new.id and r.response in ('going', 'maybe')
    and r.user_id is distinct from auth.uid();
  return new;
end $$;
create trigger events_changed_notify after update on public.events
  for each row execute function private.notify_event_changed();

-- -----------------------------------------------------------------------------
-- Money on record stays with its cause or plan.
-- -----------------------------------------------------------------------------
create function private.fund_keep_money() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if coalesce(current_setting('bua.restoring', true), '') = 'on' then
    return old;
  end if;
  if tg_table_name = 'fund_causes' and (
       exists (select 1 from public.fund_contributions where cause_id = old.id and status <> 'rejected')
       or exists (select 1 from public.fund_payouts where cause_id = old.id)
       or exists (select 1 from public.online_payments where cause_id = old.id and status = 'paid')) then
    raise exception 'Money has been given or paid out for this cause. Close it instead.' using errcode = '23503';
  end if;
  if tg_table_name = 'fund_dues_plans' and (
       exists (select 1 from public.fund_contributions where dues_plan_id = old.id and status <> 'rejected')
       or exists (select 1 from public.online_payments where dues_plan_id = old.id and status = 'paid')) then
    raise exception 'Dues have been paid under this plan. Close it instead.' using errcode = '23503';
  end if;
  return old;
end $$;
create trigger fund_causes_keep_money before delete on public.fund_causes
  for each row execute function private.fund_keep_money();
create trigger fund_dues_plans_keep_money before delete on public.fund_dues_plans
  for each row execute function private.fund_keep_money();

-- -----------------------------------------------------------------------------
-- Groups: family admins look after them.
-- -----------------------------------------------------------------------------
-- Every group, with who is in it (never what was said).
create function public.admin_groups()
returns table (id uuid, name text, about text, photo_path text, created_by uuid, created_at timestamptz,
               last_message_at timestamptz, members jsonb)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can see every group' using errcode = '42501';
  end if;
  return query
  select g.id, g.name, g.about, g.photo_path, g.created_by, g.created_at, g.last_message_at,
         coalesce((select jsonb_agg(jsonb_build_object('user_id', m.user_id, 'role', m.role) order by m.joined_at)
                     from public.chat_group_members m
                    where m.group_id = g.id and m.left_at is null), '[]'::jsonb)
    from public.chat_groups g
   order by coalesce(g.last_message_at, g.created_at) desc;
end $$;

-- A group admin, or a family admin: the group and everything said in it go.
create function public.group_delete(p_group uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not (public.is_admin() or (public.is_active_member() and public.group_admin(p_group))) then
    raise exception 'Only the group''s admins can delete it' using errcode = '42501';
  end if;
  delete from public.chat_groups where id = p_group;
end $$;

-- Group admins, and family admins (who need not be in the group).
create or replace function public.group_remove(p_group uuid, p_user uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    perform private.group_check(p_group, true);
  end if;
  if p_user = auth.uid() then
    raise exception 'Leave the group instead' using errcode = '22023';
  end if;
  update public.chat_group_members set left_at = now()
   where group_id = p_group and user_id = p_user and left_at is null;
  if found then
    perform private.group_event(p_group, auth.uid(), jsonb_build_object('type', 'removed', 'user', p_user));
    -- Someone must be able to run it.
    if not exists (select 1 from public.chat_group_members
                    where group_id = p_group and left_at is null and role = 'admin') then
      update public.chat_group_members set role = 'admin'
       where (group_id, user_id) = (select group_id, user_id from public.chat_group_members
                                     where group_id = p_group and left_at is null
                                     order by joined_at limit 1);
    end if;
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- Admins: remove a reported message, private or in a group.
-- -----------------------------------------------------------------------------
create function public.admin_remove_reported_message(p_report uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  r public.reports;
  dm public.dm_messages;
  gm public.group_messages;
begin
  if not public.is_admin() then
    raise exception 'Only admins can remove reported messages' using errcode = '42501';
  end if;
  select * into r from public.reports where id = p_report;
  if not found or r.kind <> 'message' then
    raise exception 'Not a reported message' using errcode = 'P0002';
  end if;
  select * into dm from public.dm_messages where id = r.target_id for update;
  if found then
    if dm.deleted_at is null then
      update public.dm_messages set deleted_at = now(), body = '🚫', media_path = null, duration_ms = null
       where id = dm.id;
      update public.dm_threads set last_message = '', last_message_kind = 'deleted'
       where id = dm.thread_id and last_message_at = dm.created_at;
    end if;
  else
    select * into gm from public.group_messages where id = r.target_id for update;
    if found and gm.deleted_at is null then
      update public.group_messages
         set deleted_at = now(), deleted_by = auth.uid(), body = '🚫', media_path = null, duration_ms = null,
             waveform = null
       where id = gm.id;
      update public.chat_groups set last_message = '', last_message_kind = 'deleted'
       where id = gm.group_id and last_message_at = gm.created_at;
    end if;
  end if;
  update public.reports set status = 'removed', reviewed_by = auth.uid(), reviewed_at = now()
   where id = p_report;
end $$;

revoke execute on function private.keep_columns() from public, anon, authenticated;
revoke execute on function private.mark_edited() from public, anon, authenticated;
revoke execute on function private.notify_event_changed() from public, anon, authenticated;
revoke execute on function private.fund_keep_money() from public, anon, authenticated;
revoke execute on function public.admin_groups() from public, anon;
revoke execute on function public.group_delete(uuid) from public, anon;
revoke execute on function public.group_remove(uuid, uuid) from public, anon;
revoke execute on function public.admin_remove_reported_message(uuid) from public, anon;
