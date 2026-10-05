-- =============================================================================
-- Admins can delete an account for good (see 20261102000001).
--
-- The same as the member doing "Delete my account": the account and what it
-- shared go; the family tree, albums, events, polls, elders' stories and
-- fund payments stay without the name. Not your own account (use Delete my
-- account) and not another admin's (make them a member first).
-- =============================================================================

create function public.admin_delete_account(p_user uuid, p_check_only boolean default false) returns void
language plpgsql security definer set search_path = '' as $$
declare
  target public.profiles;
  who text;
begin
  if not public.is_admin() then
    raise exception 'Only admins can delete accounts' using errcode = '42501';
  end if;
  select * into target from public.profiles where id = p_user;
  if not found then
    raise exception 'Account not found' using errcode = 'P0002';
  end if;
  if p_user = auth.uid() then
    raise exception 'To delete your own account, use More → Delete my account' using errcode = 'P0001';
  end if;
  if target.role = 'admin' then
    raise exception 'Make them a member first, then delete the account' using errcode = 'P0001';
  end if;
  if p_check_only then
    return;
  end if;
  who := private.member_name(p_user);
  perform set_config('bua.restoring', 'on', true);
  delete from auth.users where id = p_user;
  perform set_config('bua.restoring', 'off', true);
  insert into public.activity_log (user_id, action, entity, detail)
  values (auth.uid(), 'delete', 'account', jsonb_strip_nulls(jsonb_build_object('label', who)));
  -- A number the deleted account held may now go to the account that saved it.
  perform private.link_sign_in_phones();
end $$;

revoke execute on function public.admin_delete_account(uuid, boolean) from public, anon;
