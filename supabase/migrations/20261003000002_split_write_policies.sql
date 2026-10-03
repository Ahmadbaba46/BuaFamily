-- =============================================================================
-- Hardening part 2: split "for all" write policies into one policy per action
-- (performance only). Contains DROP POLICY, so the Supabase MCP tool asks for
-- confirmation; it can also be run from the dashboard's SQL editor.
-- =============================================================================

-- Performance: one policy per action. The "for all" write policies also
-- applied to SELECT, so every read evaluated two policies.
drop policy unions_write on public.unions;
create policy unions_insert on public.unions for insert to authenticated with check (public.is_admin());
create policy unions_update on public.unions for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy unions_delete on public.unions for delete to authenticated using (public.is_admin());

drop policy parent_child_write on public.parent_child;
create policy parent_child_insert on public.parent_child for insert to authenticated with check (public.is_admin());
create policy parent_child_update on public.parent_child for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy parent_child_delete on public.parent_child for delete to authenticated using (public.is_admin());

drop policy person_education_write on public.person_education;
create policy person_education_insert on public.person_education for insert to authenticated with check (public.can_edit_person(person_id));
create policy person_education_update on public.person_education for update to authenticated using (public.can_edit_person(person_id)) with check (public.can_edit_person(person_id));
create policy person_education_delete on public.person_education for delete to authenticated using (public.can_edit_person(person_id));

drop policy person_occupations_write on public.person_occupations;
create policy person_occupations_insert on public.person_occupations for insert to authenticated with check (public.can_edit_person(person_id));
create policy person_occupations_update on public.person_occupations for update to authenticated using (public.can_edit_person(person_id)) with check (public.can_edit_person(person_id));
create policy person_occupations_delete on public.person_occupations for delete to authenticated using (public.can_edit_person(person_id));

drop policy person_skills_write on public.person_skills;
create policy person_skills_insert on public.person_skills for insert to authenticated with check (public.can_edit_person(person_id));
create policy person_skills_update on public.person_skills for update to authenticated using (public.can_edit_person(person_id)) with check (public.can_edit_person(person_id));
create policy person_skills_delete on public.person_skills for delete to authenticated using (public.can_edit_person(person_id));

drop policy person_contacts_write on public.person_contacts;
create policy person_contacts_insert on public.person_contacts for insert to authenticated with check (public.can_edit_person(person_id));
create policy person_contacts_update on public.person_contacts for update to authenticated using (public.can_edit_person(person_id)) with check (public.can_edit_person(person_id));
create policy person_contacts_delete on public.person_contacts for delete to authenticated using (public.can_edit_person(person_id));

drop policy person_health_write on public.person_health;
create policy person_health_insert on public.person_health for insert to authenticated with check (public.can_edit_person(person_id));
create policy person_health_update on public.person_health for update to authenticated using (public.can_edit_person(person_id)) with check (public.can_edit_person(person_id));
create policy person_health_delete on public.person_health for delete to authenticated using (public.can_edit_person(person_id));
