-- =============================================================================
-- Android app updates
--
-- The Android app is installed from an APK file, not a store, so it can't
-- update itself. An admin publishes each new build from the app (Admin →
-- Settings → Android app): the file goes to the public 'releases' bucket and
-- its version is recorded here. The app compares that with its own version
-- and offers the download; members with the Android app are notified.
-- =============================================================================

alter type public.notification_kind add value if not exists 'app_update';

alter table public.app_settings
  add column android_build int,
  add column android_version text,
  add column android_apk_path text,
  add column android_notes text,
  add column android_published_at timestamptz;

-- Anyone may download (the link is shared with family members who have not
-- signed in yet); only admins upload.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('releases', 'releases', true, null,
        array['application/vnd.android.package-archive', 'application/octet-stream'])
on conflict (id) do nothing;

create policy releases_select on storage.objects for select to authenticated
  using (bucket_id = 'releases' and public.is_admin());
create policy releases_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'releases' and public.is_admin());
create policy releases_update on storage.objects for update to authenticated
  using (bucket_id = 'releases' and public.is_admin()) with check (bucket_id = 'releases' and public.is_admin());
create policy releases_delete on storage.objects for delete to authenticated
  using (bucket_id = 'releases' and public.is_admin());

-- The latest Android build, for the download page (also before signing in).
create function public.android_release() returns jsonb
language sql stable security definer set search_path = '' as $$
  select case when android_build is null then null else jsonb_build_object(
    'build', android_build,
    'version', android_version,
    'path', android_apk_path,
    'notes', android_notes,
    'published_at', android_published_at
  ) end
  from public.app_settings;
$$;
grant execute on function public.android_release() to anon, authenticated;

-- Admin: record a new build after uploading its file. Notifies members who
-- use the Android app (those with an Android device registered).
create function public.admin_publish_android(p_build int, p_version text, p_path text, p_notes text default null)
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
revoke execute on function public.admin_publish_android(int, text, text, text) from public, anon;
