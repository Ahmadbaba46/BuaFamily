-- =============================================================================
-- Blood donors
--
--   * A person can opt in as a blood donor (from their health details). Other
--     members then see only their blood group and town, never their genotype
--     or other health details, through public.blood_donors().
--   * Any member can post a blood request. Compatible donors who have an
--     account are notified in the app, and by SMS if they opted in to SMS.
--   * Relatives answer "I can donate"; the person who asked is notified.
-- =============================================================================

alter table public.person_health add column blood_donor boolean not null default false;

alter type public.notification_kind add value if not exists 'blood_request';
alter type public.notification_kind add value if not exists 'blood_offer';

-- Red-cell compatibility: can someone with p_donor give to p_recipient?
create function private.can_donate(p_donor text, p_recipient text) returns boolean
language sql immutable set search_path = '' as $$
  select case p_recipient
    when 'AB+' then p_donor in ('AB+', 'AB-', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-')
    when 'AB-' then p_donor in ('AB-', 'A-', 'B-', 'O-')
    when 'A+'  then p_donor in ('A+', 'A-', 'O+', 'O-')
    when 'A-'  then p_donor in ('A-', 'O-')
    when 'B+'  then p_donor in ('B+', 'B-', 'O+', 'O-')
    when 'B-'  then p_donor in ('B-', 'O-')
    when 'O+'  then p_donor in ('O+', 'O-')
    when 'O-'  then p_donor = 'O-'
    else false
  end;
$$;

-- Living donors who opted in: blood group and town only.
create function public.blood_donors()
returns table (person_id uuid, blood_group text, town text)
language sql stable security definer set search_path = '' as $$
  select h.person_id, h.blood_group, nullif(btrim(c.city), '')
  from public.person_health h
  join public.persons p on p.id = h.person_id and p.is_living
  left join public.person_contacts c on c.person_id = h.person_id
  where h.blood_donor and h.blood_group is not null and public.is_active_member();
$$;

-- -----------------------------------------------------------------------------
-- Requests and offers
-- -----------------------------------------------------------------------------
create table public.blood_requests (
  id                 uuid primary key default gen_random_uuid(),
  blood_group        text not null check (blood_group in ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
  units              smallint not null default 1 check (units between 1 and 20),
  -- Someone in the tree, or a name typed in (e.g. a friend of the family).
  patient_person_id  uuid references public.persons on delete set null,
  patient_name       text,
  hospital           text not null check (length(btrim(hospital)) > 0),
  contact_phone      text check (contact_phone ~ '^[0-9]{10,15}$'),
  note               text,
  urgent             boolean not null default true,
  status             text not null default 'open' check (status in ('open', 'closed')),
  requested_by       uuid not null default auth.uid() references auth.users on delete cascade,
  created_at         timestamptz not null default now(),
  closed_at          timestamptz,
  constraint blood_requests_has_patient
    check (patient_person_id is not null or length(btrim(coalesce(patient_name, ''))) > 0)
);
create index blood_requests_open_idx on public.blood_requests (status, created_at desc);
create index blood_requests_requested_by_idx on public.blood_requests (requested_by);
create index blood_requests_patient_idx on public.blood_requests (patient_person_id);

create table public.blood_offers (
  request_id  uuid not null references public.blood_requests on delete cascade,
  user_id     uuid not null default auth.uid() references auth.users on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (request_id, user_id)
);
create index blood_offers_user_idx on public.blood_offers (user_id);

alter table public.blood_requests enable row level security;
alter table public.blood_offers   enable row level security;

create policy blood_requests_select on public.blood_requests for select to authenticated
  using (public.is_active_member());
create policy blood_requests_insert on public.blood_requests for insert to authenticated
  with check (public.is_active_member() and requested_by = (select auth.uid()) and status = 'open');
create policy blood_requests_update on public.blood_requests for update to authenticated
  using (requested_by = (select auth.uid()) or public.is_admin())
  with check (public.is_active_member());
create policy blood_requests_delete on public.blood_requests for delete to authenticated
  using (requested_by = (select auth.uid()) or public.is_admin());

create policy blood_offers_select on public.blood_offers for select to authenticated
  using (public.is_active_member());
create policy blood_offers_insert on public.blood_offers for insert to authenticated
  with check (
    public.is_active_member()
    and user_id = (select auth.uid())
    and exists (select 1 from public.blood_requests r where r.id = request_id and r.status = 'open')
  );
create policy blood_offers_delete on public.blood_offers for delete to authenticated
  using (user_id = (select auth.uid()));

-- Phone format, closing time, and a limit of 3 requests a day per member
-- (each one can text many people).
create function private.blood_request_before() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  new.contact_phone := private.normalize_phone(new.contact_phone);
  if tg_op = 'INSERT' then
    if not public.is_admin() and (
      select count(*) from public.blood_requests
      where requested_by = new.requested_by and created_at > now() - interval '1 day') >= 3 then
      raise exception 'You can post up to 3 blood requests a day' using errcode = '54000';
    end if;
  elsif new.status = 'closed' and old.status = 'open' then
    new.closed_at := now();
  end if;
  return new;
end $$;
create trigger blood_requests_before before insert or update on public.blood_requests
  for each row execute function private.blood_request_before();

-- Tell compatible donors.
create function private.notify_blood_request() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  donors uuid[];
  patient text;
begin
  select case when p.id is null then btrim(new.patient_name) else private.person_name(p) end into patient
  from (select 1) x left join public.persons p on p.id = new.patient_person_id;

  select array_agg(distinct a.id) into donors
  from public.profiles a
  join public.person_health h on h.person_id = a.person_id
  join public.persons p on p.id = a.person_id and p.is_living
  where a.status = 'active' and a.id <> new.requested_by
    and h.blood_donor and private.can_donate(h.blood_group, new.blood_group);

  insert into public.notifications (user_id, kind, data, link, actor_id)
  select u, 'blood_request',
         jsonb_build_object('request_id', new.id, 'blood_group', new.blood_group, 'units', new.units,
                            'hospital', new.hospital, 'patient', patient),
         '/blood', new.requested_by
  from unnest(donors) u;

  perform private.queue_sms(
    donors, 'donor',
    case when new.urgent then 'Urgent: ' else '' end || new.units || ' pint(s) of ' || new.blood_group
      || ' blood needed for ' || patient || ' at ' || new.hospital || '. Open the app if you can donate.',
    'Ana bukatar jini ' || new.blood_group || ' (pint ' || new.units || ') don ' || patient || ' a '
      || new.hospital || '. Bude manhaja idan za ka iya bayarwa.',
    'blood:' || new.id);
  return new;
end $$;
create trigger blood_requests_notify after insert on public.blood_requests
  for each row execute function private.notify_blood_request();

-- Tell the person who asked when someone offers.
create function private.notify_blood_offer() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, data, link, actor_id, dedupe_key)
  select r.requested_by, 'blood_offer',
         jsonb_build_object('request_id', r.id, 'blood_group', r.blood_group),
         '/blood', new.user_id, 'blood_offer:' || r.id || ':' || new.user_id
  from public.blood_requests r
  where r.id = new.request_id and r.requested_by <> new.user_id
  on conflict (dedupe_key) do nothing;
  return new;
end $$;
create trigger blood_offers_notify after insert on public.blood_offers
  for each row execute function private.notify_blood_offer();

revoke execute on function private.can_donate(text, text) from public, anon, authenticated;
revoke execute on function private.blood_request_before() from public, anon, authenticated;
revoke execute on function private.notify_blood_request() from public, anon, authenticated;
revoke execute on function private.notify_blood_offer() from public, anon, authenticated;
revoke execute on function public.blood_donors() from public, anon;
