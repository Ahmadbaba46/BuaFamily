-- =============================================================================
-- "This is me" claims: admins confirm or decline them, and the member hears
-- back either way.
--   * Confirming = linking the account to the person (admin_update_account
--     already clears the request); the member is told they're linked.
--   * admin_decline_claim() clears the request with an optional reason.
--   * The admins' notification opens the claims list.
-- =============================================================================

alter type public.notification_kind add value if not exists 'claim_reviewed';

create or replace function private.notify_account_claim() returns trigger
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
         '/admin?tab=accounts&filter=claims', new.id,
         'claim:' || new.id || ':' || new.requested_person_id || ':' || a.id
  from public.profiles a
  where a.role = 'admin' and a.status = 'active' and a.id <> new.id
  on conflict (dedupe_key) do nothing;
  return new;
end $$;

-- An admin linked an active member to a person (their claim or not): tell them.
create function private.notify_account_linked() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.person_id is not null and new.person_id is distinct from old.person_id
     and old.status = 'active' and new.status = 'active'
     and auth.uid() is distinct from new.id then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (new.id, 'claim_reviewed',
            jsonb_build_object('approved', true,
                               'person', (select private.person_name(p) from public.persons p where p.id = new.person_id)),
            '/person/' || new.person_id, auth.uid());
  end if;
  return new;
end $$;
create trigger profiles_notify_linked after update of person_id on public.profiles
  for each row execute function private.notify_account_linked();

create function public.admin_decline_claim(p_user_id uuid, p_reason text default null) returns void
language plpgsql security definer set search_path = '' as $$
declare
  claimed uuid;
begin
  if not public.is_admin() then
    raise exception 'Only admins can review claims' using errcode = '42501';
  end if;
  select requested_person_id into claimed from public.profiles where id = p_user_id for update;
  if claimed is null then
    return;
  end if;
  update public.profiles set requested_person_id = null where id = p_user_id;
  insert into public.notifications (user_id, kind, data, link, actor_id)
  values (p_user_id, 'claim_reviewed',
          jsonb_strip_nulls(jsonb_build_object(
            'approved', false,
            'person', (select private.person_name(p) from public.persons p where p.id = claimed),
            'reason', nullif(btrim(p_reason), ''))),
          '/more', auth.uid());
end $$;

revoke execute on function private.notify_account_linked() from public, anon, authenticated;
revoke execute on function public.admin_decline_claim(uuid, text) from public, anon;
