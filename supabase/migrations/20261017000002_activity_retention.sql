-- Keep the weekly clean-up tidy: page views for 90 days, everything else in
-- the activity log for a year.
create or replace function private.cleanup_old() returns void
language sql security definer set search_path = '' as $$
  delete from private.sms_outbox where status in ('sent', 'failed') and created_at < now() - interval '60 days';
  delete from public.notifications where created_at < now() - interval '180 days';
  delete from public.activity_log where action = 'view' and at < now() - interval '90 days';
  delete from public.activity_log where at < now() - interval '365 days';
$$;
