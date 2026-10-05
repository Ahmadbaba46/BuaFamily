-- =============================================================================
-- The Android app is published as two smaller APKs, one per phone type: most
-- phones (64-bit, arm64) and older ones (32-bit, arm32). A single APK for all
-- phones is over the storage upload limit (50 MB). android_apk_path holds
-- the main one (or a single APK for all phones, as before).
-- =============================================================================

alter table public.app_settings add column android_apk_arm32_path text;

create or replace function public.android_release() returns jsonb
language sql stable security definer set search_path = '' as $$
  select case when android_build is null then null else jsonb_strip_nulls(jsonb_build_object(
    'build', android_build,
    'version', android_version,
    'path', android_apk_path,
    'path_arm32', android_apk_arm32_path,
    'notes', android_notes,
    'published_at', android_published_at
  )) end
  from public.app_settings;
$$;

-- Publishing records the main APK (and clears an older 32-bit one); the
-- 32-bit APK, when there is one, is recorded next with
-- admin_publish_android_arm32().
create or replace function public.admin_publish_android(p_build int, p_version text, p_path text, p_notes text default null)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  previous int;
begin
  if not public.is_admin() then
    raise exception 'Only admins can publish the app' using errcode = '42501';
  end if;
  if p_build is null or p_build < 1 then
    raise exception 'A build number is needed' using errcode = '22023';
  end if;
  select android_build into previous from public.app_settings;
  if previous is not null and p_build < previous then
    raise exception 'Build % is older than the published build %', p_build, previous using errcode = '22023';
  end if;

  update public.app_settings
     set android_build = p_build,
         android_version = coalesce(nullif(trim(p_version), ''), '1.0.' || p_build),
         android_apk_path = p_path,
         android_apk_arm32_path = null,
         android_notes = nullif(trim(p_notes), ''),
         android_published_at = now()
   where id;

  if previous is distinct from p_build then
    insert into public.notifications (user_id, kind, data, link, actor_id, dedupe_key)
    select distinct t.user_id, 'app_update'::public.notification_kind,
           jsonb_strip_nulls(jsonb_build_object('version', coalesce(nullif(trim(p_version), ''), '1.0.' || p_build),
                                                'notes', left(nullif(trim(p_notes), ''), 200))),
           '/get-app', auth.uid(), 'app_update:' || p_build || ':' || t.user_id
    from public.push_tokens t
    join public.profiles p on p.id = t.user_id and p.status = 'active'
    where t.platform = 'android'
    on conflict (dedupe_key) do nothing;
  end if;
end $$;

-- The 32-bit APK of the build just published.
create function public.admin_publish_android_arm32(p_build int, p_path text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can publish the app' using errcode = '42501';
  end if;
  update public.app_settings set android_apk_arm32_path = nullif(trim(p_path), '')
   where id and android_build = p_build;
  if not found then
    raise exception 'Build % is not the published build', p_build using errcode = '22023';
  end if;
end $$;

revoke execute on function public.admin_publish_android_arm32(int, text) from public, anon;
