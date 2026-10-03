-- =============================================================================
-- Memorial pages
--
--   * Prayers and memories written on the memorial page of someone who has died.
--   * "Remind me every <date>": members choose whose death anniversary they want
--     a gentle in-app reminder for. People who asked are also told when a new
--     memory is added.
-- =============================================================================

alter type public.notification_kind add value if not exists 'remembrance';
alter type public.notification_kind add value if not exists 'memory';

create table public.memories (
  id          uuid primary key default gen_random_uuid(),
  person_id   uuid not null references public.persons on delete cascade,
  author_id   uuid not null default auth.uid() references auth.users on delete cascade,
  body        text not null check (length(btrim(body)) > 0),
  created_at  timestamptz not null default now()
);
create index memories_person_idx on public.memories (person_id, created_at);
create index memories_author_idx on public.memories (author_id);

create table public.remembrance_reminders (
  user_id     uuid not null default auth.uid() references auth.users on delete cascade,
  person_id   uuid not null references public.persons on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, person_id)
);
create index remembrance_reminders_person_idx on public.remembrance_reminders (person_id);

alter table public.memories              enable row level security;
alter table public.remembrance_reminders enable row level security;

create policy memories_select on public.memories for select to authenticated
  using (public.is_active_member());
create policy memories_insert on public.memories for insert to authenticated
  with check (
    public.is_active_member()
    and author_id = (select auth.uid())
    and exists (select 1 from public.persons p where p.id = person_id and not p.is_living)
  );
create policy memories_delete on public.memories for delete to authenticated
  using (author_id = (select auth.uid()) or public.is_admin());

create policy remembrance_reminders_select on public.remembrance_reminders for select to authenticated
  using (user_id = (select auth.uid()));
create policy remembrance_reminders_insert on public.remembrance_reminders for insert to authenticated
  with check (public.is_active_member() and user_id = (select auth.uid()));
create policy remembrance_reminders_delete on public.remembrance_reminders for delete to authenticated
  using (user_id = (select auth.uid()));

-- A new memory: tell everyone who keeps this person's anniversary.
create function private.notify_memory() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, data, link, actor_id)
  select s.user_id, 'memory',
         jsonb_build_object('person_id', p.id, 'name', private.person_name(p), 'body', left(new.body, 140)),
         '/person/' || p.id || '/memorial', new.author_id
  from public.remembrance_reminders s
  join public.persons p on p.id = s.person_id
  join public.profiles m on m.id = s.user_id and m.status = 'active'
  where s.person_id = new.person_id and s.user_id <> new.author_id;
  return new;
end $$;
create trigger memories_notify after insert on public.memories
  for each row execute function private.notify_memory();

-- Death anniversaries today, for those who asked to be reminded.
create function private.remembrance_reminders(p_day date default null) returns void
language plpgsql security definer set search_path = '' as $$
declare
  today date := coalesce(p_day, (now() at time zone (select timezone from public.app_settings))::date);
begin
  insert into public.notifications (user_id, kind, data, link, dedupe_key)
  select s.user_id, 'remembrance',
         jsonb_build_object('person_id', p.id, 'name', private.person_name(p),
                            'years', extract(year from today)::int - extract(year from p.death_date)::int),
         '/person/' || p.id || '/memorial', 'remembrance:' || today || ':' || p.id || ':' || s.user_id
  from public.remembrance_reminders s
  join public.persons p on p.id = s.person_id
  join public.profiles m on m.id = s.user_id and m.status = 'active'
  where not p.is_living and p.death_date is not null and not p.death_date_approx
    and p.death_date < today
    and extract(month from p.death_date) = extract(month from today)
    and extract(day from p.death_date) = extract(day from today)
  on conflict (dedupe_key) do nothing;
end $$;

revoke execute on function private.notify_memory() from public, anon, authenticated;
revoke execute on function private.remembrance_reminders(date) from public, anon, authenticated;

-- Runs just after the morning birthday reminders (07:31 Nigeria time).
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('bua-remembrance', '31 6 * * *', 'select private.remembrance_reminders()');
  end if;
end $$;
