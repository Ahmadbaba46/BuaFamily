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
grant usage on schema test to authenticated, anon, service_role;
grant execute on all functions in schema test to authenticated, anon, service_role;
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
-- 8. Notifications and SMS.
-- ---------------------------------------------------------------------------
-- Members manage their own SMS preferences; numbers are normalised.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
update public.profiles set phone = '0803 123 4567', sms_opt_in = true where id = auth.uid();
select test.expect_error($$select public.admin_set_sms_secret('stolen')$$, 'member cannot set the SMS key');
select test.expect_error($$select public.sms_status()$$, 'member cannot see SMS status');
select test.expect_error($$insert into public.events (title, starts_at, send_sms) values ('Spam', now() + interval '1 day', true)$$,
  'member cannot send SMS to the family');
select test.expect_error($$insert into public.notifications (user_id, kind) values (auth.uid(), 'event')$$, 'cannot forge notifications');
select test.expect_error($$select private.flush_sms()$$, 'private functions are not callable');
reset role;
select test.assert((select phone = '2348031234567' from public.profiles where id = :member_id), 'phone normalised');

-- Admin configures SMS and posts an event with SMS.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
update public.app_settings set sms_enabled = true, sms_sender_id = 'BuaFamily';
select public.admin_set_sms_secret('key-123', 'https://example.termii.test');
select public.admin_set_sms_secret('key-456');
select test.assert((public.sms_status() ->> 'key_saved')::boolean, 'key saved');
insert into public.events (title, starts_at, place, send_sms) values ('Family meeting', now() + interval '3 days', 'Kano', true);
insert into public.posts (kind, body, notify) values ('announcement', 'Meeting moved to Sunday', true);
insert into public.posts (kind, body) values ('announcement', 'Quiet note');
reset role;
select test.assert((select count(*) = 2 from public.notifications where kind = 'event' and data ->> 'title' = 'Family meeting'),
  'both other members notified of the event');
select test.assert((select count(*) = 0 from public.notifications where kind = 'event' and user_id = :admin_id
  and data ->> 'title' = 'Family meeting'), 'creator not notified');
select test.assert((select count(*) = 2 from public.notifications where kind = 'announcement'), 'only announcements with notify are sent');
select test.assert((select count(*) = 1 from private.sms_outbox), 'one SMS queued: only the opted-in member');
-- Aisha's account is in Hausa.
select test.assert((select message like 'Iyalin Bua: Sabon taro - Family meeting, %Kano. Ka amsa a manhaja.' from private.sms_outbox),
  'SMS in the member''s language');

-- Members see only their own notifications and can mark them read.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert((select count(*) = (select count(*) from public.notifications where user_id = auth.uid())
  and count(*) > 0 from public.notifications), 'member sees only own notifications');
update public.notifications set read_at = now();
select test.expect_error($$update public.notifications set kind = 'birthday'$$, 'only read_at can change');
reset role;
select test.assert((select bool_and(read_at is not null) from public.notifications where user_id = :member_id), 'marked read');

-- Sending: queued → sending → sent.
select private.flush_sms();
select test.assert((select status = 'sending' and attempts = 1 from private.sms_outbox), 'SMS handed to pg_net');
select test.assert((select url = 'https://example.termii.test/api/sms/send' and body ->> 'api_key' = 'key-456'
  and body ->> 'to' = '2348031234567' and body ->> 'from' = 'BuaFamily' and body ->> 'channel' = 'generic'
  from net.sent_requests), 'Termii request is correct');
insert into net._http_response (id, status_code, content) select request_id, 200, '{"message":"Successfully Sent"}' from private.sms_outbox;
select private.flush_sms();
select test.assert((select status = 'sent' and sent_at is not null from private.sms_outbox), 'SMS marked sent');

-- A failed send is retried.
insert into private.sms_outbox (user_id, phone, message) values (:member_id, '2348031234567', 'retry me');
select private.flush_sms();
insert into net._http_response (id, status_code, content) select request_id, 400, 'Insufficient balance' from private.sms_outbox where message = 'retry me';
select private.flush_sms();
select test.assert((select status = 'sending' and attempts = 2 and error like '400%' from private.sms_outbox where message = 'retry me'),
  'failed SMS retried with the error kept');

-- Tags and comments notify the person concerned.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into public.posts (body) values ('Eid photos');
insert into public.post_people (post_id, person_id) values ((select id from public.posts where body = 'Eid photos'), (select id from test.ids where name='aisha'));
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.comments (post_id, body) values ((select id from public.posts where body = 'Eid photos'), 'Lovely');
reset role;
select test.assert((select count(*) = 1 from public.notifications where kind = 'tagged' and user_id = :member_id), 'tagged person notified');
select test.assert((select count(*) = 1 from public.notifications where kind = 'comment' and user_id = :admin_id and data ->> 'body' = 'Lovely'),
  'post author notified of a comment');

-- Daily reminders: birthdays and events tomorrow, never twice.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
update public.persons set birth_date = '1990-06-15', birth_date_approx = false, is_living = true
  where id = (select id from test.ids where name='ibrahim');
insert into public.events (title, starts_at, created_by) values ('Walima', timestamptz '2026-06-16 14:00 Africa/Lagos', :admin_id);
insert into public.event_rsvps (event_id, user_id, response) values ((select id from public.events where title = 'Walima'), :member_id, 'going');
select private.daily_reminders('2026-06-15');
select private.daily_reminders('2026-06-15');
select test.assert((select count(*) = 2 from public.notifications where kind = 'birthday'), 'birthday notice to the two other members, once');
select test.assert((select count(*) = 0 from public.notifications where kind = 'birthday' and user_id = :member2_id),
  'no birthday notice to the person themselves');
select test.assert((select (data ->> 'age')::int = 36 from public.notifications where kind = 'birthday' limit 1), 'age computed');
select test.assert((select count(*) = 1 from private.sms_outbox where message like 'Iyalin Bua: Yau ce ranar haihuwar Ibrahim Bua.%'), 'one birthday SMS');
select test.assert((select count(*) = 1 from public.notifications where kind = 'event_reminder' and user_id = :member_id), 'event reminder');
select test.assert((select count(*) = 1 from private.sms_outbox where message like 'Iyalin Bua: Tunatarwa: Walima gobe ne, 16/06, 14:00%'), 'event reminder SMS');

-- Opting out stops SMS.
update public.profiles set sms_opt_in = false where id = :member_id;
select private.daily_reminders('2027-06-15');
select test.assert((select count(*) = 1 from private.sms_outbox where message like '%haihuwar%'), 'no SMS after opting out');
select private.cleanup_old();

-- ---------------------------------------------------------------------------
-- 9. Blood donors.
-- ---------------------------------------------------------------------------
-- Aisha (member, O-) opts in as a donor and in to SMS; Ibrahim (member2, A+) opts in too.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.person_health (person_id, blood_group, genotype, visibility, blood_donor)
  values (public.my_person_id(), 'O-', 'AS', 'private', true)
  on conflict (person_id) do update set blood_group = 'O-', genotype = 'AS', visibility = 'private', blood_donor = true;
insert into public.person_contacts (person_id, city, visibility) values (public.my_person_id(), 'Kano', 'private')
  on conflict (person_id) do update set city = 'Kano', visibility = 'private';
update public.profiles set sms_opt_in = true where id = auth.uid();
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
insert into public.person_health (person_id, blood_group, blood_donor) values (public.my_person_id(), 'A+', true);
-- Other members see donors' blood group and town only, even when health and contact are private.
select test.assert((select count(*) = 2 from public.blood_donors()), 'two donors listed');
select test.assert((select blood_group = 'O-' and town = 'Kano' from public.blood_donors()
  where person_id = (select id from test.ids where name='aisha')), 'donor group and town visible');
select test.assert((select count(*) = 0 from public.person_health where person_id = (select id from test.ids where name='aisha')),
  'private health record itself stays hidden');

-- Ibrahim asks for A+ blood for his uncle Musa: Aisha (O-) can give, so she is told.
insert into public.blood_requests (blood_group, units, patient_person_id, hospital, contact_phone)
  values ('A+', 2, (select id from test.ids where name='musa'), 'ABUTH Zaria', '0803 000 1111');
select test.assert((select contact_phone = '2348030001111' from public.blood_requests), 'request phone normalised');
reset role;
select test.assert((select count(*) = 1 from public.notifications where kind = 'blood_request' and user_id = :member_id
  and data ->> 'patient' = 'Musa Bua'), 'compatible donor notified');
select test.assert((select count(*) = 0 from public.notifications where kind = 'blood_request' and user_id = :member2_id),
  'requester not notified of own request');
select test.assert((select count(*) = 1 from private.sms_outbox where dedupe_key like 'blood:%'
  and message like 'Iyalin Bua: Ana bukatar jini A+ (pint 2) don Musa Bua a ABUTH Zaria.%'), 'donor texted in Hausa');

-- A request for O- would not reach an A+ donor.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.blood_requests (blood_group, patient_name, hospital) values ('O-', 'A neighbour', 'AKTH Kano');
reset role;
select test.assert((select count(*) = 0 from public.notifications where kind = 'blood_request' and user_id = :member2_id),
  'incompatible donor not notified');

-- Aisha offers; Ibrahim hears about it. Others cannot close his request.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.blood_offers (request_id) values ((select id from public.blood_requests where hospital = 'ABUTH Zaria'));
update public.blood_requests set status = 'closed' where hospital = 'ABUTH Zaria';
select test.expect_error($$insert into public.blood_requests (blood_group, hospital) values ('O+', 'X')$$, 'request needs a patient');
reset role;
select test.assert((select count(*) = 1 from public.notifications where kind = 'blood_offer' and user_id = :member2_id),
  'requester told about the offer');
select test.assert((select status = 'open' from public.blood_requests where hospital = 'ABUTH Zaria'), 'only the requester can close');

-- The requester closes it; no more offers. Limit of 3 requests a day.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
update public.blood_requests set status = 'closed' where hospital = 'ABUTH Zaria';
insert into public.blood_requests (blood_group, patient_name, hospital) values ('B+', 'Two', 'H');
insert into public.blood_requests (blood_group, patient_name, hospital) values ('B+', 'Three', 'H');
select test.expect_error($$insert into public.blood_requests (blood_group, patient_name, hospital) values ('B+', 'Four', 'H')$$,
  'at most 3 requests a day');
reset role;
select test.assert((select status = 'closed' and closed_at is not null from public.blood_requests where hospital = 'ABUTH Zaria'),
  'requester closed the request');
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.expect_error($$insert into public.blood_offers (request_id) values ((select id from public.blood_requests where hospital = 'ABUTH Zaria'))$$,
  'no offers on a closed request');
reset role;

-- ---------------------------------------------------------------------------
-- 10. Memorial pages.
-- ---------------------------------------------------------------------------
-- Ibrahim asks to be reminded of Grandpa Ahmadu's anniversary (died 1 January 1990).
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
insert into public.remembrance_reminders (person_id) values ((select id from test.ids where name='grandpa'));
reset role;

-- Aisha writes a memory; Ibrahim is told. Memories are only for people who have died.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.memories (person_id, body) values ((select id from test.ids where name='grandpa'), 'He taught me to read.');
select test.expect_error(format($$insert into public.memories (person_id, body) values (%L, 'Hi')$$,
  (select id from test.ids where name='aisha')), 'no memorial memories for the living');
select test.assert((select count(*) = 0 from public.remembrance_reminders), 'reminder choices are private');
select test.assert((select count(*) = 1 from public.memories), 'members read memories');
reset role;
select test.assert((select count(*) = 1 from public.notifications where kind = 'memory' and user_id = :member2_id
  and data ->> 'body' = 'He taught me to read.'), 'subscriber told about a new memory');
select test.assert((select count(*) = 0 from public.notifications where kind = 'memory' and user_id = :member_id),
  'author not told about own memory');

-- Others cannot delete it; the author can.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
delete from public.memories;
reset role;
select test.assert((select count(*) = 1 from public.memories), 'others cannot delete a memory');

-- The anniversary reminder, once.
select private.remembrance_reminders('2026-01-01');
select private.remembrance_reminders('2026-01-01');
select private.remembrance_reminders('2026-01-02');
select test.assert((select count(*) = 1 from public.notifications where kind = 'remembrance' and user_id = :member2_id
  and (data ->> 'years')::int = 36), 'anniversary reminder sent once with the years');
select test.assert((select count(*) = 0 from public.notifications where kind = 'remembrance' and user_id <> :member2_id),
  'only those who asked are reminded');

select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
delete from public.memories;
reset role;
select test.assert((select count(*) = 0 from public.memories), 'author deleted own memory');

-- ---------------------------------------------------------------------------
-- 11. Notification preferences.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
update public.profiles set muted_notifications = array['tagged', 'blood_request'] where id = auth.uid();
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into public.posts (body) values ('Muted tag test');
insert into public.post_people (post_id, person_id) values ((select id from public.posts where body = 'Muted tag test'), (select id from test.ids where name='aisha'));
insert into public.blood_requests (blood_group, patient_name, hospital) values ('AB+', 'Muted test', 'H');
reset role;
select test.assert((select count(*) = 0 from public.notifications where user_id = :member_id and kind = 'tagged'
  and data ->> 'post_id' = (select id::text from public.posts where body = 'Muted tag test')), 'muted kind is not created');
select test.assert((select count(*) = 1 from public.notifications where user_id = :member_id and kind = 'blood_request'
  and data ->> 'patient' = 'Muted test'), 'blood requests cannot be muted');

-- ---------------------------------------------------------------------------
-- 12. Welfare fund.
-- ---------------------------------------------------------------------------
-- Admin makes Ibrahim (member2) treasurer; members can't make themselves one.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.admin_set_treasurer(%L, true)$$, :member_id), 'members cannot choose treasurers');
select test.expect_error($$update public.profiles set is_treasurer = true where id = auth.uid()$$, 'cannot self-appoint as treasurer');
select test.expect_error($$insert into public.fund_causes (title) values ('My open cause')$$, 'members cannot open causes directly');
insert into public.fund_causes (title, target_amount, status) values ('Help with rent', 50000, 'proposed');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select public.admin_set_treasurer(:member2_id, true);
update public.fund_settings set opening_balance = 100000, bank_name = 'Family Bank', account_number = '0123456789';
insert into public.fund_causes (title, target_amount, closes_on) values ('School fees', 600000, '2026-10-31');
reset role;
select test.assert((select count(*) = 1 from public.notifications where kind = 'fund_request' and user_id = :admin_id), 'committee told about a support request');

-- The treasurer sees the proposal; other members don't.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.assert(public.is_committee(), 'treasurer is on the committee');
select test.assert((select count(*) = 2 from public.fund_causes), 'committee sees proposals');
reset role;

-- Aisha records two contributions (one with a receipt) and stays anonymous on one.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.fund_contributions (cause_id, amount, method, show_name)
  values ((select id from public.fund_causes where title = 'School fees'), 20000, 'transfer', true);
insert into public.fund_contributions (cause_id, amount, method, show_name)
  values ((select id from public.fund_causes where title = 'School fees'), 5000, 'cash', false);
insert into storage.objects (bucket_id, name) values ('receipts', auth.uid() || '/r1.jpg');
select test.expect_error(format($$insert into storage.objects (bucket_id, name) values ('receipts', '%s/x.jpg')$$, :admin_id),
  'receipts only in own folder');
update public.fund_contributions set status = 'confirmed';
select test.expect_error($$insert into public.fund_contributions (amount, method, status) values (1, 'cash', 'confirmed')$$,
  'cannot record as already confirmed');
select test.assert((select count(*) = 1 from public.fund_causes where title = 'Help with rent'), 'requester sees own proposal');
reset role;
select test.assert((select count(*) = 0 from public.fund_contributions where status = 'confirmed'), 'members cannot confirm');
select test.assert((select count(*) = 4 from public.notifications where kind = 'fund_contribution'), 'committee (2) told about each of 2 contributions');

-- The treasurer confirms both.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
update public.fund_contributions set status = 'confirmed';
select test.assert((select count(*) = 1 from storage.objects where bucket_id = 'receipts'), 'committee can see receipts');
insert into public.fund_payouts (cause_id, amount, note) values ((select id from public.fund_causes where title = 'School fees'), 10000, 'Term fees');
reset role;
select test.assert((select bool_and(reviewed_by = :member2_id and reviewed_at is not null) from public.fund_contributions), 'review stamped');
select test.assert((select count(*) = 2 from public.notifications where kind = 'fund_confirmed' and user_id = :member_id), 'contributor told');

-- Everyone sees the balance and the cause's progress, not the amounts per person.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert(((public.fund_overview() ->> 'balance')::numeric = 115000), 'balance = opening + confirmed - payouts');
select test.assert((public.fund_overview() -> 'treasurers' ->> 0) = 'Ibrahim Bua', 'treasurer named');
select test.assert((public.fund_overview() ->> 'pending') is null, 'pending count only for the committee');
select test.assert((select raised = 25000 and contributors = 1 and names = array['Aisha Bua'] from public.fund_cause_totals()),
  'cause totals with listed names');
select test.assert((select count(*) = 0 from public.fund_payouts), 'payouts are committee-only');
reset role;

-- ---------------------------------------------------------------------------
-- 13. Mentorship and polls.
-- ---------------------------------------------------------------------------
-- Ibrahim offers to mentor; Aisha is looking for help and asks him.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
insert into public.mentors (areas) values ('Civil engineering · site work');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.mentee_requests (field, message) values ('Computer Science', 'Looking for internship advice.');
insert into public.mentor_asks (mentor_user_id, message) values (:member2_id, 'Could we talk about internships?');
select test.expect_error(format($$insert into public.mentors (user_id, areas) values (%L, 'x')$$, :admin_id), 'cannot list someone else as mentor');
reset role;
select test.assert((select count(*) = 1 from public.notifications where kind = 'mentor_request' and user_id = :member2_id), 'mentor told');

-- The admin can't read the ask; posting an opportunity tells the student.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.mentor_asks), 'asks are private to the two people');
insert into public.opportunities (title, url, deadline) values ('Postgraduate scholarship', 'https://example.org', '2026-11-30');
select test.expect_error($$insert into public.opportunities (title, url) values ('Bad', 'javascript:alert(1)')$$, 'only web links');
reset role;
select test.assert((select count(*) = 1 from public.notifications where kind = 'opportunity' and user_id = :member_id), 'student told about the opportunity');

-- Polls: Aisha asks; the others are told.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.polls (question, closes_at) values ('Where should the reunion be?', now() + interval '7 days');
insert into public.poll_options (poll_id, label, sort_order)
  select id, x.label, x.n from public.polls, (values ('Kano', 1), ('Kaduna', 2), ('Zaria', 3)) x(label, n)
  where question = 'Where should the reunion be?';
reset role;
select test.assert((select count(*) = 2 from public.notifications where kind = 'poll'), 'family told about the poll');

-- Ibrahim sees no counts until he votes, then sees them; he can change his vote.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.poll_results()), 'no results before voting');
insert into public.poll_votes (poll_id, option_id)
  select p.id, o.id from public.polls p join public.poll_options o on o.poll_id = p.id where o.label = 'Kaduna';
update public.poll_votes set option_id = (select id from public.poll_options where label = 'Kano');
select test.assert((select votes = 1 and total = 1 from public.poll_results() r join public.poll_options o on o.id = r.option_id
  where o.label = 'Kano'), 'results after voting, changed vote counted');
select test.expect_error($$insert into public.poll_options (poll_id, label) select id, 'Abuja' from public.polls$$,
  'only the creator adds options');
reset role;

-- The admin votes; Ibrahim can't see the admin's ballot.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into public.poll_votes (poll_id, option_id) select poll_id, id from public.poll_options where label = 'Zaria';
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 1 from public.poll_votes), 'ballots are secret');
reset role;

-- Closing ends voting; everyone then sees the results.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
update public.polls set closed = true;
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
update public.poll_votes set option_id = (select id from public.poll_options where label = 'Zaria');
reset role;
select test.assert((select o.label = 'Kano' from public.poll_votes v join public.poll_options o on o.id = v.option_id
  where v.user_id = :member2_id), 'no vote changes after closing');

-- ---------------------------------------------------------------------------
-- 14. Elders' stories, import and backups.
-- ---------------------------------------------------------------------------
-- Only admins record stories: Aisha cannot; Musa (admin) records one told by
-- her grandfather, and the others are told.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error(format($$insert into storage.objects (bucket_id, name) values ('stories', %L)$$,
  :member_id || '/kano.m4a'), 'members cannot upload story audio');
select test.expect_error(format($$insert into public.stories (title, speaker_name, audio_path) values ('Mine', 'Kaka', %L)$$,
  :member_id || '/kano.m4a'), 'members cannot record stories');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into storage.objects (bucket_id, name) values ('stories', :admin_id || '/kano.m4a');
select test.expect_error(format($$insert into storage.objects (bucket_id, name) values ('stories', %L)$$,
  :member_id || '/x.m4a'), 'audio only into your own folder');
insert into public.stories (title, speaker_id, language, audio_path, duration_seconds, source_note)
  values ('How the family came to Kano', (select id from test.ids where name = 'grandpa'), 'ha',
          :admin_id || '/kano.m4a', 760, 'Recorded 1979 on cassette');
select test.expect_error($$insert into public.stories (title, audio_path) values ('No speaker', 'x.m4a')$$,
  'a story needs a speaker');
reset role;
select test.assert((select count(*) = 2 from public.notifications where kind = 'story'), 'family told about the story');
select test.assert((select data ->> 'speaker' = 'Ahmadu Bua' from public.notifications where kind = 'story' limit 1),
  'notification names the speaker');

-- Ibrahim can listen but not change it.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 1 from public.stories), 'members see stories');
select test.assert((select count(*) = 1 from storage.objects where bucket_id = 'stories'), 'members can open the audio');
update public.stories set title = 'Changed';
select test.expect_error($$select public.admin_import('{}')$$, 'members cannot import');
select test.expect_error($$select public.admin_backup_now()$$, 'members cannot take backups');
reset role;
select test.assert((select title = 'How the family came to Kano' from public.stories), 'only the uploader or an admin edits');

-- Import: Musa is matched; his new son and wife are added, the duplicate link
-- to Aisha is ignored, and a third biological parent is skipped.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((
  select r = '{"people": 3, "parents": 2, "unions": 1, "skipped": 1}'::jsonb
  from public.admin_import(jsonb_build_object(
    'people', jsonb_build_array(
      jsonb_build_object('key', 'I1', 'id', (select id from test.ids where name = 'musa')),
      jsonb_build_object('key', 'I2', 'id', (select id from test.ids where name = 'aisha')),
      jsonb_build_object('key', 'I3', 'first_name', 'Bashir', 'last_name', 'Bua', 'sex', 'male', 'birth_date', '1985-04-02'),
      jsonb_build_object('key', 'I4', 'first_name', 'Amina', 'sex', 'female'),
      jsonb_build_object('key', 'I5', 'first_name', 'Rukayya', 'sex', 'female')),
    'parents', jsonb_build_array(
      jsonb_build_object('parent', 'I1', 'child', 'I3'),
      jsonb_build_object('parent', 'I4', 'child', 'I3'),
      jsonb_build_object('parent', 'I1', 'child', 'I2'),
      jsonb_build_object('parent', 'I5', 'child', 'I3'),
      jsonb_build_object('parent', 'I1', 'child', 'missing')),
    'unions', jsonb_build_array(jsonb_build_object('a', 'I1', 'b', 'I4'))
  )) r), 'import adds new people and links, skipping duplicates and impossible links');
select test.assert((select count(*) = 2 from public.parent_child pc join public.persons p on p.id = pc.child_id
  where p.first_name = 'Bashir'), 'Bashir has his two parents');

-- Backups: on demand, listed, and downloadable; switched off, the weekly job skips.
select test.assert((select public.admin_backup_now() is not null), 'backup taken');
select test.assert((select count(*) = 1 and min(size_bytes) > 0 from public.admin_backups()), 'backup listed');
select test.assert((select jsonb_array_length(public.admin_backup(slot) -> 'persons') = (select count(*) from public.persons)
  from public.admin_backups()), 'backup has every person');
select test.assert((select public.admin_backup(slot) -> 'stories' -> 0 ->> 'title' = 'How the family came to Kano'
  from public.admin_backups()), 'backup includes stories');
update public.app_settings set weekly_backup = false;
reset role;
select test.assert((select private.take_backup() is null), 'weekly backup can be switched off');
update public.app_settings set weekly_backup = true;

-- ---------------------------------------------------------------------------
-- 15. Restoring a backup.
-- ---------------------------------------------------------------------------
-- After the backup, Musa is renamed, Bashir deleted and the story removed.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
update public.persons set first_name = 'Musa-renamed' where first_name = 'Musa';
delete from public.persons where first_name = 'Bashir';
delete from public.stories;
create temp table restore_check as
  select (select slot from public.admin_backups() where slot >= 0 limit 1) as slot,
         (select count(*) from public.notifications) as notes;

-- A trial run reports what would come back and changes nothing.
select test.assert((
  select r -> 'persons' = '{"added": 1, "updated": 0, "skipped": 0}'::jsonb
     and (r -> 'parent_child' ->> 'added')::int = 2
     and (r -> 'stories' ->> 'added')::int = 1
  from public.admin_restore_backup((select slot from restore_check)) r), 'trial run counts');
select test.assert((select count(*) = 0 from public.persons where first_name = 'Bashir'), 'trial run changes nothing');
select test.assert((select count(*) = 0 from public.admin_backups() where slot = -1), 'no restore point from a trial');
select test.assert((
  select (r -> 'persons' ->> 'updated')::int = 1
  from public.admin_restore_backup((select slot from restore_check), true) r), 'trial run with undo counts the rename');

-- The real restore brings everything back, quietly, and keeps a restore point.
select public.admin_restore_backup((select slot from restore_check), true, false);
select test.assert((select count(*) = 1 from public.persons where first_name = 'Bashir'), 'deleted person back');
select test.assert((select count(*) = 2 from public.parent_child pc join public.persons p on p.id = pc.child_id
  where p.first_name = 'Bashir'), 'his parents back');
select test.assert((select count(*) = 1 from public.persons where first_name = 'Musa')
  and (select count(*) = 0 from public.persons where first_name = 'Musa-renamed'), 'edit undone');
select test.assert((select count(*) = 1 from public.stories), 'story back');
select test.assert((select count(*) from public.notifications) = (select notes from restore_check), 'restoring sends no notifications');
select test.assert((select count(*) = 1 from public.admin_backups() where slot = -1), 'restore point kept');
select test.assert((select (public.admin_backup((-1)::smallint) -> 'persons') @> '[{"first_name": "Musa-renamed"}]'),
  'restore point has the data from before');
-- Restoring again changes nothing.
select test.assert((select sum((v ->> 'added')::int + (v ->> 'updated')::int) = 0
  from jsonb_each(public.admin_restore_backup((select slot from restore_check), true)) e(k, v)), 'restore is repeatable');

-- Rows from accounts that no longer exist: optional links are cleared, the rest skipped.
select test.assert((
  select r -> 'persons' = '{"added": 1, "updated": 0, "skipped": 0}'::jsonb
     and r -> 'posts' = '{"added": 0, "updated": 0, "skipped": 1}'::jsonb
  from public.admin_restore(jsonb_build_object(
    'format', 'bua-family-backup',
    'persons', jsonb_build_array(jsonb_build_object('id', gen_random_uuid(), 'first_name', 'Hadiza',
                                                    'created_by', gen_random_uuid())),
    'posts', jsonb_build_array(jsonb_build_object('id', gen_random_uuid(), 'body', 'Old',
                                                  'author_id', gen_random_uuid()))
  ), false, false) r), 'unknown accounts handled');
select test.expect_error($$select public.admin_restore('{"persons": []}')$$, 'only Bua Family backups');
reset role;

select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error($$select public.admin_restore('{"format": "bua-family-backup"}')$$, 'members cannot restore');
select test.expect_error($$select public.admin_backup((-1)::smallint)$$, 'members cannot read the restore point');
reset role;

-- ---------------------------------------------------------------------------
-- 16. Push notifications.
-- ---------------------------------------------------------------------------
\set aisha_token '''aisha-phone-token-0123456789abcdef'''
\set shared_token '''shared-tablet-token-0123456789abcdef'''
-- Devices: a tablet moves to whoever signs in last; members see only their own.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select public.register_push_token(:shared_token, 'android');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select public.register_push_token(:shared_token, 'android');
select test.assert((select count(*) = 1 from public.push_tokens), 'Ibrahim sees his tablet');
select test.expect_error($$select public.admin_set_push('{}', 'https://x')$$, 'members cannot set up push');
select test.expect_error($$select public.push_config()$$, 'the Firebase key is not readable by members');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.push_tokens), 'the tablet moved to Ibrahim');
select public.register_push_token(:aisha_token, 'web');
delete from public.push_tokens where token = :shared_token;
reset role;
select test.assert((select count(*) = 2 from public.push_tokens), 'cannot remove someone else''s device');
-- (Accounts awaiting approval may register a device too: see section 18.)

-- Until an admin sets it up, nothing is sent.
create temp table push_check as select coalesce(max(id), 0) as before from net.sent_requests;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select public.send_test_push();
select test.expect_error($$select public.admin_set_push('not json', null)$$, 'rejects a file that is not JSON');
select test.expect_error($$select public.admin_set_push('{"type": "user"}', null)$$, 'rejects other JSON');
select test.expect_error($$select public.admin_set_push(null, 'http://insecure')$$, 'function address must be https');
select public.admin_set_push(
  '{"type": "service_account", "project_id": "bua-family", "client_email": "push@bua-family.iam.gserviceaccount.com", "private_key": "-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----\n"}',
  'https://example.supabase.co/functions/v1/push');
select test.assert((select (public.push_status() ->> 'enabled')::boolean and public.push_status() ->> 'project_id' = 'bua-family'
  and (public.push_status() ->> 'devices')::int = 2), 'push set up');
reset role;
select test.assert((select count(*) = 0 from net.sent_requests where id > (select before from push_check)),
  'nothing pushed before setup');

-- A new poll: one request, only for members with a device (not the asker).
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into public.polls (question) values ('Push test poll?');
reset role;
select test.assert((select count(*) = 1 from net.sent_requests where id > (select before from push_check)), 'one request per statement');
select test.assert((
  select r.url = 'https://example.supabase.co/functions/v1/push'
     and jsonb_array_length(r.body -> 'ids') = 2
     and r.headers ->> 'x-push-secret' = (select decrypted_secret from vault.decrypted_secrets where name = 'push_webhook_secret')
  from net.sent_requests r where r.id > (select before from push_check)), 'request names the notifications and carries the secret');

-- The Edge Function gets the text's language and the devices.
select format('%L', array(select jsonb_array_elements_text(r.body -> 'ids')
                          from net.sent_requests r where r.id > (select before from push_check))) as push_ids \gset
set role service_role;
select test.assert((
  select count(*) = 2 and bool_and(kind = 'poll') and bool_and(jsonb_array_length(tokens) = 1)
  from public.push_payloads(:push_ids::uuid[])
), 'payloads for the Edge Function');
select test.assert((select (public.push_config() -> 'service_account' ->> 'project_id') = 'bua-family'), 'service role reads the config');
select public.push_report(2);
select public.push_report(0, 'UNREGISTERED');
reset role;
select test.assert((select sent_7d = 2 and last_sent_at is not null from private.push_stats), 'push_report updates its row');

-- The browser's service worker confirms delivery without signing in.
set role anon;
select public.push_ack((:push_ids::uuid[])[1]);
reset role;
select test.assert((select count(*) = 1 from public.notifications where pushed_at is not null), 'delivery receipt recorded');

-- Muted kinds are not pushed.
update public.profiles set muted_notifications = '{poll}' where id in (:member_id, :member2_id);
truncate push_check;
insert into push_check select coalesce(max(id), 0) from net.sent_requests;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into public.polls (question) values ('Muted poll?');
select test.assert((select (public.push_status() ->> 'sent_7d')::int = 2 and public.push_status() ->> 'last_error' = 'UNREGISTERED'
  and (public.push_status() ->> 'received_7d')::int = 1), 'status shows what was sent and received');
reset role;
select test.assert((select count(*) = 0 from net.sent_requests where id > (select before from push_check)), 'muted kinds are not pushed');
update public.profiles set muted_notifications = '{}';

-- ---------------------------------------------------------------------------
-- 18. Sign-ups, suggestions and reviews reach the inbox.
-- ---------------------------------------------------------------------------
select test.assert((select count(*) = 1 from public.notifications
  where user_id = :admin_id and kind = 'account_request' and data ->> 'email' = 'aisha@example.com' and not data ? 'note'),
  'admins hear about a sign-up');
select test.assert((select count(*) = 1 from public.notifications
  where user_id = :admin_id and kind = 'account_request' and data ->> 'note' = 'Aisha, daughter of Musa'),
  'admins hear who a new account says they are');
select test.assert((select link = '/admin?tab=accounts' from public.notifications
  where user_id = :admin_id and kind = 'account_request' limit 1), 'sign-up opens the accounts tab');
select test.assert((select count(*) = 0 from public.notifications where kind = 'account_request' and user_id <> :admin_id),
  'only admins hear about sign-ups');
select test.assert((select count(*) = 1 from public.notifications where user_id = :member_id and kind = 'account_approved'),
  'the new member hears they were approved');
select test.assert((select count(*) = 3 from public.notifications where user_id = :admin_id and kind = 'change_request'
  and actor_id = :member_id), 'admins hear about each suggestion');
select test.assert((select count(*) = 1 from public.notifications where user_id = :admin_id and kind = 'change_request'
  and data ->> 'person' = 'Fatima' and data ->> 'name' is not null), 'a suggestion names who it adds and who asked');
select test.assert((select count(*) >= 1 from public.notifications where user_id = :member_id and kind = 'request_reviewed'
  and (data ->> 'approved')::boolean and link = '/my-requests'), 'the member hears their suggestion was approved');

-- A later note edit, or an admin's own suggestion, is not news.
update public.profiles set claim_note = 'Changed' where id = :pending_id;
update public.profiles set claim_note = 'Changed again' where id = :pending_id;
select test.assert((select count(*) = 1 from public.notifications where kind = 'account_request' and data ->> 'note' = 'Changed'),
  'first note announced once');
select test.assert((select count(*) = 0 from public.notifications where kind = 'account_request' and data ->> 'note' = 'Changed again'),
  'later note edits are quiet');

-- People waiting for approval can turn on notifications for their device.
select set_config('request.jwt.claims', json_build_object('sub', :pending_id)::text, false);
set role authenticated;
select public.register_push_token('pending-device-token-0123456789', 'web');
reset role;
select test.assert((select count(*) = 1 from public.push_tokens where user_id = :pending_id), 'pending account registers its device');
update public.profiles set status = 'suspended' where id = :pending_id;
select set_config('request.jwt.claims', json_build_object('sub', :pending_id)::text, false);
set role authenticated;
select test.expect_error($$select public.register_push_token('suspended-device-token-0123456789', 'web')$$,
  'suspended account cannot register a device');
reset role;

-- ---------------------------------------------------------------------------
-- 19. Comment notifications name the commenter and open the post.
-- ---------------------------------------------------------------------------
select test.assert((select data ->> 'name' like 'Aisha%' and link = '/posts/' || (select id from public.posts where body = 'Eid photos')
  from public.notifications where kind = 'comment' and user_id = :admin_id and data ->> 'body' = 'Lovely'),
  'comment notification names the commenter and opens the post');
select test.assert((select link like '/posts/%' from public.notifications where kind = 'tagged' and user_id = :member_id),
  'tag notification opens the post');
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into public.comments (post_id, body) values ((select id from public.posts where body = 'Eid photos'), 'Thank you');
reset role;
select test.assert((select count(*) = 1 from public.notifications where kind = 'comment' and user_id = :member_id
  and data ->> 'body' = 'Thank you' and (data ->> 'also')::boolean), 'earlier commenters hear about replies');
select test.assert((select count(*) = 0 from public.notifications where kind = 'comment' and user_id = :admin_id
  and data ->> 'body' = 'Thank you'), 'nobody is told about their own comment');

-- An unlinked member says which person they are: admins hear about it.
update public.profiles set person_id = null where id = :member2_id;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
update public.profiles set requested_person_id = (select id from test.ids where name='ibrahim') where id = auth.uid();
reset role;
select test.assert((select count(*) = 1 from public.notifications where user_id = :admin_id and kind = 'account_request'
  and data ->> 'person' is not null and actor_id = :member2_id), 'admins hear when a member says "this is me"');

-- ---------------------------------------------------------------------------
-- 20. Tree rules: birth order, no marrying within one line, removing links.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
-- Hauwa is Grandpa's wife; she cannot also become his granddaughter (via Sani).
select test.expect_error(format($$insert into public.parent_child (parent_id, child_id) values (%L, %L)$$,
  (select id from test.ids where name='sani'), (select id from test.ids where name='hauwa')), 'a wife cannot become a granddaughter');
select test.expect_error(format($$insert into public.unions (partner1_id, partner2_id) values (%L, %L)$$,
  (select id from test.ids where name='musa'), (select id from test.ids where name='aisha')), 'no marriage to your own child');
select test.expect_error(format($$insert into public.unions (partner1_id, partner2_id) values (%L, %L)$$,
  (select id from test.ids where name='aisha'), (select id from test.ids where name='grandpa')), 'no marriage to your grandparent');

-- Birth order is saved and two siblings with the same number are flagged.
select public.create_person_with_relation('{"first_name":"Halima","sex":"female","birth_order":2}',
  json_build_object('type','child','person_id',(select id from test.ids where name='musa'))::jsonb);
update public.persons set birth_order = 2 where id = (select id from test.ids where name='aisha');
select test.assert((select count(*) = 1 from jsonb_array_elements(public.tree_problems()) x where x ->> 'kind' = 'same_birth_order'),
  'siblings sharing a birth order are flagged');
update public.persons set birth_order = 1 where id = (select id from test.ids where name='aisha');
select test.assert((select count(*) = 0 from jsonb_array_elements(public.tree_problems()) x where x ->> 'kind' = 'same_birth_order'),
  'fixed birth order clears the problem');
update public.persons set birth_date = '2000-01-01' where id = (select id from test.ids where name='musa');
update public.persons set birth_date = '1995-01-01' where id = (select id from test.ids where name='aisha');
select test.assert((select count(*) >= 1 from jsonb_array_elements(public.tree_problems()) x where x ->> 'kind' = 'parent_younger' and x ->> 'b' = (select id::text from test.ids where name='aisha')),
  'a parent younger than their child is flagged');
update public.persons set birth_date = null where id in (select id from test.ids where name in ('musa', 'aisha'));

-- Admins remove a relationship directly; the people stay.
delete from public.parent_child where kind = 'adopted' and child_id = (select id from test.ids where name='aisha');
select test.assert((select count(*) = 0 from public.parent_child where kind = 'adopted'), 'admin removes a link');
reset role;

-- Members suggest removing one; approving it removes the link only.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error($$select public.tree_problems()$$, 'only admins check the tree');
insert into public.change_requests (kind, target_person_id, payload) values ('remove_union',
  (select id from test.ids where name='zainab'),
  json_build_object('partner1_id', (select id from test.ids where name='zainab'), 'partner2_id', (select id from test.ids where name='grandpa'))::jsonb);
delete from public.unions;
reset role;
select test.assert((select count(*) = 2 from public.unions where partner1_id = (select id from test.ids where name='grandpa')),
  'members cannot remove a marriage themselves');
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select public.review_change_request((select id from public.change_requests where kind = 'remove_union'), true);
reset role;
select test.assert((select count(*) = 0 from public.unions u where (select id from test.ids where name='zainab') in (u.partner1_id, u.partner2_id)),
  'approved removal deletes the marriage');
select test.assert((select count(*) = 1 from public.persons where first_name = 'Zainab'), 'the person stays');
select test.assert((select count(*) = 1 from public.notifications where kind = 'request_reviewed' and data ->> 'request_kind' = 'remove_union'),
  'the member hears the removal was approved');

-- ---------------------------------------------------------------------------
-- 21. Publishing an Android update.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error($$select public.admin_publish_android(5, '1.0.5', 'bua-family.apk')$$, 'members cannot publish the app');
select test.expect_error($$insert into storage.objects (bucket_id, name) values ('releases', 'bua-family.apk')$$, 'members cannot upload releases');
select test.assert((select public.android_release() is null), 'nothing published yet');
select public.register_push_token('aisha-android-token-0123456789', 'android');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into storage.objects (bucket_id, name) values ('releases', 'bua-family.apk');
select public.admin_publish_android(5, '1.0.5', 'bua-family.apk', 'Photos in the tree');
select test.expect_error($$select public.admin_publish_android(4, '1.0.4', 'bua-family.apk')$$, 'cannot publish an older build');
reset role;
set role anon;
select test.assert((select (public.android_release() ->> 'build')::int = 5 and public.android_release() ->> 'path' = 'bua-family.apk'),
  'anyone can see the latest build');
reset role;
select test.assert((select count(*) = 1 from public.notifications where kind = 'app_update' and user_id = :member_id
  and link = '/get-app' and data ->> 'version' = '1.0.5'), 'Android users hear about the update');
select test.assert((select count(*) = 0 from public.notifications n where kind = 'app_update'
  and not exists (select 1 from public.push_tokens t where t.user_id = n.user_id and t.platform = 'android')),
  'people without the Android app are not told');

-- ---------------------------------------------------------------------------
-- 22. Activity and the admin's users list.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select public.touch_activity('android', 250);
select public.touch_activity('android', 250);
select test.expect_error($$select public.admin_users()$$, 'members cannot list accounts');
select test.assert((select count(*) = 0 from public.activity_days), 'members cannot read activity');
reset role;
select test.assert((select count(*) = 1 from public.activity_days where user_id = :member_id and platform = 'android'),
  'one activity row per day and platform');
select test.assert((select last_platform = 'android' and app_build = 250 and last_seen_at is not null
  from public.profiles where id = :member_id), 'last seen, platform and app build recorded');
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select (u ->> 'active_days_30')::int = 1 and u ->> 'person_name' like 'Aisha%'
    and (u -> 'devices' ->> 'android')::int >= 1 and (u ->> 'comments')::int >= 1
  from jsonb_array_elements(public.admin_users()) u where u ->> 'id' = :member_id),
  'admins see each account with its person, devices and activity');
reset role;

-- ---------------------------------------------------------------------------
-- 23. Phone sign-in and invite links.
-- ---------------------------------------------------------------------------
\set phone_id '''00000000-0000-0000-0000-0000000000f1'''
insert into auth.users (id, phone, raw_user_meta_data) values (:phone_id, '2348031112222', '{"locale": "ha"}');
select test.assert((select display_name = '+2348031112222' and phone = '2348031112222' and status = 'pending'
  from public.profiles where id = :phone_id), 'a phone sign-up gets its number as name and phone');

update public.app_settings set sms_enabled = true, sms_sender_id = 'BuaFamily';
select public.send_sms_hook('{"user": {"phone": "2348031112222", "user_metadata": {"locale": "ha"}}, "sms": {"otp": "123456"}}');
select test.assert((select count(*) = 1 from private.sms_outbox where phone = '2348031112222' and message like '%123456%'
  and message like 'Lambar shiga%'), 'the sign-in code is queued for Termii in the member''s language');
update public.app_settings set sms_enabled = false;
select test.assert((select public.send_sms_hook('{"user": {"phone": "2348031112222"}, "sms": {"otp": "1"}}') ? 'error'),
  'without SMS set up the hook says so');

select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into test.ids values ('zara', public.create_person_with_relation('{"first_name":"Zara","last_name":"Bua","sex":"female"}'));
insert into public.invites (code, person_id) values ('welcome123', (select id from test.ids where name = 'zara'));
insert into public.invites (code, expires_at) values ('oldlink123', now() - interval '1 day');
reset role;
set role anon;
select test.assert((select (public.invite_info('welcome123') ->> 'valid')::boolean
  and public.invite_info('welcome123') ->> 'person' = 'Zara Bua'), 'anyone can see who an invite is for');
select test.assert((select count(*) = 0 from public.invites), 'invites themselves are private');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :phone_id)::text, false);
set role authenticated;
select test.expect_error($$select public.redeem_invite('oldlink123')$$, 'expired invites cannot be used');
select test.expect_error($$insert into public.invites (code) values ('mine')$$, 'members cannot create invites');
select public.redeem_invite('WELCOME123');
reset role;
select test.assert((select status = 'active' and person_id = (select id from test.ids where name = 'zara')
  from public.profiles where id = :phone_id), 'an invite approves the account and links it to the person');
select set_config('request.jwt.claims', json_build_object('sub', :pending_id)::text, false);
set role authenticated;
select test.expect_error($$select public.redeem_invite('welcome123')$$, 'an invite works once');
reset role;

-- ---------------------------------------------------------------------------
-- 24. Admin metrics.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error($$select public.admin_metrics(array['comments'], (now() at time zone 'Africa/Lagos')::date - 7, (now() at time zone 'Africa/Lagos')::date)$$, 'members cannot see metrics');
select test.expect_error($$select public.admin_snapshot()$$, 'members cannot see the snapshot');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select jsonb_array_length(m -> 'buckets') = 8
    and jsonb_array_length(m -> 'series' -> 'comments') = 8
    and (m -> 'totals' ->> 'comments')::int >= 2
    and (m -> 'totals' ->> 'active_members')::int >= 1
    and (m -> 'previous' ->> 'comments')::int = 0
  from public.admin_metrics(array['comments', 'active_members', 'money_in'], (now() at time zone 'Africa/Lagos')::date - 7, (now() at time zone 'Africa/Lagos')::date) m),
  'daily series, totals and the previous period for any metrics');
select test.assert((select jsonb_array_length(m -> 'buckets') between 1 and 2
  from public.admin_metrics(array['comments'], (now() at time zone 'Africa/Lagos')::date - 7, (now() at time zone 'Africa/Lagos')::date, 'month') m), 'monthly buckets');
select test.assert((select (m -> 'totals' ->> 'active_members')::int >= 1
  from public.admin_metrics(array['active_members'], (now() at time zone 'Africa/Lagos')::date - 7, (now() at time zone 'Africa/Lagos')::date, 'day', 'android') m),
  'filter by platform');
select test.assert((select (m -> 'totals' ->> 'active_members')::int = 0
  from public.admin_metrics(array['active_members'], (now() at time zone 'Africa/Lagos')::date - 7, (now() at time zone 'Africa/Lagos')::date, 'day', 'web') m),
  'platform filter excludes others');
select test.assert((select jsonb_array_length(b) >= 1 and bool_and(e ->> 'label' <> '')
  from public.admin_metric_breakdown('comments', (now() at time zone 'Africa/Lagos')::date - 7, (now() at time zone 'Africa/Lagos')::date, 'member') b,
       jsonb_array_elements(b) e group by b), 'every top member has a name, linked or not');
select test.assert((select jsonb_array_length(b) >= 1 and b -> 0 ->> 'label' <> ''
  from public.admin_metric_breakdown('comments', (now() at time zone 'Africa/Lagos')::date - 7, (now() at time zone 'Africa/Lagos')::date, 'member') b), 'top members for a metric');
select test.assert((select (s ->> 'accounts')::int >= 3 and (s ->> 'people')::int >= 7 and s ? 'branches'
  from public.admin_snapshot() s), 'snapshot of accounts and the tree');
select test.expect_error($$select public.admin_metrics(array['comments'], (now() at time zone 'Africa/Lagos')::date, (now() at time zone 'Africa/Lagos')::date - 1)$$, 'the period must make sense');
reset role;

-- ---------------------------------------------------------------------------
-- 25. Mentorship conversations.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
insert into public.mentors (areas) values ('Civil engineering') on conflict (user_id) do nothing;
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.mentor_asks (mentor_user_id, message) values (:member2_id, 'Which courses should I take?');
reset role;
select id as convo_ask from public.mentor_asks where message = 'Which courses should I take?' \gset
select test.assert((select last_message = 'Which courses should I take?' and asker_read_at is not null and mentor_read_at is null
  from public.mentor_asks where id = :'convo_ask'), 'a new ask starts the conversation');
select test.assert((select link = '/mentors/ask/' || :'convo_ask' from public.notifications
  where kind = 'mentor_request' and data ->> 'ask_id' = :'convo_ask'), 'the mentor is linked to the conversation');

-- Ibrahim (the mentor) replies; Aisha is told who wrote.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
insert into public.mentor_messages (ask_id, body) values (:'convo_ask', 'Start with statics and surveying.');
select public.mark_mentor_ask_read(:'convo_ask');
reset role;
select test.assert((select count(*) = 1 from public.notifications
  where kind = 'mentor_reply' and user_id = :member_id and (data ->> 'from_mentor')::boolean
    and link = '/mentors/ask/' || :'convo_ask'), 'the asker is told about the reply');
select test.assert((select last_message_by = :member2_id and mentor_read_at is not null
  and asker_read_at < last_message_at from public.mentor_asks where id = :'convo_ask'), 'unread for the asker');

-- Aisha answers and reads it.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 1 from public.mentor_messages where ask_id = :'convo_ask'), 'the asker reads the reply');
insert into public.mentor_messages (ask_id, body) values (:'convo_ask', 'Thank you!');
select test.expect_error(format($$insert into public.mentor_messages (ask_id, body, author_id) values (%L, 'x', %L)$$,
  :'convo_ask', :member2_id), 'cannot write as someone else');
select test.expect_error(format($$insert into public.mentor_messages (ask_id, body) values (%L, '   ')$$, :'convo_ask'),
  'no empty messages');
reset role;
select test.assert((select count(*) = 1 from public.notifications
  where kind = 'mentor_reply' and user_id = :member2_id and not (data ->> 'from_mentor')::boolean), 'the mentor is told');

-- Nobody else can read or write.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.mentor_messages), 'conversations are private, even from admins');
select test.expect_error(format($$insert into public.mentor_messages (ask_id, body) values (%L, 'Hello')$$, :'convo_ask'),
  'outsiders cannot write');
select public.mark_mentor_ask_read(:'convo_ask');
reset role;
select test.assert((select count(*) = 2 from public.mentor_messages where ask_id = :'convo_ask'), 'both messages kept');

-- ---------------------------------------------------------------------------
-- 26. Who is online, and the activity log.
-- ---------------------------------------------------------------------------
-- Aisha opens the app on the tree page, then a person's page.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select public.log_session('sign_in', 'android');
select public.touch_presence('/tree', 'android');
select public.touch_presence('/tree', 'android');
select public.touch_presence('/person/x', 'android');
select test.expect_error($$select public.admin_online()$$, 'members cannot see who is online');
select test.expect_error($$select public.admin_activity()$$, 'members cannot see the log');
select test.expect_error($$select count(*) from public.activity_log$$, 'members cannot read the log directly');
select test.assert((select count(*) = 0 from public.presence), 'members cannot see presence');
-- A change she makes is logged with what it was.
insert into public.posts (body) values ('Activity log test moment');
reset role;
select test.assert((select count(*) = 1 from public.activity_log
  where user_id = :member_id and action = 'open' and entity = 'session' and platform = 'android'), 'one visit, not one per beat');
select test.assert((select array_agg(target order by id) = array['/tree', '/person/x'] from public.activity_log
  where user_id = :member_id and action = 'view'), 'each page change is logged once');
select test.assert((select count(*) = 1 from public.activity_log
  where user_id = :member_id and action = 'sign_in'), 'sign-in logged');
select test.assert((select detail ->> 'label' = 'Activity log test moment' and platform = 'android'
  from public.activity_log where entity = 'posts' and action = 'insert' and user_id = :member_id
  order by id desc limit 1), 'changes are logged with a label and platform');

-- The admin sees her online, on the person page, and the log.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select (e ->> 'online')::boolean and e ->> 'page' = '/person/x' and e ->> 'platform' = 'android'
  from jsonb_array_elements(public.admin_online()) e where e ->> 'user_id' = :member_id), 'admin sees who is online');
select test.assert((select jsonb_array_length(public.admin_activity(p_user => :member_id, p_actions => array['view'])) = 2),
  'filter by member and action');
select test.assert((select public.admin_activity(p_search => 'log test') -> 0 ->> 'entity' = 'posts'), 'search by label');
select test.assert((select jsonb_array_length(public.admin_activity(p_limit => 1)) = 1), 'paged');
reset role;

-- Private conversations are logged without content; quiet updates are not logged.
select test.assert((select bool_and(detail = '{}'::jsonb) from public.activity_log
  where entity in ('mentor_asks', 'mentor_messages')), 'mentorship content is not logged');
select count(*) as log_before from public.activity_log \gset
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select public.touch_activity('android', 5);
select public.leave_presence();
reset role;
select test.assert((select count(*) = :log_before from public.activity_log), 'last-seen updates are not logged');
select test.assert((select seen_at < now() - interval '2 minutes' from public.presence where user_id = :member_id),
  'leaving takes her offline');
-- System changes (no one signed in) are not logged.
select set_config('request.jwt.claims', '{}', false);
update public.persons set biography = 'Updated by the system' where id = (select id from public.persons limit 1);
select test.assert((select count(*) = :log_before from public.activity_log), 'system changes are not logged');

-- ---------------------------------------------------------------------------
-- 27. Password reset by SMS.
-- ---------------------------------------------------------------------------
update public.app_settings set sms_enabled = true, sms_sender_id = 'BuaFamily';
update public.profiles set phone = '2348035550001' where id = :member_id;
update auth.users set email = 'aisha@example.com', encrypted_password = 'old' where id = :member_id;
select count(*) as sms_before from private.sms_outbox \gset

set role anon;
select test.assert((select public.request_password_reset_sms('0803 555 0001') ->> 'ok' = 'true'), 'a code is sent');
select test.assert((select public.request_password_reset_sms('0803 555 0001') ->> 'reason' = 'too_many'),
  'one code a minute');
select test.assert((select public.request_password_reset_sms('0809 999 9999') ->> 'ok' = 'true'),
  'unknown numbers get the same answer');
reset role;
select test.assert((select count(*) = :sms_before + 1 from private.sms_outbox), 'only the member gets a text');
select test.assert((select message ~ ': [0-9]{6}\. ' from private.sms_outbox
  where phone = '2348035550001' order by id desc limit 1), 'the text carries a 6-digit code');
select test.assert((select code_hash not like '%' || substring(o.message from '[0-9]{6}') || '%'
  from private.password_resets r, private.sms_outbox o
  where r.phone = '2348035550001' and o.phone = r.phone order by o.id desc limit 1), 'the code is stored hashed');
-- Make the code known for the test.
update private.password_resets set code_hash = extensions.crypt('123456', extensions.gen_salt('bf'))
  where phone = '2348035550001';

set role anon;
select test.assert((select public.reset_password_with_sms('08035550001', '123456', 'short') ->> 'reason' = 'weak_password'),
  'passwords need 8 characters');
select test.assert((select public.reset_password_with_sms('08035550001', '000000', 'new-password-1') ->> 'reason' = 'wrong_code'),
  'wrong code refused');
select test.assert((select public.reset_password_with_sms('08035550001', '123456', 'new-password-1') ->> 'email' = 'aisha@example.com'),
  'right code sets the password and returns the email');
select test.assert((select public.reset_password_with_sms('08035550001', '123456', 'another-pass') ->> 'reason' = 'expired'),
  'a code works once');
select test.expect_error($$select count(*) from private.password_resets$$, 'codes are not readable');
reset role;
select test.assert((select encrypted_password = extensions.crypt('new-password-1', encrypted_password)
  from auth.users where id = :member_id), 'the new password is stored as a bcrypt hash');

-- Five wrong tries end the code.
update private.password_resets set created_at = created_at - interval '2 minutes';
set role anon;
select public.request_password_reset_sms('08035550001');
select public.reset_password_with_sms('08035550001', '000001', 'whatever-123') from generate_series(1, 5);
reset role;
update private.password_resets set code_hash = extensions.crypt('654321', extensions.gen_salt('bf'))
  where phone = '2348035550001' and used_at is null;
set role anon;
select test.assert((select public.reset_password_with_sms('08035550001', '654321', 'whatever-123') ->> 'reason' = 'expired'),
  'locked after five wrong tries');
reset role;
update public.app_settings set sms_enabled = false;
set role anon;
select test.assert((select public.request_password_reset_sms('08035550001') ->> 'reason' = 'sms_off'), 'needs SMS set up');
reset role;

-- Google accounts get Google's name.
insert into auth.users (id, email, raw_user_meta_data)
  values ('00000000-0000-0000-0000-0000000000ee', 'zainab.bua@gmail.com', '{"full_name": "Zainab Bua", "avatar_url": "x"}');
select test.assert((select display_name = 'Zainab Bua' and status = 'pending' from public.profiles
  where id = '00000000-0000-0000-0000-0000000000ee'), 'Google sign-ups use their Google name');

-- ---------------------------------------------------------------------------
-- 28. Hijri dates and Islamic greetings.
-- ---------------------------------------------------------------------------
select test.assert((select (year, month, day) = (1448, 4, 21) from private.hijri('2026-10-04')), 'same Hijri date as the app');
select test.assert((select (year, month, day) = (1447, 10, 1) from private.hijri('2026-03-19', 1)), 'offset follows the moon sighting');
select count(*) as occ_before from public.notifications where kind = 'occasion' \gset
select count(*) as active_members from public.profiles where status = 'active' \gset
select test.assert((select private.islamic_greetings('2026-10-04') = 0), 'an ordinary day sends nothing');
select test.assert((select private.islamic_greetings('2026-03-19') = :active_members), 'Eid is expected tomorrow');
select test.assert((select private.islamic_greetings('2026-03-20') = :active_members), 'Eid Mubarak on the day');
select test.assert((select private.islamic_greetings('2026-03-20') = 0), 'only once');
select test.assert((select count(*) = :occ_before + 2 * :active_members from public.notifications where kind = 'occasion'),
  'one notice and one greeting each');
select test.assert((select data ->> 'occasion' = 'eid_al_fitr' and (data ->> 'eve')::boolean = false
  and (data ->> 'hijri_year')::int = 1447 from public.notifications where kind = 'occasion' order by created_at desc, id limit 1),
  'the greeting names the occasion');
update public.app_settings set islamic_greetings = false;
select test.assert((select private.islamic_greetings('2026-05-27') = 0), 'admins can turn greetings off');
update public.app_settings set islamic_greetings = true, hijri_offset = 1;
select test.assert((select private.islamic_greetings('2026-05-26') = :active_members), 'with the offset, Eid al-Adha a day earlier');
update public.app_settings set hijri_offset = 0;

-- ---------------------------------------------------------------------------
-- 29. Dues and fund reports.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error($$insert into public.fund_dues_plans (title, amount) values ('Mine', 10)$$,
  'only the committee creates dues');
reset role;

select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into public.fund_dues_plans (title, amount, period, starts_on) values ('Monthly dues', 2000, 'monthly', '2026-01-01');
select id as plan_id from public.fund_dues_plans where title = 'Monthly dues' \gset
insert into public.fund_dues_members (plan_id, user_id, starts_on) values (:'plan_id', :member_id, '2026-08-01');
insert into public.fund_dues_members (plan_id, user_id, exempt, note) values (:'plan_id', :member2_id, true, 'Student');
reset role;

select test.assert((select periods_due = 3 and owed = 6000 and owed_periods = 3 and paid_through is null
  and next_due = '2026-08-01' from private.dues_rows('2026-10-15') where plan_id = :'plan_id' and user_id = :member_id),
  'owes August to October');
select test.assert((select owed = 0 from private.dues_rows('2026-10-15') where plan_id = :'plan_id' and user_id = :member2_id),
  'exempt members owe nothing');

-- Aisha pays part; it counts once confirmed.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.fund_contributions (amount, method, dues_plan_id) values (3000, 'transfer', :'plan_id');
select test.expect_error(format($$insert into public.fund_contributions (amount, method, dues_plan_id, cause_id)
  values (10, 'cash', %L, (select id from public.fund_causes limit 1))$$, :'plan_id'), 'dues or a cause, not both');
select test.expect_error($$select public.fund_dues_status(true)$$, 'members see only their own dues');
select test.assert((select jsonb_array_length(public.fund_dues_status()) = 1
  and public.fund_dues_status() -> 0 ->> 'user_id' = :member_id), 'a member sees their standing');
reset role;
select test.assert((select pending = 3000 and owed = 6000 from private.dues_rows('2026-10-15')
  where plan_id = :'plan_id' and user_id = :member_id), 'pending payments are not counted yet');

select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
update public.fund_contributions set status = 'confirmed' where dues_plan_id = :'plan_id' and user_id = :member_id;
reset role;
select test.assert((select owed = 3000 and owed_periods = 2 and paid_through = '2026-08-01' and next_due = '2026-09-01'
  from private.dues_rows('2026-10-15') where plan_id = :'plan_id' and user_id = :member_id), 'part paid');

-- The treasurer records cash collected from her: confirmed at once, she is told.
select count(*) as confirmed_before from public.notifications where kind = 'fund_confirmed' and user_id = :member_id \gset
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select public.fund_record_for(:member_id, 5000, 'cash', null, :'plan_id');
select test.assert((select jsonb_array_length(public.fund_dues_status(true)) >= 3), 'the committee sees everyone');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.fund_record_for(%L, 100, 'cash', null, %L)$$, :member_id, :'plan_id'),
  'members cannot record for others');
reset role;
select test.assert((select count(*) = :confirmed_before + 1 from public.notifications
  where kind = 'fund_confirmed' and user_id = :member_id), 'told it was recorded');
select test.assert((select owed = 0 and paid = 8000 and paid_through = '2026-11-01'
  from private.dues_rows('2026-10-15') where plan_id = :'plan_id' and user_id = :member_id), 'paid ahead to November');

-- Reminders on the first day of a period, to those who owe.
select test.assert((select private.dues_reminders('2026-11-02') = 0), 'no reminders mid-period');
select private.dues_reminders('2026-11-01');
select test.assert((select count(*) = 0 from public.notifications where kind = 'dues_reminder' and user_id in (:member_id, :member2_id)),
  'paid-up and exempt members are not reminded');
select test.assert((select (data ->> 'owed')::numeric > 0 from public.notifications
  where kind = 'dues_reminder' and user_id = :admin_id limit 1), 'those who owe are reminded with the amount');
select test.assert((select private.dues_reminders('2026-11-01') = 0), 'once per period');
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.fund_dues_remind(%L)$$, :'plan_id'), 'members cannot send reminders');
reset role;

-- Reports: everyone sees totals; the committee also sees every transaction.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select public.fund_report(current_date - 30, current_date + 1) as member_report \gset
reset role;
select test.assert((select (:'member_report'::jsonb -> 'transactions') = 'null'::jsonb
  and (:'member_report'::jsonb -> 'dues') = 'null'::jsonb), 'members get totals only');
select test.assert((select (r ->> 'closing')::numeric = (r ->> 'opening')::numeric + (r ->> 'in')::numeric - (r ->> 'out')::numeric
  from (select :'member_report'::jsonb as r) x), 'closing = opening + in - out');
select test.assert((select (s ->> 'in')::numeric = 8000 from jsonb_array_elements(:'member_report'::jsonb -> 'sources') s
  where s ->> 'kind' = 'dues'), 'dues appear as a source');
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select jsonb_array_length(r -> 'transactions') = (r ->> 'payments')::int
    + (select count(*) from public.fund_payouts where paid_on between current_date - 30 and current_date + 1)
  and (r -> 'dues' -> 0 ->> 'title') = 'Monthly dues'
  from (select public.fund_report(current_date - 30, current_date + 1) r) x), 'the committee sees every transaction and dues');
select test.expect_error($$select public.fund_report('2026-02-01', '2026-01-01')$$, 'a period must run forwards');
reset role;
select test.assert((select private.backup_data() ? 'fund_dues_plans'), 'backups include dues plans');

-- ---------------------------------------------------------------------------
-- 30. Reviewing "This is me" claims.
-- ---------------------------------------------------------------------------
-- Ibrahim (active, not linked) says he is Ahmadu Bua; then someone else.
update public.profiles set person_id = null, requested_person_id = null where id = :member2_id;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
update public.profiles set requested_person_id = (select id from test.ids where name = 'grandpa') where id = :member2_id;
reset role;
select test.assert((select link = '/admin?tab=accounts&filter=claims' from public.notifications
  where kind = 'account_request' and user_id = :admin_id and actor_id = :member2_id order by created_at desc limit 1),
  'admins are taken to the claims');

-- Declined, with a reason: the request is cleared and he is told.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.admin_decline_claim(%L)$$, :member2_id), 'only admins review claims');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select public.admin_decline_claim(:member2_id, 'Ahmadu passed in 1990; please pick your own name');
reset role;
select test.assert((select requested_person_id is null from public.profiles where id = :member2_id), 'claim cleared');
select test.assert((select (data ->> 'approved')::boolean = false and data ->> 'person' = 'Ahmadu Bua'
  and data ->> 'reason' like 'Ahmadu passed%' from public.notifications
  where kind = 'claim_reviewed' and user_id = :member2_id order by created_at desc limit 1), 'told it was declined, and why');

-- He claims again and the admin confirms by linking: he is told.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
update public.profiles set requested_person_id = (select id from test.ids where name = 'grandpa') where id = :member2_id;
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select public.admin_update_account(:member2_id, p_person_id => (select id from test.ids where name = 'grandpa'));
reset role;
select test.assert((select person_id = (select id from test.ids where name = 'grandpa') and requested_person_id is null
  from public.profiles where id = :member2_id), 'linked and the request cleared');
select test.assert((select (data ->> 'approved')::boolean and link like '/person/%' from public.notifications
  where kind = 'claim_reviewed' and user_id = :member2_id order by created_at desc limit 1), 'told he is linked');
-- Put things back for the sections after.
update public.profiles set person_id = null where id = :member2_id;

-- ---------------------------------------------------------------------------
-- 31. Search everything.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.posts (body) values ('Barka da Sallah daga gidan ɗan uwa Musa, mun gode 100% sosai');
select test.assert((select count(*) >= 1 from public.search_all('dan uwa') where kind = 'post'), 'Hausa letters match plain letters');
select test.assert((select snippet like '%ɗan uwa%' from public.search_all('dan uwa') where kind = 'post' limit 1),
  'the snippet shows the original text');
select test.assert((select count(*) = 0 from public.search_all('%')), 'wildcards are taken literally, and 1 letter is too short');
select test.assert((select count(*) >= 1 from public.search_all('100%') where kind = 'post'), 'a literal % still matches');
select test.assert((select count(*) >= 1 from public.search_all('Postgraduate') where kind = 'opportunity'),
  'finds opportunities');
select test.assert((select link like '/posts/%' from public.search_all('sallah daga') limit 1), 'results link to their page');
reset role;
-- Private things stay private: a conversation message is not searchable at all;
-- a proposed cause shows only to its author and the committee.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.fund_causes (title, status) values ('Zebra private rent help', 'proposed');
select test.assert((select count(*) = 1 from public.search_all('zebra private') where kind = 'cause'), 'the author finds their request');
reset role;
update public.profiles set is_treasurer = false where id = :member2_id;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.search_all('zebra private')), 'other members do not');
reset role;
update public.profiles set is_treasurer = true where id = :member2_id;
set role anon;
select test.expect_error($$select * from public.search_all('sallah')$$, 'not for anonymous visitors');
reset role;

-- ---------------------------------------------------------------------------
-- 32. Backups include votes, likes, conversations and invites.
-- ---------------------------------------------------------------------------
select test.assert((select private.backup_data() ?& array['poll_votes', 'likes', 'invites']),
  'backups include votes, likes and invites');
select test.assert((select not (private.backup_data() ?| array['mentor_asks', 'mentor_messages'])),
  'private mentorship conversations are not in backups');

-- ---------------------------------------------------------------------------
-- 33. Blood family, married in, men and women.
-- ---------------------------------------------------------------------------
reset role;
create temp table lin (k text primary key, id uuid not null default gen_random_uuid());
insert into lin (k) values ('founder'), ('wife'), ('son'), ('daughter_in_law'), ('grandchild'), ('stepchild'),
  ('son_in_law'), ('daughter'), ('loner');
insert into public.persons (id, first_name, sex)
select id, 'Lin ' || k, case when k in ('founder', 'son', 'son_in_law') then 'male'
                             when k in ('wife', 'daughter_in_law', 'daughter') then 'female'
                             else 'unknown' end::public.sex from lin;
insert into public.unions (partner1_id, partner2_id) values
  ((select id from lin where k = 'founder'), (select id from lin where k = 'wife')),
  ((select id from lin where k = 'son'), (select id from lin where k = 'daughter_in_law')),
  ((select id from lin where k = 'son_in_law'), (select id from lin where k = 'daughter'));
insert into public.parent_child (parent_id, child_id, kind) values
  ((select id from lin where k = 'founder'), (select id from lin where k = 'son'), 'biological'),
  ((select id from lin where k = 'wife'), (select id from lin where k = 'son'), 'biological'),
  ((select id from lin where k = 'founder'), (select id from lin where k = 'daughter'), 'biological'),
  ((select id from lin where k = 'son'), (select id from lin where k = 'grandchild'), 'biological'),
  ((select id from lin where k = 'son'), (select id from lin where k = 'stepchild'), 'step');
select test.assert((select string_agg(lin.k || '=' || g.lineage, ',' order by lin.k)
    from lin join private.person_lineage() g on g.person_id = lin.id)
  = 'daughter=blood,daughter_in_law=married_in,founder=blood,grandchild=blood,loner=other,son=blood,'
    || 'son_in_law=married_in,stepchild=other,wife=married_in', 'who is blood family and who married in');
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select (s -> 'composition' -> 'blood' ->> 'male')::int >= 2
    and (s -> 'composition' -> 'married_in' ->> 'female')::int >= 2
    and (s -> 'composition' -> 'married_in' ->> 'male')::int >= 1
    and (s -> 'composition' -> 'married_in' ->> 'living_female')::int >= 2
  from public.admin_snapshot() s), 'snapshot counts men and women, blood and married in');
reset role;
delete from public.persons where id in (select id from lin);
drop table lin;

-- ---------------------------------------------------------------------------
-- 34. Deleting my account: my things go, the family's records stay.
-- ---------------------------------------------------------------------------
reset role;
\set leaver_id '''00000000-0000-0000-0000-0000000000d1'''
insert into auth.users (id, email, raw_user_meta_data) values (:leaver_id, 'leaver@example.com', '{"display_name": "Leaver"}');
update public.profiles set status = 'active' where id = :leaver_id;
select set_config('request.jwt.claims', json_build_object('sub', :leaver_id)::text, false);
set role authenticated;
insert into public.albums (title) values ('Leaver album');
insert into public.events (title, starts_at) values ('Leaver event', now() + interval '9 days');
insert into public.posts (body) values ('Leaver moment');
insert into public.polls (question) values ('Leaver poll?');
insert into public.fund_contributions (cause_id, amount, method, show_name)
  values ((select id from public.fund_causes limit 1), 777, 'cash', true);
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into public.photos (storage_path, album_id) values
  (format('uploads/%s/in-leaver-album.jpg', :admin_id), (select id from public.albums where title = 'Leaver album'));
insert into public.event_rsvps (event_id, user_id, response)
  values ((select id from public.events where title = 'Leaver event'), :admin_id, 'going');
-- The only admin can't leave.
select test.expect_error($$select public.delete_my_account()$$, 'the only admin cannot delete their account');
select test.expect_error($$select public.delete_my_account(true)$$, 'the check says so too');
reset role;
create temp table leaver_notes as select clock_timestamp() as t;
select set_config('request.jwt.claims', json_build_object('sub', :leaver_id)::text, false);
set role authenticated;
select public.delete_my_account(true);
select test.assert((select count(*) = 1 from public.profiles where id = :leaver_id), 'checking first deletes nothing');
select public.delete_my_account();
reset role;
select test.assert((select count(*) = 0 from auth.users where id = :leaver_id), 'the account is gone');
select test.assert((select count(*) = 0 from public.profiles where id = :leaver_id), 'the profile is gone');
select test.assert((select count(*) = 0 from public.posts where body = 'Leaver moment'), 'their moments are gone');
select test.assert((select created_by is null from public.albums where title = 'Leaver album'), 'their album stays, unnamed');
select test.assert((select count(*) = 1 from public.photos p join public.albums a on a.id = p.album_id
  where a.title = 'Leaver album'), 'with everyone else''s photos');
select test.assert((select count(*) = 1 from public.event_rsvps r join public.events e on e.id = r.event_id
  where e.title = 'Leaver event'), 'their event stays with everyone''s replies');
select test.assert((select count(*) = 1 from public.polls where question = 'Leaver poll?' and created_by is null), 'their poll stays');
select test.assert((select count(*) = 1 from public.fund_contributions where amount = 777 and user_id is null),
  'the fund keeps the payment');
select test.assert((select detail ->> 'label' = 'Leaver' from public.activity_log
  where entity = 'account' and action = 'delete' order by id desc limit 1), 'admins can see who left');
select test.assert((select count(*) = 0 from public.activity_log where user_id is null and entity = 'posts'
  and detail ->> 'label' = 'Leaver moment' and action = 'delete'), 'no log line for each removed row');
select test.assert((select count(*) = 0 from public.notifications where created_at >= (select t from leaver_notes)),
  'no notifications about removed rows');
drop table leaver_notes;

-- ---------------------------------------------------------------------------
-- 35. Public info: the Play link and the developer's contact, for anyone.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', '{}', false);
update public.app_settings set developer_email = 'dev@example.com', play_store_url = null;
select test.expect_error($$update public.app_settings set play_store_url = 'https://evil.example.com/app'$$,
  'only a Google Play link');
update public.app_settings set play_store_url = 'https://play.google.com/store/apps/details?id=com.fuyoudhat.buafamily';
select set_config('request.jwt.claims', '{}', false);
set role anon;
select test.assert((select i ->> 'developer_email' = 'dev@example.com' and i ->> 'play_store_url' like 'https://play.google.com/%'
  and not i ? 'hijri_offset' from public.public_info() i), 'anyone sees the Play link and how to reach the developer');
reset role;
update public.app_settings set play_store_url = null;

-- ---------------------------------------------------------------------------
-- 36. Weekly summary and alerts for admins.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', '{}', false);
select test.assert((select private.weekly_summary('2031-01-06') >= 1), 'a weekly summary goes to admins');
select test.assert((select private.weekly_summary('2031-01-06') = 0), 'only once a week');
select test.assert((select data ? 'moments' and data ? 'waiting_suggestions' and link = '/admin/metrics'
  from public.notifications where kind = 'weekly_summary' and user_id = :admin_id order by created_at desc limit 1),
  'it says what happened and what is waiting');
select test.assert((select count(*) = 0 from public.notifications where kind = 'weekly_summary' and user_id = :member_id),
  'members do not get it');
update public.app_settings set weekly_summary = false;
select test.assert((select private.weekly_summary('2031-01-13') = 0), 'admins can turn it off');
update public.app_settings set weekly_summary = true;

-- A blood request with no offer, two hours on.
insert into public.blood_requests (requested_by, blood_group, patient_name, hospital, created_at)
  values (:member_id, 'O-', 'Alert patient', 'AKTH', now() - interval '3 hours');
select private.admin_alerts();
select test.assert((select count(*) = 1 from public.notifications where kind = 'admin_alert' and user_id = :admin_id
  and data ->> 'alert' = 'blood_no_offer' and data ->> 'patient' = 'Alert patient'), 'admins hear about a request nobody answered');
select private.admin_alerts();
select test.assert((select count(*) = 1 from public.notifications where kind = 'admin_alert'
  and data ->> 'alert' = 'blood_no_offer' and data ->> 'patient' = 'Alert patient'), 'once');
update public.blood_requests set status = 'closed' where patient_name = 'Alert patient';

-- The fund below the level set: once, until it recovers.
update public.app_settings set fund_alert_below = private.fund_balance() + 1000;
select private.admin_alerts();
select private.admin_alerts();
select test.assert((select count(*) = 1 from public.notifications where kind = 'admin_alert' and user_id = :admin_id
  and data ->> 'alert' = 'fund_low'), 'the fund-low alert goes out once');
select test.assert((select count(*) = 1 from public.notifications where kind = 'admin_alert' and user_id = :member2_id
  and data ->> 'alert' = 'fund_low'), 'treasurers hear too');
update public.app_settings set fund_alert_below = 0;
select private.admin_alerts();
select test.assert((select count(*) = 0 from private.alert_marks where key = 'fund_low' and at is not null), 'recovered: ready to warn again');
update public.app_settings set fund_alert_below = null;

-- Waiting over three days (in the morning, Nigerian time).
insert into public.change_requests (requested_by, kind, payload, created_at)
  values (:member_id, 'create_person', '{"first_name": "Waiting"}', now() - interval '4 days');
select private.admin_alerts(date_trunc('day', now() at time zone 'Africa/Lagos') at time zone 'Africa/Lagos' + interval '9 hours');
select test.assert((select (data ->> 'suggestions')::int >= 1 from public.notifications where kind = 'admin_alert'
  and user_id = :admin_id and data ->> 'alert' = 'waiting'), 'admins hear about suggestions waiting three days');
delete from public.change_requests where payload ->> 'first_name' = 'Waiting';

-- ---------------------------------------------------------------------------
-- 37. Direct messages: only the two people in a conversation.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.dm_open(%L)$$, :member_id), 'not with yourself');
select test.expect_error($$select public.dm_open(gen_random_uuid())$$, 'only with a family member');
insert into test.ids values ('dm', public.dm_open(:member2_id));
select test.assert((select public.dm_open(:member2_id) = (select id from test.ids where name = 'dm')),
  'one conversation per pair');
insert into public.dm_messages (thread_id, body) values ((select id from test.ids where name = 'dm'), 'Salam, how is Kano?');
select test.expect_error(format($$insert into public.dm_messages (thread_id, author_id, body) values (%L, %L, 'fake')$$,
  (select id from test.ids where name = 'dm'), :member2_id), 'cannot write as someone else');
select test.expect_error($$insert into public.dm_threads (user_a, user_b) values (gen_random_uuid(), gen_random_uuid())$$,
  'conversations only start through dm_open');
reset role;
select test.assert((select last_message = 'Salam, how is Kano?' and last_message_by = :member_id
  from public.dm_threads where id = (select id from test.ids where name = 'dm')), 'the conversation shows the last message');
select test.assert((select count(*) = 1 from public.notifications where user_id = :member2_id and kind = 'direct_message'
  and data ->> 'body' = 'Salam, how is Kano?' and link = '/messages/' || (select id from test.ids where name = 'dm')),
  'the other person is told');

-- The other person reads and replies.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 1 from public.dm_messages), 'they can read it');
select public.dm_mark_read((select id from test.ids where name = 'dm'));
insert into public.dm_messages (thread_id, body) values ((select id from test.ids where name = 'dm'), 'Lafiya lau!');
select test.expect_error(format($$update public.dm_messages set body = 'edited' where thread_id = %L$$,
  (select id from test.ids where name = 'dm')), 'messages are not changed afterwards');
reset role;

-- Nobody else, admins included.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.dm_messages), 'admins cannot read other people''s messages');
select test.assert((select count(*) = 0 from public.dm_threads), 'or see the conversation');
select test.expect_error(format($$insert into public.dm_messages (thread_id, body) values (%L, 'hi')$$,
  (select id from test.ids where name = 'dm')), 'or write into it');
reset role;
select test.assert((select not (private.backup_data() ? 'dm_messages')), 'private messages are not in backups');

-- ---------------------------------------------------------------------------
-- 38. Event photos and who came.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into public.events (title, starts_at) values ('Sallah lunch', now() - interval '1 hour');
insert into public.events (title, starts_at) values ('Next year''s reunion', now() + interval '200 days');
insert into test.ids values ('lunch', (select id from public.events where title = 'Sallah lunch'));
insert into test.ids values ('reunion', (select id from public.events where title = 'Next year''s reunion'));
reset role;

-- Anyone in the family gets the event's album, made once.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into test.ids values ('lunch_album', public.event_album((select id from test.ids where name = 'lunch')));
select test.assert((select public.event_album((select id from test.ids where name = 'lunch'))
  = (select id from test.ids where name = 'lunch_album')), 'one album per event');
select test.assert((select title = 'Sallah lunch' and event_id = (select id from test.ids where name = 'lunch')
  from public.albums where id = (select id from test.ids where name = 'lunch_album')), 'named after the event');

-- Members mark themselves as there, once the event has begun.
insert into public.event_attendance (event_id, person_id)
  values ((select id from test.ids where name = 'lunch'), public.my_person_id());
select test.expect_error(format($$insert into public.event_attendance (event_id, person_id) values (%L, public.my_person_id())$$,
  (select id from test.ids where name = 'reunion')), 'not before the day');
select test.expect_error(format($$insert into public.event_attendance (event_id, person_id)
  select %L, id from public.persons where id <> public.my_person_id() limit 1$$,
  (select id from test.ids where name = 'lunch')), 'members only mark themselves');
reset role;

-- The host (an admin here) marks anyone, including relatives without the app.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
insert into public.event_attendance (event_id, person_id)
  select (select id from test.ids where name = 'lunch'), id from public.persons
  where id not in (select person_id from public.event_attendance) limit 2;
select test.assert((select count(*) = 3 from public.event_attendance
  where event_id = (select id from test.ids where name = 'lunch')), 'three came');
reset role;
select test.assert((select private.backup_data() ? 'event_attendance'), 'who came is in backups');

-- ---------------------------------------------------------------------------
-- 39. The Android app as two APKs, one per phone type.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select public.admin_publish_android(6, '1.0.6', 'bua-family-1.0.6.apk');
select public.admin_publish_android_arm32(6, 'bua-family-1.0.6-arm32.apk');
select test.expect_error($$select public.admin_publish_android_arm32(5, 'old.apk')$$, 'only for the published build');
reset role;
set role anon;
select test.assert((select r ->> 'path' = 'bua-family-1.0.6.apk' and r ->> 'path_arm32' = 'bua-family-1.0.6-arm32.apk'
  from public.android_release() r), 'both files are offered');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select public.admin_publish_android(7, '1.0.7', 'bua-family-1.0.7.apk');
reset role;
select test.assert((select not (public.android_release() ? 'path_arm32')), 'a single APK for all phones still works');
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error($$select public.admin_publish_android_arm32(7, 'x.apk')$$, 'members cannot publish');
reset role;

-- ---------------------------------------------------------------------------
-- 40. Admins can turn messages off for everyone.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
update public.app_settings set messages_enabled = false;
reset role;
select test.assert((select messages_enabled from public.app_settings), 'a member cannot turn messages off');
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
update public.app_settings set messages_enabled = false;
select test.expect_error(format($$select public.dm_open(%L)$$, :member_id), 'no new conversations while off');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.dm_threads), 'conversations are hidden while off');
select test.assert((select count(*) = 0 from public.dm_messages), 'and their messages');
select test.expect_error(format($$insert into public.dm_messages (thread_id, body) values (%L, 'still there?')$$,
  (select id from test.ids where name = 'dm')), 'nobody can send while off');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
update public.app_settings set messages_enabled = true;
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 2 from public.dm_messages), 'turned back on, the conversations are all there');
reset role;

-- ---------------------------------------------------------------------------
-- 41. Dues: the committee writes, members only read (one rule each).
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert((select count(*) >= 1 from public.fund_dues_plans), 'members read the dues plans');
update public.fund_dues_plans set amount = 1 where title = 'Monthly dues';
delete from public.fund_dues_members where plan_id = (select id from public.fund_dues_plans where title = 'Monthly dues');
reset role;
select test.assert((select amount = 2000 from public.fund_dues_plans where title = 'Monthly dues'), 'members cannot change a plan');
select test.assert((select count(*) = 2 from public.fund_dues_members m join public.fund_dues_plans p on p.id = m.plan_id
  where p.title = 'Monthly dues'), 'or remove who pays');
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
update public.fund_dues_plans set amount = 2500 where title = 'Monthly dues';
select test.assert((select count(*) = 2 from public.fund_dues_members m join public.fund_dues_plans p on p.id = m.plan_id
  where p.title = 'Monthly dues'), 'the treasurer sees everyone on the plan');
reset role;
select test.assert((select amount = 2500 from public.fund_dues_plans where title = 'Monthly dues'), 'the treasurer changes a plan');
update public.fund_dues_plans set amount = 2000 where title = 'Monthly dues';
select set_config('request.jwt.claims', '{}', false);

-- ---------------------------------------------------------------------------
-- 42. One phone number, one account; admins can delete accounts.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', '{}', false);
\set dup_id '''00000000-0000-0000-0000-0000000000d1'''
\set saver_id '''00000000-0000-0000-0000-0000000000d2'''
insert into auth.users (id, email, raw_user_meta_data) values (:saver_id, 'saver@example.com', '{"display_name": "Saver"}');
update public.profiles set status = 'active' where id = :saver_id;

-- A number saved on an email account signs in to that account.
select set_config('request.jwt.claims', json_build_object('sub', :saver_id)::text, false);
set role authenticated;
update public.profiles set phone = '08051234567' where id = :saver_id;
reset role;
select test.assert((select phone = '2348051234567' from auth.users where id = :saver_id),
  'the saved number becomes the account''s phone sign-in');
select test.expect_error($$insert into auth.users (id, phone) values (gen_random_uuid(), '2348051234567')$$,
  'signing up again with that number makes no second account');

-- Changed, the sign-in number moves; cleared, it goes.
select set_config('request.jwt.claims', json_build_object('sub', :saver_id)::text, false);
set role authenticated;
update public.profiles set phone = '08059998888' where id = :saver_id;
reset role;
select test.assert((select phone = '2348059998888' from auth.users where id = :saver_id), 'a changed number moves with it');
select set_config('request.jwt.claims', json_build_object('sub', :saver_id)::text, false);
set role authenticated;
update public.profiles set phone = null where id = :saver_id;
reset role;
select test.assert((select phone is null from auth.users where id = :saver_id), 'a removed number no longer signs in');

-- A number someone else already signed up with can't be saved.
select set_config('request.jwt.claims', '{}', false);
insert into auth.users (id, phone) values (:dup_id, '2348051234567');
select set_config('request.jwt.claims', json_build_object('sub', :saver_id)::text, false);
set role authenticated;
select test.expect_error($$update public.profiles set phone = '2348051234567' where id = auth.uid()$$,
  'a number on another account is refused');
reset role;

-- Deleting accounts: admins only, not their own, not another admin's.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.admin_delete_account(%L)$$, :dup_id), 'members cannot delete accounts');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.admin_delete_account(%L)$$, :admin_id), 'not your own account');
reset role;
select set_config('request.jwt.claims', '{}', false);
update public.profiles set role = 'admin' where id = :saver_id;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.admin_delete_account(%L)$$, :saver_id), 'not another admin''s');
reset role;
select set_config('request.jwt.claims', '{}', false);
update public.profiles set role = 'member' where id = :saver_id;

-- Like the live case: the number is on the saver's profile and on a second,
-- phone-only account made before this fix.
alter table public.profiles disable trigger profiles_phone_unique;
update public.profiles set phone = '2348051234567' where id = :saver_id;
alter table public.profiles enable trigger profiles_phone_unique;
select test.assert((select phone is null from auth.users where id = :saver_id), 'while another account holds it, it is not linked');
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select public.admin_delete_account(:dup_id, true);
reset role;
select test.assert((select exists (select 1 from auth.users where id = :dup_id)), 'checking deletes nothing');
set role authenticated;
select public.admin_delete_account(:dup_id);
reset role;
select test.assert((select not exists (select 1 from auth.users where id = :dup_id)), 'the account is deleted');
select test.assert((select phone = '2348051234567' from auth.users where id = :saver_id),
  'and the number now signs in to the account that saved it');
select test.assert((select exists (select 1 from public.activity_log where user_id = :admin_id and action = 'delete'
  and entity = 'account')), 'the deletion is in the activity log');
select set_config('request.jwt.claims', '{}', false);
delete from auth.users where id = :saver_id;

-- ---------------------------------------------------------------------------
-- 43. Paying online through Korapay.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error($$select public.admin_set_korapay('sk_test_abc')$$, 'only admins set the Korapay key');
select test.expect_error($$select public.korapay_config()$$, 'members cannot read the key');
select test.expect_error(format($$select public.online_payment_start(%L, 5000)$$, :member_id),
  'members cannot start payments directly (only through the Edge Function)');
reset role;

select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.expect_error($$select public.admin_set_korapay('pk_test_public')$$, 'the public key is refused');
select public.admin_set_korapay('sk_test_family123');
select test.assert((select public.korapay_status() ->> 'mode' = 'test'), 'the committee sees the key is saved, in test mode');
select test.assert((select not (public.fund_overview() ->> 'online_payments')::boolean), 'not on until the committee switches it on');
update public.fund_settings set online_payments = true;
select test.assert((select (public.fund_overview() ->> 'online_payments')::boolean), 'switched on, members can pay');
insert into public.fund_causes (title, target_amount) values ('Hospital bill', 100000);
reset role;
select id as paycause from public.fund_causes where title = 'Hospital bill' \gset

set role service_role;
select test.assert((select public.korapay_config() ->> 'secret_key' = 'sk_test_family123'), 'the Edge Function reads the key');
select test.expect_error(format($$select public.online_payment_start(%L, 50)$$, :member_id), 'at least ₦100');
select test.expect_error(format($$select public.online_payment_start(%L, 5000)$$, gen_random_uuid()), 'only members pay');
select (public.online_payment_start(:member_id, 5000, :'paycause')) ->> 'reference' as payref \gset
select test.assert((select status = 'started' and amount = 5000 from public.online_payments where reference = :'payref'),
  'a payment is started');
select test.expect_error(format($$select public.online_payment_paid(%L, 4000)$$, :'payref'), 'paying less is refused');
select public.online_payment_paid(:'payref', 5000, 75);
select public.online_payment_paid(:'payref', 5000, 75);
reset role;
select test.assert((select count(*) = 1 from public.fund_contributions where gateway_reference = :'payref'
  and status = 'confirmed' and amount = 5000 and user_id = :member_id), 'paid once: one confirmed contribution, even if told twice');
select test.assert((select status = 'paid' and fee = 75 and contribution_id is not null from public.online_payments
  where reference = :'payref'), 'the payment is marked paid with its fee');
select test.assert((select count(*) >= 1 from public.notifications where user_id = :member_id and kind = 'fund_confirmed'
  and (data ->> 'amount')::numeric = 5000), 'the member is told it is confirmed');
select test.assert((select count(*) >= 1 from public.notifications where user_id = :admin_id and kind = 'fund_contribution'
  and (data ->> 'online')::boolean), 'the committee hears it was paid online');

-- Members see their own payments only.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 1 from public.online_payments), 'members see their own payments');
select test.expect_error($$insert into public.online_payments (reference, user_id, amount) values ('x', auth.uid(), 500)$$,
  'members cannot write payments');
reset role;

-- A closed cause can't be paid for; switched off, nothing can.
update public.fund_causes set status = 'closed' where id = :'paycause';
set role service_role;
select test.expect_error(format($$select public.online_payment_start(%L, 5000, %L)$$, :member_id, :'paycause'),
  'a closed cause can''t be paid for');
reset role;
update public.fund_settings set online_payments = false;
set role service_role;
select test.expect_error(format($$select public.online_payment_start(%L, 5000)$$, :member_id), 'switched off, no payments');
reset role;
select set_config('request.jwt.claims', '{}', false);

-- ---------------------------------------------------------------------------
-- 44. Reporting to admins, and blocking.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
insert into public.posts (body) values ('Something nobody should post');
reset role;
select id as bad_post from public.posts where body = 'Something nobody should post' \gset
select m.id as bad_msg from public.dm_messages m where m.author_id = :member2_id and m.body = 'Lafiya lau!' \gset

select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.report_content('post', %L, 'whatever')$$, :'bad_post'), 'a reason is needed');
select test.expect_error(format($$select public.report_content('post', %L, 'abuse')$$, gen_random_uuid()), 'only things that exist');
select public.report_content('post', :'bad_post', 'child_safety', 'Please look at this');
select public.report_content('post', :'bad_post', 'abuse');
select test.assert((select count(*) = 1 and bool_and(reason = 'abuse' and note = 'Please look at this')
  from public.reports where target_id = :'bad_post'), 'reporting again updates the same open report');
select public.report_content('message', :'bad_msg', 'abuse');
select test.assert((select count(*) = 2 from public.reports), 'members see their own reports');
select test.expect_error($$update public.reports set status = 'dismissed'$$, 'members cannot change reports');
select test.expect_error($$insert into public.reports (kind, target_id, reason) values ('post', gen_random_uuid(), 'spam')$$,
  'reports are only made through report_content');
reset role;
select test.assert((select status = 'open' from public.reports where target_id = :'bad_post'), 'still open');

-- Someone else's message, or your own things, can't be reported.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.report_content('message', %L, 'abuse')$$, :'bad_msg'),
  'only people in the conversation can report a message');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.report_content('post', %L, 'spam')$$, :'bad_post'), 'not your own');
select test.assert((select count(*) = 0 from public.reports), 'the reported person does not see the reports');
reset role;

-- Admins hear about it and see what was reported, even a private message.
select test.assert((select count(*) = 1 from public.notifications where user_id = :admin_id and kind = 'content_report'
  and data ->> 'kind' = 'post'), 'admins are told');
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select snapshot ->> 'body' = 'Lafiya lau!' and target_user = :member2_id
  from public.reports where kind = 'message'), 'admins see the reported message and who wrote it');
select test.assert((select link = '/posts/' || :'bad_post' from public.reports where kind = 'post'), 'and where it is');
delete from public.posts where id = :'bad_post';
select public.admin_resolve_report((select id from public.reports where kind = 'post'), 'removed');
select test.assert((select status = 'removed' and reviewed_by = :admin_id and snapshot ->> 'body' = 'Something nobody should post'
  from public.reports where kind = 'post'), 'resolved, and the copy stays after the content is gone');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.admin_resolve_report(%L, 'dismissed')$$,
  (select id from public.reports where kind = 'message')), 'only admins resolve reports');

-- Blocking: neither can message the other.
insert into public.blocks (blocked_id) values (:member2_id);
select test.expect_error(format($$insert into public.blocks (blocker_id, blocked_id) values (%L, %L)$$, :member2_id, :member_id),
  'you only block for yourself');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.blocks), 'the blocked person does not see the block');
select test.expect_error(format($$insert into public.dm_messages (thread_id, body) values (%L, 'hello?')$$,
  (select id from public.dm_threads where :member_id in (user_a, user_b) and :member2_id in (user_a, user_b))),
  'a blocked person cannot send');
select test.expect_error(format($$select public.dm_open(%L)$$, :member_id), 'or start a conversation');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.dm_open(%L)$$, :member2_id), 'nor can the one who blocked');
delete from public.blocks where blocked_id = :member2_id;
insert into public.dm_messages (thread_id, body)
values (public.dm_open(:member2_id), 'Sorry, unblocked you');
reset role;
select set_config('request.jwt.claims', '{}', false);

-- ---------------------------------------------------------------------------
-- 45. Quran khatm: 30 juz shared out, completion and reminders.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.khatms (title, due_on) values ('Khatm for Kaka', (now() at time zone 'Africa/Lagos')::date + 1);
select test.expect_error($$insert into public.khatms (title, completed_at) values ('Already done', now())$$,
  'a khatm can''t start complete');
reset role;
select id as kid from public.khatms where title = 'Khatm for Kaka' \gset
select test.assert((select count(*) >= 2 from public.notifications where kind = 'khatm' and data ->> 'title' = 'Khatm for Kaka'),
  'everyone else is told about it');

select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert((select public.khatm_take(:'kid', 5) = 5), 'take juz 5');
select test.assert((select public.khatm_take(:'kid') = 1), 'or the first free one');
select test.expect_error(format($$insert into public.khatm_parts (khatm_id, juz, user_id) values (%L, 9, auth.uid())$$, :'kid'),
  'parts only change through the functions');
update public.khatms set completed_at = now() where id = :'kid';
reset role;
select test.assert((select completed_at is null from public.khatms where id = :'kid'), 'nobody marks it complete by hand');

select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.khatm_take(%L, 5)$$, :'kid'), 'a taken juz can''t be taken again');
select test.expect_error(format($$select public.khatm_done(%L, 5)$$, :'kid'), 'or marked read by someone else');
select test.expect_error(format($$select public.khatm_release(%L, 5)$$, :'kid'), 'or given back by someone else');
select test.assert((select public.khatm_take(:'kid') = 2), 'the next free one is 2');
select test.expect_error(format($$select public.khatm_take(%L, 31)$$, :'kid'), 'there are 30');
reset role;

-- The day before it's due, those still holding a juz are reminded.
select test.assert((select private.khatm_reminders() >= 2), 'reminders go out');
select test.assert((select (data -> 'juz') = '[1, 5]'::jsonb from public.notifications
  where kind = 'khatm_reminder' and user_id = :member_id), 'with which juz are theirs');
select test.assert((select private.khatm_reminders() = 0), 'once');

-- Give one back; the one who started it can free someone else's.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select public.khatm_done(:'kid', 5);
select test.expect_error(format($$select public.khatm_release(%L, 5)$$, :'kid'), 'a read juz stays');
select public.khatm_release(:'kid', 1);
select public.khatm_release(:'kid', 2);
reset role;
select test.assert((select user_id is null from public.khatm_parts where khatm_id = :'kid' and juz = 2),
  'whoever started it can free a juz someone is holding');

-- Finishing all 30 completes it, and those who took part are told.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
do $$
declare j int;
begin
  for j in 1..30 loop
    continue when j = 5;
    perform public.khatm_take((select id from public.khatms where title = 'Khatm for Kaka'), j);
    perform public.khatm_done((select id from public.khatms where title = 'Khatm for Kaka'), j);
  end loop;
end $$;
reset role;
select test.assert((select completed_at is not null from public.khatms where id = :'kid'), 'all 30 read: complete');
select test.assert((select count(*) = 2 from public.notifications where kind = 'khatm_completed'
  and data ->> 'khatm_id' = :'kid'), 'both readers are told (the starter is one of them)');
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.khatm_done(%L, 3, false)$$, :'kid'), 'a complete khatm is closed');
reset role;
select test.assert((select private.backup_data() -> 'khatm_parts' @> jsonb_build_array(jsonb_build_object('juz', 5))),
  'khatms are in backups');
select set_config('request.jwt.claims', '{}', false);

-- ---------------------------------------------------------------------------
-- 46. Merging a person entered twice.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
-- Kabiru, son of Ahmadu, entered twice: once with Hauwa as mother and a skill,
-- once with a birth date, a wife, a child, the same skill and another.
insert into test.ids values
  ('kab1', public.create_person_with_relation('{"first_name":"Kabiru","last_name":"Bua","sex":"male"}',
     json_build_object('type','child','person_id',(select id from test.ids where name='grandpa'),
                       'other_parent_id',(select id from test.ids where name='hauwa'))::jsonb)),
  ('kab2', public.create_person_with_relation('{"first_name":"Kabir","sex":"unknown","birth_date":"1960-03-01","birth_place":"Kano"}',
     json_build_object('type','child','person_id',(select id from test.ids where name='grandpa'))::jsonb));
insert into test.ids values
  ('kabwife', public.create_person_with_relation('{"first_name":"Ladi","sex":"female"}',
     json_build_object('type','spouse','person_id',(select id from test.ids where name='kab2'))::jsonb));
insert into test.ids values
  ('kabson', public.create_person_with_relation('{"first_name":"Yusuf","sex":"male"}',
     json_build_object('type','child','person_id',(select id from test.ids where name='kab2'))::jsonb));
insert into public.person_skills (person_id, skill) values
  ((select id from test.ids where name = 'kab1'), 'Farming'),
  ((select id from test.ids where name = 'kab2'), 'Farming'),
  ((select id from test.ids where name = 'kab2'), 'Tailoring');
reset role;
select id as kab1 from test.ids where name = 'kab1' \gset
select id as kab2 from test.ids where name = 'kab2' \gset

select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.admin_merge_persons(%L, %L)$$, :'kab1', :'kab2'), 'only admins merge');
select test.expect_error(format($$insert into public.not_duplicates (person_a, person_b) values (%L, %L)$$,
  least(:'kab1'::uuid, :'kab2'::uuid), greatest(:'kab1'::uuid, :'kab2'::uuid)), 'only admins mark pairs');
reset role;

select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.admin_merge_persons(%L, %L)$$, :'kab1', :'kab1'), 'two different people');
select test.expect_error(format($$select public.admin_merge_persons(%L, %L)$$,
  (select id from test.ids where name = 'hauwa'), :'kab1'), 'a woman and a man are not merged');
select public.admin_merge_persons(:'kab1', :'kab2');
reset role;
select test.assert((select birth_date = '1960-03-01' and birth_place = 'Kano' and last_name = 'Bua' and first_name = 'Kabiru'
  from public.persons where id = :'kab1'), 'the kept record keeps its details and gains the missing ones');
select test.assert((select count(*) = 1 from public.unions
  where :'kab1' in (partner1_id, partner2_id)), 'the wife moved to the kept record');
select test.assert((select count(*) = 1 from public.parent_child
  where parent_id = :'kab1' and child_id = (select id from test.ids where name = 'kabson')), 'and the child');
select test.assert((select count(*) = 2 from public.parent_child where child_id = :'kab1'),
  'parents stay two (father once, mother)');
select test.assert((select array_agg(skill order by skill) = '{Farming,Tailoring}' from public.person_skills
  where person_id = :'kab1'), 'skills joined without repeats');

-- The duplicate is then deleted; what's left goes with it.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
delete from public.persons where id = :'kab2';
insert into public.not_duplicates (person_a, person_b)
values (least((select id from test.ids where name = 'musa'), (select id from test.ids where name = 'sani')),
        greatest((select id from test.ids where name = 'musa'), (select id from test.ids where name = 'sani')));
select test.assert((select count(*) = 1 from public.not_duplicates), 'admins can say two people are different');
reset role;
select test.assert((select count(*) = 0 from public.persons where id = :'kab2'), 'the duplicate is gone');
select test.assert((select count(*) = 2 from public.parent_child where child_id = :'kab1'), 'the kept links remain');
select test.assert((select exists (select 1 from public.activity_log where action = 'merge' and target = :'kab1')),
  'the merge is in the activity log');
select set_config('request.jwt.claims', '{}', false);

-- ---------------------------------------------------------------------------
-- 47. Messages like WhatsApp: ticks, photos and voice notes, replies, delete.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', '{}', false);
select id as dmt from public.dm_threads
 where :member_id in (user_a, user_b) and :member2_id in (user_a, user_b) \gset

select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.dm_messages (thread_id, body) values (:'dmt', 'Are you coming tomorrow?');
reset role;
select id as q from public.dm_messages where body = 'Are you coming tomorrow?' \gset
select test.assert((select (case when user_a = :member_id then b_delivered_at else a_delivered_at end) is null
                           or (case when user_a = :member_id then b_delivered_at else a_delivered_at end) < last_message_at
  from public.dm_threads where id = :'dmt'), 'not yet delivered to the other person');

-- Their app hears of it: delivered. They open it: read.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select public.dm_mark_delivered();
reset role;
select test.assert((select (case when user_a = :member2_id then a_delivered_at else b_delivered_at end) >= last_message_at
  from public.dm_threads where id = :'dmt'), 'delivered (two grey ticks)');

-- A photo with a caption, replying to the question; files only in this conversation's folder.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.expect_error(format($$insert into public.dm_messages (thread_id, body, kind, media_path)
  values (%L, 'x', 'photo', 'other-thread/%s/a.jpg')$$, :'dmt', :member2_id), 'files go in this conversation''s folder');
select test.expect_error(format($$insert into public.dm_messages (thread_id, body, kind) values (%L, '📷', 'photo')$$, :'dmt'),
  'a photo needs its file');
insert into public.dm_messages (thread_id, body, kind, media_path, reply_to)
values (:'dmt', 'Yes, see the ticket', 'photo', :'dmt' || '/' || :member2_id || '/ticket.jpg', :'q');
insert into storage.objects (bucket_id, name) values ('dm', :'dmt' || '/' || :member2_id || '/ticket.jpg');
select test.expect_error(format($$insert into storage.objects (bucket_id, name) values ('dm', '%s/%s/x.jpg')$$,
  :'dmt', :member_id), 'files are uploaded under your own name');
insert into public.dm_messages (thread_id, body, kind, media_path, duration_ms, reply_to)
values (:'dmt', '🎤', 'voice', :'dmt' || '/' || :member2_id || '/note.m4a', 4200,
        (select id from public.dm_messages where body = 'Lafiya lau!'));
reset role;
select test.assert((select reply_to = :'q' from public.dm_messages where body = 'Yes, see the ticket'), 'a reply quotes the message');
select test.assert((select last_message_kind = 'voice' and last_message = '' from public.dm_threads where id = :'dmt'),
  'the conversation shows it was a voice note');
select test.assert((select data ->> 'message_kind' = 'voice' from public.notifications
  where kind = 'direct_message' and user_id = :member_id order by created_at desc limit 1), 'the notice says what kind');

-- The other person sees the photo; nobody else can.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 1 from storage.objects where bucket_id = 'dm'), 'the other person can open the photo');
select public.dm_mark_read(:'dmt');
select test.expect_error(format($$select public.dm_delete_message(%L)$$,
  (select id from public.dm_messages where body = 'Yes, see the ticket')), 'only the sender deletes a message');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from storage.objects where bucket_id = 'dm'), 'admins cannot open it');
reset role;

-- Delete for everyone.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select public.dm_delete_message((select id from public.dm_messages where body = '🎤' and kind = 'voice'));
reset role;
select test.assert((select deleted_at is not null and media_path is null and body = '🚫' from public.dm_messages
  where kind = 'voice' and duration_ms is null), 'deleted for everyone');
select test.assert((select last_message_kind = 'deleted' from public.dm_threads where id = :'dmt'), 'and the preview says so');
select set_config('request.jwt.claims', '{}', false);

-- ---------------------------------------------------------------------------
-- 48. Reactions to messages, and voice note waveforms.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', '{}', false);
select id as dmt from public.dm_threads
 where :member_id in (user_a, user_b) and :member2_id in (user_a, user_b) \gset
select id as liked from public.dm_messages where body = 'Yes, see the ticket' \gset

select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
insert into public.dm_messages (thread_id, body, kind, media_path, duration_ms, waveform)
values (:'dmt', '🎤', 'voice', :'dmt' || '/' || :member_id || '/w.m4a', 3000, '{10,40,90,30}');
-- The thread id sent is ignored: it comes from the message.
insert into public.dm_reactions (message_id, thread_id, emoji) values (:'liked', gen_random_uuid(), '❤️');
reset role;
select test.assert((select thread_id = :'dmt' from public.dm_reactions where message_id = :'liked'), 'the reaction belongs to the conversation');
select test.assert((select waveform = '{10,40,90,30}' from public.dm_messages where kind = 'voice' and author_id = :member_id
  and deleted_at is null), 'the voice note keeps its waveform');
select test.assert((select data ->> 'message_kind' = 'reaction' and data ->> 'body' = '❤️' from public.notifications
  where user_id = :member2_id and kind = 'direct_message' order by created_at desc limit 1), 'the sender is told');

-- Changing it replaces it; the other person sees it; others don't.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
update public.dm_reactions set emoji = '😂' where message_id = :'liked';
select test.expect_error(format($$insert into public.dm_reactions (message_id, emoji) values (%L, '👍')$$, :'liked'),
  'one reaction per person per message');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.assert((select emoji = '😂' from public.dm_reactions where message_id = :'liked'), 'the other person sees it');
update public.dm_reactions set emoji = '😡' where message_id = :'liked';
reset role;
select test.assert((select emoji = '😂' from public.dm_reactions where message_id = :'liked'), 'someone else''s reaction stays');
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.dm_reactions), 'admins see no reactions');
select test.expect_error(format($$insert into public.dm_reactions (message_id, emoji) values (%L, '👍')$$, :'liked'),
  'or add them');
reset role;
-- Deleted messages take none.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.expect_error(format($$insert into public.dm_reactions (message_id, emoji) values (%L, '👍')$$,
  (select id from public.dm_messages where kind = 'voice' and deleted_at is not null limit 1)), 'deleted messages take no reactions');
delete from public.dm_reactions where message_id = :'liked';
select test.assert((select count(*) = 0 from public.dm_reactions), 'a reaction can be taken back');
reset role;
select set_config('request.jwt.claims', '{}', false);

-- ---------------------------------------------------------------------------
-- 49. Group chats.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims', '{}', false);

-- Aisha starts a group with Musa: she is its admin; Musa is told.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select public.group_create('Cousins', array[:member2_id]::uuid[], 'For the cousins') as grp \gset
select test.assert((select count(*) = 2 from public.chat_group_members where group_id = :'grp'), 'two members');
select test.assert((select role = 'admin' from public.chat_group_members where group_id = :'grp' and user_id = auth.uid()),
  'whoever starts it is admin');
select test.assert((select count(*) = 2 from public.group_messages where group_id = :'grp' and kind = 'event'),
  'created and added notices');
select test.expect_error($$insert into public.chat_groups (name) values ('Sneaky')$$, 'groups are made through group_create');
select test.expect_error(format($$insert into public.group_messages (group_id, body, kind, event)
  values (%L, 'added', 'event', '{"type":"added"}')$$, :'grp'), 'members cannot write notices');
insert into public.group_messages (group_id, body) values (:'grp', 'Salam everyone');
reset role;
select test.assert((select data ->> 'group' = 'Cousins' from public.notifications
  where user_id = :member2_id and kind = 'group_added'), 'Musa is told he was added');
select test.assert((select data ->> 'body' = 'Salam everyone' and link = '/groups/' || :'grp' from public.notifications
  where user_id = :member2_id and kind = 'group_message'), 'and about the message');
select test.assert((select last_message = 'Salam everyone' and last_message_kind = 'text' from public.chat_groups
  where id = :'grp'), 'the group shows its last message');

-- The admin of the family is not in it: sees nothing, can't post or upload.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.chat_groups where id = :'grp'), 'outsiders don''t see the group');
select test.assert((select count(*) = 0 from public.group_messages where group_id = :'grp'), 'or its messages');
select test.expect_error(format($$insert into public.group_messages (group_id, body) values (%L, 'hi')$$, :'grp'),
  'outsiders cannot post');
select test.expect_error(format($$insert into storage.objects (bucket_id, name) values ('dm', 'g/%s/%s/x.jpg')$$,
  :'grp', :admin_id), 'or upload');
select test.expect_error(format($$select public.group_add(%L, array[%L]::uuid[])$$, :'grp', :admin_id),
  'or add themselves');
reset role;

-- Musa: delivered, then read; a photo replying; only a group admin manages it.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 3 from public.group_messages where group_id = :'grp'), 'Musa sees what was sent since he joined');
select public.dm_mark_delivered();
select test.assert((select delivered_at >= (select last_message_at from public.chat_groups where id = :'grp')
  from public.chat_group_members where group_id = :'grp' and user_id = auth.uid()), 'delivered to Musa');
select public.group_mark_read(:'grp');
insert into storage.objects (bucket_id, name) values ('dm', 'g/' || :'grp' || '/' || :member2_id || '/p.jpg');
select test.expect_error(format($$insert into public.group_messages (group_id, body, kind, media_path)
  values (%L, '📷', 'photo', 'g/%s/%s/p.jpg')$$, :'grp', :'grp', :member_id), 'files go under your own name');
insert into public.group_messages (group_id, body, kind, media_path, reply_to)
values (:'grp', 'Wa alaikum salam', 'photo', 'g/' || :'grp' || '/' || :member2_id || '/p.jpg',
        (select id from public.group_messages where body = 'Salam everyone'));
select test.expect_error(format($$select public.group_update(%L, 'Renamed')$$, :'grp'), 'only group admins rename it');
select test.expect_error(format($$select public.group_add(%L, array[%L]::uuid[])$$, :'grp', :admin_id),
  'or add people');
insert into public.group_reactions (message_id, group_id, emoji)
values ((select id from public.group_messages where body = 'Salam everyone'), gen_random_uuid(), '❤️');
reset role;
select test.assert((select reply_to is not null from public.group_messages where body = 'Wa alaikum salam'), 'a reply');
select test.assert((select group_id = :'grp' from public.group_reactions), 'the reaction belongs to the group');
select test.assert((select data ->> 'message_kind' = 'reaction' from public.notifications
  where user_id = :member_id and kind = 'group_message' order by created_at desc limit 1), 'Aisha is told of the reaction');

-- Aisha adds the admin, renames it, lets only admins send; the newcomer sees
-- only what came after.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select test.assert((select public.group_add(:'grp', array[:admin_id, :member2_id]::uuid[]) = 1), 'only new people are added');
select public.group_update(:'grp', 'Cousins & co', null, true);
select public.group_mute(:'grp', true);
reset role;
select test.assert((select name = 'Cousins & co' and only_admins_send and about = 'For the cousins'
  from public.chat_groups where id = :'grp'), 'renamed; only admins send; the description stays');
select test.assert((select last_message_kind = 'event' and last_event ->> 'type' = 'only_admins'
  from public.chat_groups where id = :'grp'), 'the list shows the last notice');
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.group_messages where group_id = :'grp' and body = 'Salam everyone'),
  'a newcomer does not see older messages');
select test.assert((select count(*) >= 1 from public.group_messages where group_id = :'grp'
  and event ->> 'type' = 'renamed'), 'but sees what came after');
select test.assert((select count(*) = 1 from storage.objects where bucket_id = 'dm' and name like 'g/%'),
  'and the group''s files');
select test.expect_error(format($$insert into public.group_messages (group_id, body) values (%L, 'hi')$$, :'grp'),
  'only admins send now');
reset role;
-- Muted: no notification for Aisha.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select public.group_set_admin(:'grp', :member2_id, true);
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
insert into public.group_messages (group_id, body) values (:'grp', 'Admins only now');
reset role;
select test.assert((select count(*) = 0 from public.notifications
  where user_id = :member_id and kind = 'group_message' and data ->> 'body' = 'Admins only now'), 'a muted group stays quiet');
select test.assert((select count(*) = 1 from public.notifications
  where user_id = :admin_id and kind = 'group_message' and data ->> 'body' = 'Admins only now'), 'others are told');

-- Delete for everyone: a group admin can delete anyone's message.
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.expect_error(format($$select public.group_delete_message(%L)$$,
  (select id from public.group_messages where body = 'Admins only now')), 'members delete only their own');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select public.group_delete_message((select id from public.group_messages where body = 'Admins only now'));
reset role;
select test.assert((select deleted_at is not null and deleted_by = :member_id and body = '🚫'
  from public.group_messages where deleted_by is not null), 'deleted for everyone by a group admin');

-- Removed and leaving; the last admin leaving hands it on.
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select public.group_remove(:'grp', :admin_id);
select public.group_set_admin(:'grp', :member2_id, false);
select public.group_leave(:'grp');
select test.assert((select count(*) = 0 from public.chat_groups where id = :'grp'), 'once you leave, you don''t see it');
reset role;
select test.assert((select left_at is not null from public.chat_group_members where group_id = :'grp' and user_id = :admin_id),
  'removed');
select test.assert((select role = 'admin' from public.chat_group_members where group_id = :'grp' and user_id = :member2_id),
  'the one left becomes admin');
select set_config('request.jwt.claims', json_build_object('sub', :admin_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.group_messages where group_id = :'grp'), 'removed: nothing to read');
reset role;

-- Messages off: groups are off too.
update public.app_settings set messages_enabled = false;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select test.assert((select count(*) = 0 from public.chat_groups), 'off: no groups');
select test.expect_error($$select public.group_create('New', '{}')$$, 'off: no new groups');
reset role;
update public.app_settings set messages_enabled = true;

-- A group message can be reported.
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
select public.group_add(:'grp', array[:member_id]::uuid[]);
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member2_id)::text, false);
set role authenticated;
insert into public.group_messages (group_id, body) values (:'grp', 'Something rude');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', :member_id)::text, false);
set role authenticated;
select public.report_content('message', (select id from public.group_messages where body = 'Something rude'), 'abuse');
reset role;
select test.assert((select snapshot ->> 'group' = 'Cousins & co' and target_user = :member2_id from public.reports
  where kind = 'message' and snapshot ->> 'body' = 'Something rude'), 'reported, with the group''s name');
select set_config('request.jwt.claims', '{}', false);

-- ---------------------------------------------------------------------------
-- 17. Anonymous users see nothing.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{}', false);
set role anon;
select test.assert((select count(*) = 0 from public.persons), 'anon sees no persons');
reset role;

\echo 'All database tests passed.'
