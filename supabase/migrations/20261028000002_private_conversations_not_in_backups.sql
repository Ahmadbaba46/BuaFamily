-- =============================================================================
-- Private conversations stay private: mentorship conversations come out of
-- backups again (admins can download backups), like direct messages, which
-- were never in them. Only the two people in a conversation can read it.
-- =============================================================================

create or replace function private.backup_data() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  t       text;
  chunk   jsonb;
  result  jsonb := jsonb_build_object('format', 'bua-family-backup', 'version', 1, 'taken_at', now());
begin
  foreach t in array array[
    'persons', 'unions', 'parent_child', 'person_education', 'person_occupations', 'person_skills',
    'person_contacts', 'person_health', 'profiles', 'app_settings',
    'posts', 'post_people', 'albums', 'photos', 'photo_people', 'events', 'event_rsvps', 'comments',
    'memories', 'stories', 'blood_requests', 'fund_settings', 'fund_causes', 'fund_dues_plans',
    'fund_dues_members', 'fund_contributions', 'fund_payouts', 'mentors', 'mentee_requests', 'opportunities',
    'polls', 'poll_options', 'poll_votes', 'likes', 'invites'
  ] loop
    execute format('select coalesce(jsonb_agg(to_jsonb(x)), ''[]'') from public.%I x', t) into chunk;
    result := result || jsonb_build_object(t, chunk);
  end loop;
  return result;
end $$;

create or replace function public.admin_restore(p_data jsonb, p_overwrite boolean default false, p_dry_run boolean default true)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  -- Parents before children, so references resolve.
  tables text[] := array[
    'persons', 'unions', 'parent_child', 'person_education', 'person_occupations', 'person_skills',
    'person_contacts', 'person_health', 'albums', 'posts', 'post_people', 'photos', 'photo_people',
    'events', 'event_rsvps', 'comments', 'memories', 'stories', 'blood_requests', 'fund_settings',
    'fund_causes', 'fund_dues_plans', 'fund_dues_members', 'fund_contributions', 'fund_payouts', 'mentors',
    'mentee_requests', 'opportunities', 'polls', 'poll_options', 'poll_votes', 'likes', 'invites'
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
