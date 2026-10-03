-- Indexes for the remaining foreign keys flagged by the Supabase performance
-- advisor ("who created / updated / reviewed this"). They keep deletes of
-- accounts and people fast as the family grows.
create index if not exists app_settings_root_person_idx on public.app_settings (root_person_id);
create index if not exists app_settings_updated_by_idx on public.app_settings (updated_by);
create index if not exists change_requests_reviewed_by_idx on public.change_requests (reviewed_by);
create index if not exists parent_child_created_by_idx on public.parent_child (created_by);
create index if not exists persons_created_by_idx on public.persons (created_by);
create index if not exists persons_updated_by_idx on public.persons (updated_by);
create index if not exists unions_created_by_idx on public.unions (created_by);
