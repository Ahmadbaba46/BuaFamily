-- Recently deleted: gone for good after 30 days, or sooner when an admin says so.

-- Admins: forget something deleted (it can no longer be restored).
create function public.admin_forget_deleted(p_txid bigint) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can do this' using errcode = '42501';
  end if;
  delete from public.deleted_items where txid = p_txid;
end $$;
revoke execute on function public.admin_forget_deleted(bigint) from public, anon;

-- Every night: copies older than 30 days go.
create function private.purge_deleted() returns void
language sql security definer set search_path = '' as $$
  delete from public.deleted_items where deleted_at < now() - interval '30 days';
$$;
revoke execute on function private.purge_deleted() from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('bua-purge-deleted', '17 3 * * *', 'select private.purge_deleted()');
  end if;
end $$;
