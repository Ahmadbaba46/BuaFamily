-- =============================================================================
-- Who is in the family by blood and who married in, and men and women, for
-- the admin snapshot.
--
-- Blood family: the founders (the family's root person, and anyone else at
-- the top of a line who isn't a spouse marrying in) and everyone descended
-- from them as a born or adopted child. Married in: the spouses of blood
-- family who aren't blood themselves. Everyone else (step or foster
-- children, people not connected to anyone yet) is "other".
--
-- At the top of a line both partners have no parents in the tree; the
-- family's root person, or else the husband, is the founder. This is the
-- same rule the members list uses to place spouses who married in.
-- =============================================================================

create or replace function private.person_lineage()
returns table (person_id uuid, lineage text)
language sql stable security definer set search_path = '' as $$
  with recursive
  root as (select root_person_id as id from public.app_settings where id),
  has_parents as (select distinct child_id as id from public.parent_child),
  partners as (
    select partner1_id as a, partner2_id as b from public.unions
    union
    select partner2_id, partner1_id from public.unions
  ),
  founders as (
    select p.id from public.persons p
    where p.id not in (select id from has_parents)
      and (p.id in (select id from root where id is not null)
           or (exists (select 1 from public.parent_child c where c.parent_id = p.id)
               and not exists (
                 select 1 from partners s join public.persons q on q.id = s.b
                 where s.a = p.id
                   and (q.id in (select id from has_parents)
                        or q.id in (select id from root where id is not null)
                        or (q.sex = 'male' and p.sex = 'female')))))
  ),
  blood (id) as (
    select id from founders
    union
    select c.child_id from public.parent_child c join blood b on b.id = c.parent_id
    where c.kind in ('biological', 'adopted')
  )
  select p.id,
         case when p.id in (select id from blood) then 'blood'
              when exists (select 1 from partners s where s.a = p.id and s.b in (select id from blood)) then 'married_in'
              else 'other' end
  from public.persons p;
$$;

revoke execute on function private.person_lineage() from public, anon, authenticated;

create or replace function public.admin_snapshot() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can see metrics' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'accounts', (select count(*) from public.profiles),
    'approved', (select count(*) from public.profiles where status = 'active'),
    'waiting', (select count(*) from public.profiles where status = 'pending'),
    'linked', (select count(*) from public.profiles where status = 'active' and person_id is not null),
    'active_7d', (select count(distinct user_id) from public.activity_days
                  where day > (now() at time zone 'Africa/Lagos')::date - 7),
    'active_30d', (select count(distinct user_id) from public.activity_days
                   where day > (now() at time zone 'Africa/Lagos')::date - 30),
    'push_on', (select count(distinct t.user_id) from public.push_tokens t
                join public.profiles p on p.id = t.user_id and p.status = 'active'),
    'android_app', (select count(distinct t.user_id) from public.push_tokens t where t.platform = 'android'),
    'people', (select count(*) from public.persons),
    'living', (select count(*) from public.persons where is_living),
    'with_photo', (select count(*) from public.persons where photo_path is not null),
    'with_birth_date', (select count(*) from public.persons where birth_date is not null),
    'with_account', (select count(*) from public.profiles where person_id is not null),
    'branches', coalesce((select jsonb_agg(b order by b) from
                  (select distinct nullif(trim(branch), '') b from public.persons) x where b is not null), '[]'::jsonb),
    'fund_balance', (select coalesce(sum(amount), 0) from public.fund_contributions where status::text = 'confirmed')
                    - (select coalesce(sum(amount), 0) from public.fund_payouts),
    'open_blood_requests', (select count(*) from public.blood_requests where status::text = 'open'),
    'pending_suggestions', (select count(*) from public.change_requests where status = 'pending'),
    -- Men and women: in the family by blood, married in, or not connected
    -- yet; and how many are living.
    'composition', (
      select coalesce(jsonb_object_agg(lineage, by_sex), '{}'::jsonb) from (
        select g.lineage, jsonb_build_object(
                 'male', count(*) filter (where p.sex = 'male'),
                 'female', count(*) filter (where p.sex = 'female'),
                 'unknown', count(*) filter (where p.sex = 'unknown'),
                 'living_male', count(*) filter (where p.sex = 'male' and p.is_living),
                 'living_female', count(*) filter (where p.sex = 'female' and p.is_living),
                 'living_unknown', count(*) filter (where p.sex = 'unknown' and p.is_living)) as by_sex
        from private.person_lineage() g join public.persons p on p.id = g.person_id
        group by g.lineage
      ) x)
  );
end $$;
