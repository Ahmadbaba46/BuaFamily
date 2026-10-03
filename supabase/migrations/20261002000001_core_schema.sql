-- =============================================================================
-- BuaFamily core schema
--
-- Key idea: a *person* (anyone in the family tree, living or deceased) is
-- separate from an *account* (someone who signs in). An account can be linked
-- to exactly one person ("this is me").
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Types
-- -----------------------------------------------------------------------------
create type public.app_role       as enum ('admin', 'member');
create type public.account_status as enum ('pending', 'active', 'suspended');
create type public.sex            as enum ('male', 'female', 'unknown');
-- 'family'  = every active member can see it
-- 'private' = only the person themselves (their linked account) and admins
create type public.visibility     as enum ('family', 'private');
create type public.union_status   as enum ('married', 'divorced', 'widowed', 'separated');
create type public.parent_kind    as enum ('biological', 'adopted', 'foster', 'step');
create type public.request_kind   as enum ('create_person', 'update_person', 'add_parent_child', 'add_union');
create type public.request_status as enum ('pending', 'approved', 'rejected');

-- -----------------------------------------------------------------------------
-- Persons: everyone in the tree
-- -----------------------------------------------------------------------------
create table public.persons (
  id                 uuid primary key default gen_random_uuid(),
  title              text,                      -- e.g. Alhaji, Hajiya, Malam, Dr
  first_name         text not null check (length(btrim(first_name)) > 0),
  middle_name        text,
  last_name          text,
  nickname           text,                      -- lakabi / alkunya
  sex                public.sex not null default 'unknown',
  birth_date         date,
  birth_date_approx  boolean not null default false, -- true when only the year is known
  birth_place        text,
  is_living          boolean not null default true,
  death_date         date,
  death_date_approx  boolean not null default false,
  death_place        text,
  burial_place       text,
  biography          text,
  photo_path         text,                      -- path inside the 'photos' storage bucket
  branch             text,                      -- family branch / house name
  created_at         timestamptz not null default now(),
  created_by         uuid default auth.uid() references auth.users on delete set null,
  updated_at         timestamptz not null default now(),
  updated_by         uuid references auth.users on delete set null,
  constraint persons_death_only_if_deceased check (death_date is null or not is_living),
  constraint persons_death_after_birth check (death_date is null or birth_date is null or death_date >= birth_date)
);
create index persons_name_idx on public.persons (lower(first_name), lower(last_name));

-- -----------------------------------------------------------------------------
-- Relationships
-- -----------------------------------------------------------------------------
create table public.unions (
  id           uuid primary key default gen_random_uuid(),
  partner1_id  uuid not null references public.persons on delete cascade,
  partner2_id  uuid not null references public.persons on delete cascade,
  status       public.union_status not null default 'married',
  start_date   date,
  end_date     date,
  sort_order   smallint,        -- e.g. order of wives (1st, 2nd, ...)
  notes        text,
  created_at   timestamptz not null default now(),
  created_by   uuid default auth.uid() references auth.users on delete set null,
  constraint unions_distinct_partners check (partner1_id <> partner2_id)
);
create unique index unions_pair_uniq on public.unions (least(partner1_id, partner2_id), greatest(partner1_id, partner2_id));
create index unions_partner2_idx on public.unions (partner2_id);

create table public.parent_child (
  id          uuid primary key default gen_random_uuid(),
  parent_id   uuid not null references public.persons on delete cascade,
  child_id    uuid not null references public.persons on delete cascade,
  kind        public.parent_kind not null default 'biological',
  created_at  timestamptz not null default now(),
  created_by  uuid default auth.uid() references auth.users on delete set null,
  constraint parent_child_uniq unique (parent_id, child_id),
  constraint parent_child_distinct check (parent_id <> child_id)
);
create index parent_child_child_idx on public.parent_child (child_id);

-- -----------------------------------------------------------------------------
-- Person details
-- -----------------------------------------------------------------------------
create table public.person_education (
  id             uuid primary key default gen_random_uuid(),
  person_id      uuid not null references public.persons on delete cascade,
  institution    text not null,
  qualification  text,          -- e.g. BSc, SSCE, Diploma, Islamiyya
  field          text,          -- e.g. Medicine, Accounting
  start_year     smallint,
  end_year       smallint,
  notes          text,
  created_at     timestamptz not null default now()
);
create index person_education_person_idx on public.person_education (person_id);

create table public.person_occupations (
  id            uuid primary key default gen_random_uuid(),
  person_id     uuid not null references public.persons on delete cascade,
  title         text not null,  -- e.g. Doctor, Farmer, Trader
  organization  text,
  industry      text,
  location      text,
  start_year    smallint,
  end_year      smallint,
  is_current    boolean not null default false,
  created_at    timestamptz not null default now()
);
create index person_occupations_person_idx on public.person_occupations (person_id);

create table public.person_skills (
  id          uuid primary key default gen_random_uuid(),
  person_id   uuid not null references public.persons on delete cascade,
  skill       text not null check (length(btrim(skill)) > 0),
  notes       text,
  created_at  timestamptz not null default now(),
  constraint person_skills_uniq unique (person_id, skill)
);
create index person_skills_skill_idx on public.person_skills (lower(skill));

create table public.person_contacts (
  person_id   uuid primary key references public.persons on delete cascade,
  phone       text,
  email       text,
  address     text,
  city        text,
  country     text,
  visibility  public.visibility not null default 'family',
  updated_at  timestamptz not null default now()
);

create table public.person_health (
  person_id    uuid primary key references public.persons on delete cascade,
  blood_group  text check (blood_group in ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
  genotype     text check (genotype in ('AA','AS','AC','SS','SC','CC')),
  conditions   text,            -- known hereditary / chronic conditions
  notes        text,
  visibility   public.visibility not null default 'private',
  updated_at   timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- Accounts
-- -----------------------------------------------------------------------------
create table public.profiles (
  id                   uuid primary key references auth.users on delete cascade,
  display_name         text not null default '',
  email                text,
  role                 public.app_role not null default 'member',
  status               public.account_status not null default 'pending',
  person_id            uuid unique references public.persons on delete set null,
  requested_person_id  uuid references public.persons on delete set null,
  -- Free text from a new user, e.g. "Aisha, daughter of Musa Bua of Kano".
  -- Pending users cannot browse the tree, so this helps admins link them.
  claim_note           text,
  locale               text not null default 'en' check (locale in ('en', 'ha')),
  created_at           timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- App settings (single row)
-- -----------------------------------------------------------------------------
create table public.app_settings (
  id                            boolean primary key default true check (id),
  family_name                   text not null default 'Bua',
  -- When true, members may propose new relatives / relationships for admin approval.
  member_contributions_enabled  boolean not null default false,
  -- Person shown at the top of the tree by default.
  root_person_id                uuid references public.persons on delete set null,
  updated_at                    timestamptz not null default now(),
  updated_by                    uuid references auth.users on delete set null
);
insert into public.app_settings default values;

-- -----------------------------------------------------------------------------
-- Change requests (member proposals awaiting admin approval)
--
-- payload formats:
--   create_person    {"person": {...person fields}, "relation": {"type": "parent"|"child"|"spouse",
--                     "person_id": uuid, "kind": parent_kind?, "other_parent_id": uuid?, "status": union_status?}}
--                    relation says: the NEW person is the <type> of person_id.
--                    other_parent_id (type=child only): the other parent of the new child.
--   update_person    {"person": {...changed person fields}}   (target_person_id required)
--   add_parent_child {"parent_id": uuid, "child_id": uuid, "kind": parent_kind?}
--   add_union        {"partner1_id": uuid, "partner2_id": uuid, "status": union_status?, "start_date": date?}
-- -----------------------------------------------------------------------------
create table public.change_requests (
  id                uuid primary key default gen_random_uuid(),
  kind              public.request_kind not null,
  target_person_id  uuid references public.persons on delete cascade,
  payload           jsonb not null default '{}'::jsonb,
  status            public.request_status not null default 'pending',
  requested_by      uuid not null default auth.uid() references auth.users on delete cascade,
  reviewed_by       uuid references auth.users on delete set null,
  reviewed_at       timestamptz,
  review_note       text,
  result_person_id  uuid references public.persons on delete set null,
  created_at        timestamptz not null default now(),
  constraint change_requests_update_has_target check (kind <> 'update_person' or target_person_id is not null)
);
create index change_requests_status_idx on public.change_requests (status, created_at);
create index change_requests_requested_by_idx on public.change_requests (requested_by);

-- =============================================================================
-- Helper functions (used by RLS policies)
-- =============================================================================
create function public.is_active_member() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles where id = auth.uid() and status = 'active');
$$;

create function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles where id = auth.uid() and status = 'active' and role = 'admin');
$$;

create function public.my_person_id() returns uuid
language sql stable security definer set search_path = '' as $$
  select person_id from public.profiles where id = auth.uid() and status = 'active';
$$;

create function public.contributions_enabled() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select member_contributions_enabled from public.app_settings), false);
$$;

create function public.can_view(p_visibility public.visibility, p_person_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select public.is_admin()
      or (p_person_id is not null and p_person_id = public.my_person_id())
      or (p_visibility = 'family' and public.is_active_member());
$$;

create function public.can_edit_person(p_person_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select public.is_admin() or (p_person_id is not null and p_person_id = public.my_person_id());
$$;

-- =============================================================================
-- Triggers
-- =============================================================================

-- Keep updated_at / updated_by current.
create function public.touch_updated() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  if tg_table_name in ('persons', 'app_settings') then
    new.updated_by := auth.uid();
  end if;
  return new;
end $$;

create trigger persons_touch before update on public.persons
  for each row execute function public.touch_updated();
create trigger person_contacts_touch before update on public.person_contacts
  for each row execute function public.touch_updated();
create trigger person_health_touch before update on public.person_health
  for each row execute function public.touch_updated();
create trigger app_settings_touch before update on public.app_settings
  for each row execute function public.touch_updated();

-- Members may edit their own record, but names, sex, dates and life status
-- need admin approval (via a change request).
create function public.persons_guard_core_fields() returns trigger
language plpgsql set search_path = '' as $$
begin
  if public.is_admin() then
    return new;
  end if;
  if (new.first_name, new.middle_name, new.last_name, new.sex,
      new.birth_date, new.birth_date_approx, new.is_living,
      new.death_date, new.death_date_approx, new.death_place, new.burial_place)
     is distinct from
     (old.first_name, old.middle_name, old.last_name, old.sex,
      old.birth_date, old.birth_date_approx, old.is_living,
      old.death_date, old.death_date_approx, old.death_place, old.burial_place) then
    raise exception 'Changes to names, sex, dates or life status need admin approval'
      using errcode = '42501', hint = 'Submit a change request instead.';
  end if;
  return new;
end $$;

create trigger persons_guard before update on public.persons
  for each row execute function public.persons_guard_core_fields();

-- Prevent impossible family structures.
create function public.parent_child_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  parent_sex public.sex;
begin
  -- A person cannot be their own ancestor.
  if exists (
    with recursive descendants(id) as (
      select pc.child_id from public.parent_child pc where pc.parent_id = new.child_id
      union
      select pc.child_id from public.parent_child pc join descendants d on pc.parent_id = d.id
    )
    select 1 from descendants where id = new.parent_id
  ) then
    raise exception 'This link would make a person their own ancestor' using errcode = '23514';
  end if;

  if new.kind = 'biological' then
    if (select count(*) from public.parent_child pc
        where pc.child_id = new.child_id and pc.kind = 'biological' and pc.id <> new.id) >= 2 then
      raise exception 'A person can have at most two biological parents' using errcode = '23514';
    end if;

    select sex into parent_sex from public.persons where id = new.parent_id;
    if parent_sex <> 'unknown' and exists (
      select 1 from public.parent_child pc
      join public.persons p on p.id = pc.parent_id
      where pc.child_id = new.child_id and pc.kind = 'biological'
        and pc.id <> new.id and p.sex = parent_sex
    ) then
      raise exception 'This person already has a biological %',
        case parent_sex when 'male' then 'father' else 'mother' end
        using errcode = '23514';
    end if;
  end if;
  return new;
end $$;

create trigger parent_child_guard before insert or update on public.parent_child
  for each row execute function public.parent_child_guard();

-- Create a profile for every new auth user. The very first user becomes an
-- active admin so the family can bootstrap itself.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  first_user boolean;
begin
  perform pg_advisory_xact_lock(hashtext('buafamily_first_admin'));
  select not exists (select 1 from public.profiles where role = 'admin') into first_user;

  insert into public.profiles (id, display_name, email, role, status, locale)
  values (
    new.id,
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''), split_part(coalesce(new.email, ''), '@', 1)),
    new.email,
    case when first_user then 'admin'::public.app_role else 'member'::public.app_role end,
    case when first_user then 'active'::public.account_status else 'pending'::public.account_status end,
    case when new.raw_user_meta_data ->> 'locale' = 'ha' then 'ha' else 'en' end
  );
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- =============================================================================
-- Row level security
-- =============================================================================
alter table public.persons            enable row level security;
alter table public.unions             enable row level security;
alter table public.parent_child       enable row level security;
alter table public.person_education   enable row level security;
alter table public.person_occupations enable row level security;
alter table public.person_skills      enable row level security;
alter table public.person_contacts    enable row level security;
alter table public.person_health      enable row level security;
alter table public.profiles           enable row level security;
alter table public.app_settings       enable row level security;
alter table public.change_requests    enable row level security;

-- persons
create policy persons_select on public.persons for select to authenticated
  using (public.is_active_member());
create policy persons_insert on public.persons for insert to authenticated
  with check (public.is_admin());
create policy persons_update on public.persons for update to authenticated
  using (public.can_edit_person(id)) with check (public.can_edit_person(id));
create policy persons_delete on public.persons for delete to authenticated
  using (public.is_admin());

-- relationships: everyone active can read, only admins write
create policy unions_select on public.unions for select to authenticated
  using (public.is_active_member());
create policy unions_write on public.unions for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy parent_child_select on public.parent_child for select to authenticated
  using (public.is_active_member());
create policy parent_child_write on public.parent_child for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- education / occupations / skills: everyone active can read; admin or the person edits
create policy person_education_select on public.person_education for select to authenticated
  using (public.is_active_member());
create policy person_education_write on public.person_education for all to authenticated
  using (public.can_edit_person(person_id)) with check (public.can_edit_person(person_id));

create policy person_occupations_select on public.person_occupations for select to authenticated
  using (public.is_active_member());
create policy person_occupations_write on public.person_occupations for all to authenticated
  using (public.can_edit_person(person_id)) with check (public.can_edit_person(person_id));

create policy person_skills_select on public.person_skills for select to authenticated
  using (public.is_active_member());
create policy person_skills_write on public.person_skills for all to authenticated
  using (public.can_edit_person(person_id)) with check (public.can_edit_person(person_id));

-- contacts & health: governed by their visibility setting
create policy person_contacts_select on public.person_contacts for select to authenticated
  using (public.can_view(visibility, person_id));
create policy person_contacts_write on public.person_contacts for all to authenticated
  using (public.can_edit_person(person_id)) with check (public.can_edit_person(person_id));

create policy person_health_select on public.person_health for select to authenticated
  using (public.can_view(visibility, person_id));
create policy person_health_write on public.person_health for all to authenticated
  using (public.can_edit_person(person_id)) with check (public.can_edit_person(person_id));

-- profiles: you see your own; admins see everyone. Role/status/person link
-- are changed only through admin_update_account().
create policy profiles_select on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin());
create policy profiles_update_self on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
revoke update on public.profiles from authenticated, anon;
grant update (display_name, requested_person_id, claim_note, locale) on public.profiles to authenticated;
revoke insert, delete on public.profiles from authenticated, anon;

-- settings
create policy app_settings_select on public.app_settings for select to authenticated
  using (true);
create policy app_settings_update on public.app_settings for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
revoke insert, delete on public.app_settings from authenticated, anon;

-- change requests
create policy change_requests_select on public.change_requests for select to authenticated
  using (requested_by = auth.uid() or public.is_admin());
create policy change_requests_insert on public.change_requests for insert to authenticated
  with check (
    public.is_active_member()
    and requested_by = auth.uid()
    and status = 'pending'
    and reviewed_by is null and reviewed_at is null and result_person_id is null
    and (
      public.contributions_enabled()
      or public.is_admin()
      -- proposing a change to your own record is always allowed
      or (kind = 'update_person' and target_person_id = public.my_person_id())
    )
  );
-- members can withdraw their own pending requests
create policy change_requests_delete on public.change_requests for delete to authenticated
  using ((requested_by = auth.uid() and status = 'pending') or public.is_admin());
revoke update on public.change_requests from authenticated, anon;

-- =============================================================================
-- RPCs
-- =============================================================================

-- Person columns that may be set from a JSON payload.
create function public._person_columns() returns text[]
language sql immutable set search_path = '' as $$
  select array['title','first_name','middle_name','last_name','nickname','sex',
               'birth_date','birth_date_approx','birth_place','is_living',
               'death_date','death_date_approx','death_place','burial_place',
               'biography','photo_path','branch'];
$$;

create function public._insert_person(p_person jsonb, p_created_by uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  cols text[] := '{}';
  col  text;
  new_id uuid;
begin
  if p_person is null or jsonb_typeof(p_person) <> 'object' then
    raise exception 'person must be a JSON object' using errcode = '22023';
  end if;
  foreach col in array public._person_columns() loop
    if p_person ? col then
      cols := cols || col;
    end if;
  end loop;
  if not ('first_name' = any (cols)) then
    raise exception 'first_name is required' using errcode = '23502';
  end if;

  execute format(
    'insert into public.persons (%1$s, created_by)
     select %2$s, $2 from jsonb_populate_record(null::public.persons, $1) x
     returning id',
    (select string_agg(format('%I', c), ', ') from unnest(cols) c),
    (select string_agg(format('x.%I', c), ', ') from unnest(cols) c)
  ) into new_id using p_person, p_created_by;
  return new_id;
end $$;

create function public._update_person(p_person_id uuid, p_person jsonb) returns void
language plpgsql security definer set search_path = '' as $$
declare
  sets text[] := '{}';
  col  text;
begin
  if p_person is null or jsonb_typeof(p_person) <> 'object' then
    raise exception 'person must be a JSON object' using errcode = '22023';
  end if;
  foreach col in array public._person_columns() loop
    if p_person ? col then
      sets := sets || format('%1$I = x.%1$I', col);
    end if;
  end loop;
  if cardinality(sets) = 0 then
    return;
  end if;
  execute format(
    'update public.persons t set %s
     from jsonb_populate_record(null::public.persons, $1) x
     where t.id = $2',
    array_to_string(sets, ', ')
  ) using p_person, p_person_id;
  if not found then
    raise exception 'Person not found' using errcode = 'P0002';
  end if;
end $$;

create function public._link_relation(p_new_person uuid, p_relation jsonb) returns void
language plpgsql security definer set search_path = '' as $$
declare
  other      uuid;
  other_par  uuid;
  pkind      public.parent_kind;
begin
  if p_relation is null or jsonb_typeof(p_relation) = 'null' or p_relation ->> 'person_id' is null then
    return;
  end if;
  other := (p_relation ->> 'person_id')::uuid;
  pkind := coalesce((p_relation ->> 'kind')::public.parent_kind, 'biological');

  case p_relation ->> 'type'
    when 'parent' then
      insert into public.parent_child (parent_id, child_id, kind) values (p_new_person, other, pkind);
    when 'child' then
      insert into public.parent_child (parent_id, child_id, kind) values (other, p_new_person, pkind);
      other_par := (p_relation ->> 'other_parent_id')::uuid;
      if other_par is not null then
        insert into public.parent_child (parent_id, child_id, kind) values (other_par, p_new_person, pkind);
      end if;
    when 'spouse' then
      insert into public.unions (partner1_id, partner2_id, status)
      values (other, p_new_person, coalesce((p_relation ->> 'status')::public.union_status, 'married'));
    else
      raise exception 'Unknown relation type: %', p_relation ->> 'type' using errcode = '22023';
  end case;
end $$;

-- Admin: create a person and (optionally) link them to an existing person in one step.
create function public.create_person_with_relation(p_person jsonb, p_relation jsonb default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  new_id uuid;
begin
  if not public.is_admin() then
    raise exception 'Only admins can add people directly; submit a change request instead'
      using errcode = '42501';
  end if;
  new_id := public._insert_person(p_person, auth.uid());
  perform public._link_relation(new_id, p_relation);
  return new_id;
end $$;

-- Admin: approve or reject a change request. Approving applies it.
create function public.review_change_request(p_request_id uuid, p_approve boolean, p_note text default null)
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
    case r.kind
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

-- Admin: activate/suspend accounts, change roles, link an account to a person.
create function public.admin_update_account(
  p_user_id      uuid,
  p_status       public.account_status default null,
  p_role         public.app_role default null,
  p_person_id    uuid default null,
  p_unlink       boolean default false
) returns public.profiles
language plpgsql security definer set search_path = '' as $$
declare
  cur  public.profiles;
  res  public.profiles;
begin
  if not public.is_admin() then
    raise exception 'Only admins can manage accounts' using errcode = '42501';
  end if;

  select * into cur from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'Account not found' using errcode = 'P0002';
  end if;

  -- Never leave the family without an active admin.
  if cur.role = 'admin' and cur.status = 'active'
     and (coalesce(p_role, cur.role) <> 'admin' or coalesce(p_status, cur.status) <> 'active')
     and (select count(*) from public.profiles where role = 'admin' and status = 'active') <= 1 then
    raise exception 'There must be at least one active admin' using errcode = '55000';
  end if;

  if p_person_id is not null and exists (
    select 1 from public.profiles where person_id = p_person_id and id <> p_user_id
  ) then
    raise exception 'That person is already linked to another account' using errcode = '23505';
  end if;

  update public.profiles
     set status    = coalesce(p_status, status),
         role      = coalesce(p_role, role),
         person_id = case when p_unlink then null else coalesce(p_person_id, person_id) end,
         requested_person_id = case when p_person_id is not null then null else requested_person_id end
   where id = p_user_id
  returning * into res;
  return res;
end $$;

-- Lock down internal helpers; expose only the intended RPCs.
revoke execute on function public._person_columns() from public, anon, authenticated;
revoke execute on function public._insert_person(jsonb, uuid) from public, anon, authenticated;
revoke execute on function public._update_person(uuid, jsonb) from public, anon, authenticated;
revoke execute on function public._link_relation(uuid, jsonb) from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.create_person_with_relation(jsonb, jsonb) from public, anon;
revoke execute on function public.review_change_request(uuid, boolean, text) from public, anon;
revoke execute on function public.admin_update_account(uuid, public.account_status, public.app_role, uuid, boolean) from public, anon;
