-- =============================================================================
-- Members choose which in-app notifications they want (Settings → Notify me
-- about). Muted kinds are simply not created. Urgent blood requests and offers
-- can't be muted.
-- =============================================================================
alter table public.profiles
  add column muted_notifications text[] not null default '{}';
grant update (muted_notifications) on public.profiles to authenticated;

create function private.skip_muted_notification() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.kind::text not in ('blood_request', 'blood_offer')
     and exists (select 1 from public.profiles
                 where id = new.user_id and new.kind::text = any (muted_notifications)) then
    return null;
  end if;
  return new;
end $$;
revoke execute on function private.skip_muted_notification() from public, anon, authenticated;

create trigger notifications_skip_muted before insert on public.notifications
  for each row execute function private.skip_muted_notification();
