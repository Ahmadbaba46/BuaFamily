-- =============================================================================
-- Hardening after Supabase advisor review (part 1: grants, policies, indexes)
-- =============================================================================

-- Security: helper functions used by RLS policies only need to be callable by
-- signed-in users. The trigger function never needs to be called directly.
revoke execute on function public.is_active_member() from public, anon;
revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.my_person_id() from public, anon;
revoke execute on function public.contributions_enabled() from public, anon;
revoke execute on function public.can_view(public.visibility, uuid) from public, anon;
revoke execute on function public.can_edit_person(uuid) from public, anon;
revoke execute on function public.parent_child_guard() from public, anon, authenticated;
revoke execute on function public.persons_guard_core_fields() from public, anon, authenticated;
revoke execute on function public.touch_updated() from public, anon, authenticated;

-- Performance: evaluate auth.uid() once per query, not once per row.
alter policy profiles_select on public.profiles
  using (id = (select auth.uid()) or public.is_admin());
alter policy profiles_update_self on public.profiles
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
alter policy change_requests_select on public.change_requests
  using (requested_by = (select auth.uid()) or public.is_admin());
alter policy change_requests_delete on public.change_requests
  using ((requested_by = (select auth.uid()) and status = 'pending') or public.is_admin());
alter policy change_requests_insert on public.change_requests
  with check (
    public.is_active_member()
    and requested_by = (select auth.uid())
    and status = 'pending'
    and reviewed_by is null and reviewed_at is null and result_person_id is null
    and (
      public.contributions_enabled()
      or public.is_admin()
      or (kind = 'update_person' and target_person_id = public.my_person_id())
    )
  );

-- Performance: indexes for foreign keys that are looked up or cascaded on.
create index unions_partner1_idx on public.unions (partner1_id);
create index change_requests_target_person_idx on public.change_requests (target_person_id);
create index change_requests_result_person_idx on public.change_requests (result_person_id);
create index profiles_requested_person_idx on public.profiles (requested_person_id);
