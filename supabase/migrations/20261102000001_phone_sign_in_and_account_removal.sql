-- =============================================================================
-- One phone number, one account; and admins can remove accounts.
--
-- Phone: the number someone saves on their profile now also signs them in to
-- that same account (Sign in → Phone). Before, a number saved on an email
-- account wasn't known to sign-in, so signing in with it made a second,
-- empty account. A number can only be on one account: saving one that is
-- already on another account, or signing up with it, is refused.
-- Accounts that sign in only by phone keep the number they signed up with.
--
-- Admins: decline a waiting account or suspend an active one (as before,
-- admin_update_account), and now delete an account for good
-- (admin_delete_account): it goes the same way as "Delete my account".
-- =============================================================================

-- Give each email account whose saved number is free that number to sign in with.
create function private.link_sign_in_phones() returns int
language plpgsql security definer set search_path = '' as $$
declare
  n int;
begin
  update auth.users u
     set phone = p.phone, updated_at = now()
    from public.profiles p
   where p.id = u.id and p.phone is not null and u.email is not null and coalesce(u.phone, '') = ''
     and not exists (select 1 from auth.users o where o.phone = p.phone and o.id <> u.id)
     and not exists (select 1 from public.profiles q where q.phone = p.phone and q.id <> p.id);
  get diagnostics n = row_count;
  return n;
end $$;
revoke execute on function private.link_sign_in_phones() from public, anon, authenticated;

-- A number already on another account is refused (also for new phone sign-ups,
-- whose profile is made with their number).
create function private.profiles_phone_unique() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.phone is not null and exists (
       select 1 from public.profiles where phone = new.phone and id <> new.id) then
    raise exception 'This phone number is already used by another account' using errcode = '23505';
  end if;
  return new;
end $$;
-- Runs after profiles_normalize_phone (triggers run in name order).
create trigger profiles_phone_unique before insert or update of phone on public.profiles
  for each row execute function private.profiles_phone_unique();

-- A changed number moves with the account's phone sign-in.
create function private.profiles_sign_in_phone() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.phone is not distinct from old.phone
     or not exists (select 1 from auth.users where id = new.id and email is not null) then
    return new;
  end if;
  if old.phone is not null then
    update auth.users set phone = null, updated_at = now() where id = new.id and phone = old.phone;
  end if;
  perform private.link_sign_in_phones();
  return new;
end $$;
create trigger profiles_sign_in_phone after update of phone on public.profiles
  for each row execute function private.profiles_sign_in_phone();

do $$ begin perform private.link_sign_in_phones(); end $$;
