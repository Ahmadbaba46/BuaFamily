-- =============================================================================
-- Wedding and naming contributions ("gudummawa") on an event.
--
-- Whoever made the event (or an admin) can open contributions on it: who
-- receives them (the host, by default whoever opens it), how to pay (bank
-- account details), an optional target, and whether members
-- see each other's amounts. Everyone is told.
--
-- Members say what they give: an amount (or something in kind), how
-- (transfer, cash, in kind), a note, and whether to stay anonymous to the
-- other members; first as a pledge, then "sent" once they have paid. The
-- receiver (or whoever opened it, or an admin) marks each gift received, and
-- the giver is thanked. The money goes straight to the receiver; it is not
-- the welfare fund's and isn't counted in it.
--
-- Members see the list through event_gift_list(), which hides an anonymous
-- giver's name, and the amounts when they are kept private, from everyone
-- but the giver and those who run the collection.
-- =============================================================================

alter type public.notification_kind add value if not exists 'event_collection';
alter type public.notification_kind add value if not exists 'event_gift';
alter type public.notification_kind add value if not exists 'event_gift_received';

create table public.event_collections (
  event_id      uuid primary key references public.events on delete cascade,
  receiver_id   uuid not null references auth.users on delete cascade,
  target        numeric(14, 2) check (target is null or target > 0),
  pay_details   text check (length(pay_details) <= 1000),
  show_amounts  boolean not null default true,
  open          boolean not null default true,
  created_by    uuid default auth.uid() references auth.users on delete set null,
  created_at    timestamptz not null default now()
);
create index event_collections_receiver_idx on public.event_collections (receiver_id);
create index event_collections_created_by_idx on public.event_collections (created_by);

create table public.event_gifts (
  id           uuid primary key default gen_random_uuid(),
  event_id     uuid not null references public.event_collections on delete cascade,
  giver_id     uuid not null default auth.uid() references auth.users on delete cascade,
  amount       numeric(14, 2) check (amount is null or amount > 0),
  -- What is given in kind ("a ram", "20 bags of rice").
  item         text check (length(item) <= 200),
  method       text not null default 'transfer' check (method in ('transfer', 'cash', 'in_kind', 'other')),
  note         text check (length(note) <= 500),
  -- Hidden from other members (never from whoever receives it).
  anonymous    boolean not null default false,
  status       text not null default 'pledged' check (status in ('pledged', 'sent', 'received')),
  received_at  timestamptz,
  received_by  uuid references auth.users on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint event_gifts_what check (amount is not null or (method = 'in_kind' and nullif(btrim(item), '') is not null))
);
create index event_gifts_event_idx on public.event_gifts (event_id, created_at);
create index event_gifts_giver_idx on public.event_gifts (giver_id);
create index event_gifts_received_by_idx on public.event_gifts (received_by);

-- The receiver, whoever made the event, or an admin.
create function public.runs_collection(p_event uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select public.is_admin()
      or exists (select 1 from public.events e where e.id = p_event and e.created_by = (select auth.uid()))
      or exists (select 1 from public.event_collections c where c.event_id = p_event and c.receiver_id = (select auth.uid()));
$$;

alter table public.event_collections enable row level security;
alter table public.event_gifts enable row level security;

create policy event_collections_select on public.event_collections for select to authenticated
  using (public.is_active_member());
create policy event_collections_insert on public.event_collections for insert to authenticated
  with check (public.is_active_member() and created_by = (select auth.uid())
              and (public.is_admin()
                   or exists (select 1 from public.events e where e.id = event_id and e.created_by = (select auth.uid())))
              and exists (select 1 from public.profiles p where p.id = receiver_id and p.status = 'active'));
create policy event_collections_update on public.event_collections for update to authenticated
  using (public.runs_collection(event_id))
  with check (public.runs_collection(event_id)
              and exists (select 1 from public.profiles p where p.id = receiver_id and p.status = 'active'));
create policy event_collections_remove on public.event_collections for delete to authenticated
  using (public.is_admin() or exists (select 1 from public.events e where e.id = event_id and e.created_by = (select auth.uid())));

-- Rows directly: your own gifts, or all of them if you run the collection.
create policy event_gifts_select on public.event_gifts for select to authenticated
  using (giver_id = (select auth.uid()) or public.runs_collection(event_id));
create policy event_gifts_insert on public.event_gifts for insert to authenticated
  with check (public.is_active_member() and giver_id = (select auth.uid()) and status in ('pledged', 'sent')
              and exists (select 1 from public.event_collections c where c.event_id = event_gifts.event_id and c.open));
create policy event_gifts_update on public.event_gifts for update to authenticated
  using (giver_id = (select auth.uid()) or public.runs_collection(event_id))
  with check (giver_id = (select auth.uid()) or public.runs_collection(event_id));
create policy event_gifts_remove on public.event_gifts for delete to authenticated
  using ((giver_id = (select auth.uid()) and status <> 'received') or public.runs_collection(event_id));

-- Only those who run it mark a gift received; givers change their own until then.
create function private.event_gift_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  runs boolean := public.runs_collection(new.event_id)
                  or coalesce(current_setting('bua.restoring', true), '') = 'on'
                  or auth.uid() is null;
begin
  if tg_op = 'UPDATE' then
    new.event_id := old.event_id;
    new.giver_id := old.giver_id;
    new.created_at := old.created_at;
    if not runs and old.status = 'received' then
      raise exception 'This gift has been received; ask the host to change it' using errcode = '42501';
    end if;
  end if;
  if new.status = 'received' and (tg_op = 'INSERT' or old.status <> 'received') then
    if not runs then
      raise exception 'Only the host marks a gift received' using errcode = '42501';
    end if;
    new.received_at := coalesce(new.received_at, now());
    new.received_by := coalesce(new.received_by, auth.uid());
  elsif new.status <> 'received' then
    new.received_at := null;
    new.received_by := null;
  end if;
  new.updated_at := now();
  return new;
end $$;
create trigger event_gifts_guard before insert or update on public.event_gifts
  for each row execute function private.event_gift_guard();

-- -----------------------------------------------------------------------------
-- Notices: contributions open (everyone); a gift (the receiver); received (the giver).
-- -----------------------------------------------------------------------------
create function private.on_event_collection() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if coalesce(current_setting('bua.restoring', true), '') = 'on' then
    return new;
  end if;
  insert into public.notifications (user_id, kind, data, link, actor_id, dedupe_key)
  select p.id, 'event_collection',
         jsonb_build_object('event_id', e.id, 'title', e.title, 'category', e.category,
                            'receiver', private.member_name(new.receiver_id)),
         '/events/' || e.id, new.created_by, 'collection:' || e.id || ':' || p.id
    from public.events e
    cross join public.profiles p
   where e.id = new.event_id and p.status = 'active' and p.id is distinct from new.created_by
  on conflict (dedupe_key) do nothing;
  return new;
end $$;
create trigger event_collections_notify after insert on public.event_collections
  for each row execute function private.on_event_collection();

create function private.on_event_gift() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  c public.event_collections;
  title text;
begin
  if coalesce(current_setting('bua.restoring', true), '') = 'on' then
    return new;
  end if;
  select * into c from public.event_collections where event_id = new.event_id;
  select e.title into title from public.events e where e.id = new.event_id;
  if new.status in ('pledged', 'sent') and (tg_op = 'INSERT' or old.status is distinct from new.status)
     and c.receiver_id <> new.giver_id then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (c.receiver_id, 'event_gift',
            jsonb_build_object('event_id', new.event_id, 'title', title, 'name', private.member_name(new.giver_id),
                               'amount', new.amount, 'item', new.item, 'status', new.status),
            '/events/' || new.event_id, new.giver_id);
  elsif new.status = 'received' and tg_op = 'UPDATE' and old.status <> 'received'
        and new.giver_id is distinct from auth.uid() then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (new.giver_id, 'event_gift_received',
            jsonb_build_object('event_id', new.event_id, 'title', title, 'amount', new.amount, 'item', new.item,
                               'name', private.member_name(c.receiver_id)),
            '/events/' || new.event_id, auth.uid());
  end if;
  return new;
end $$;
create trigger event_gifts_notify after insert or update on public.event_gifts
  for each row execute function private.on_event_gift();

-- -----------------------------------------------------------------------------
-- The list members see.
-- -----------------------------------------------------------------------------
create function public.event_gift_list(p_event uuid)
returns table (id uuid, giver_id uuid, amount numeric, item text, method text, note text, anonymous boolean,
               status text, created_at timestamptz, received_at timestamptz)
language plpgsql stable security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  runs boolean := public.runs_collection(p_event);
  shown boolean := coalesce((select show_amounts from public.event_collections where event_id = p_event), false);
begin
  if not public.is_active_member() then
    return;
  end if;
  return query
  select g.id,
         case when g.anonymous and not runs and g.giver_id <> me then null else g.giver_id end,
         case when shown or runs or g.giver_id = me then g.amount end,
         g.item, g.method,
         case when runs or g.giver_id = me then g.note end,
         g.anonymous, g.status, g.created_at, g.received_at
    from public.event_gifts g
   where g.event_id = p_event
   order by g.created_at;
end $$;

revoke execute on function public.runs_collection(uuid) from public, anon;
revoke execute on function private.event_gift_guard() from public, anon, authenticated;
revoke execute on function private.on_event_collection() from public, anon, authenticated;
revoke execute on function private.on_event_gift() from public, anon, authenticated;
revoke execute on function public.event_gift_list(uuid) from public, anon;

create trigger zz_log_change after insert or update or delete on public.event_collections
  for each row execute function private.log_change();

-- -----------------------------------------------------------------------------
-- Backups and restores include contributions.
-- -----------------------------------------------------------------------------
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
    'posts', 'post_people', 'events', 'albums', 'photos', 'photo_people', 'event_rsvps', 'event_attendance',
    'comments',
    'memories', 'stories', 'blood_requests', 'fund_settings', 'fund_causes', 'fund_dues_plans',
    'fund_dues_members', 'fund_contributions', 'fund_payouts', 'mentors', 'mentee_requests', 'opportunities',
    'polls', 'poll_options', 'poll_votes', 'likes', 'invites', 'khatms', 'khatm_parts',
    'event_collections', 'event_gifts'
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
    'person_contacts', 'person_health', 'events', 'albums', 'posts', 'post_people', 'photos', 'photo_people',
    'event_rsvps', 'event_attendance', 'comments', 'memories', 'stories', 'blood_requests', 'fund_settings',
    'fund_causes', 'fund_dues_plans', 'fund_dues_members', 'fund_contributions', 'fund_payouts', 'mentors',
    'mentee_requests', 'opportunities', 'polls', 'poll_options', 'poll_votes', 'likes', 'invites',
    'khatms', 'khatm_parts', 'event_collections', 'event_gifts'
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
