-- =============================================================================
-- Sharing and events: moments (posts), albums, photos, tags, "Ma sha Allah"
-- likes, comments, events with RSVPs, and announcements.
--
-- Everything here is visible to every active member. Members may post moments,
-- events and announcements, add photos to any album and tag relatives.
-- Only admins may pin a post or an event to Home.
-- =============================================================================

create type public.post_kind      as enum ('moment', 'announcement');
create type public.event_category as enum ('naming', 'wedding', 'meeting', 'condolence', 'graduation', 'other');
create type public.rsvp_response  as enum ('going', 'maybe', 'no');

-- -----------------------------------------------------------------------------
-- Albums
-- -----------------------------------------------------------------------------
create table public.albums (
  id           uuid primary key default gen_random_uuid(),
  title        text not null check (length(btrim(title)) > 0),
  description  text,
  created_by   uuid not null default auth.uid() references auth.users on delete cascade,
  created_at   timestamptz not null default now()
);
create index albums_created_by_idx on public.albums (created_by);

-- -----------------------------------------------------------------------------
-- Posts (moments and announcements)
-- -----------------------------------------------------------------------------
create table public.posts (
  id          uuid primary key default gen_random_uuid(),
  kind        public.post_kind not null default 'moment',
  body        text not null default '',
  -- When set, the post's photos were also added to this album.
  album_id    uuid references public.albums on delete set null,
  pinned      boolean not null default false,
  author_id   uuid not null default auth.uid() references auth.users on delete cascade,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index posts_created_idx on public.posts (created_at desc);
create index posts_author_idx on public.posts (author_id);
create index posts_album_idx on public.posts (album_id);

-- People a post is about ("Who's in it?").
create table public.post_people (
  post_id    uuid not null references public.posts on delete cascade,
  person_id  uuid not null references public.persons on delete cascade,
  tagged_by  uuid not null default auth.uid() references auth.users on delete cascade,
  primary key (post_id, person_id)
);
create index post_people_person_idx on public.post_people (person_id);
create index post_people_tagged_by_idx on public.post_people (tagged_by);

-- -----------------------------------------------------------------------------
-- Photos: belong to a post, an album, or both.
-- Storage path: uploads/<uploader user id>/<file>
-- -----------------------------------------------------------------------------
create table public.photos (
  id            uuid primary key default gen_random_uuid(),
  storage_path  text not null unique,
  post_id       uuid references public.posts on delete cascade,
  album_id      uuid references public.albums on delete cascade,
  caption       text,
  taken_year    smallint check (taken_year between 1800 and 2200),
  uploaded_by   uuid not null default auth.uid() references auth.users on delete cascade,
  created_at    timestamptz not null default now(),
  constraint photos_has_home check (post_id is not null or album_id is not null)
);
create index photos_post_idx on public.photos (post_id);
create index photos_album_idx on public.photos (album_id, taken_year);
create index photos_uploaded_by_idx on public.photos (uploaded_by);

create table public.photo_people (
  photo_id   uuid not null references public.photos on delete cascade,
  person_id  uuid not null references public.persons on delete cascade,
  tagged_by  uuid not null default auth.uid() references auth.users on delete cascade,
  primary key (photo_id, person_id)
);
create index photo_people_person_idx on public.photo_people (person_id);
create index photo_people_tagged_by_idx on public.photo_people (tagged_by);

-- -----------------------------------------------------------------------------
-- Events
-- -----------------------------------------------------------------------------
create table public.events (
  id            uuid primary key default gen_random_uuid(),
  title         text not null check (length(btrim(title)) > 0),
  category      public.event_category not null default 'other',
  details       text,
  starts_at     timestamptz not null,
  ends_at       timestamptz check (ends_at is null or ends_at >= starts_at),
  place         text,
  address       text,
  rsvp_enabled  boolean not null default true,
  pinned        boolean not null default false,
  created_by    uuid not null default auth.uid() references auth.users on delete cascade,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index events_starts_idx on public.events (starts_at);
create index events_created_by_idx on public.events (created_by);

create table public.event_rsvps (
  event_id    uuid not null references public.events on delete cascade,
  user_id     uuid not null default auth.uid() references auth.users on delete cascade,
  response    public.rsvp_response not null,
  -- People coming along who are not counted separately (children, guests).
  guests      smallint not null default 0 check (guests between 0 and 20),
  updated_at  timestamptz not null default now(),
  primary key (event_id, user_id)
);
create index event_rsvps_user_idx on public.event_rsvps (user_id);

-- -----------------------------------------------------------------------------
-- Likes ("Ma sha Allah") and comments (memories / wishes) on exactly one of:
-- a post, a photo or an event.
-- -----------------------------------------------------------------------------
create table public.likes (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid references public.posts on delete cascade,
  photo_id    uuid references public.photos on delete cascade,
  event_id    uuid references public.events on delete cascade,
  user_id     uuid not null default auth.uid() references auth.users on delete cascade,
  created_at  timestamptz not null default now(),
  constraint likes_one_target check (num_nonnulls(post_id, photo_id, event_id) = 1)
);
create unique index likes_post_user_idx  on public.likes (post_id, user_id)  where post_id is not null;
create unique index likes_photo_user_idx on public.likes (photo_id, user_id) where photo_id is not null;
create unique index likes_event_user_idx on public.likes (event_id, user_id) where event_id is not null;
create index likes_user_idx on public.likes (user_id);

create table public.comments (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid references public.posts on delete cascade,
  photo_id    uuid references public.photos on delete cascade,
  event_id    uuid references public.events on delete cascade,
  body        text not null check (length(btrim(body)) > 0),
  author_id   uuid not null default auth.uid() references auth.users on delete cascade,
  created_at  timestamptz not null default now(),
  constraint comments_one_target check (num_nonnulls(post_id, photo_id, event_id) = 1)
);
create index comments_post_idx  on public.comments (post_id, created_at)  where post_id is not null;
create index comments_photo_idx on public.comments (photo_id, created_at) where photo_id is not null;
create index comments_event_idx on public.comments (event_id, created_at) where event_id is not null;
create index comments_author_idx on public.comments (author_id);

-- -----------------------------------------------------------------------------
-- Display names of authors. Profiles are private to their owner, so the feed
-- reads names through this function instead.
-- -----------------------------------------------------------------------------
create function public.member_directory()
returns table (user_id uuid, display_name text, person_id uuid, role public.app_role)
language sql stable security definer set search_path = '' as $$
  select p.id, p.display_name, p.person_id, p.role
  from public.profiles p
  where p.status = 'active' and public.is_active_member();
$$;
revoke execute on function public.member_directory() from public, anon;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

-- Only admins may pin or unpin.
create function public.guard_pinned() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.pinned is distinct from (case when tg_op = 'INSERT' then false else old.pinned end)
     and not public.is_admin() then
    raise exception 'Only admins can pin to Home' using errcode = '42501';
  end if;
  return new;
end $$;
revoke execute on function public.guard_pinned() from public, anon, authenticated;

create trigger posts_guard_pinned before insert or update on public.posts
  for each row execute function public.guard_pinned();
create trigger events_guard_pinned before insert or update on public.events
  for each row execute function public.guard_pinned();

create function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;
revoke execute on function public.touch_updated_at() from public, anon, authenticated;

create trigger posts_touch before update on public.posts
  for each row execute function public.touch_updated_at();
create trigger events_touch before update on public.events
  for each row execute function public.touch_updated_at();
create trigger event_rsvps_touch before update on public.event_rsvps
  for each row execute function public.touch_updated_at();

-- -----------------------------------------------------------------------------
-- Row level security
-- -----------------------------------------------------------------------------
alter table public.albums       enable row level security;
alter table public.posts        enable row level security;
alter table public.post_people  enable row level security;
alter table public.photos       enable row level security;
alter table public.photo_people enable row level security;
alter table public.events       enable row level security;
alter table public.event_rsvps  enable row level security;
alter table public.likes        enable row level security;
alter table public.comments     enable row level security;

-- Albums: shared; the creator or an admin may rename or delete.
create policy albums_select on public.albums for select to authenticated
  using (public.is_active_member());
create policy albums_insert on public.albums for insert to authenticated
  with check (public.is_active_member() and created_by = (select auth.uid()));
create policy albums_update on public.albums for update to authenticated
  using (created_by = (select auth.uid()) or public.is_admin())
  with check (public.is_active_member());
create policy albums_delete on public.albums for delete to authenticated
  using (created_by = (select auth.uid()) or public.is_admin());

-- Posts: authors edit their own; admins moderate.
create policy posts_select on public.posts for select to authenticated
  using (public.is_active_member());
create policy posts_insert on public.posts for insert to authenticated
  with check (public.is_active_member() and author_id = (select auth.uid()));
create policy posts_update on public.posts for update to authenticated
  using (author_id = (select auth.uid()) or public.is_admin())
  with check (public.is_active_member());
create policy posts_delete on public.posts for delete to authenticated
  using (author_id = (select auth.uid()) or public.is_admin());

-- Tags: anyone may tag; the tagger, the tagged person or an admin may untag.
create policy post_people_select on public.post_people for select to authenticated
  using (public.is_active_member());
create policy post_people_insert on public.post_people for insert to authenticated
  with check (public.is_active_member() and tagged_by = (select auth.uid()));
create policy post_people_delete on public.post_people for delete to authenticated
  using (tagged_by = (select auth.uid()) or person_id = public.my_person_id() or public.is_admin());

create policy photo_people_select on public.photo_people for select to authenticated
  using (public.is_active_member());
create policy photo_people_insert on public.photo_people for insert to authenticated
  with check (public.is_active_member() and tagged_by = (select auth.uid()));
create policy photo_people_delete on public.photo_people for delete to authenticated
  using (tagged_by = (select auth.uid()) or person_id = public.my_person_id() or public.is_admin());

-- Photos: anyone may add to any album; a photo on a post must be on one's own post.
create policy photos_select on public.photos for select to authenticated
  using (public.is_active_member());
create policy photos_insert on public.photos for insert to authenticated
  with check (
    public.is_active_member()
    and uploaded_by = (select auth.uid())
    and storage_path like 'uploads/' || (select auth.uid())::text || '/%'
    and (post_id is null
         or exists (select 1 from public.posts p where p.id = post_id and p.author_id = (select auth.uid())))
  );
create policy photos_update on public.photos for update to authenticated
  using (uploaded_by = (select auth.uid()) or public.is_admin())
  with check (public.is_active_member());
create policy photos_delete on public.photos for delete to authenticated
  using (uploaded_by = (select auth.uid()) or public.is_admin());

-- Events: anyone may create; the creator or an admin may change or cancel.
create policy events_select on public.events for select to authenticated
  using (public.is_active_member());
create policy events_insert on public.events for insert to authenticated
  with check (public.is_active_member() and created_by = (select auth.uid()));
create policy events_update on public.events for update to authenticated
  using (created_by = (select auth.uid()) or public.is_admin())
  with check (public.is_active_member());
create policy events_delete on public.events for delete to authenticated
  using (created_by = (select auth.uid()) or public.is_admin());

-- RSVPs: everyone sees who is coming; each person answers for themselves.
create policy event_rsvps_select on public.event_rsvps for select to authenticated
  using (public.is_active_member());
create policy event_rsvps_insert on public.event_rsvps for insert to authenticated
  with check (
    public.is_active_member()
    and user_id = (select auth.uid())
    and exists (select 1 from public.events e where e.id = event_id and e.rsvp_enabled)
  );
create policy event_rsvps_update on public.event_rsvps for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy event_rsvps_delete on public.event_rsvps for delete to authenticated
  using (user_id = (select auth.uid()));

-- Likes and comments.
create policy likes_select on public.likes for select to authenticated
  using (public.is_active_member());
create policy likes_insert on public.likes for insert to authenticated
  with check (public.is_active_member() and user_id = (select auth.uid()));
create policy likes_delete on public.likes for delete to authenticated
  using (user_id = (select auth.uid()));

create policy comments_select on public.comments for select to authenticated
  using (public.is_active_member());
create policy comments_insert on public.comments for insert to authenticated
  with check (public.is_active_member() and author_id = (select auth.uid()));
create policy comments_delete on public.comments for delete to authenticated
  using (author_id = (select auth.uid()) or public.is_admin());

-- -----------------------------------------------------------------------------
-- Storage: members upload shared photos into their own folder.
-- -----------------------------------------------------------------------------
create policy photos_uploads_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'photos'
    and public.is_active_member()
    and (storage.foldername(name))[1] = 'uploads'
    and (storage.foldername(name))[2] = (select auth.uid())::text
  );
create policy photos_uploads_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'photos'
    and (storage.foldername(name))[1] = 'uploads'
    and (storage.foldername(name))[2] = (select auth.uid())::text
  );
