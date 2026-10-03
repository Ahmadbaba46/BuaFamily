-- =============================================================================
-- Notifications: an in-app inbox for every member, plus SMS through Termii.
--
--   * New events and announcements notify the family (in the app; by SMS too
--     when an admin ticks "Also send SMS").
--   * Being tagged, and comments on your posts/photos/events, notify you in the app.
--   * Every morning: birthday reminders, and a reminder the day before an event
--     for everyone who said Going or Maybe.
--
-- SMS are queued in private.sms_outbox and sent once a minute by pg_cron using
-- pg_net, straight to Termii's API. The Termii API key lives in Supabase Vault
-- and is set from the app by an admin (public.admin_set_sms_secret). Members
-- choose whether they want SMS and which ones.
-- =============================================================================

-- Hosted Supabase provides these; the local test database uses stand-ins.
do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_net') then
    create extension if not exists pg_net with schema extensions;
  end if;
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
  end if;
end $$;

-- Not exposed through the API.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Settings
-- -----------------------------------------------------------------------------
alter table public.profiles
  add column phone          text check (phone ~ '^[0-9]{10,15}$'),
  add column sms_opt_in     boolean not null default false,
  add column sms_birthdays  boolean not null default true,
  add column sms_events     boolean not null default true;
grant update (phone, sms_opt_in, sms_birthdays, sms_events) on public.profiles to authenticated;

alter table public.app_settings
  add column sms_enabled    boolean not null default false,
  -- Sender ID registered with Termii (3–11 letters or digits).
  add column sms_sender_id  text check (sms_sender_id ~ '^[A-Za-z0-9 ]{3,11}$'),
  -- 'dnd' also reaches numbers on Do-Not-Disturb but must be activated by Termii.
  add column sms_channel    text not null default 'generic' check (sms_channel in ('generic', 'dnd')),
  add column timezone       text not null default 'Africa/Lagos';

-- "0803 123 4567", "+234 803…" and "803…" all become 2348031234567.
create function private.normalize_phone(p text) returns text
language sql immutable set search_path = '' as $$
  select case
    when d = '' then null
    when d ~ '^0[789][01][0-9]{8}$' then '234' || substr(d, 2)
    when d ~ '^[789][01][0-9]{8}$' then '234' || d
    else d
  end
  from (select regexp_replace(coalesce(p, ''), '[^0-9]', '', 'g') as d) x;
$$;

create function private.profiles_normalize_phone() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  new.phone := private.normalize_phone(new.phone);
  return new;
end $$;
create trigger profiles_normalize_phone before insert or update of phone on public.profiles
  for each row execute function private.profiles_normalize_phone();

-- Posts and events say whether to tell the family.
alter table public.events
  add column notify    boolean not null default true,
  add column send_sms  boolean not null default false;
alter table public.posts
  add column notify    boolean not null default false,
  add column send_sms  boolean not null default false;

-- Only admins may send SMS to the family (it costs money).
create function private.guard_send_sms() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.send_sms and not public.is_admin() then
    raise exception 'Only admins can send SMS to the family' using errcode = '42501';
  end if;
  return new;
end $$;
create trigger events_guard_send_sms before insert on public.events
  for each row execute function private.guard_send_sms();
create trigger posts_guard_send_sms before insert on public.posts
  for each row execute function private.guard_send_sms();

-- -----------------------------------------------------------------------------
-- In-app notifications. The app writes the text from kind + data, in the
-- reader's language.
-- -----------------------------------------------------------------------------
create type public.notification_kind as enum
  ('event', 'announcement', 'birthday', 'event_reminder', 'tagged', 'comment');

create table public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users on delete cascade,
  kind        public.notification_kind not null,
  data        jsonb not null default '{}'::jsonb,
  link        text,
  actor_id    uuid references auth.users on delete set null,
  -- Stops daily jobs from sending the same reminder twice.
  dedupe_key  text unique,
  created_at  timestamptz not null default now(),
  read_at     timestamptz
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);
create index notifications_actor_idx on public.notifications (actor_id);

alter table public.notifications enable row level security;
create policy notifications_select on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));
create policy notifications_update on public.notifications for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy notifications_delete on public.notifications for delete to authenticated
  using (user_id = (select auth.uid()));
revoke insert, update on public.notifications from authenticated, anon;
grant update (read_at) on public.notifications to authenticated;

-- Live updates for the bell badge.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- SMS outbox
-- -----------------------------------------------------------------------------
create table private.sms_outbox (
  id               bigint generated always as identity primary key,
  user_id          uuid references auth.users on delete cascade,
  phone            text not null,
  message          text not null,
  dedupe_key       text unique,
  status           text not null default 'queued' check (status in ('queued', 'sending', 'sent', 'failed')),
  attempts         smallint not null default 0,
  request_id       bigint,
  error            text,
  created_at       timestamptz not null default now(),
  last_attempt_at  timestamptz,
  sent_at          timestamptz
);
create index sms_outbox_status_idx on private.sms_outbox (status, id);
create index sms_outbox_user_idx on private.sms_outbox (user_id);

-- "Bua Family" / "Iyalin Bua"
create function private.sms_prefix(p_locale text) returns text
language sql stable set search_path = '' as $$
  select case when p_locale = 'ha' then 'Iyalin ' || family_name else family_name || ' Family' end
  from public.app_settings;
$$;

-- Queue one SMS per opted-in recipient. p_pref is 'events' or 'birthdays'.
-- Texts avoid Hausa hooked letters (ɗ ƙ ƴ): they double the cost of an SMS.
create function private.queue_sms(
  p_user_ids uuid[], p_pref text, p_text_en text, p_text_ha text, p_dedupe_prefix text
) returns int
language plpgsql security definer set search_path = '' as $$
declare
  n int;
begin
  if not (select sms_enabled from public.app_settings) then
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

create function private.person_name(p public.persons) returns text
language sql immutable set search_path = '' as $$
  select concat_ws(' ', nullif(btrim(p.title), ''), p.first_name, nullif(btrim(p.last_name), ''));
$$;

create function private.event_when(p_at timestamptz, p_locale text) returns text
language sql stable set search_path = '' as $$
  select case when p_locale = 'ha'
    then to_char(p_at at time zone s.timezone, 'DD/MM, HH24:MI')
    else to_char(p_at at time zone s.timezone, 'Dy FMDD Mon, FMHH12:MIam')
  end
  from public.app_settings s;
$$;

-- -----------------------------------------------------------------------------
-- Telling the family about new events and announcements
-- -----------------------------------------------------------------------------
create function private.notify_new_event() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  members uuid[];
begin
  if not new.notify then
    return new;
  end if;
  select array_agg(id) into members from public.profiles where status = 'active' and id <> new.created_by;
  insert into public.notifications (user_id, kind, data, link, actor_id)
  select u, 'event', jsonb_build_object('event_id', new.id, 'title', new.title, 'starts_at', new.starts_at, 'place', new.place),
         '/events/' || new.id, new.created_by
  from unnest(members) u;
  if new.send_sms then
    perform private.queue_sms(
      members, 'events',
      'New event - ' || new.title || ', ' || private.event_when(new.starts_at, 'en')
        || coalesce(' at ' || new.place, '') || '. Reply in the app.',
      'Sabon taro - ' || new.title || ', ' || private.event_when(new.starts_at, 'ha')
        || coalesce(' a ' || new.place, '') || '. Ka amsa a manhaja.',
      'event:' || new.id);
  end if;
  return new;
end $$;
create trigger events_notify after insert on public.events
  for each row execute function private.notify_new_event();

create function private.notify_new_announcement() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  members uuid[];
begin
  if new.kind <> 'announcement' or not new.notify then
    return new;
  end if;
  select array_agg(id) into members from public.profiles where status = 'active' and id <> new.author_id;
  insert into public.notifications (user_id, kind, data, link, actor_id)
  select u, 'announcement', jsonb_build_object('post_id', new.id, 'body', left(new.body, 200)), '/events', new.author_id
  from unnest(members) u;
  if new.send_sms then
    perform private.queue_sms(members, 'events', new.body, new.body, 'announcement:' || new.id);
  end if;
  return new;
end $$;
create trigger posts_notify after insert on public.posts
  for each row execute function private.notify_new_announcement();

-- -----------------------------------------------------------------------------
-- Tags and comments (in the app only)
-- -----------------------------------------------------------------------------
create function private.notify_post_tag() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, data, link, actor_id, dedupe_key)
  select p.id, 'tagged', jsonb_build_object('post_id', new.post_id), '/home', new.tagged_by,
         'tag:post:' || new.post_id || ':' || p.id
  from public.profiles p
  where p.person_id = new.person_id and p.status = 'active' and p.id <> new.tagged_by
  on conflict (dedupe_key) do nothing;
  return new;
end $$;
create trigger post_people_notify after insert on public.post_people
  for each row execute function private.notify_post_tag();

create function private.notify_photo_tag() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  ph public.photos;
begin
  select * into ph from public.photos where id = new.photo_id;
  insert into public.notifications (user_id, kind, data, link, actor_id, dedupe_key)
  select p.id, 'tagged', jsonb_build_object('photo_id', ph.id),
         '/photo/' || ph.id || case when ph.album_id is not null then '?album=' || ph.album_id else '?post=' || ph.post_id end,
         new.tagged_by,
         -- Tagging someone in a moment tags every photo too: notify once per post.
         case when ph.post_id is not null then 'tag:post:' || ph.post_id else 'tag:photo:' || ph.id end || ':' || p.id
  from public.profiles p
  where p.person_id = new.person_id and p.status = 'active' and p.id <> new.tagged_by
  on conflict (dedupe_key) do nothing;
  return new;
end $$;
create trigger photo_people_notify after insert on public.photo_people
  for each row execute function private.notify_photo_tag();

create function private.notify_comment() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  owner uuid;
  target_link text;
begin
  if new.post_id is not null then
    select author_id, '/home' into owner, target_link from public.posts where id = new.post_id;
  elsif new.photo_id is not null then
    select uploaded_by,
           '/photo/' || id || case when album_id is not null then '?album=' || album_id else '?post=' || post_id end
      into owner, target_link from public.photos where id = new.photo_id;
  else
    select created_by, '/events/' || id into owner, target_link from public.events where id = new.event_id;
  end if;
  if owner is not null and owner <> new.author_id then
    insert into public.notifications (user_id, kind, data, link, actor_id)
    values (owner, 'comment',
            jsonb_build_object('body', left(new.body, 140),
                               'target', case when new.post_id is not null then 'post'
                                              when new.photo_id is not null then 'photo' else 'event' end),
            target_link, new.author_id);
  end if;
  return new;
end $$;
create trigger comments_notify after insert on public.comments
  for each row execute function private.notify_comment();

-- -----------------------------------------------------------------------------
-- Daily reminders: birthdays today and events tomorrow
-- -----------------------------------------------------------------------------
-- Living people with a known exact date of birth on this day.
create function private.birthdays_on(p_day date)
returns table (id uuid, name text, age int)
language sql stable set search_path = '' as $$
  select p.id, private.person_name(p),
         extract(year from p_day)::int - extract(year from p.birth_date)::int
  from public.persons p
  where p.is_living and p.birth_date is not null and not p.birth_date_approx
    and p.birth_date < p_day
    and extract(month from p.birth_date) = extract(month from p_day)
    and extract(day from p.birth_date) = extract(day from p_day);
$$;

create function private.daily_reminders(p_day date default null) returns void
language plpgsql security definer set search_path = '' as $$
declare
  tz text := (select timezone from public.app_settings);
  today date := coalesce(p_day, (now() at time zone tz)::date);
  r record;
begin
  insert into public.notifications (user_id, kind, data, link, dedupe_key)
  select m.id, 'birthday', jsonb_build_object('person_id', b.id, 'name', b.name, 'age', b.age),
         '/person/' || b.id, 'birthday:' || today || ':' || b.id || ':' || m.id
  from private.birthdays_on(today) b
  cross join public.profiles m
  where m.status = 'active' and m.person_id is distinct from b.id
  on conflict (dedupe_key) do nothing;

  -- One SMS per member listing everyone with a birthday today.
  for r in
    select m.id, string_agg(b.name, ', ' order by b.name) as names, count(*) as n
    from public.profiles m
    join private.birthdays_on(today) b on m.person_id is distinct from b.id
    where m.status = 'active'
    group by m.id
  loop
    perform private.queue_sms(
      array[r.id], 'birthdays',
      case when r.n = 1 then 'Today is ' || r.names || '''s birthday. Send a greeting in the app.'
           else 'Birthdays today: ' || r.names || '. Send a greeting in the app.' end,
      'Yau ce ranar haihuwar ' || r.names || '. Aika gaisuwa a manhaja.',
      'birthday:' || today);
  end loop;

  -- Events tomorrow, for everyone who said Going or Maybe.
  for r in
    select e.*, v.user_id
    from public.events e
    join public.event_rsvps v on v.event_id = e.id and v.response in ('going', 'maybe')
    where (e.starts_at at time zone tz)::date = today + 1
  loop
    insert into public.notifications (user_id, kind, data, link, dedupe_key)
    values (r.user_id, 'event_reminder',
            jsonb_build_object('event_id', r.id, 'title', r.title, 'starts_at', r.starts_at, 'place', r.place),
            '/events/' || r.id, 'event_reminder:' || r.id || ':' || r.user_id)
    on conflict (dedupe_key) do nothing;
    perform private.queue_sms(
      array[r.user_id], 'events',
      'Reminder: ' || r.title || ' is tomorrow, ' || private.event_when(r.starts_at, 'en') || coalesce(' at ' || r.place, '') || '.',
      'Tunatarwa: ' || r.title || ' gobe ne, ' || private.event_when(r.starts_at, 'ha') || coalesce(' a ' || r.place, '') || '.',
      'event_reminder:' || r.id);
  end loop;
end $$;

-- Weekly housekeeping.
create function private.cleanup_old() returns void
language sql security definer set search_path = '' as $$
  delete from private.sms_outbox where status in ('sent', 'failed') and created_at < now() - interval '60 days';
  delete from public.notifications where created_at < now() - interval '180 days';
$$;

-- -----------------------------------------------------------------------------
-- Sending: reconcile earlier requests, then post queued messages to Termii.
-- -----------------------------------------------------------------------------
create function private.flush_sms(p_limit int default 50) returns int
language plpgsql security definer set search_path = '' as $$
declare
  s public.app_settings;
  api_key text;
  base_url text;
  r record;
  n int := 0;
begin
  -- Results of earlier requests (pg_net keeps responses for a few hours).
  update private.sms_outbox o
  set status = case when h.status_code between 200 and 299 then 'sent'
                    when o.attempts >= 3 then 'failed' else 'queued' end,
      sent_at = case when h.status_code between 200 and 299 then now() end,
      error = case when h.status_code between 200 and 299 then null
                   else left(coalesce(h.error_msg, h.status_code::text || ' ' || coalesce(h.content, '')), 500) end,
      request_id = null
  from net._http_response h
  where o.status = 'sending' and h.id = o.request_id;

  -- No answer after 15 minutes: try again (up to 3 times).
  update private.sms_outbox
  set status = case when attempts >= 3 then 'failed' else 'queued' end,
      error = 'No response from Termii', request_id = null
  where status = 'sending' and last_attempt_at < now() - interval '15 minutes';

  select * into s from public.app_settings;
  select decrypted_secret into api_key from vault.decrypted_secrets where name = 'termii_api_key';
  select decrypted_secret into base_url from vault.decrypted_secrets where name = 'termii_base_url';
  if not s.sms_enabled or s.sms_sender_id is null or api_key is null then
    return 0;
  end if;

  for r in
    select id, phone, message from private.sms_outbox
    where status = 'queued' order by id limit p_limit
    for update skip locked
  loop
    update private.sms_outbox
    set status = 'sending', attempts = attempts + 1, last_attempt_at = now(),
        request_id = net.http_post(
          url := rtrim(coalesce(base_url, 'https://api.ng.termii.com'), '/') || '/api/sms/send',
          body := jsonb_build_object(
            'to', r.phone, 'from', s.sms_sender_id, 'sms', r.message,
            'type', 'plain', 'channel', s.sms_channel, 'api_key', api_key),
          headers := '{"Content-Type": "application/json"}'::jsonb,
          timeout_milliseconds := 15000)
    where id = r.id;
    n := n + 1;
  end loop;
  return n;
end $$;

-- -----------------------------------------------------------------------------
-- Admin tools
-- -----------------------------------------------------------------------------

-- Save the Termii API key (and optionally the account's base URL) in Vault.
create function public.admin_set_sms_secret(p_api_key text default null, p_base_url text default null) returns void
language plpgsql security definer set search_path = '' as $$
declare
  existing uuid;
begin
  if not public.is_admin() then
    raise exception 'Only admins can change SMS settings' using errcode = '42501';
  end if;
  if nullif(btrim(p_api_key), '') is not null then
    select id into existing from vault.secrets where name = 'termii_api_key';
    if existing is null then
      perform vault.create_secret(btrim(p_api_key), 'termii_api_key', 'Termii API key for family SMS');
    else
      perform vault.update_secret(existing, btrim(p_api_key));
    end if;
  end if;
  if nullif(btrim(p_base_url), '') is not null then
    if p_base_url !~ '^https://[A-Za-z0-9.-]+(/.*)?$' then
      raise exception 'The base URL must start with https://';
    end if;
    select id into existing from vault.secrets where name = 'termii_base_url';
    if existing is null then
      perform vault.create_secret(btrim(p_base_url), 'termii_base_url', 'Termii API base URL');
    else
      perform vault.update_secret(existing, btrim(p_base_url));
    end if;
  end if;
end $$;

-- What admins see on the SMS settings card.
create function public.sms_status() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can see SMS status' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'key_saved', exists (select 1 from vault.secrets where name = 'termii_api_key'),
    'base_url', (select decrypted_secret from vault.decrypted_secrets where name = 'termii_base_url'),
    'queued', (select count(*) from private.sms_outbox where status in ('queued', 'sending')),
    'sent_7d', (select count(*) from private.sms_outbox where status = 'sent' and sent_at > now() - interval '7 days'),
    'failed_7d', (select count(*) from private.sms_outbox where status = 'failed' and created_at > now() - interval '7 days'),
    'subscribers', (select count(*) from public.profiles where status = 'active' and sms_opt_in and phone is not null),
    'last_error', (select error from private.sms_outbox where error is not null order by id desc limit 1)
  );
end $$;

-- Sends a test SMS to the admin's own phone straight away.
create function public.send_test_sms() returns void
language plpgsql security definer set search_path = '' as $$
declare
  me public.profiles;
begin
  if not public.is_admin() then
    raise exception 'Only admins can send a test SMS' using errcode = '42501';
  end if;
  select * into me from public.profiles where id = auth.uid();
  if me.phone is null then
    raise exception 'Add your phone number under Notifications first';
  end if;
  insert into private.sms_outbox (user_id, phone, message)
  values (me.id, me.phone,
          private.sms_prefix(me.locale) || ': '
            || case when me.locale = 'ha' then 'Gwaji. SMS na aiki.' else 'Test message. SMS is working.' end);
  perform private.flush_sms();
end $$;

-- -----------------------------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------------------------
revoke execute on all functions in schema private from public, anon, authenticated;
revoke execute on function public.admin_set_sms_secret(text, text) from public, anon;
revoke execute on function public.sms_status() from public, anon;
revoke execute on function public.send_test_sms() from public, anon;

-- -----------------------------------------------------------------------------
-- Schedules (hosted only): send queued SMS every minute; reminders at 07:30
-- Nigeria time (06:30 UTC); cleanup on Sunday nights.
-- -----------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('bua-send-sms', '* * * * *', 'select private.flush_sms()');
    perform cron.schedule('bua-daily-reminders', '30 6 * * *', 'select private.daily_reminders()');
    perform cron.schedule('bua-cleanup', '0 3 * * 0', 'select private.cleanup_old()');
  end if;
end $$;
