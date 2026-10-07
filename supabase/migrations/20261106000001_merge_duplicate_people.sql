-- =============================================================================
-- Finding and merging people entered twice in the tree.
--
-- The app suggests likely pairs (same or similar names, compatible dates,
-- shared parents or spouses). An admin chooses which record to keep;
-- admin_merge_persons then fills the kept record's empty details from the
-- other, and moves every link to it: parents, children, spouses, education,
-- work, skills, contact and health details, tags in moments and photos,
-- memories, stories, events attended, khatms, the linked account and so on.
-- Links the kept person already has are left on the duplicate. The app then
-- deletes the duplicate as usual, and what was left goes with it.
--
-- It refuses when both records are linked to accounts, and the tree's own
-- rules still apply (two different fathers, say, stop the merge until one
-- link is removed). Pairs an admin says are different people are remembered
-- in not_duplicates and not suggested again.
-- =============================================================================

create table public.not_duplicates (
  person_a    uuid not null references public.persons on delete cascade,
  person_b    uuid not null references public.persons on delete cascade,
  created_by  uuid default auth.uid() references auth.users on delete set null,
  created_at  timestamptz not null default now(),
  primary key (person_a, person_b),
  constraint not_duplicates_ordered check (person_a < person_b)
);
create index not_duplicates_b_idx on public.not_duplicates (person_b);
create index not_duplicates_created_by_idx on public.not_duplicates (created_by);

alter table public.not_duplicates enable row level security;
create policy not_duplicates_select on public.not_duplicates for select to authenticated
  using (public.is_admin());
create policy not_duplicates_insert on public.not_duplicates for insert to authenticated
  with check (public.is_admin());
create policy not_duplicates_remove on public.not_duplicates for delete to authenticated
  using (public.is_admin());

create function public.admin_merge_persons(p_keep uuid, p_remove uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  k public.persons;
  r public.persons;
  moved int := 0;
  n int;
begin
  if not public.is_admin() then
    raise exception 'Only admins can merge people' using errcode = '42501';
  end if;
  if p_keep = p_remove then
    raise exception 'Choose two different people' using errcode = '22023';
  end if;
  select * into k from public.persons where id = p_keep for update;
  select * into r from public.persons where id = p_remove for update;
  if k.id is null or r.id is null then
    raise exception 'Person not found' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.profiles where person_id = p_keep)
     and exists (select 1 from public.profiles where person_id = p_remove) then
    raise exception 'Both are linked to accounts. Unlink one account first (Admin → Accounts).'
      using errcode = '55000';
  end if;
  if k.sex <> 'unknown' and r.sex <> 'unknown' and k.sex <> r.sex then
    raise exception 'One is recorded as male and the other as female' using errcode = '55000';
  end if;

  -- Fill what the kept record is missing.
  update public.persons set
    title          = coalesce(k.title, r.title),
    middle_name    = coalesce(k.middle_name, r.middle_name),
    last_name      = coalesce(k.last_name, r.last_name),
    nickname       = coalesce(k.nickname, r.nickname),
    sex            = case when k.sex = 'unknown' then r.sex else k.sex end,
    birth_date     = coalesce(k.birth_date, r.birth_date),
    birth_date_approx = case when k.birth_date is null then r.birth_date_approx else k.birth_date_approx end,
    birth_place    = coalesce(k.birth_place, r.birth_place),
    is_living      = k.is_living and r.is_living,
    death_date     = coalesce(k.death_date, r.death_date),
    death_date_approx = case when k.death_date is null then r.death_date_approx else k.death_date_approx end,
    death_place    = coalesce(k.death_place, r.death_place),
    burial_place   = coalesce(k.burial_place, r.burial_place),
    biography      = coalesce(nullif(btrim(k.biography), ''), r.biography),
    photo_path     = coalesce(k.photo_path, r.photo_path),
    branch         = coalesce(k.branch, r.branch),
    birth_order    = coalesce(k.birth_order, r.birth_order)
  where id = p_keep;

  -- Parents and children (not the link between the two, nor ones already there).
  update public.parent_child x set parent_id = p_keep
   where x.parent_id = p_remove and x.child_id <> p_keep
     and not exists (select 1 from public.parent_child y where y.parent_id = p_keep and y.child_id = x.child_id);
  get diagnostics n = row_count; moved := moved + n;
  update public.parent_child x set child_id = p_keep
   where x.child_id = p_remove and x.parent_id <> p_keep
     and not exists (select 1 from public.parent_child y where y.child_id = p_keep and y.parent_id = x.parent_id);
  get diagnostics n = row_count; moved := moved + n;

  -- Spouses.
  update public.unions x set partner1_id = p_keep
   where x.partner1_id = p_remove and x.partner2_id <> p_keep
     and not exists (select 1 from public.unions y
                     where (y.partner1_id = p_keep and y.partner2_id = x.partner2_id)
                        or (y.partner2_id = p_keep and y.partner1_id = x.partner2_id));
  get diagnostics n = row_count; moved := moved + n;
  update public.unions x set partner2_id = p_keep
   where x.partner2_id = p_remove and x.partner1_id <> p_keep
     and not exists (select 1 from public.unions y
                     where (y.partner1_id = p_keep and y.partner2_id = x.partner1_id)
                        or (y.partner2_id = p_keep and y.partner1_id = x.partner1_id));
  get diagnostics n = row_count; moved := moved + n;

  -- Details.
  update public.person_education set person_id = p_keep where person_id = p_remove;
  update public.person_occupations set person_id = p_keep where person_id = p_remove;
  update public.person_skills x set person_id = p_keep
   where x.person_id = p_remove
     and not exists (select 1 from public.person_skills y where y.person_id = p_keep and y.skill = x.skill);
  update public.person_contacts set person_id = p_keep
   where person_id = p_remove and not exists (select 1 from public.person_contacts where person_id = p_keep);
  update public.person_health set person_id = p_keep
   where person_id = p_remove and not exists (select 1 from public.person_health where person_id = p_keep);

  -- Everything else that points at the person.
  update public.profiles set person_id = p_keep where person_id = p_remove;
  update public.profiles set requested_person_id = p_keep where requested_person_id = p_remove;
  update public.app_settings set root_person_id = p_keep where root_person_id = p_remove;
  update public.change_requests set target_person_id = p_keep where target_person_id = p_remove;
  update public.change_requests set result_person_id = p_keep where result_person_id = p_remove;
  update public.post_people x set person_id = p_keep
   where x.person_id = p_remove
     and not exists (select 1 from public.post_people y where y.post_id = x.post_id and y.person_id = p_keep);
  update public.photo_people x set person_id = p_keep
   where x.person_id = p_remove
     and not exists (select 1 from public.photo_people y where y.photo_id = x.photo_id and y.person_id = p_keep);
  update public.event_attendance x set person_id = p_keep
   where x.person_id = p_remove
     and not exists (select 1 from public.event_attendance y where y.event_id = x.event_id and y.person_id = p_keep);
  update public.remembrance_reminders x set person_id = p_keep
   where x.person_id = p_remove
     and not exists (select 1 from public.remembrance_reminders y where y.user_id = x.user_id and y.person_id = p_keep);
  update public.memories set person_id = p_keep where person_id = p_remove;
  update public.stories set speaker_id = p_keep where speaker_id = p_remove;
  update public.blood_requests set patient_person_id = p_keep where patient_person_id = p_remove;
  update public.invites set person_id = p_keep where person_id = p_remove;
  update public.khatms set person_id = p_keep where person_id = p_remove;

  insert into public.activity_log (user_id, action, entity, target, detail)
  values (auth.uid(), 'merge', 'persons', p_keep::text,
          jsonb_build_object('label', private.person_name(k), 'merged', private.person_name(r)));
  return jsonb_build_object('kept', p_keep, 'links_moved', moved);
end $$;

revoke execute on function public.admin_merge_persons(uuid, uuid) from public, anon;
