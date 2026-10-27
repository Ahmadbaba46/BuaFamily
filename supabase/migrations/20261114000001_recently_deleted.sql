-- =============================================================================
-- Recently deleted: 30 days to undo a mistake.
--
-- 1. When someone deletes a person, event, poll, cause, dues plan, payout,
--    blood request, opportunity, memory, comment, relationship or detail, a
--    copy is kept, with everything that went with it (a person's links and
--    details, an event's replies and gifts...).
-- 2. Admins see what was deleted, by whom, and can put it all back. A
--    restored person is linked again to their account and, if they were,
--    made the tree's root again.
-- 3. Copies go for good after 30 days (or when an admin removes them).
-- 4. The activity log also records changes to people's details, the fund's
--    bank settings, reports being handled and groups being started, renamed
--    or deleted (never what is said in them).
-- =============================================================================

create table public.deleted_items (
  id          bigint generated always as identity primary key,
  -- Everything deleted together (one request) shares a txid and comes back together.
  txid        bigint not null default txid_current(),
  entity      text not null,
  row_id      text,
  -- What the person deleted (not something that went with it).
  root        boolean not null default false,
  label       text,
  data        jsonb not null,
  extra       jsonb,
  deleted_by  uuid references auth.users on delete set null,
  deleted_at  timestamptz not null default now(),
  restored_at timestamptz,
  restored_by uuid references auth.users on delete set null
);
create index deleted_items_txid_idx on public.deleted_items (txid);
create index deleted_items_deleted_at_idx on public.deleted_items (deleted_at desc);
create index deleted_items_deleted_by_idx on public.deleted_items (deleted_by);
create index deleted_items_restored_by_idx on public.deleted_items (restored_by);
alter table public.deleted_items enable row level security;
-- No policies: read and restored through the admin functions below.
revoke all on public.deleted_items from authenticated, anon;

-- Parents before children, so references resolve on the way back.
create function private.bin_order() returns text[]
language sql immutable set search_path = '' as $$
  select array[
    'persons', 'unions', 'parent_child', 'person_education', 'person_occupations', 'person_skills',
    'person_contacts', 'person_health', 'memories', 'remembrance_reminders', 'photo_people', 'post_people',
    'events', 'event_rsvps', 'event_attendance', 'event_collections', 'event_gifts', 'comments', 'likes',
    'blood_requests', 'blood_offers', 'fund_causes', 'fund_dues_plans', 'fund_dues_members', 'fund_payouts',
    'opportunities', 'polls', 'poll_options', 'poll_votes'
  ];
$$;

-- What someone would call "deleting something" (unliking or unticking is not).
create function private.bin_roots() returns text[]
language sql immutable set search_path = '' as $$
  select array[
    'persons', 'unions', 'parent_child', 'person_education', 'person_occupations', 'person_skills',
    'person_contacts', 'person_health', 'memories', 'events', 'event_gifts', 'comments', 'blood_requests',
    'fund_causes', 'fund_dues_plans', 'fund_payouts', 'opportunities', 'polls'
  ];
$$;

create function private.keep_deleted() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  r jsonb := to_jsonb(old);
  is_root boolean := pg_trigger_depth() = 1;
  name_of text;
  label text;
  extra jsonb;
begin
  -- A backup being restored, an account removing itself, or the system tidying up.
  if auth.uid() is null or coalesce(current_setting('bua.restoring', true), '') = 'on' then
    return old;
  end if;
  if is_root and not (tg_table_name = any (private.bin_roots())) then
    return old;
  end if;
  label := case tg_table_name
    when 'persons' then nullif(concat_ws(' ', r ->> 'first_name', r ->> 'last_name'), '')
    when 'parent_child' then concat_ws(' → ',
      (select concat_ws(' ', p.first_name, p.last_name) from public.persons p where p.id = (r ->> 'parent_id')::uuid),
      (select concat_ws(' ', p.first_name, p.last_name) from public.persons p where p.id = (r ->> 'child_id')::uuid))
    when 'unions' then concat_ws(' & ',
      (select concat_ws(' ', p.first_name, p.last_name) from public.persons p where p.id = (r ->> 'partner1_id')::uuid),
      (select concat_ws(' ', p.first_name, p.last_name) from public.persons p where p.id = (r ->> 'partner2_id')::uuid))
    else coalesce(r ->> 'title', r ->> 'question', r ->> 'patient_name', r ->> 'institution', r ->> 'skill',
                  left(coalesce(r ->> 'body', r ->> 'note', r ->> 'details'), 80))
  end;
  if tg_table_name in ('person_education', 'person_occupations', 'person_skills', 'person_contacts', 'person_health',
                       'memories') then
    name_of := (select concat_ws(' ', p.first_name, p.last_name) from public.persons p where p.id = (r ->> 'person_id')::uuid);
    label := concat_ws(': ', name_of, case when tg_table_name = 'person_health' then null else label end);
  end if;
  if tg_table_name = 'persons' then
    extra := jsonb_build_object(
      'accounts', coalesce((select jsonb_agg(id) from public.profiles where person_id = old.id), '[]'::jsonb),
      'root', exists (select 1 from public.app_settings where root_person_id = old.id));
  end if;
  insert into public.deleted_items (entity, row_id, root, label, data, extra, deleted_by)
  values (tg_table_name, coalesce(r ->> 'id', concat_ws(':', r ->> 'event_id', r ->> 'poll_id', r ->> 'user_id')),
          is_root, nullif(btrim(label), ''), r, extra, auth.uid());
  return old;
end $$;

do $$
declare
  t text;
begin
  foreach t in array private.bin_order() loop
    execute format('create trigger aa_keep_deleted before delete on public.%I
                    for each row execute function private.keep_deleted()', t);
  end loop;
end $$;

-- -----------------------------------------------------------------------------
-- Admins: what was deleted lately, one entry per deletion.
-- -----------------------------------------------------------------------------
create function public.admin_deleted_items(p_before bigint default null, p_limit int default 50) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can see what was deleted' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(g order by g.id desc)
    from (
      select min(d.id) as id, d.txid, min(d.deleted_at) as deleted_at,
             (array_agg(d.deleted_by order by d.id))[1] as deleted_by,
             private.member_name((array_agg(d.deleted_by order by d.id))[1]) as deleted_by_name,
             max(d.restored_at) as restored_at,
             private.member_name(max(d.restored_by::text)::uuid) as restored_by_name,
             count(*)::int as total,
             jsonb_agg(jsonb_build_object('entity', d.entity, 'id', d.row_id, 'label', d.label) order by d.id)
               filter (where d.root) as items,
             coalesce(jsonb_agg(distinct d.entity) filter (where not d.root), '[]'::jsonb) as also
        from public.deleted_items d
       group by d.txid
      having bool_or(d.root) and (p_before is null or min(d.id) < p_before)
       order by min(d.id) desc
       limit least(greatest(coalesce(p_limit, 50), 1), 200)
    ) g
  ), '[]'::jsonb);
end $$;

-- Admins: put back everything deleted together. Returns how many rows came back
-- (and how many could not: something they belonged to is gone too).
create function public.admin_restore_deleted(p_txid bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  d record;
  restored int := 0;
  skipped int := 0;
  first_root public.deleted_items;
begin
  if not public.is_admin() then
    raise exception 'Only admins can restore what was deleted' using errcode = '42501';
  end if;
  if not exists (select 1 from public.deleted_items where txid = p_txid and root) then
    raise exception 'Nothing to restore' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.deleted_items where txid = p_txid and restored_at is not null) then
    raise exception 'This has already been restored' using errcode = '22023';
  end if;

  -- Put back quietly: nobody is notified again, nothing is logged twice.
  perform set_config('bua.restoring', 'on', true);
  for d in
    select * from public.deleted_items
     where txid = p_txid
     order by array_position(private.bin_order(), entity), id
  loop
    begin
      execute format('insert into public.%I select * from jsonb_populate_record(null::public.%I, $1) on conflict do nothing',
                     d.entity, d.entity)
        using d.data;
      restored := restored + 1;
    exception when others then
      skipped := skipped + 1;
    end;
    if d.entity = 'persons' and d.extra is not null then
      update public.profiles set person_id = d.row_id::uuid
       where id in (select (jsonb_array_elements_text(d.extra -> 'accounts'))::uuid) and person_id is null
         and exists (select 1 from public.persons where id = d.row_id::uuid);
      if (d.extra ->> 'root')::boolean then
        update public.app_settings set root_person_id = d.row_id::uuid
         where root_person_id is null and exists (select 1 from public.persons where id = d.row_id::uuid);
      end if;
    end if;
  end loop;
  perform set_config('bua.restoring', 'off', true);

  update public.deleted_items set restored_at = now(), restored_by = auth.uid() where txid = p_txid;
  select * into first_root from public.deleted_items where txid = p_txid and root order by id limit 1;
  insert into public.activity_log (user_id, action, entity, target, detail, platform)
  values (auth.uid(), 'restore', first_root.entity, first_root.row_id,
          jsonb_strip_nulls(jsonb_build_object('label', first_root.label, 'restored', restored, 'skipped', skipped)),
          (select p.platform from public.presence p where p.user_id = auth.uid()));
  return jsonb_build_object('restored', restored, 'skipped', skipped);
end $$;

-- -----------------------------------------------------------------------------
-- The activity log: people's details, the fund's settings, reports, groups.
-- -----------------------------------------------------------------------------
create or replace function private.log_change() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  who uuid := auth.uid();
  r jsonb := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  quiet text[] := array['updated_at', 'updated_by', 'last_message_at', 'last_message', 'last_message_by',
                        'last_message_kind', 'last_event',
                        'mentor_read_at', 'asker_read_at', 'last_seen_at', 'last_platform', 'app_build'];
  private_ boolean := tg_table_name in ('mentor_asks', 'mentor_messages');
  -- Health details: only whose they are.
  health boolean := tg_table_name = 'person_health';
  label text;
begin
  if who is null or current_setting('bua.restoring', true) = 'on' then
    return null;   -- the system (reminders, cron), or a restore putting rows back
  end if;
  if tg_op = 'UPDATE' and (to_jsonb(old) - quiet) = (to_jsonb(new) - quiet) then
    return null;   -- nothing anyone would call a change
  end if;
  label := case
    when private_ or health then null
    when tg_table_name = 'persons' then nullif(concat_ws(' ', r ->> 'first_name', r ->> 'last_name'), '')
    when tg_table_name = 'profiles' then r ->> 'display_name'
    when tg_table_name = 'chat_groups' then r ->> 'name'
    when tg_table_name = 'fund_settings' then null
    when tg_table_name = 'reports' then r ->> 'kind'
    else coalesce(r ->> 'title', r ->> 'question', r ->> 'patient_name', r ->> 'field', r ->> 'areas',
                  r ->> 'institution', r ->> 'skill',
                  left(coalesce(r ->> 'body', r ->> 'caption', r ->> 'message', r ->> 'note'), 80))
  end;
  insert into public.activity_log (user_id, action, entity, target, detail, platform)
  values (who, lower(tg_op), tg_table_name, coalesce(r ->> 'id', r ->> 'code', r ->> 'person_id'),
          case when private_ then '{}'::jsonb
               when health then jsonb_build_object('person_id', r ->> 'person_id')
               else jsonb_strip_nulls(jsonb_build_object(
            'label', label,
            'kind', r ->> 'kind', 'status', r ->> 'status', 'role', r ->> 'role',
            'response', r ->> 'response', 'amount', r -> 'amount',
            'post_id', r ->> 'post_id', 'photo_id', r ->> 'photo_id', 'event_id', r ->> 'event_id',
            'poll_id', r ->> 'poll_id', 'album_id', r ->> 'album_id', 'cause_id', r ->> 'cause_id',
            'request_id', r ->> 'request_id',
            'person_id', coalesce(r ->> 'person_id', r ->> 'target_person_id', r ->> 'patient_person_id',
                                  r ->> 'child_id', r ->> 'partner1_id'))) end,
          (select p.platform from public.presence p where p.user_id = who));
  return null;
end $$;

do $$
declare
  t text;
begin
  foreach t in array array['person_education', 'person_occupations', 'person_skills', 'person_contacts',
                           'person_health', 'fund_settings', 'reports', 'chat_groups'] loop
    execute format('create trigger zz_log_change after insert or update or delete on public.%I
                    for each row execute function private.log_change()', t);
  end loop;
end $$;

revoke execute on function private.bin_order() from public, anon, authenticated;
revoke execute on function private.bin_roots() from public, anon, authenticated;
revoke execute on function private.keep_deleted() from public, anon, authenticated;
revoke execute on function public.admin_deleted_items(bigint, int) from public, anon;
revoke execute on function public.admin_restore_deleted(bigint) from public, anon;
