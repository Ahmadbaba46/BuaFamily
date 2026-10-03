-- =============================================================================
-- Restore from a backup (admins)
--
-- admin_restore() puts a backup's rows back, table by table:
--   * rows that are missing (deleted since, or a fresh project) are added back;
--   * with p_overwrite, rows that were changed since are changed back;
--   * nothing is ever deleted, so anything added after the backup stays.
-- Rows that can't go back (their account no longer exists, or they break the
-- tree rules) are skipped and counted. Restoring sends no notifications or SMS.
--
-- p_dry_run does the whole restore and then rolls it back, so the app can show
-- exactly what would change before the admin confirms. A real restore first
-- saves the current data as a restore point (listed as backup slot -1), so it
-- can itself be undone.
--
-- Accounts (profiles) and settings are not restored: members sign in again and
-- an admin links them. Photos, voice recordings and receipts are files kept in
-- storage; a backup has their details but not the files.
-- =============================================================================

create table private.restore_points (
  id        boolean primary key default true check (id),
  taken_at  timestamptz not null,
  data      jsonb not null
);

-- Nothing is announced while a restore runs.
create or replace function private.skip_muted_notification() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if current_setting('bua.restoring', true) = 'on' then
    return null;
  end if;
  if new.kind::text not in ('blood_request', 'blood_offer')
     and exists (select 1 from public.profiles
                 where id = new.user_id and new.kind::text = any (muted_notifications)) then
    return null;
  end if;
  return new;
end $$;

create or replace function private.queue_sms(
  p_user_ids uuid[], p_pref text, p_text_en text, p_text_ha text, p_dedupe_prefix text
) returns int
language plpgsql security definer set search_path = '' as $$
declare
  n int;
begin
  if current_setting('bua.restoring', true) = 'on' or not (select sms_enabled from public.app_settings) then
    return 0;
  end if;
  insert into private.sms_outbox (user_id, phone, message, dedupe_key)
  select p.id, p.phone,
         left(private.sms_prefix(p.locale) || ': ' || case when p.locale = 'ha' then p_text_ha else p_text_en end, 306),
         case when p_dedupe_prefix is null then null else p_dedupe_prefix || ':' || p.id end
  from public.profiles p
  where p.id = any (p_user_ids)
    and p.status = 'active'
    and p.sms_opt_in
    and p.phone is not null
    and case p_pref when 'events' then p.sms_events when 'birthdays' then p.sms_birthdays else true end
  on conflict (dedupe_key) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;

-- Returns {"<table>": {"added": n, "updated": n, "skipped": n}, ...}.
create function public.admin_restore(p_data jsonb, p_overwrite boolean default false, p_dry_run boolean default true)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  -- Parents before children, so references resolve.
  tables text[] := array[
    'persons', 'unions', 'parent_child', 'person_education', 'person_occupations', 'person_skills',
    'person_contacts', 'person_health', 'albums', 'posts', 'post_people', 'photos', 'photo_people',
    'events', 'event_rsvps', 'comments', 'memories', 'stories', 'blood_requests', 'fund_settings',
    'fund_causes', 'fund_contributions', 'fund_payouts', 'mentors', 'mentee_requests', 'opportunities',
    'polls', 'poll_options'
  ];
  users     text[] := (select coalesce(array_agg(id::text), '{}') from auth.users);
  t         text;
  r         jsonb;
  c         text;
  optional  text[];
  required  text[];
  all_cols  text[];
  pk_cols   text[];
  pk        text;
  cols      text;
  ycols     text;
  ucols     text;
  uycols    text;
  n         int;
  added     int;
  updated   int;
  skipped   int;
  missing   boolean;
  result    jsonb := '{}';
begin
  if not public.is_admin() then
    raise exception 'Only admins can restore backups' using errcode = '42501';
  end if;
  if p_data ->> 'format' is distinct from 'bua-family-backup' then
    raise exception 'This is not a Bua Family backup' using errcode = '22023';
  end if;

  perform set_config('bua.restoring', 'on', true);
  if not p_dry_run then
    insert into private.restore_points (id, taken_at, data) values (true, now(), private.backup_data())
    on conflict (id) do update set taken_at = excluded.taken_at, data = excluded.data;
  end if;

  begin
    foreach t in array tables loop
      continue when jsonb_typeof(p_data -> t) is distinct from 'array';

      -- Columns that point at accounts: optional ones are cleared when the
      -- account is gone; rows whose required account is gone are skipped.
      select coalesce(array_agg(a.attname::text) filter (where not a.attnotnull), '{}'),
             coalesce(array_agg(a.attname::text) filter (where a.attnotnull), '{}')
        into optional, required
      from pg_constraint k
      join pg_attribute a on a.attrelid = k.conrelid and a.attnum = any (k.conkey)
      where k.contype = 'f' and k.conrelid = format('public.%I', t)::regclass
        and k.confrelid = 'auth.users'::regclass;

      select coalesce(array_agg(a.attname::text order by a.attnum), '{}')
        into all_cols
      from pg_attribute a
      where a.attrelid = format('public.%I', t)::regclass and a.attnum > 0 and not a.attisdropped;

      select coalesce(array_agg(a.attname::text), '{}')
        into pk_cols
      from pg_index i
      join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any (i.indkey)
      where i.indrelid = format('public.%I', t)::regclass and i.indisprimary;
      pk := (select string_agg(format('x.%1$I = y.%1$I', k), ' and ') from unnest(pk_cols) k);

      added := 0; updated := 0; skipped := 0;
      for r in select * from jsonb_array_elements(p_data -> t) loop
        missing := false;
        foreach c in array required loop
          missing := missing or not (r ->> c = any (users));
        end loop;
        if missing then
          skipped := skipped + 1;
          continue;
        end if;
        foreach c in array optional loop
          if r ->> c is not null and not (r ->> c = any (users)) then
            r := jsonb_set(r, array[c], 'null');
          end if;
        end loop;

        -- Only the columns the backup has, so newer columns keep their defaults.
        select string_agg(format('%I', k), ', ' order by array_position(all_cols, k)),
               string_agg(format('y.%I', k), ', ' order by array_position(all_cols, k)),
               string_agg(format('%I', k), ', ' order by array_position(all_cols, k)) filter (where k <> all (pk_cols)),
               string_agg(format('y.%I', k), ', ' order by array_position(all_cols, k)) filter (where k <> all (pk_cols))
          into cols, ycols, ucols, uycols
        from jsonb_object_keys(r) k
        where k = any (all_cols);
        continue when cols is null;

        begin
          execute format('insert into public.%1$I (%2$s) select %3$s from jsonb_populate_record(null::public.%1$I, $1) y
                          on conflict do nothing', t, cols, ycols)
            using r;
          get diagnostics n = row_count;
          if n > 0 then
            added := added + 1;
          elsif p_overwrite and ucols is not null then
            execute format(
              'update public.%1$I x set (%2$s) = row(%3$s)
               from jsonb_populate_record(null::public.%1$I, $1) y
               where %4$s and not (to_jsonb(x) @> (to_jsonb(y) - $2))',
              t, ucols, uycols, pk)
              using r, array(select k from unnest(all_cols) k where not r ? k) || array['updated_at', 'updated_by'];
            get diagnostics n = row_count;
            updated := updated + n;
          end if;
        exception when others then
          skipped := skipped + 1;
        end;
      end loop;
      result := result || jsonb_build_object(t, jsonb_build_object('added', added, 'updated', updated, 'skipped', skipped));
    end loop;

    if p_dry_run then
      raise exception using errcode = 'BU001', message = 'dry run';
    end if;
  exception when sqlstate 'BU001' then
    null;  -- rolled back; the counts stay
  end;

  perform set_config('bua.restoring', 'off', true);
  return result;
end $$;

-- Restore one of the stored backups (or, with -1, the restore point).
create function public.admin_restore_backup(p_slot smallint, p_overwrite boolean default false, p_dry_run boolean default true)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  d jsonb := public.admin_backup(p_slot);
begin
  if d is null then
    raise exception 'Backup not found' using errcode = 'P0002';
  end if;
  return public.admin_restore(d, p_overwrite, p_dry_run);
end $$;

-- The restore point is listed with the backups as slot -1.
create or replace function public.admin_backups()
returns table (slot smallint, taken_at timestamptz, size_bytes int)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can see backups' using errcode = '42501';
  end if;
  return query
    select x.slot, x.taken_at, x.size_bytes from (
      select b.slot, b.taken_at, octet_length(b.data::text) as size_bytes from private.backups b
      union all
      select (-1)::smallint, p.taken_at, octet_length(p.data::text) from private.restore_points p
    ) x order by x.slot = -1, x.taken_at desc;
end $$;

create or replace function public.admin_backup(p_slot smallint) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can download backups' using errcode = '42501';
  end if;
  if p_slot = -1 then
    return (select data from private.restore_points);
  end if;
  return (select data from private.backups where slot = p_slot);
end $$;

revoke execute on function private.skip_muted_notification() from public, anon, authenticated;
revoke execute on function private.queue_sms(uuid[], text, text, text, text) from public, anon, authenticated;
revoke execute on function public.admin_restore(jsonb, boolean, boolean) from public, anon;
revoke execute on function public.admin_restore_backup(smallint, boolean, boolean) from public, anon;
