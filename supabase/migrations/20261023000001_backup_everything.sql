-- =============================================================================
-- Backups cover everything members create: also poll votes, likes,
-- mentorship conversations and invite links. A restore doesn't fill the
-- activity log with every row it puts back.
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
    'polls', 'poll_options', 'poll_votes', 'likes', 'mentor_asks', 'mentor_messages', 'invites'
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
    'mentee_requests', 'opportunities', 'polls', 'poll_options', 'poll_votes', 'likes', 'mentor_asks',
    'mentor_messages', 'invites'
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

create or replace function private.log_change() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  who uuid := auth.uid();
  r jsonb := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  quiet text[] := array['updated_at', 'updated_by', 'last_message_at', 'last_message', 'last_message_by',
                        'mentor_read_at', 'asker_read_at', 'last_seen_at', 'last_platform', 'app_build'];
  private_ boolean := tg_table_name in ('mentor_asks', 'mentor_messages');
  label text;
begin
  if who is null or current_setting('bua.restoring', true) = 'on' then
    return null;   -- the system (reminders, cron), or a restore putting rows back
  end if;
  if tg_op = 'UPDATE' and (to_jsonb(old) - quiet) = (to_jsonb(new) - quiet) then
    return null;   -- nothing anyone would call a change
  end if;
  label := case
    when private_ then null
    when tg_table_name = 'persons' then nullif(concat_ws(' ', r ->> 'first_name', r ->> 'last_name'), '')
    when tg_table_name = 'profiles' then r ->> 'display_name'
    else coalesce(r ->> 'title', r ->> 'question', r ->> 'patient_name', r ->> 'field', r ->> 'areas',
                  left(coalesce(r ->> 'body', r ->> 'caption', r ->> 'message', r ->> 'note'), 80))
  end;
  insert into public.activity_log (user_id, action, entity, target, detail, platform)
  values (who, lower(tg_op), tg_table_name, coalesce(r ->> 'id', r ->> 'code'),
          case when private_ then '{}'::jsonb else jsonb_strip_nulls(jsonb_build_object(
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
