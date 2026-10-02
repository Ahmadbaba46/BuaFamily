-- =============================================================================
-- Photo storage
--
-- Private bucket 'photos'. Path convention:
--   persons/<person_id>/<file>   profile photos and personal images
-- Only active members can view. Admins can upload anywhere; members can upload
-- into the folder of the person linked to their account.
-- =============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 10485760, array['image/jpeg', 'image/png', 'image/webp', 'image/heic'])
on conflict (id) do nothing;

create policy photos_select on storage.objects for select to authenticated
  using (bucket_id = 'photos' and public.is_active_member());

create policy photos_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'photos'
    and (
      public.is_admin()
      or ((storage.foldername(name))[1] = 'persons'
          and (storage.foldername(name))[2] = public.my_person_id()::text)
    )
  );

create policy photos_update on storage.objects for update to authenticated
  using (
    bucket_id = 'photos'
    and (
      public.is_admin()
      or ((storage.foldername(name))[1] = 'persons'
          and (storage.foldername(name))[2] = public.my_person_id()::text)
    )
  );

create policy photos_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'photos'
    and (
      public.is_admin()
      or ((storage.foldername(name))[1] = 'persons'
          and (storage.foldername(name))[2] = public.my_person_id()::text)
    )
  );
