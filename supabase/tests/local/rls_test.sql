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
     and r -> 'stories' = '{"added": 0, "updated": 0, "skipped": 1}'::jsonb
  from public.admin_restore(jsonb_build_object(
    'format', 'bua-family-backup',
    'persons', jsonb_build_array(jsonb_build_object('id', gen_random_uuid(), 'first_name', 'Hadiza',
                                                    'created_by', gen_random_uuid())),
    'stories', jsonb_build_array(jsonb_build_object('id', gen_random_uuid(), 'title', 'Old', 'speaker_name', 'X',
                                                    'audio_path', 'x.m4a', 'added_by', gen_random_uuid()))
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
-- 17. Anonymous users see nothing.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{}', false);
set role anon;
select test.assert((select count(*) = 0 from public.persons), 'anon sees no persons');
reset role;

\echo 'All database tests passed.'
