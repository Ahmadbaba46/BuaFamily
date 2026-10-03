-- =============================================================================
-- Push delivery receipts, and a fix for the push status counter
--
-- * push_report() updated its single row without a WHERE clause, which
--   Supabase's API rejects ("UPDATE requires a WHERE clause"), so the admin
--   status never showed what was sent.
-- * When a browser receives a notification, its service worker calls
--   push_ack() with the notification's id. The admin status then shows how
--   many actually arrived, which tells "Google didn't deliver it" apart from
--   "the device received it but didn't show it".
-- =============================================================================

create or replace function public.push_report(p_sent int, p_error text default null) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update private.push_stats set
    sent_7d       = case when sent_7d_start > now() - interval '7 days' then sent_7d + p_sent else p_sent end,
    sent_7d_start = case when sent_7d_start > now() - interval '7 days' then sent_7d_start else now() end,
    last_sent_at  = case when p_sent > 0 then now() else last_sent_at end,
    last_error    = coalesce(left(p_error, 500), last_error),
    last_error_at = case when p_error is not null then now() else last_error_at end
  where id;
end $$;

alter table public.notifications add column pushed_at timestamptz;

-- Called by the browser's service worker (no sign-in there). Knowing a
-- notification's id only lets you mark it as delivered.
create function public.push_ack(p_id uuid) returns void
language sql security definer set search_path = '' as $$
  update public.notifications set pushed_at = now() where id = p_id and pushed_at is null;
$$;

create or replace function public.push_status() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  s private.push_stats := (select x from private.push_stats x);
begin
  if not public.is_admin() then
    raise exception 'Only admins can see this' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'enabled', (select push_enabled from public.app_settings),
    'project_id', private.vault_get('fcm_service_account')::jsonb ->> 'project_id',
    'function_url', private.vault_get('push_function_url'),
    'devices', (select count(*) from public.push_tokens),
    'members', (select count(distinct user_id) from public.push_tokens),
    'sent_7d', case when s.sent_7d_start > now() - interval '7 days' then s.sent_7d else 0 end,
    'received_7d', (select count(*) from public.notifications where pushed_at > now() - interval '7 days'),
    'last_sent_at', s.last_sent_at,
    'last_received_at', (select max(pushed_at) from public.notifications),
    'last_error', s.last_error,
    'last_error_at', s.last_error_at
  );
end $$;

revoke execute on function public.push_report(int, text) from public, anon, authenticated;
grant execute on function public.push_report(int, text) to service_role;
revoke execute on function public.push_ack(uuid) from public;
grant execute on function public.push_ack(uuid) to anon, authenticated;
revoke execute on function public.push_status() from public, anon;
