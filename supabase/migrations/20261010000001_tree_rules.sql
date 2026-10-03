-- =============================================================================
-- Tree: birth order, impossible links, a health check, removing relationships
--
-- * persons.birth_order: 1 for the first-born, 2 for the next... Siblings are
--   ordered by it (then by date of birth).
-- * Nobody can be married to their own parent, grandparent, child or
--   grandchild. Both sides are checked: adding a marriage, and adding a
--   parent/child link that would put a spouse in the same line (for example
--   a man's wife added as his granddaughter).
-- * tree_problems(): what an admin should look at in the existing tree.
-- * Admins can remove a relationship (not the person) directly. The request
--   kinds for members to suggest a removal are added here; approving them is
--   in the next migration.
-- =============================================================================

alter table public.persons add column birth_order smallint
  constraint persons_birth_order_range check (birth_order between 1 and 60);

create or replace function public._person_columns() returns text[]
language sql immutable set search_path = '' as $$
  select array['title','first_name','middle_name','last_name','nickname','sex',
               'birth_date','birth_date_approx','birth_place','is_living',
               'death_date','death_date_approx','death_place','burial_place',
               'biography','photo_path','branch','birth_order'];
$$;
revoke execute on function public._person_columns() from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Same line of descent
-- -----------------------------------------------------------------------------
create function private.ancestors(p_id uuid) returns table (id uuid)
language sql stable set search_path = '' as $$
  with recursive up(id) as (
    select pc.parent_id from public.parent_child pc where pc.child_id = p_id
    union
    select pc.parent_id from public.parent_child pc join up on pc.child_id = up.id
  )
  select id from up;
$$;

create function private.descendants(p_id uuid) returns table (id uuid)
language sql stable set search_path = '' as $$
  with recursive down(id) as (
    select pc.child_id from public.parent_child pc where pc.parent_id = p_id
    union
    select pc.child_id from public.parent_child pc join down on pc.parent_id = down.id
  )
  select id from down;
$$;

-- True when one of the two descends from the other.
create function private.same_line(a uuid, b uuid) returns boolean
language sql stable set search_path = '' as $$
  select exists (select 1 from private.ancestors(a) x where x.id = b)
      or exists (select 1 from private.ancestors(b) x where x.id = a);
$$;

create function private.unions_line_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if private.same_line(new.partner1_id, new.partner2_id) then
    raise exception 'Someone cannot be married to their own parent, grandparent, child or grandchild'
      using errcode = '23514';
  end if;
  return new;
end $$;

create trigger unions_line_guard before insert or update of partner1_id, partner2_id on public.unions
  for each row execute function private.unions_line_guard();

-- After linking parent P to child K, P and P's ancestors become ancestors of K
-- and K's descendants. None of them may be married to one of those.
create function private.parent_child_line_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if exists (
    with up as (select new.parent_id as id union select id from private.ancestors(new.parent_id)),
         down as (select new.child_id as id union select id from private.descendants(new.child_id))
    select 1 from public.unions u
    where (u.partner1_id in (select id from up) and u.partner2_id in (select id from down))
       or (u.partner2_id in (select id from up) and u.partner1_id in (select id from down))
  ) then
    raise exception 'This would make someone the child or grandchild of their own husband or wife'
      using errcode = '23514';
  end if;
  return new;
end $$;

create trigger parent_child_line_guard before insert or update on public.parent_child
  for each row execute function private.parent_child_line_guard();

revoke execute on function private.ancestors(uuid) from public, anon, authenticated;
revoke execute on function private.descendants(uuid) from public, anon, authenticated;
revoke execute on function private.same_line(uuid, uuid) from public, anon, authenticated;
revoke execute on function private.unions_line_guard() from public, anon, authenticated;
revoke execute on function private.parent_child_line_guard() from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Admin: things in the tree that look wrong (entered before these checks, or
-- simply unlikely), each with the people involved.
-- -----------------------------------------------------------------------------
create function public.tree_problems() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can check the tree' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(x order by x ->> 'kind', x ->> 'a') from (
      -- Married within the same line of descent.
      select jsonb_build_object('kind', 'married_in_line', 'a', u.partner1_id, 'b', u.partner2_id, 'union_id', u.id) x
      from public.unions u
      where private.same_line(u.partner1_id, u.partner2_id)
      union all
      -- A parent born after (or the same year as) their child.
      select jsonb_build_object('kind', 'parent_younger', 'a', pc.parent_id, 'b', pc.child_id, 'link_id', pc.id)
      from public.parent_child pc
      join public.persons p on p.id = pc.parent_id
      join public.persons c on c.id = pc.child_id
      where pc.kind = 'biological' and p.birth_date is not null and c.birth_date is not null
        and p.birth_date > c.birth_date - interval '10 years'
      union all
      -- A child born more than a year after a biological parent died.
      select jsonb_build_object('kind', 'born_after_death', 'a', pc.parent_id, 'b', pc.child_id, 'link_id', pc.id)
      from public.parent_child pc
      join public.persons p on p.id = pc.parent_id
      join public.persons c on c.id = pc.child_id
      where pc.kind = 'biological' and p.death_date is not null and c.birth_date is not null
        and c.birth_date > p.death_date + interval '1 year'
      union all
      -- Two siblings given the same birth order.
      select distinct on (least(a.child_id, b.child_id), greatest(a.child_id, b.child_id))
             jsonb_build_object('kind', 'same_birth_order', 'a', least(a.child_id, b.child_id),
                                'b', greatest(a.child_id, b.child_id), 'parent', a.parent_id)
      from public.parent_child a
      join public.parent_child b on b.parent_id = a.parent_id and b.child_id <> a.child_id
      join public.persons pa on pa.id = a.child_id
      join public.persons pb on pb.id = b.child_id
      where pa.birth_order is not null and pa.birth_order = pb.birth_order
    ) s
  ), '[]'::jsonb);
end $$;
revoke execute on function public.tree_problems() from public, anon;

-- -----------------------------------------------------------------------------
-- Removing a relationship
-- -----------------------------------------------------------------------------
alter type public.request_kind add value if not exists 'remove_parent_child';
alter type public.request_kind add value if not exists 'remove_union';
