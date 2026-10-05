-- =============================================================================
-- Database cleanup (from the Supabase advisors).
--
-- * Indexes for the foreign keys that had none, so deleting an account or a
--   person doesn't scan whole tables.
-- * Dues plans and members: the committee's write rule also covered reading,
--   so every read checked two rules. Writing now has its own rules for
--   insert, update and delete; reading keeps one rule (which already lets the
--   committee read everything).
-- =============================================================================

create index if not exists password_resets_user_idx on private.password_resets (user_id);
create index if not exists dm_messages_author_idx on public.dm_messages (author_id);
create index if not exists dm_threads_last_message_by_idx on public.dm_threads (last_message_by);
create index if not exists event_attendance_recorded_by_idx on public.event_attendance (recorded_by);
create index if not exists fund_contributions_recorded_by_idx on public.fund_contributions (recorded_by);
create index if not exists fund_dues_plans_created_by_idx on public.fund_dues_plans (created_by);
create index if not exists invites_created_by_idx on public.invites (created_by);
create index if not exists invites_person_idx on public.invites (person_id);
create index if not exists invites_used_by_idx on public.invites (used_by);
create index if not exists mentor_asks_last_message_by_idx on public.mentor_asks (last_message_by);
create index if not exists mentor_messages_author_idx on public.mentor_messages (author_id);

drop policy fund_dues_plans_write on public.fund_dues_plans;
create policy fund_dues_plans_insert on public.fund_dues_plans for insert to authenticated
  with check (public.is_committee());
create policy fund_dues_plans_update on public.fund_dues_plans for update to authenticated
  using (public.is_committee()) with check (public.is_committee());
create policy fund_dues_plans_delete on public.fund_dues_plans for delete to authenticated
  using (public.is_committee());

drop policy fund_dues_members_write on public.fund_dues_members;
create policy fund_dues_members_insert on public.fund_dues_members for insert to authenticated
  with check (public.is_committee());
create policy fund_dues_members_update on public.fund_dues_members for update to authenticated
  using (public.is_committee()) with check (public.is_committee());
create policy fund_dues_members_delete on public.fund_dues_members for delete to authenticated
  using (public.is_committee());
