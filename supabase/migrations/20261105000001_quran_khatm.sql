-- =============================================================================
-- Family Quran khatm: the 30 juz shared out among volunteers, for a relative
-- who has passed or for an occasion.
--
-- Any member starts one (everyone is told). Members take a juz, or several,
-- and mark it read; they can give back one they can't finish. Whoever started
-- it, or an admin, can free a juz someone is holding. When all 30 are read the
-- khatm is complete and everyone who took part is told. The day before the
-- date it should be finished by, those still holding an unread juz get a
-- reminder.
--
-- Giving a juz back clears who holds it (the row stays), so nothing here
-- deletes rows.
-- =============================================================================

alter type public.notification_kind add value if not exists 'khatm';
alter type public.notification_kind add value if not exists 'khatm_completed';
alter type public.notification_kind add value if not exists 'khatm_reminder';

create table public.khatms (
  id            uuid primary key default gen_random_uuid(),
  title         text not null check (length(btrim(title)) between 1 and 200),
  purpose       text not null default 'memorial' check (purpose in ('memorial', 'occasion', 'other')),
  -- The relative it is for (usually one who has passed).
  person_id     uuid references public.persons on delete set null,
  note          text check (length(note) <= 2000),
  due_on        date,
  cancelled     boolean not null default false,
  completed_at  timestamptz,
  created_by    uuid default auth.uid() references auth.users on delete set null,
  created_at    timestamptz not null default now()
);
create index khatms_created_idx on public.khatms (created_at desc);
create index khatms_person_idx on public.khatms (person_id);
create index khatms_created_by_idx on public.khatms (created_by);

create table public.khatm_parts (
  khatm_id    uuid not null references public.khatms on delete cascade,
  juz         smallint not null check (juz between 1 and 30),
  -- Null: free to take (given back, or the account was deleted before reading it).
  user_id     uuid references auth.users on delete set null,
  claimed_at  timestamptz,
  done_at     timestamptz,
  primary key (khatm_id, juz),
  constraint khatm_parts_done_has_reader check (done_at is null or claimed_at is not null)
);
create index khatm_parts_user_idx on public.khatm_parts (user_id);

alter table public.khatms enable row level security;
alter table public.khatm_parts enable row level security;

create policy khatms_select on public.khatms for select to authenticated
  using (public.is_active_member());
create policy khatms_insert on public.khatms for insert to authenticated
  with check (public.is_active_member() and created_by = (select auth.uid())
              and completed_at is null and not cancelled);
create policy khatms_update on public.khatms for update to authenticated
  using (created_by = (select auth.uid()) or public.is_admin())
  with check (created_by = (select auth.uid()) or public.is_admin());
create policy khatms_delete on public.khatms for delete to authenticated
  using (created_by = (select auth.uid()) or public.is_admin());
-- Who started it and when stay as they were; only khatm_done (or a restore)
-- decides when it is complete.
create function private.khatm_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  new.created_by := old.created_by;
  new.created_at := old.created_at;
  if new.completed_at is distinct from old.completed_at
     and coalesce(current_setting('bua.khatm', true), '') <> 'on'
     and coalesce(current_setting('bua.restoring', true), '') <> 'on' then
    new.completed_at := old.completed_at;
  end if;
  return new;
end $$;
create trigger khatms_guard before update on public.khatms
  for each row execute function private.khatm_guard();

create policy khatm_parts_select on public.khatm_parts for select to authenticated
  using (public.is_active_member());
revoke insert, update, delete on public.khatm_parts from authenticated, anon;

create trigger zz_log_change after insert or update or delete on public.khatms
  for each row execute function private.log_change();

-- -----------------------------------------------------------------------------
-- Taking, reading and giving back a juz
-- -----------------------------------------------------------------------------
create function private.khatm_open(p_khatm uuid) returns public.khatms
language plpgsql security definer set search_path = '' as $$
declare
  k public.khatms;
begin
  if not public.is_active_member() then
    raise exception 'Only family members can take part' using errcode = '42501';
  end if;
  select * into k from public.khatms where id = p_khatm for update;
  if not found then
    raise exception 'Khatm not found' using errcode = 'P0002';
  end if;
  if k.cancelled or k.completed_at is not null then
    raise exception 'This khatm is closed' using errcode = '55000';
  end if;
  return k;
end $$;

-- Take a juz (p_juz), or the first free one (p_juz null). Returns its number.
create function public.khatm_take(p_khatm uuid, p_juz int default null) returns int
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  j int := p_juz;
  n int;
begin
  perform private.khatm_open(p_khatm);
  if j is null then
    select g into j from generate_series(1, 30) g
    where not exists (select 1 from public.khatm_parts p
                      where p.khatm_id = p_khatm and p.juz = g and p.user_id is not null)
    order by g limit 1;
    if j is null then
      raise exception 'Every juz has been taken' using errcode = '55000';
    end if;
  elsif j not between 1 and 30 then
    raise exception 'A juz is 1 to 30' using errcode = '22023';
  end if;
  insert into public.khatm_parts as p (khatm_id, juz, user_id, claimed_at)
  values (p_khatm, j, me, now())
  on conflict (khatm_id, juz) do update set user_id = me, claimed_at = now(), done_at = null
    where p.user_id is null;
  get diagnostics n = row_count;
  if n = 0 then
    raise exception 'Juz % is already taken', j using errcode = '55000';
  end if;
  return j;
end $$;

-- Mark a juz read (or not read). Your own, or any if you started it or are an admin.
create function public.khatm_done(p_khatm uuid, p_juz int, p_done boolean default true) returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  k public.khatms := private.khatm_open(p_khatm);
  part public.khatm_parts;
  readers uuid[];
begin
  select * into part from public.khatm_parts where khatm_id = p_khatm and juz = p_juz for update;
  if not found or part.user_id is null then
    raise exception 'Take this juz first' using errcode = '55000';
  end if;
  if part.user_id <> me and k.created_by is distinct from me and not public.is_admin() then
    raise exception 'This juz is someone else''s' using errcode = '42501';
  end if;
  update public.khatm_parts set done_at = case when p_done then now() end
   where khatm_id = p_khatm and juz = p_juz;

  -- All 30 read: complete, and tell everyone who took part and whoever started it.
  if p_done and (select count(*) from public.khatm_parts
                 where khatm_id = p_khatm and done_at is not null) = 30 then
    perform set_config('bua.khatm', 'on', true);
    update public.khatms set completed_at = now() where id = p_khatm;
    perform set_config('bua.khatm', 'off', true);
    readers := array(select distinct user_id from public.khatm_parts where khatm_id = p_khatm and user_id is not null);
    insert into public.notifications (user_id, kind, data, link, dedupe_key)
    select u, 'khatm_completed',
           jsonb_build_object('khatm_id', k.id, 'title', k.title, 'readers', cardinality(readers)),
           '/khatm/' || k.id, 'khatm_done:' || k.id || ':' || u
    from unnest(readers || k.created_by) u
    where u is not null and exists (select 1 from public.profiles where id = u and status = 'active')
    on conflict (dedupe_key) do nothing;
  end if;
end $$;

-- Give a juz back (not once read). Your own, or any if you started it or are an admin.
create function public.khatm_release(p_khatm uuid, p_juz int) returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  k public.khatms := private.khatm_open(p_khatm);
  part public.khatm_parts;
begin
  select * into part from public.khatm_parts where khatm_id = p_khatm and juz = p_juz for update;
  if not found or part.user_id is null then
    return;
  end if;
  if part.done_at is not null then
    raise exception 'This juz has been read' using errcode = '55000';
  end if;
  if part.user_id <> me and k.created_by is distinct from me and not public.is_admin() then
    raise exception 'This juz is someone else''s' using errcode = '42501';
  end if;
  update public.khatm_parts set user_id = null, claimed_at = null where khatm_id = p_khatm and juz = p_juz;
end $$;

-- -----------------------------------------------------------------------------
-- Notices: a new khatm to everyone; a reminder the day before it's due.
-- -----------------------------------------------------------------------------
create function private.on_khatm_insert() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, data, link, actor_id)
  select p.id, 'khatm',
         jsonb_build_object('khatm_id', new.id, 'title', new.title,
                            'person', (select private.person_name(pe) from public.persons pe where pe.id = new.person_id),
                            'due_on', new.due_on),
         '/khatm/' || new.id, new.created_by
  from public.profiles p
  where p.status = 'active' and p.id is distinct from new.created_by;
  return new;
end $$;
create trigger khatms_notify after insert on public.khatms
  for each row execute function private.on_khatm_insert();

create function private.khatm_reminders(p_day date default null) returns int
language plpgsql security definer set search_path = '' as $$
declare
  today date := coalesce(p_day, (now() at time zone 'Africa/Lagos')::date);
  n int;
begin
  insert into public.notifications (user_id, kind, data, link, dedupe_key)
  select p.user_id, 'khatm_reminder',
         jsonb_build_object('khatm_id', k.id, 'title', k.title, 'juz', array_agg(p.juz order by p.juz)),
         '/khatm/' || k.id, 'khatm_rem:' || k.id || ':' || p.user_id
  from public.khatms k
  join public.khatm_parts p on p.khatm_id = k.id and p.user_id is not null and p.done_at is null
  where not k.cancelled and k.completed_at is null and k.due_on = today + 1
  group by k.id, k.title, p.user_id
  on conflict (dedupe_key) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;

revoke execute on function private.khatm_open(uuid) from public, anon, authenticated;
revoke execute on function private.khatm_guard() from public, anon, authenticated;
revoke execute on function private.on_khatm_insert() from public, anon, authenticated;
revoke execute on function private.khatm_reminders(date) from public, anon, authenticated;
revoke execute on function public.khatm_take(uuid, int) from public, anon;
revoke execute on function public.khatm_done(uuid, int, boolean) from public, anon;
revoke execute on function public.khatm_release(uuid, int) from public, anon;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    -- 08:00 in Nigeria.
    perform cron.schedule('bua-khatm-reminders', '0 7 * * *', 'select private.khatm_reminders()');
  end if;
end $$;
