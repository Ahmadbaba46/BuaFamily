-- =============================================================================
-- Notifications for accounts and suggestions
--
-- Until now, admins only noticed a new sign-up or a member's suggestion by
-- opening the app (the badge on the admin menu). These go to the inbox, and
-- so to phones too:
--
--   account_request   someone signed up (or added a note about who they are)  -> admins
--   change_request    a member suggested a change to the tree                 -> admins
--   account_approved  an admin approved your account                          -> you
--   request_reviewed  an admin approved or declined your suggestion           -> you
--
-- People waiting for approval may now turn on notifications for their
-- device, so the "you're in" message reaches them.
-- =============================================================================

alter type public.notification_kind add value if not exists 'account_request';
alter type public.notification_kind add value if not exists 'change_request';
alter type public.notification_kind add value if not exists 'account_approved';
alter type public.notification_kind add value if not exists 'request_reviewed';

-- Who a suggestion is about: the person it changes, or the one it adds.
create function private.request_subject(r public.change_requests) returns text
language sql stable set search_path = '' as $$
  select coalesce(
    (select private.person_name(p) from public.persons p
      where p.id = coalesce(r.target_person_id, r.result_person_id)),
    nullif(trim(concat_ws(' ', r.payload #>> '{person,first_name}', r.payload #>> '{person,last_name}')), ''),
    (select private.person_name(p) from public.persons p
      where p.id = coalesce((r.payload ->> 'child_id')::uuid, (r.payload ->> 'partner1_id')::uuid))
  );
$$;

-- -----------------------------------------------------------------------------
-- Accounts
-- -----------------------------------------------------------------------------
create function private.notify_account_request() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.status <> 'pending' then
    return new;
  end if;
  if tg_op = 'UPDATE' then
    -- Only the first note about who they are; later edits are not news.
    if coalesce(trim(old.claim_note), '') <> '' or coalesce(trim(new.claim_note), '') = '' then
      return new;
    end if;
  end if;
  insert into public.notifications (user_id, kind, data, link, actor_id, dedupe_key)
  select a.id, 'account_request',
         jsonb_strip_nulls(jsonb_build_object(
           'name', new.display_name, 'email', new.email,
           'note', case when tg_op = 'UPDATE' then left(new.claim_note, 200) end)),
         '/admin?tab=accounts', new.id,
         'account:' || new.id || ':' || lower(tg_op) || ':' || a.id
  from public.profiles a
  where a.role = 'admin' and a.status = 'active' and a.id <> new.id
  on conflict (dedupe_key) do nothing;
  return new;
end $$;

create trigger profiles_notify_signup after insert on public.profiles
  for each row execute function private.notify_account_request();
create trigger profiles_notify_claim_note after update of claim_note on public.profiles
  for each row execute function private.notify_account_request();

create function private.notify_account_approved() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if old.status = 'pending' and new.status = 'active' then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (new.id, 'account_approved', jsonb_build_object('name', new.display_name), '/home', auth.uid());
  end if;
  return new;
end $$;

create trigger profiles_notify_approved after update of status on public.profiles
  for each row execute function private.notify_account_approved();

-- -----------------------------------------------------------------------------
-- Suggestions (change requests)
-- -----------------------------------------------------------------------------
create function private.notify_change_request() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.status <> 'pending' then
    return new;
  end if;
  insert into public.notifications (user_id, kind, data, link, actor_id)
  select a.id, 'change_request',
         jsonb_strip_nulls(jsonb_build_object(
           'request_id', new.id, 'request_kind', new.kind,
           'name', private.member_name(new.requested_by),
           'person', private.request_subject(new))),
         '/admin', new.requested_by
  from public.profiles a
  where a.role = 'admin' and a.status = 'active' and a.id <> new.requested_by;
  return new;
end $$;

create trigger change_requests_notify after insert on public.change_requests
  for each row execute function private.notify_change_request();

create function private.notify_request_reviewed() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if old.status = 'pending' and new.status <> 'pending'
     and new.requested_by is distinct from new.reviewed_by then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (new.requested_by, 'request_reviewed',
            jsonb_strip_nulls(jsonb_build_object(
              'request_id', new.id, 'request_kind', new.kind,
              'approved', new.status = 'approved',
              'person', private.request_subject(new),
              'note', left(new.review_note, 200))),
            '/my-requests', new.reviewed_by);
  end if;
  return new;
end $$;

create trigger change_requests_notify_reviewed after update of status on public.change_requests
  for each row execute function private.notify_request_reviewed();

revoke execute on function private.request_subject(public.change_requests) from public, anon, authenticated;
revoke execute on function private.notify_account_request() from public, anon, authenticated;
revoke execute on function private.notify_account_approved() from public, anon, authenticated;
revoke execute on function private.notify_change_request() from public, anon, authenticated;
revoke execute on function private.notify_request_reviewed() from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Let people waiting for approval register their device, so the approval
-- itself can reach them. They only ever receive their own notifications.
-- -----------------------------------------------------------------------------
create or replace function public.register_push_token(p_token text, p_platform text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.profiles where id = auth.uid() and status in ('active', 'pending')) then
    raise exception 'Only family members get notifications' using errcode = '42501';
  end if;
  insert into public.push_tokens (token, user_id, platform)
  values (p_token, auth.uid(), p_platform)
  on conflict (token) do update
    set user_id = excluded.user_id, platform = excluded.platform, last_seen_at = now();
end $$;
revoke execute on function public.register_push_token(text, text) from public, anon;
