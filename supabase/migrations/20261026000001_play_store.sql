-- =============================================================================
-- Google Play
--
-- When the app is on Google Play, an admin saves its link (Admin → Settings →
-- Android app). The download page then sends people there, and the Play
-- build of the app updates from Play (Play doesn't allow apps to update
-- themselves from a downloaded file).
--
-- public_info(): what anyone may see, also before signing in: the Play link
-- and the developer's contact details (the privacy policy and the
-- account-deletion page show them).
-- =============================================================================

alter table public.app_settings add column play_store_url text
  check (play_store_url is null or play_store_url ~ '^https://play\.google\.com/');

create function public.public_info() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'family_name', family_name,
    'play_store_url', play_store_url,
    'developer_name', nullif(btrim(developer_name), ''),
    'developer_company', nullif(btrim(developer_company), ''),
    'developer_email', nullif(btrim(developer_email), ''),
    'developer_phone', nullif(btrim(developer_phone), ''),
    'developer_website', nullif(btrim(developer_website), '')))
  from public.app_settings;
$$;
grant execute on function public.public_info() to anon, authenticated;
