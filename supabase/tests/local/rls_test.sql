-- Behavioural tests for permissions and the approval workflow.
-- Run with ./run.sh (any failed assertion aborts with a non-zero exit).
\set ON_ERROR_STOP 1
\set QUIET 1
\o /dev/null

-- Test identities
\set admin_id   '''00000000-0000-0000-0000-00000000000a'''
\set member_id  '''00000000-0000-0000-0000-00000000000b'''
\set member2_id '''00000000-0000-0000-0000-00000000000c'''

create schema test;
create function test.assert(cond boolean, msg text) returns void language plpgsql as $$
begin
  if cond is not true then raise exception 'ASSERTION FAILED: %', msg; end if;
end $$;
-- Run SQL and require it to fail (as the current role).
create function test.expect_error(sql text, msg text) returns void language plpgsql as $$
begin
  execute sql;
  raise exception 'ASSERTION FAILED (expected an error): %', msg;
exception
  when raise_exception then
    if sqlerrm like 'ASSERTION FAILED%' then raise; end if;
  when others then null;
end $$;
grant usage on schema test to authenticated, anon;
grant execute on all functions in schema test to authenticated, anon;
create table test.ids (name text primary key, id uuid);
grant all on test.ids to authenticated;

-- ---------------------------------------------------------------------------
-- 1. Sign-up bootstrap: first user becomes active admin, later users pending.
-- ---------------------------------------------------------------------------
insert into auth.users (id, email, raw_user_meta_data) values
  (:admin_id,   'admin@example.com',  '{"display_name": "Admin"}'),
  (:member_id,  'aisha@example.com',  '{"display_name": "Aisha", "locale": "ha"}'),
  (:member2_id, 'musa@example.com',   '{}');

select test.assert((select role = 'admin' and status = 'active' from public.profiles where id = :admin_id), 'first user is active admin');
select test.assert((select role = 'member' and status = 'pending' and locale = 'ha' from public.profiles where id = :member_id), 'second user is pending member with locale');
select test.assert((select display_name = 'musa' from public.profiles where id = :member2_id), 'display name falls back to email');

-- ---------------------------------------------------------------------------
-- 2. Pending users see nothing and cannot write.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.persons), 'pending user cannot read persons');
select test.expect_error($$insert into public.persons (first_name) values ('X')$$, 'pending user cannot insert persons');
update public.profiles set claim_note = 'Aisha, daughter of Musa' where id = auth.uid();
select test.expect_error($$update public.profiles set role = 'admin' where id = auth.uid()$$, 'cannot self-promote');
select test.expect_error($$update public.profiles set status = 'active' where id = auth.uid()$$, 'cannot self-activate');
reset role;
select test.assert((select claim_note = 'Aisha, daughter of Musa' and role = 'member' from public.profiles where id = :member_id), 'claim note saved, role unchanged');

-- ---------------------------------------------------------------------------
-- 3. Admin builds a small tree.
--    Grandpa Bua (+ wives Hauwa, Zainab) -> Musa (Hauwa), Sani (Zainab)
--    Musa -> Aisha
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into test.ids values
  ('grandpa', public.create_person_with_relation('{"first_name":"Ahmadu","last_name":"Bua","sex":"male","is_living":false,"death_date":"1990-01-01","birth_date":"1920-01-01","birth_date_approx":true}'));
insert into test.ids values
  ('hauwa',  public.create_person_with_relation('{"first_name":"Hauwa","sex":"female"}', json_build_object('type','spouse','person_id',(select id from test.ids where name='grandpa'))::jsonb)),
  ('zainab', public.create_person_with_relation('{"first_name":"Zainab","sex":"female"}', json_build_object('type','spouse','person_id',(select id from test.ids where name='grandpa'))::jsonb));
insert into test.ids values
  ('musa', public.create_person_with_relation('{"first_name":"Musa","last_name":"Bua","sex":"male"}',
     json_build_object('type','child','person_id',(select id from test.ids where name='grandpa'),'other_parent_id',(select id from test.ids where name='hauwa'))::jsonb)),
  ('sani', public.create_person_with_relation('{"first_name":"Sani","last_name":"Bua","sex":"male"}',
     json_build_object('type','child','person_id',(select id from test.ids where name='grandpa'),'other_parent_id',(select id from test.ids where name='zainab'))::jsonb));
insert into test.ids values
  ('aisha', public.create_person_with_relation('{"first_name":"Aisha","last_name":"Bua","sex":"female"}',
     json_build_object('type','child','person_id',(select id from test.ids where name='musa'))::jsonb)),
  ('ibrahim', public.create_person_with_relation('{"first_name":"Ibrahim","last_name":"Bua","sex":"male"}'));

select test.assert((select count(*) = 7 from public.persons), 'seven persons created');
select test.assert((select count(*) = 2 from public.unions), 'two unions (polygamous) created');
select test.assert((select count(*) = 5 from public.parent_child), 'five parent links');
select test.assert((select birth_date_approx and not is_living from public.persons where first_name = 'Ahmadu'), 'deceased ancestor with approximate date');

-- Impossible structures are rejected.
select test.expect_error(format($$insert into public.parent_child (parent_id, child_id) values (%L, %L)$$,
  (select id from test.ids where name='aisha'), (select id from test.ids where name='grandpa')), 'no ancestor cycles');
select test.expect_error(format($$insert into public.parent_child (parent_id, child_id) values (%L, %L)$$,
  (select id from test.ids where name='sani'), (select id from test.ids where name='aisha')), 'no second biological father');
select test.expect_error(format($$insert into public.parent_child (parent_id, child_id) values (%L, %L)$$,
  (select id from test.ids where name='zainab'), (select id from test.ids where name='musa')), 'no third biological parent');
select test.expect_error($$select public.create_person_with_relation('{"last_name":"NoFirst"}')$$, 'first_name required');
-- Adopted parent is allowed alongside biological ones.
insert into public.parent_child (parent_id, child_id, kind)
  values ((select id from test.ids where name='sani'), (select id from test.ids where name='aisha'), 'adopted');

-- Activate and link both members.
select public.admin_update_account(:member_id, 'active', null, (select id from test.ids where name='aisha'));
select public.admin_update_account(:member2_id, 'active', null, (select id from test.ids where name='ibrahim'));
select test.expect_error(format($$select public.admin_update_account(%L, null, null, %L)$$, :member2_id,
  (select id from test.ids where name='aisha')), 'person cannot be linked to two accounts');
select test.expect_error(format($$select public.admin_update_account(%L, null, 'member')$$, :admin_id), 'last admin cannot be demoted');

-- Health data for Aisha (private by default) and Musa (shared with family).
insert into public.person_health (person_id, blood_group, genotype) values ((select id from test.ids where name='aisha'), 'O+', 'AS');
insert into public.person_health (person_id, blood_group, visibility) values ((select id from test.ids where name='musa'), 'A+', 'family');
reset role;

-- ---------------------------------------------------------------------------
-- 4. Active member permissions.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 7 from public.persons), 'member reads all persons');
select test.assert(public.my_person_id() = (select id from test.ids where name='aisha'), 'member linked to Aisha');
select test.expect_error($$insert into public.persons (first_name) values ('X')$$, 'member cannot insert persons directly');
select test.expect_error($$select public.create_person_with_relation('{"first_name":"X"}')$$, 'member cannot use admin create');

-- Own record: details yes, core fields no.
update public.persons set biography = 'I love my family', nickname = 'Ayi' where id = public.my_person_id();
select test.assert((select biography = 'I love my family' from public.persons where id = public.my_person_id()), 'member edits own biography');
select test.expect_error($$update public.persons set first_name = 'Changed' where id = public.my_person_id()$$, 'member cannot rename self directly');
update public.persons set biography = 'hacked' where first_name = 'Musa';
select test.assert((select biography is null from public.persons where first_name = 'Musa'), 'member cannot edit others (no rows updated)');
insert into public.person_skills (person_id, skill) values (public.my_person_id(), 'Nursing');
select test.expect_error(format($$insert into public.person_skills (person_id, skill) values (%L, 'Hacking')$$,
  (select id from test.ids where name='musa')), 'member cannot add skills for others');
select test.expect_error(format($$insert into public.parent_child (parent_id, child_id) values (%L, %L)$$,
  (select id from test.ids where name='aisha'), (select id from test.ids where name='ibrahim')), 'member cannot add relationships');

-- Health visibility.
select test.assert((select count(*) = 2 from public.person_health), 'member sees own private + family-shared health');

-- Contributions disabled: only self-update requests.
select test.expect_error($$insert into public.change_requests (kind, payload) values ('create_person', '{"person":{"first_name":"New"}}')$$,
  'create request blocked while contributions disabled');
insert into public.change_requests (kind, target_person_id, payload)
  values ('update_person', public.my_person_id(), '{"person":{"middle_name":"Hadiza"}}');
select test.expect_error($$select public.review_change_request((select id from public.change_requests limit 1), true)$$, 'member cannot approve');
update public.app_settings set member_contributions_enabled = true;
reset role;
select test.assert((select not member_contributions_enabled from public.app_settings), 'member cannot toggle contributions');

-- Other member cannot see Aisha's private health.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 1 from public.person_health), 'other member sees only family-shared health');
select test.assert((select count(*) = 0 from public.change_requests), 'other member cannot see others requests');
select test.assert((select count(*) = 1 from public.profiles), 'member sees only own profile');
reset role;

-- ---------------------------------------------------------------------------
-- 5. Admin turns on contributions; member proposes a new relative; admin approves.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
update public.app_settings set member_contributions_enabled = true;
select test.assert((select member_contributions_enabled and updated_by = :admin_id from public.app_settings), 'admin toggles contributions');
-- Approve Aisha's own name change.
select public.review_change_request((select id from public.change_requests where kind = 'update_person'), true, 'ok');
select test.assert((select middle_name = 'Hadiza' from public.persons where id = (select id from test.ids where name='aisha')), 'approved self update applied');
reset role;

select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.change_requests (kind, payload) values ('create_person',
  json_build_object('person', json_build_object('first_name','Fatima','sex','female','id','11111111-1111-1111-1111-111111111111','created_by', :admin_id),
                    'relation', json_build_object('type','child','person_id',(select id from test.ids where name='aisha')))::jsonb);
insert into public.change_requests (kind, payload) values ('create_person', '{"person":{"first_name":"Spam"}}');
select test.assert((select count(*) = 3 from public.change_requests), 'member sees own requests');
select test.expect_error($$update public.change_requests set status = 'approved' where status = 'pending'$$, 'member cannot self-approve via update');
reset role;
select test.assert((select count(*) = 2 from public.change_requests where status = 'pending'), 'requests still pending after member update attempt');

select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select public.review_change_request((select id from public.change_requests where payload -> 'person' ->> 'first_name' = 'Fatima'), true);
select public.review_change_request((select id from public.change_requests where payload -> 'person' ->> 'first_name' = 'Spam'), false, 'duplicate');
select test.expect_error($$select public.review_change_request((select id from public.change_requests where payload -> 'person' ->> 'first_name' = 'Spam'), true)$$, 'cannot review twice');
select test.assert((select count(*) = 1 from public.persons where first_name = 'Fatima'), 'approved person created');
select test.assert((select id <> '11111111-1111-1111-1111-111111111111' and created_by = :member_id from public.persons where first_name = 'Fatima'),
  'payload cannot set id/created_by; creator is the requester');
select test.assert((select count(*) = 1 from public.parent_child pc join public.persons p on p.id = pc.child_id
  where p.first_name = 'Fatima' and pc.parent_id = (select id from test.ids where name='aisha')), 'approved relation linked');
select test.assert((select count(*) = 0 from public.persons where first_name = 'Spam'), 'rejected person not created');
select test.assert((select result_person_id is not null from public.change_requests where payload -> 'person' ->> 'first_name' = 'Fatima'), 'result person recorded');
reset role;

-- ---------------------------------------------------------------------------
-- 6. Storage: members upload only into their own person folder.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into storage.objects (bucket_id, name) values ('photos', 'persons/' || public.my_person_id() || '/me.jpg');
select test.expect_error(format($$insert into storage.objects (bucket_id, name) values ('photos', 'persons/%s/x.jpg')$$,
  (select id from test.ids where name='musa')), 'member cannot upload into another person folder');
reset role;

-- ---------------------------------------------------------------------------
-- 7. Sharing and events.
-- ---------------------------------------------------------------------------
\set pending_id '''00000000-0000-0000-0000-00000000000d'''
insert into auth.users (id, email) values (:pending_id, 'pending@example.com');

-- Member posts a moment with a photo, tags people, adds it to an album.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.albums (title) values ('Sallah 2026');
insert into public.posts (body, album_id) values ('Sallah day', (select id from public.albums where title = 'Sallah 2026'));
insert into public.photos (storage_path, post_id, album_id) values
  ('uploads/' || auth.uid() || '/a.jpg', (select id from public.posts where body = 'Sallah day'), (select id from public.albums where title = 'Sallah 2026'));
insert into public.post_people (post_id, person_id) values ((select id from public.posts where body = 'Sallah day'), (select id from test.ids where name='musa'));
insert into public.photo_people (photo_id, person_id) values ((select id from public.photos limit 1), (select id from test.ids where name='musa'));
insert into storage.objects (bucket_id, name) values ('photos', 'uploads/' || auth.uid() || '/a.jpg');
select test.expect_error(format($$insert into storage.objects (bucket_id, name) values ('photos', 'uploads/%s/x.jpg')$$, :admin_id),
  'member cannot upload into another user folder');
select test.expect_error(format($$insert into public.photos (storage_path, album_id) values ('uploads/%s/x.jpg', (select id from public.albums limit 1))$$, :admin_id),
  'photo path must be in own folder');
select test.expect_error($$insert into public.posts (body, pinned) values ('Look at me', true)$$, 'member cannot pin a post');
select test.expect_error(format($$insert into public.posts (body, author_id) values ('Fake', %L)$$, :admin_id), 'cannot post as someone else');
insert into public.likes (post_id) values ((select id from public.posts where body = 'Sallah day'));
select test.expect_error($$insert into public.likes (post_id) values ((select id from public.posts where body = 'Sallah day'))$$, 'one like per person');
select test.expect_error($$insert into public.likes (post_id, photo_id) values ((select id from public.posts limit 1), (select id from public.photos limit 1))$$, 'like has one target');
insert into public.comments (post_id, body) values ((select id from public.posts where body = 'Sallah day'), 'Barka da Sallah');
insert into public.events (title, category, starts_at, place) values ('Naming ceremony', 'naming', now() + interval '7 days', 'Kano');
insert into public.event_rsvps (event_id, response, guests) values ((select id from public.events where title = 'Naming ceremony'), 'going', 2);
select test.assert((select count(*) = 1 from public.member_directory() where display_name = 'Aisha'), 'members see the directory');
reset role;

-- Another member sees everything but cannot change or delete it.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 1 from public.posts), 'other member sees the post');
select test.assert((select count(*) = 1 from public.photos), 'other member sees the photo');
select test.assert((select count(*) = 1 from public.event_rsvps), 'other member sees RSVPs');
update public.posts set body = 'hacked';
delete from public.posts;
delete from public.comments;
update public.event_rsvps set response = 'no';
delete from public.photo_people;
reset role;
select test.assert((select body = 'Sallah day' from public.posts), 'other member cannot edit or delete the post');
select test.assert((select count(*) = 1 from public.comments), 'other member cannot delete a comment');
select test.assert((select response = 'going' from public.event_rsvps), 'other member cannot change my RSVP');
select test.assert((select count(*) = 1 from public.photo_people), 'other member cannot untag someone else''s tag');

-- Admins moderate.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
update public.posts set pinned = true where body = 'Sallah day';
select test.assert((select pinned from public.posts where body = 'Sallah day'), 'admin can pin');
delete from public.comments;
reset role;
select test.assert((select count(*) = 0 from public.comments), 'admin can delete a comment');

-- The author edits their own post but cannot unpin it.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
update public.posts set body = 'Sallah day at Kaka''s house';
select test.expect_error($$update public.posts set pinned = false$$, 'author cannot unpin');
delete from public.photos;
reset role;
select test.assert((select body = 'Sallah day at Kaka''s house' and pinned from public.posts), 'author edited own post');
select test.assert((select count(*) = 0 from public.photos), 'uploader deleted own photo');

-- Pending users see none of it.
select set_config('request.jwt.claims', json_build_object('sub', :pending_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.posts), 'pending user sees no posts');
select test.assert((select count(*) = 0 from public.events), 'pending user sees no events');
select test.assert((select count(*) = 0 from public.member_directory()), 'pending user sees no directory');
select test.expect_error($$insert into public.posts (body) values ('hi')$$, 'pending user cannot post');
reset role;

-- ---------------------------------------------------------------------------
-- 8. Anonymous users see nothing.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{}', false);
set role anon;
select test.assert((select count(*) = 0 from public.persons), 'anon sees no persons');
reset role;

\echo 'All database tests passed.'
