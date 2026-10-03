-- =============================================================================
-- Mentorship and polls
--
-- Mentorship: relatives offer guidance in their areas, students say what help
-- they want, and anyone can share an opportunity (scholarship, job...).
-- "Ask" sends a mentor a short note and notifies them.
--
-- Polls: any member can ask the family a question. Ballots are secret: members
-- see only their own vote, and the counts once they have voted or the poll has
-- closed. Votes can be changed until it closes.
-- =============================================================================

alter type public.notification_kind add value if not exists 'mentor_request';
alter type public.notification_kind add value if not exists 'opportunity';
alter type public.notification_kind add value if not exists 'poll';

-- -----------------------------------------------------------------------------
-- Mentorship
-- -----------------------------------------------------------------------------
create table public.mentors (
  user_id     uuid primary key default auth.uid() references auth.users on delete cascade,
  areas       text not null check (length(btrim(areas)) > 0),   -- "Medicine · residency applications"
  note        text,
  created_at  timestamptz not null default now()
);

create table public.mentee_requests (
  user_id     uuid primary key default auth.uid() references auth.users on delete cascade,
  field       text not null check (length(btrim(field)) > 0),   -- "Computer Science"
  message     text not null check (length(btrim(message)) > 0),
  created_at  timestamptz not null default now()
);

create table public.mentor_asks (
  id              uuid primary key default gen_random_uuid(),
  mentor_user_id  uuid not null references public.mentors (user_id) on delete cascade,
  from_user_id    uuid not null default auth.uid() references auth.users on delete cascade,
  message         text not null check (length(btrim(message)) > 0),
  created_at      timestamptz not null default now()
);
create index mentor_asks_mentor_idx on public.mentor_asks (mentor_user_id, created_at desc);
create index mentor_asks_from_idx on public.mentor_asks (from_user_id);

create table public.opportunities (
  id          uuid primary key default gen_random_uuid(),
  title       text not null check (length(btrim(title)) > 0),
  details     text,
  url         text check (url is null or url ~ '^https?://'),
  deadline    date,
  posted_by   uuid not null default auth.uid() references auth.users on delete cascade,
  created_at  timestamptz not null default now()
);
create index opportunities_created_idx on public.opportunities (created_at desc);
create index opportunities_posted_by_idx on public.opportunities (posted_by);

alter table public.mentors         enable row level security;
alter table public.mentee_requests enable row level security;
alter table public.mentor_asks     enable row level security;
alter table public.opportunities   enable row level security;

-- Mentor and student listings: everyone reads; each member manages their own.
create policy mentors_select on public.mentors for select to authenticated using (public.is_active_member());
create policy mentors_insert on public.mentors for insert to authenticated
  with check (public.is_active_member() and user_id = (select auth.uid()));
create policy mentors_update on public.mentors for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy mentors_delete on public.mentors for delete to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());

create policy mentee_requests_select on public.mentee_requests for select to authenticated using (public.is_active_member());
create policy mentee_requests_insert on public.mentee_requests for insert to authenticated
  with check (public.is_active_member() and user_id = (select auth.uid()));
create policy mentee_requests_update on public.mentee_requests for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy mentee_requests_delete on public.mentee_requests for delete to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());

-- Asks: only the mentor and the person asking can read them.
create policy mentor_asks_select on public.mentor_asks for select to authenticated
  using (mentor_user_id = (select auth.uid()) or from_user_id = (select auth.uid()));
create policy mentor_asks_insert on public.mentor_asks for insert to authenticated
  with check (public.is_active_member() and from_user_id = (select auth.uid()) and mentor_user_id <> (select auth.uid()));
create policy mentor_asks_delete on public.mentor_asks for delete to authenticated
  using (mentor_user_id = (select auth.uid()) or from_user_id = (select auth.uid()));

create policy opportunities_select on public.opportunities for select to authenticated using (public.is_active_member());
create policy opportunities_insert on public.opportunities for insert to authenticated
  with check (public.is_active_member() and posted_by = (select auth.uid()));
create policy opportunities_delete on public.opportunities for delete to authenticated
  using (posted_by = (select auth.uid()) or public.is_admin());

create function private.notify_mentor_ask() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, data, link, actor_id)
  values (new.mentor_user_id, 'mentor_request', jsonb_build_object('ask_id', new.id, 'body', left(new.message, 160)),
          '/mentors', new.from_user_id);
  return new;
end $$;
create trigger mentor_asks_notify after insert on public.mentor_asks
  for each row execute function private.notify_mentor_ask();

-- New opportunity: tell the students who are looking for help.
create function private.notify_opportunity() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, data, link, actor_id)
  select m.user_id, 'opportunity', jsonb_build_object('opportunity_id', new.id, 'title', new.title),
         '/mentors?tab=opportunities', new.posted_by
  from public.mentee_requests m
  join public.profiles a on a.id = m.user_id and a.status = 'active'
  where m.user_id <> new.posted_by;
  return new;
end $$;
create trigger opportunities_notify after insert on public.opportunities
  for each row execute function private.notify_opportunity();

-- -----------------------------------------------------------------------------
-- Polls
-- -----------------------------------------------------------------------------
create table public.polls (
  id          uuid primary key default gen_random_uuid(),
  question    text not null check (length(btrim(question)) > 0),
  context     text,                                  -- "For the family meeting"
  closes_at   timestamptz,
  closed      boolean not null default false,        -- closed early by the creator or an admin
  created_by  uuid not null default auth.uid() references auth.users on delete cascade,
  created_at  timestamptz not null default now()
);
create index polls_created_idx on public.polls (created_at desc);
create index polls_created_by_idx on public.polls (created_by);

create table public.poll_options (
  id          uuid primary key default gen_random_uuid(),
  poll_id     uuid not null references public.polls on delete cascade,
  label       text not null check (length(btrim(label)) > 0),
  sort_order  smallint not null default 0
);
create index poll_options_poll_idx on public.poll_options (poll_id, sort_order);

create table public.poll_votes (
  poll_id     uuid not null references public.polls on delete cascade,
  user_id     uuid not null default auth.uid() references auth.users on delete cascade,
  option_id   uuid not null references public.poll_options on delete cascade,
  updated_at  timestamptz not null default now(),
  primary key (poll_id, user_id)
);
create index poll_votes_user_idx on public.poll_votes (user_id);
create index poll_votes_option_idx on public.poll_votes (option_id);

create function public.poll_is_open(p_poll uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.polls
                 where id = p_poll and not closed and (closes_at is null or closes_at > now()));
$$;

alter table public.polls        enable row level security;
alter table public.poll_options enable row level security;
alter table public.poll_votes   enable row level security;

create policy polls_select on public.polls for select to authenticated using (public.is_active_member());
create policy polls_insert on public.polls for insert to authenticated
  with check (public.is_active_member() and created_by = (select auth.uid()) and not closed);
create policy polls_update on public.polls for update to authenticated
  using (created_by = (select auth.uid()) or public.is_admin()) with check (public.is_active_member());
create policy polls_delete on public.polls for delete to authenticated
  using (created_by = (select auth.uid()) or public.is_admin());

create policy poll_options_select on public.poll_options for select to authenticated using (public.is_active_member());
create policy poll_options_insert on public.poll_options for insert to authenticated
  with check (exists (select 1 from public.polls p where p.id = poll_id and p.created_by = (select auth.uid())));

-- Ballots are secret: you see only your own.
create policy poll_votes_select on public.poll_votes for select to authenticated
  using (user_id = (select auth.uid()));
create policy poll_votes_insert on public.poll_votes for insert to authenticated
  with check (
    public.is_active_member() and user_id = (select auth.uid()) and public.poll_is_open(poll_id)
    and exists (select 1 from public.poll_options o where o.id = option_id and o.poll_id = poll_votes.poll_id)
  );
create policy poll_votes_update on public.poll_votes for update to authenticated
  using (user_id = (select auth.uid()) and public.poll_is_open(poll_id))
  with check (
    user_id = (select auth.uid()) and public.poll_is_open(poll_id)
    and exists (select 1 from public.poll_options o where o.id = option_id and o.poll_id = poll_votes.poll_id)
  );

create trigger poll_votes_touch before update on public.poll_votes
  for each row execute function public.touch_updated_at();

-- Counts per option, shown once you have voted, the poll has closed, or you
-- created it (or are an admin). Also returns how many members could vote.
create function public.poll_results()
returns table (poll_id uuid, option_id uuid, votes int, total int, eligible int)
language sql stable security definer set search_path = '' as $$
  with visible as (
    select p.id from public.polls p
    where public.is_active_member() and (
      not public.poll_is_open(p.id)
      or p.created_by = auth.uid()
      or public.is_admin()
      or exists (select 1 from public.poll_votes v where v.poll_id = p.id and v.user_id = auth.uid())
    )
  ),
  totals as (select v.poll_id, count(*)::int as total from public.poll_votes v group by v.poll_id)
  select o.poll_id, o.id, count(v.user_id)::int, coalesce(t.total, 0),
         (select count(*)::int from public.profiles where status = 'active')
  from public.poll_options o
  join visible on visible.id = o.poll_id
  left join public.poll_votes v on v.option_id = o.id
  left join totals t on t.poll_id = o.poll_id
  group by o.poll_id, o.id, t.total;
$$;

create function private.notify_poll() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, kind, data, link, actor_id)
  select a.id, 'poll', jsonb_build_object('poll_id', new.id, 'question', left(new.question, 160)), '/polls', new.created_by
  from public.profiles a
  where a.status = 'active' and a.id <> new.created_by;
  return new;
end $$;
create trigger polls_notify after insert on public.polls
  for each row execute function private.notify_poll();

revoke execute on function private.notify_mentor_ask() from public, anon, authenticated;
revoke execute on function private.notify_opportunity() from public, anon, authenticated;
revoke execute on function private.notify_poll() from public, anon, authenticated;
revoke execute on function public.poll_is_open(uuid) from public, anon;
revoke execute on function public.poll_results() from public, anon;
