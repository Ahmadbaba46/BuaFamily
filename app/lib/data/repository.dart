import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/account.dart';
import '../models/details.dart';
import '../models/family_graph.dart';
import '../models/help.dart';
import '../models/notification.dart';
import '../models/person.dart';
import '../models/social.dart';

/// All server access. Row level security on the server decides what each
/// user may read or change; the app only hides buttons that would fail.
class FamilyRepository {
  FamilyRepository(this._db);

  final SupabaseClient _db;

  static const photosBucket = 'photos';
  static const _pageSize = 1000; // Supabase returns at most 1000 rows per request.

  GoTrueClient get auth => _db.auth;
  String? get userId => _db.auth.currentUser?.id;

  // ---------------------------------------------------------------- accounts

  Future<Profile?> myProfile() async {
    final id = userId;
    if (id == null) return null;
    final row = await _db.from('profiles').select().eq('id', id).maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  Future<void> updateMyProfile({String? claimNote, String? requestedPersonId, String? locale}) async {
    await _db.from('profiles').update({
      'claim_note': ?claimNote,
      'requested_person_id': ?requestedPersonId,
      'locale': ?locale,
    }).eq('id', userId!);
  }

  Future<List<Profile>> allProfiles() async {
    final rows = await _db.from('profiles').select().order('created_at');
    return rows.map(Profile.fromJson).toList();
  }

  Future<void> adminUpdateAccount(
    String userId, {
    AccountStatus? status,
    AppRole? role,
    String? personId,
    bool unlink = false,
  }) async {
    await _db.rpc('admin_update_account', params: {
      'p_user_id': userId,
      'p_status': status?.name,
      'p_role': role?.name,
      'p_person_id': personId,
      'p_unlink': unlink,
    });
  }

  // ---------------------------------------------------------------- settings

  Future<AppSettings> settings() async {
    final row = await _db.from('app_settings').select().maybeSingle();
    return row == null ? const AppSettings() : AppSettings.fromJson(row);
  }

  Future<void> updateSettings(Map<String, dynamic> changes) async {
    await _db.from('app_settings').update(changes).eq('id', true);
  }

  // ---------------------------------------------------------------- family graph

  Future<FamilyGraph> loadGraph() async {
    final results = await Future.wait([
      _all('persons'),
      _all('unions'),
      _all('parent_child'),
    ]);
    return FamilyGraph(
      persons: results[0].map(Person.fromJson),
      unions: results[1].map(FamilyUnion.fromJson).toList(),
      links: results[2].map(ParentLink.fromJson).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> _all(String table) async {
    final out = <Map<String, dynamic>>[];
    for (var from = 0;; from += _pageSize) {
      final page = await _db.from(table).select().order('id').range(from, from + _pageSize - 1);
      out.addAll(page);
      if (page.length < _pageSize) return out;
    }
  }

  /// Admin only: create a person, optionally linked to an existing one.
  Future<String> createPerson(Map<String, dynamic> person, {Map<String, dynamic>? relation}) async {
    final id = await _db.rpc('create_person_with_relation', params: {
      'p_person': person,
      'p_relation': relation,
    });
    return id as String;
  }

  Future<void> updatePerson(String id, Map<String, dynamic> changes) async {
    if (changes.isEmpty) return;
    await _db.from('persons').update(changes).eq('id', id);
  }

  Future<void> deletePerson(String id) async {
    await _db.from('persons').delete().eq('id', id);
  }

  Future<void> addParentChild(String parentId, String childId, ParentKind kind) async {
    await _db.from('parent_child').insert({'parent_id': parentId, 'child_id': childId, 'kind': kind.name});
  }

  Future<void> addUnion(String a, String b, UnionStatus status) async {
    await _db.from('unions').insert({'partner1_id': a, 'partner2_id': b, 'status': status.name});
  }

  // ---------------------------------------------------------------- photos

  Future<void> uploadPhoto(String personId, Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('jpeg', 'jpg');
    final path = 'persons/$personId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from(photosBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: ext == 'jpg' ? 'image/jpeg' : 'image/$ext'),
        );
    await updatePerson(personId, {'photo_path': path});
  }

  Future<String> photoUrl(String path) =>
      _db.storage.from(photosBucket).createSignedUrl(path, 60 * 60);

  // ---------------------------------------------------------------- details

  Future<PersonDetails> details(String personId) async {
    final r = await Future.wait([
      _db.from('person_education').select().eq('person_id', personId).order('start_year'),
      _db.from('person_occupations').select().eq('person_id', personId).order('start_year'),
      _db.from('person_skills').select().eq('person_id', personId).order('skill'),
      _db.from('person_contacts').select().eq('person_id', personId),
      _db.from('person_health').select().eq('person_id', personId),
    ]);
    return PersonDetails(
      education: r[0].map(Education.fromJson).toList(),
      occupations: r[1].map(Occupation.fromJson).toList(),
      skills: r[2].map(Skill.fromJson).toList(),
      contact: r[3].isEmpty ? null : Contact.fromJson(r[3].first),
      health: r[4].isEmpty ? null : Health.fromJson(r[4].first),
    );
  }

  Future<void> saveEducation(Education e) => _save('person_education', e.id, e.toJson());
  Future<void> saveOccupation(Occupation o) => _save('person_occupations', o.id, o.toJson());
  Future<void> addSkill(String personId, String skill) =>
      _db.from('person_skills').insert({'person_id': personId, 'skill': skill.trim()});
  Future<void> saveContact(Contact c) => _db.from('person_contacts').upsert(c.toJson());
  Future<void> saveHealth(Health h) => _db.from('person_health').upsert(h.toJson());

  Future<void> deleteDetail(String table, String id) => _db.from(table).delete().eq('id', id);

  Future<void> _save(String table, String? id, Map<String, dynamic> row) async {
    if (id == null) {
      await _db.from(table).insert(row);
    } else {
      await _db.from(table).update(row).eq('id', id);
    }
  }

  // ---------------------------------------------------------------- change requests

  Future<void> submitRequest(RequestKind kind, Map<String, dynamic> payload, {String? targetPersonId}) async {
    await _db.from('change_requests').insert({
      'kind': kind.dbName,
      'payload': payload,
      'target_person_id': ?targetPersonId,
    });
  }

  /// Admins get every request; members get their own (enforced by the server).
  Future<List<ChangeRequest>> requests({RequestStatus? status}) async {
    var q = _db.from('change_requests').select();
    if (status != null) q = q.eq('status', status.name);
    final rows = await q.order('created_at', ascending: false).limit(200);
    return rows.map(ChangeRequest.fromJson).toList();
  }

  Future<void> reviewRequest(String id, {required bool approve, String? note}) async {
    await _db.rpc('review_change_request', params: {
      'p_request_id': id,
      'p_approve': approve,
      'p_note': note,
    });
  }

  Future<void> withdrawRequest(String id) => _db.from('change_requests').delete().eq('id', id);

  // ---------------------------------------------------------------- sharing

  Future<Map<String, Member>> memberDirectory() async {
    final rows = await _db.rpc('member_directory') as List;
    return {for (final r in rows) (r as Map)['user_id'] as String: Member.fromJson(r.cast<String, dynamic>())};
  }

  Future<List<Post>> feed({int limit = 60}) async {
    final rows = await _db.from('posts').select(Post.select).order('created_at', ascending: false).limit(limit);
    return rows.map(Post.fromJson).toList();
  }

  /// Ids of every post, photo and event the current user has liked.
  Future<Set<String>> myLikes() async {
    final rows = await _db.from('likes').select('post_id, photo_id, event_id').eq('user_id', userId!);
    return {for (final r in rows) (r['post_id'] ?? r['photo_id'] ?? r['event_id']) as String};
  }

  Future<void> setLiked(Target target, bool liked) async {
    if (liked) {
      await _db.from('likes').insert({target.column: target.id});
    } else {
      await _db.from('likes').delete().eq(target.column, target.id).eq('user_id', userId!);
    }
  }

  Future<List<Comment>> comments(Target target) async {
    final rows = await _db.from('comments').select().eq(target.column, target.id).order('created_at');
    return rows.map(Comment.fromJson).toList();
  }

  Future<void> addComment(Target target, String body) =>
      _db.from('comments').insert({target.column: target.id, 'body': body.trim()});

  Future<void> deleteComment(String id) => _db.from('comments').delete().eq('id', id);

  /// Creates a moment or announcement, uploads its photos (also into [albumId]
  /// when given) and tags [people] on the post and on every photo.
  Future<String> createPost({
    PostKind kind = PostKind.moment,
    String body = '',
    String? albumId,
    bool pinned = false,
    bool notify = false,
    bool sendSms = false,
    List<String> people = const [],
    List<PickedImage> images = const [],
  }) async {
    final post = await _db
        .from('posts')
        .insert({
          'kind': kind.name,
          'body': body.trim(),
          'album_id': albumId,
          if (pinned) 'pinned': true,
          if (notify) 'notify': true,
          if (sendSms) 'send_sms': true,
        })
        .select('id')
        .single();
    final postId = post['id'] as String;
    if (people.isNotEmpty) {
      await _db.from('post_people').insert([for (final p in people) {'post_id': postId, 'person_id': p}]);
    }
    final photoIds = <String>[];
    for (final (i, img) in images.indexed) {
      final path = await _upload(img, i);
      final row = await _db
          .from('photos')
          .insert({'storage_path': path, 'post_id': postId, 'album_id': albumId})
          .select('id')
          .single();
      photoIds.add(row['id'] as String);
    }
    if (people.isNotEmpty && photoIds.isNotEmpty) {
      await _db.from('photo_people').insert([
        for (final ph in photoIds)
          for (final p in people) {'photo_id': ph, 'person_id': p},
      ]);
    }
    return postId;
  }

  Future<String> _upload(PickedImage img, int index) async {
    final ext = img.extension.toLowerCase().replaceAll('jpeg', 'jpg');
    final path = 'uploads/$userId/${DateTime.now().millisecondsSinceEpoch}_$index.$ext';
    await _db.storage.from(photosBucket).uploadBinary(
          path,
          Uint8List.fromList(img.bytes),
          fileOptions: FileOptions(contentType: ext == 'jpg' ? 'image/jpeg' : 'image/$ext'),
        );
    return path;
  }

  Future<void> deletePost(Post post) async {
    await _db.from('posts').delete().eq('id', post.id);
    final mine = post.photos.where((p) => p.uploadedBy == userId).map((p) => p.storagePath).toList();
    if (mine.isNotEmpty) await _db.storage.from(photosBucket).remove(mine);
  }

  Future<List<Album>> albums() async {
    final rows = await _db.from('albums').select(Album.select).order('created_at', ascending: false);
    return rows.map(Album.fromJson).toList();
  }

  Future<String> createAlbum(String title, {String? description}) async {
    final row = await _db
        .from('albums')
        .insert({'title': title.trim(), 'description': ?description})
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<List<Photo>> albumPhotos(String albumId) async {
    final rows = await _db
        .from('photos')
        .select(Photo.select)
        .eq('album_id', albumId)
        .order('taken_year', nullsFirst: false)
        .order('created_at');
    return rows.map(Photo.fromJson).toList();
  }

  Future<List<Photo>> photosOf(String personId) async {
    final tagged = await _db.from('photo_people').select('photo_id').eq('person_id', personId);
    if (tagged.isEmpty) return const [];
    final rows = await _db
        .from('photos')
        .select(Photo.select)
        .inFilter('id', [for (final t in tagged) t['photo_id']])
        .order('created_at', ascending: false);
    return rows.map(Photo.fromJson).toList();
  }

  Future<void> updatePhoto(String id, {String? caption, int? takenYear}) =>
      _db.from('photos').update({'caption': caption, 'taken_year': takenYear}).eq('id', id);

  Future<void> deletePhoto(Photo photo) async {
    await _db.from('photos').delete().eq('id', photo.id);
    if (photo.uploadedBy == userId) await _db.storage.from(photosBucket).remove([photo.storagePath]);
  }

  Future<void> tagPhoto(String photoId, String personId) =>
      _db.from('photo_people').insert({'photo_id': photoId, 'person_id': personId});

  Future<void> untagPhoto(String photoId, String personId) =>
      _db.from('photo_people').delete().eq('photo_id', photoId).eq('person_id', personId);

  // ---------------------------------------------------------------- events

  Future<List<FamilyEvent>> events() async {
    final rows = await _db.from('events').select(FamilyEvent.select).order('starts_at').limit(500);
    return rows.map(FamilyEvent.fromJson).toList();
  }

  Future<String> createEvent(Map<String, dynamic> event) async {
    final row = await _db.from('events').insert(event).select('id').single();
    return row['id'] as String;
  }

  Future<void> deleteEvent(String id) => _db.from('events').delete().eq('id', id);

  Future<void> setRsvp(String eventId, RsvpResponse response, {int guests = 0}) =>
      _db.from('event_rsvps').upsert({
        'event_id': eventId,
        'user_id': userId,
        'response': response.name,
        'guests': guests,
      });

  Future<void> setPinned({String? postId, String? eventId, required bool pinned}) => postId != null
      ? _db.from('posts').update({'pinned': pinned}).eq('id', postId)
      : _db.from('events').update({'pinned': pinned}).eq('id', eventId!);

  // ---------------------------------------------------------------- notifications

  /// The newest notifications, kept up to date as new ones arrive.
  Stream<List<AppNotification>> notifications() => _db
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId!)
      .order('created_at')
      .limit(100)
      .map((rows) => rows.map(AppNotification.fromJson).whereType<AppNotification>().toList());

  Future<void> markRead(String id) =>
      _db.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);

  Future<void> markAllRead() => _db
      .from('notifications')
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .eq('user_id', userId!)
      .isFilter('read_at', null);

  Future<void> updateSmsPreferences({String? phone, bool? optIn, bool? birthdays, bool? events}) =>
      _db.from('profiles').update({
        'phone': ?phone,
        'sms_opt_in': ?optIn,
        'sms_birthdays': ?birthdays,
        'sms_events': ?events,
      }).eq('id', userId!);

  Future<void> clearPhone() => _db.from('profiles').update({'phone': null, 'sms_opt_in': false}).eq('id', userId!);

  Future<SmsStatus> smsStatus() async =>
      SmsStatus.fromJson(((await _db.rpc('sms_status')) as Map).cast<String, dynamic>());

  Future<void> setSmsSecret({String? apiKey, String? baseUrl}) =>
      _db.rpc('admin_set_sms_secret', params: {'p_api_key': apiKey, 'p_base_url': baseUrl});

  Future<void> sendTestSms() => _db.rpc('send_test_sms');

  // ---------------------------------------------------------------- who can help & blood

  /// Skills, work and study of every living person, with contact details
  /// where the person shares them with the family.
  Future<List<HelpProfile>> helpDirectory(FamilyGraph graph) async {
    final r = await Future.wait([
      _all('person_occupations'),
      _all('person_education'),
      _all('person_skills'),
      _allBy('person_contacts', 'person_id', columns: 'person_id, phone, city'),
    ]);
    Map<String, List<T>> byPerson<T>(List<Map<String, dynamic>> rows, T Function(Map<String, dynamic>) f) {
      final out = <String, List<T>>{};
      for (final row in rows) {
        out.putIfAbsent(row['person_id'] as String, () => []).add(f(row));
      }
      return out;
    }

    final jobs = byPerson(r[0], Occupation.fromJson);
    final study = byPerson(r[1], Education.fromJson);
    final skills = byPerson(r[2], Skill.fromJson);
    final contacts = {for (final c in r[3]) c['person_id'] as String: c};
    final ids = {...jobs.keys, ...study.keys, ...skills.keys};
    return [
      for (final id in ids)
        if (graph[id] case final p? when p.isLiving)
          HelpProfile(
            person: p,
            occupations: jobs[id] ?? const [],
            education: study[id] ?? const [],
            skills: skills[id] ?? const [],
            phone: contacts[id]?['phone'] as String?,
            city: contacts[id]?['city'] as String?,
          ),
    ]..sort((a, b) => a.person.displayName.compareTo(b.person.displayName));
  }

  Future<List<Map<String, dynamic>>> _allBy(String table, String order, {String columns = '*'}) async {
    final out = <Map<String, dynamic>>[];
    for (var from = 0;; from += _pageSize) {
      final page = await _db.from(table).select(columns).order(order).range(from, from + _pageSize - 1);
      out.addAll(page);
      if (page.length < _pageSize) return out;
    }
  }

  Future<List<BloodDonor>> bloodDonors() async {
    final rows = await _db.rpc('blood_donors') as List;
    return [for (final r in rows) BloodDonor.fromJson((r as Map).cast<String, dynamic>())];
  }

  Future<List<BloodRequest>> bloodRequests() async {
    final rows = await _db.from('blood_requests').select(BloodRequest.select).order('created_at', ascending: false).limit(50);
    return rows.map(BloodRequest.fromJson).toList();
  }

  Future<void> createBloodRequest(Map<String, dynamic> request) => _db.from('blood_requests').insert(request);

  Future<void> setBloodOffer(String requestId, bool offering) => offering
      ? _db.from('blood_offers').insert({'request_id': requestId})
      : _db.from('blood_offers').delete().eq('request_id', requestId).eq('user_id', userId!);

  Future<void> closeBloodRequest(String id) => _db.from('blood_requests').update({'status': 'closed'}).eq('id', id);

  // ---------------------------------------------------------------- memorial pages

  Future<List<Memory>> memories(String personId) async {
    final rows = await _db.from('memories').select().eq('person_id', personId).order('created_at', ascending: false);
    return rows.map(Memory.fromJson).toList();
  }

  Future<void> addMemory(String personId, String body) =>
      _db.from('memories').insert({'person_id': personId, 'body': body.trim()});

  Future<void> deleteMemory(String id) => _db.from('memories').delete().eq('id', id);

  /// Whether the current user asked to be reminded of this person's anniversary.
  Future<bool> remembranceReminder(String personId) async =>
      (await _db.from('remembrance_reminders').select('person_id').eq('person_id', personId)).isNotEmpty;

  Future<void> setRemembranceReminder(String personId, bool on) => on
      ? _db.from('remembrance_reminders').upsert({'person_id': personId, 'user_id': userId})
      : _db.from('remembrance_reminders').delete().eq('person_id', personId).eq('user_id', userId!);

  // ---------------------------------------------------------------- my settings

  Future<void> setMutedNotifications(List<String> kinds) =>
      _db.from('profiles').update({'muted_notifications': kinds}).eq('id', userId!);
}
