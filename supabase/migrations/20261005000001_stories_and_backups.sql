-- =============================================================================
-- Elders' stories, import and weekly backups
--
-- Stories: voice recordings of elders (recorded in the app or uploaded from an
-- old cassette transfer), with an optional transcript. Audio lives in a private
-- 'stories' bucket that every active member can listen to.
--
-- Import: admins add a GEDCOM or CSV file in one step. The app matches people
-- already in the tree; admin_import() adds the rest and their relationships in
-- a single transaction, skipping links the tree rules reject.
--
-- Backups: a weekly snapshot of the family's data as JSON, kept in eight
-- rotating slots (about two months) that admins can download.
-- =============================================================================

alter type public.notification_kind add value if not exists 'story';

-- -----------------------------------------------------------------------------
-- Stories
-- -----------------------------------------------------------------------------
create table public.stories (
  id                uuid primary key default gen_random_uuid(),
  title             text not null check (length(btrim(title)) > 0),
  -- Who is speaking: someone in the tree, or just a name.
  speaker_id        uuid references public.persons on delete set null,
  speaker_name      text,
  language          text not null default 'ha' check (language in ('ha', 'en', 'other')),
  audio_path        text not null,
  duration_seconds  int check (duration_seconds >= 0),
  -- "Recorded 1979 on cassette, digitised by Bello"
  source_note       text,
  transcript        text,
  added_by          uuid not null default auth.uid() references auth.users on delete cascade,
  created_at        timestamptz not null default now(),
  constraint stories_speaker check (speaker_id is not null or coalesce(length(btrim(speaker_name)), 0) > 0)
);
create index stories_created_idx on public.stories (created_at desc);
create index stories_speaker_idx on public.stories (speaker_id);
create index stories_added_by_idx on public.stories (added_by);

alter table public.stories enable row level security;

create policy stories_select on public.stories for select to authenticated using (public.is_active_member());
create policy stories_insert on public.stories for insert to authenticated
  with check (public.is_active_member() and added_by = (select auth.uid()));
create policy stories_update on public.stories for update to authenticated
  using (added_by = (select auth.uid()) or public.is_admin())
  with check (public.is_active_member());
create policy stories_delete on public.stories for delete to authenticated
  using (added_by = (select auth.uid()) or public.is_admin());

create function private.notify_story() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  speaker text := coalesce((select private.person_name(p) from public.persons p where p.id = new.speaker_id),
                           new.speaker_name);
begin
  insert into public.notifications (user_id, kind, data, link, actor_id)
  select a.id, 'story', jsonb_build_object('story_id', new.id, 'title', new.title, 'speaker', speaker),
         '/stories', new.added_by
  from public.profiles a
  where a.status = 'active' and a.id <> new.added_by;
  return new;
end $$;
create trigger stories_notify after insert on public.stories
  for each row execute function private.notify_story();

-- Audio: members upload into their own folder; every active member can listen.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('stories', 'stories', false, 52428800,
        array['audio/mp4', 'audio/m4a', 'audio/x-m4a', 'audio/aac', 'audio/mpeg', 'audio/mp3',
              'audio/wav', 'audio/x-wav', 'audio/ogg', 'audio/opus', 'audio/webm', 'audio/3gpp'])
on conflict (id) do nothing;

create policy stories_audio_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'stories' and public.is_active_member()
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy stories_audio_select on storage.objects for select to authenticated
  using (bucket_id = 'stories' and public.is_active_member());
create policy stories_audio_delete on storage.objects for delete to authenticated
  using (bucket_id = 'stories'
         and ((storage.foldername(name))[1] = (select auth.uid())::text or public.is_admin()));

-- -----------------------------------------------------------------------------
-- Import (admins)
--
-- p_data: {
--   "people":  [{"key": "I1", "id": uuid?, ...person columns}],  -- id = already in the tree
--   "parents": [{"parent": "I1", "child": "I2", "kind": "biological"?}],
--   "unions":  [{"a": "I1", "b": "I3", "status": "married"?}]
-- }
-- Returns {"people": n, "parents": n, "unions": n, "skipped": n}.
-- -----------------------------------------------------------------------------
create function public.admin_import(p_data jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  ids      jsonb := '{}';
  person   jsonb;
  link     jsonb;
  a        uuid;
  b        uuid;
  new_id   uuid;
  added    int := 0;
  parents  int := 0;
  unions   int := 0;
  skipped  int := 0;
begin
  if not public.is_admin() then
    raise exception 'Only admins can import' using errcode = '42501';
  end if;

  for person in select * from jsonb_array_elements(coalesce(p_data -> 'people', '[]')) loop
    if person ->> 'id' is not null then
      if not exists (select 1 from public.persons where id = (person ->> 'id')::uuid) then
        raise exception 'Person % is no longer in the tree', person ->> 'id' using errcode = 'P0002';
      end if;
      ids := ids || jsonb_build_object(person ->> 'key', person ->> 'id');
    else
      new_id := public._insert_person(person - 'key' - 'id', auth.uid());
      ids := ids || jsonb_build_object(person ->> 'key', new_id);
      added := added + 1;
    end if;
  end loop;

  for link in select * from jsonb_array_elements(coalesce(p_data -> 'parents', '[]')) loop
    a := (ids ->> (link ->> 'parent'))::uuid;
    b := (ids ->> (link ->> 'child'))::uuid;
    continue when a is null or b is null
      or exists (select 1 from public.parent_child where parent_id = a and child_id = b);
    begin
      insert into public.parent_child (parent_id, child_id, kind)
      values (a, b, coalesce((link ->> 'kind')::public.parent_kind, 'biological'));
      parents := parents + 1;
    exception when others then
      skipped := skipped + 1;
    end;
  end loop;

  for link in select * from jsonb_array_elements(coalesce(p_data -> 'unions', '[]')) loop
    a := (ids ->> (link ->> 'a'))::uuid;
    b := (ids ->> (link ->> 'b'))::uuid;
    continue when a is null or b is null
      or exists (select 1 from public.unions
                 where least(partner1_id, partner2_id) = least(a, b)
                   and greatest(partner1_id, partner2_id) = greatest(a, b));
    begin
      insert into public.unions (partner1_id, partner2_id, status)
      values (a, b, coalesce((link ->> 'status')::public.union_status, 'married'));
      unions := unions + 1;
    exception when others then
      skipped := skipped + 1;
    end;
  end loop;

  return jsonb_build_object('people', added, 'parents', parents, 'unions', unions, 'skipped', skipped);
end $$;

-- -----------------------------------------------------------------------------
-- Weekly backups
-- -----------------------------------------------------------------------------
alter table public.app_settings add column weekly_backup boolean not null default true;

create table private.backups (
  slot      smallint primary key check (slot between 0 and 7),
  taken_at  timestamptz not null,
  data      jsonb not null
);

-- Everything the family has entered, as one JSON document.
create function private.backup_data() returns jsonb
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
    'memories', 'stories', 'blood_requests', 'fund_settings', 'fund_causes', 'fund_contributions',
    'fund_payouts', 'mentors', 'mentee_requests', 'opportunities', 'polls', 'poll_options'
  ] loop
    execute format('select coalesce(jsonb_agg(to_jsonb(x)), ''[]'') from public.%I x', t) into chunk;
    result := result || jsonb_build_object(t, chunk);
  end loop;
  return result;
end $$;

-- Takes a snapshot into this week's slot (the slot from eight weeks ago).
create function private.take_backup(p_force boolean default false) returns timestamptz
language plpgsql security definer set search_path = '' as $$
begin
  if not p_force and not coalesce((select weekly_backup from public.app_settings), true) then
    return null;
  end if;
  insert into private.backups (slot, taken_at, data)
  values ((extract(week from now())::int % 8), now(), private.backup_data())
  on conflict (slot) do update set taken_at = excluded.taken_at, data = excluded.data;
  return now();
end $$;

create function public.admin_backups()
returns table (slot smallint, taken_at timestamptz, size_bytes int)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can see backups' using errcode = '42501';
  end if;
  return query
    select b.slot, b.taken_at, octet_length(b.data::text) from private.backups b order by b.taken_at desc;
end $$;

create function public.admin_backup(p_slot smallint) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can download backups' using errcode = '42501';
  end if;
  return (select data from private.backups where slot = p_slot);
end $$;

create function public.admin_backup_now() returns timestamptz
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can take backups' using errcode = '42501';
  end if;
  return private.take_backup(true);
end $$;

revoke execute on function private.notify_story() from public, anon, authenticated;
revoke execute on function private.backup_data() from public, anon, authenticated;
revoke execute on function private.take_backup(boolean) from public, anon, authenticated;
revoke execute on function public.admin_import(jsonb) from public, anon;
revoke execute on function public.admin_backups() from public, anon;
revoke execute on function public.admin_backup(smallint) from public, anon;
revoke execute on function public.admin_backup_now() from public, anon;

-- Sunday 02:00 UTC (03:00 in Nigeria).
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('bua-backup', '0 2 * * 0', 'select private.take_backup()');
  end if;
end $$;
