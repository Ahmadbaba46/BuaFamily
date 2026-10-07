-- =============================================================================
-- Reporting and blocking (Google Play's child safety standards for social apps).
--
-- Reports: any member can report a moment, photo, comment, profile, member or
-- private message to the family's admins, with a reason and a note. Only the
-- reporter and admins see a report. Admins are told at once (a child safety
-- report as urgent), then remove the content, suspend or delete the account,
-- or dismiss the report. What was reported is copied into the report when it
-- is made, so admins see it even if it is changed or deleted later, and so a
-- reported private message (which admins can't otherwise read) can be acted on.
--
-- Blocking: a member can block someone. Neither can then start a
-- conversation with the other or send them a message.
-- =============================================================================

alter type public.notification_kind add value if not exists 'content_report';

create table public.reports (
  id           uuid primary key default gen_random_uuid(),
  reporter_id  uuid default auth.uid() references auth.users on delete set null,
  kind         text not null check (kind in ('post', 'photo', 'comment', 'profile', 'member', 'message')),
  target_id    uuid not null,
  -- Whose content it is (the account), when known.
  target_user  uuid references auth.users on delete set null,
  reason       text not null check (reason in ('child_safety', 'abuse', 'spam', 'other')),
  note         text check (length(note) <= 2000),
  snapshot     jsonb not null default '{}',
  link         text,
  status       text not null default 'open' check (status in ('open', 'removed', 'actioned', 'dismissed')),
  reviewed_by  uuid references auth.users on delete set null,
  reviewed_at  timestamptz,
  created_at   timestamptz not null default now()
);
create index reports_status_idx on public.reports (status, created_at desc);
create index reports_reporter_idx on public.reports (reporter_id);
create index reports_target_user_idx on public.reports (target_user);
create index reports_reviewed_by_idx on public.reports (reviewed_by);
-- One open report per person per thing.
create unique index reports_one_open on public.reports (reporter_id, kind, target_id) where status = 'open';

alter table public.reports enable row level security;
create policy reports_select on public.reports for select to authenticated
  using (reporter_id = (select auth.uid()) or public.is_admin());
revoke insert, update, delete on public.reports from authenticated, anon;

create table public.blocks (
  blocker_id  uuid not null default auth.uid() references auth.users on delete cascade,
  blocked_id  uuid not null references auth.users on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_not_self check (blocker_id <> blocked_id)
);
create index blocks_blocked_idx on public.blocks (blocked_id);

alter table public.blocks enable row level security;
create policy blocks_select on public.blocks for select to authenticated
  using (blocker_id = (select auth.uid()));
create policy blocks_insert on public.blocks for insert to authenticated
  with check (blocker_id = (select auth.uid()) and public.is_active_member());
create policy blocks_remove on public.blocks for delete to authenticated
  using (blocker_id = (select auth.uid()));

-- Either of the two has blocked the other.
create function public.blocked_between(p_a uuid, p_b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.blocks
                 where (blocker_id = p_a and blocked_id = p_b) or (blocker_id = p_b and blocked_id = p_a));
$$;

-- In this conversation, the two have blocked each other (either way).
create function public.dm_blocked(p_thread uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select public.blocked_between(t.user_a, t.user_b) from public.dm_threads t where t.id = p_thread), false);
$$;

alter policy dm_messages_insert on public.dm_messages
  with check (public.messages_enabled() and public.is_active_member()
              and author_id = (select auth.uid()) and public.in_dm_thread(thread_id)
              and not public.dm_blocked(thread_id));

create or replace function public.dm_open(p_user uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  a uuid;
  b uuid;
  thread uuid;
begin
  if not public.messages_enabled() then
    raise exception 'Messages are turned off by the family admins' using errcode = '42501';
  end if;
  if me is null or not public.is_active_member() then
    raise exception 'Only family members can send messages' using errcode = '42501';
  end if;
  if p_user is null or p_user = me
     or not exists (select 1 from public.profiles where id = p_user and status = 'active') then
    raise exception 'You can only message another family member' using errcode = '22023';
  end if;
  if public.blocked_between(me, p_user) then
    raise exception 'You can''t message this member' using errcode = '42501';
  end if;
  a := least(me, p_user);
  b := greatest(me, p_user);
  insert into public.dm_threads (user_a, user_b) values (a, b)
  on conflict (user_a, user_b) do nothing;
  select id into thread from public.dm_threads where user_a = a and user_b = b;
  return thread;
end $$;

-- -----------------------------------------------------------------------------
-- Reporting
-- -----------------------------------------------------------------------------
create function public.report_content(p_kind text, p_target uuid, p_reason text, p_note text default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  owner uuid;
  snap jsonb;
  link text;
  new_id uuid;
begin
  if me is null or not public.is_active_member() then
    raise exception 'Only family members can report' using errcode = '42501';
  end if;
  if p_reason not in ('child_safety', 'abuse', 'spam', 'other') then
    raise exception 'Choose a reason' using errcode = '22023';
  end if;

  -- What it is, whose it is, and a copy of it; only what the reporter can see.
  case p_kind
    when 'post' then
      select p.author_id, jsonb_build_object('body', left(p.body, 2000)), '/posts/' || p.id
        into owner, snap, link from public.posts p where p.id = p_target;
    when 'photo' then
      select ph.uploaded_by, jsonb_build_object('caption', ph.caption, 'storage_path', ph.storage_path), '/photo/' || ph.id
        into owner, snap, link from public.photos ph where ph.id = p_target;
    when 'comment' then
      select c.author_id, jsonb_build_object('body', left(c.body, 2000)),
             case when c.post_id is not null then '/posts/' || c.post_id
                  when c.photo_id is not null then '/photo/' || c.photo_id
                  else '/events/' || c.event_id end
        into owner, snap, link from public.comments c where c.id = p_target;
    when 'profile' then
      select pr.id, jsonb_build_object('name', private.person_name(pe)), '/person/' || pe.id
        into owner, snap, link
        from public.persons pe left join public.profiles pr on pr.person_id = pe.id where pe.id = p_target;
      if snap is null then
        raise exception 'Not found' using errcode = 'P0002';
      end if;
    when 'member' then
      select pr.id, jsonb_build_object('name', private.member_name(pr.id)),
             case when pr.person_id is not null then '/person/' || pr.person_id end
        into owner, snap, link from public.profiles pr where pr.id = p_target;
    when 'message' then
      select m.author_id, jsonb_build_object('body', left(m.body, 2000), 'sent_at', m.created_at), null
        into owner, snap, link
        from public.dm_messages m join public.dm_threads t on t.id = m.thread_id
       where m.id = p_target and me in (t.user_a, t.user_b);
    else
      raise exception 'Unknown kind %', p_kind using errcode = '22023';
  end case;
  if snap is null then
    raise exception 'Not found' using errcode = 'P0002';
  end if;
  if owner = me then
    raise exception 'You can''t report your own' using errcode = '22023';
  end if;

  insert into public.reports (reporter_id, kind, target_id, target_user, reason, note, snapshot, link)
  values (me, p_kind, p_target, owner, p_reason, nullif(btrim(coalesce(p_note, '')), ''),
          snap || jsonb_build_object('author', private.member_name(owner)), link)
  on conflict (reporter_id, kind, target_id) where status = 'open'
  do update set reason = excluded.reason, note = coalesce(excluded.note, public.reports.note)
  returning id into new_id;

  insert into public.notifications (user_id, kind, data, link, dedupe_key)
  select a.id, 'content_report',
         jsonb_build_object('report_id', new_id, 'kind', p_kind, 'reason', p_reason),
         '/admin/reports', 'report:' || new_id || ':' || a.id
  from public.profiles a
  where a.role = 'admin' and a.status = 'active' and a.id <> me
  on conflict (dedupe_key) do nothing;
  return new_id;
end $$;

-- Admin: what was done about a report.
create function public.admin_resolve_report(p_report uuid, p_status text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can review reports' using errcode = '42501';
  end if;
  if p_status not in ('open', 'removed', 'actioned', 'dismissed') then
    raise exception 'Unknown status %', p_status using errcode = '22023';
  end if;
  update public.reports
     set status = p_status,
         reviewed_by = case when p_status = 'open' then null else auth.uid() end,
         reviewed_at = case when p_status = 'open' then null else now() end
   where id = p_report;
end $$;

revoke execute on function public.blocked_between(uuid, uuid) from public, anon;
revoke execute on function public.dm_blocked(uuid) from public, anon;
revoke execute on function public.report_content(text, uuid, text, text) from public, anon;
revoke execute on function public.admin_resolve_report(uuid, text) from public, anon;
