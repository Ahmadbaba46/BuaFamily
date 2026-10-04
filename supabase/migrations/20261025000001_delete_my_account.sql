-- =============================================================================
-- Members can delete their own account (Google Play requires it).
--
-- Gone: the account (sign-in, phone, email) and what the member shared or
-- did: moments, comments, likes, the photos they uploaded (the app removes
-- the files first), memories, messages, requests, replies, votes,
-- notifications and devices.
-- Kept, without their name: the family tree (the family's record, not the
-- account's), albums and events they created (with everyone else's photos
-- and replies), polls (with everyone's votes), elders' stories they
-- recorded, and welfare fund payments (the fund's accounts must add up).
-- =============================================================================

do $$
declare
  c record;
begin
  for c in select * from (values ('albums', 'created_by'), ('events', 'created_by'), ('polls', 'created_by'),
                                 ('stories', 'added_by'), ('fund_contributions', 'user_id')) v(t, col) loop
    execute format('alter table public.%1$I alter column %2$I drop not null,
                      drop constraint %1$s_%2$s_fkey,
                      add constraint %1$s_%2$s_fkey foreign key (%2$I) references auth.users on delete set null',
                   c.t, c.col);
  end loop;
end $$;

-- With p_check_only, only says whether it can be done (so the app removes
-- photo files only when it can).
create function public.delete_my_account(p_check_only boolean default false) returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  who text;
begin
  if me is null then
    raise exception 'Not signed in' using errcode = '42501';
  end if;
  if public.is_admin() and not exists (
       select 1 from public.profiles where id <> me and role = 'admin' and status = 'active') then
    raise exception 'You are the only admin. Make someone else an admin first.' using errcode = 'P0001';
  end if;
  if p_check_only then
    return;
  end if;
  who := private.member_name(me);
  -- Quietly: no "removed" notifications and no log line for every row that goes.
  perform set_config('bua.restoring', 'on', true);
  delete from auth.users where id = me;
  perform set_config('bua.restoring', 'off', true);
  insert into public.activity_log (user_id, action, entity, detail)
  values (null, 'delete', 'account', jsonb_strip_nulls(jsonb_build_object('label', who)));
end $$;

revoke execute on function public.delete_my_account(boolean) from public, anon;
