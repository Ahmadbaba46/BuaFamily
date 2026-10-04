-- =============================================================================
-- Elders' stories are recorded by admins only; members listen.
-- The About page's developer details, editable by admins.
-- =============================================================================

alter policy stories_insert on public.stories
  with check (public.is_admin() and added_by = (select auth.uid()));

alter policy stories_audio_insert on storage.objects
  with check (bucket_id = 'stories' and public.is_admin()
              and (storage.foldername(name))[1] = (select auth.uid())::text);

alter table public.app_settings
  add column developer_name    text default 'Ahmad Baba',
  add column developer_company text default 'Fuyoudhat Tech Support',
  add column developer_phone   text,
  add column developer_email   text,
  add column developer_website text check (developer_website is null or developer_website ~ '^https?://');
