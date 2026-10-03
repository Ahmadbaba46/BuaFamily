-- =============================================================================
-- Approving a member's suggestion to remove a relationship
--
-- review_change_request() learns the remove_parent_child and remove_union
-- request kinds (added in 20261010000001_tree_rules.sql). Only the link is
-- removed; both people stay in the tree.
--
-- The app offers removal to admins only for now; member suggestions can be
-- switched on in the app once this is applied.
-- =============================================================================

create or replace function public.review_change_request(p_request_id uuid, p_approve boolean, p_note text default null)
returns public.change_requests
language plpgsql security definer set search_path = '' as $$
declare
  r       public.change_requests;
  new_id  uuid;
begin
  if not public.is_admin() then
    raise exception 'Only admins can review requests' using errcode = '42501';
  end if;

  select * into r from public.change_requests where id = p_request_id for update;
  if not found then
    raise exception 'Request not found' using errcode = 'P0002';
  end if;
  if r.status <> 'pending' then
    raise exception 'Request has already been reviewed' using errcode = '55000';
  end if;

  if p_approve then
    case r.kind::text
      when 'create_person' then
        new_id := public._insert_person(r.payload -> 'person', r.requested_by);
        perform public._link_relation(new_id, r.payload -> 'relation');
      when 'update_person' then
        perform public._update_person(r.target_person_id, r.payload -> 'person');
      when 'add_parent_child' then
        insert into public.parent_child (parent_id, child_id, kind)
        values ((r.payload ->> 'parent_id')::uuid, (r.payload ->> 'child_id')::uuid,
                coalesce((r.payload ->> 'kind')::public.parent_kind, 'biological'));
      when 'add_union' then
        insert into public.unions (partner1_id, partner2_id, status, start_date)
        values ((r.payload ->> 'partner1_id')::uuid, (r.payload ->> 'partner2_id')::uuid,
                coalesce((r.payload ->> 'status')::public.union_status, 'married'),
                (r.payload ->> 'start_date')::date);
      when 'remove_parent_child' then
        -- Already gone is fine: the tree ends up as asked.
        perform 1 from public.parent_child
         where parent_id = (r.payload ->> 'parent_id')::uuid and child_id = (r.payload ->> 'child_id')::uuid;
        if found then
          execute 'delete from public.parent_child where parent_id = $1 and child_id = $2'
            using (r.payload ->> 'parent_id')::uuid, (r.payload ->> 'child_id')::uuid;
        end if;
      when 'remove_union' then
        execute 'delete from public.unions where least(partner1_id, partner2_id) = least($1, $2)
                   and greatest(partner1_id, partner2_id) = greatest($1, $2)'
          using (r.payload ->> 'partner1_id')::uuid, (r.payload ->> 'partner2_id')::uuid;
    end case;
  end if;

  update public.change_requests
     set status           = case when p_approve then 'approved'::public.request_status else 'rejected'::public.request_status end,
         reviewed_by      = auth.uid(),
         reviewed_at      = now(),
         review_note      = p_note,
         result_person_id = coalesce(new_id, r.target_person_id)
   where id = r.id
  returning * into r;
  return r;
end $$;
revoke execute on function public.review_change_request(uuid, boolean, text) from public, anon;
