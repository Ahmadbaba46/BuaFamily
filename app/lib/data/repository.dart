import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/account.dart';
import '../models/community.dart';
import '../models/details.dart';
import '../models/family_graph.dart';
import '../models/fund.dart';
import '../models/help.dart';
import '../models/metrics.dart';
import '../models/notification.dart';
import '../models/person.dart';
import '../models/social.dart';
import '../models/story.dart';
import '../services/app_update.dart';
import '../services/offline_cache.dart';

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

  /// Saved-copy key for the signed-in account (see [cachedRead]).
  String _key(String name) => '${userId ?? 'anon'}:$name';

  Future<Profile?> myProfile() async {
    final id = userId;
    if (id == null) return null;
    return cachedRead(
      _key('profile'),
      () => _db.from('profiles').select().eq('id', id).maybeSingle(),
      (raw) => raw == null ? null : Profile.fromJson(Map<String, dynamic>.from(raw as Map)),
    );
  }

  Future<void> updateMyProfile({String? claimNote, String? requestedPersonId, String? locale}) async {
    await _db.from('profiles').update({
      'claim_note': ?claimNote,
      'requested_person_id': ?requestedPersonId,
      'locale': ?locale,
    }).eq('id', userId!);
  }

  // ---------------------------------------------------------------- invites

  /// Admin: a one-time link that approves whoever joins with it.
  Future<String> createInvite({String? personId}) async {
    final row = await _db.from('invites').insert({'person_id': ?personId}).select('code').single();
    return row['code'] as String;
  }

  /// Who an invite is for (works before signing in); null if the code is unknown.
  Future<Map<String, dynamic>?> inviteInfo(String code) async {
    final r = await _db.rpc('invite_info', params: {'p_code': code});
    return r == null ? null : Map<String, dynamic>.from(r as Map);
  }

  Future<void> redeemInvite(String code) => _db.rpc('redeem_invite', params: {'p_code': code});

  // ---------------------------------------------------------------- metrics

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Admin: series and totals for [metrics] over [q] (see admin_metrics).
  Future<MetricsResult> adminMetrics(List<String> metrics, MetricsQuery q) async =>
      MetricsResult.fromJson(Map<String, dynamic>.from(await _db.rpc('admin_metrics', params: {
        'p_metrics': metrics,
        'p_from': _day(q.from),
        'p_to': _day(q.to),
        'p_bucket': q.bucket.name,
        'p_platform': q.platform,
        'p_branch': q.branch,
      }) as Map));

  /// Admin: one metric split by 'branch', 'platform' or 'member'.
  Future<List<BreakdownRow>> adminMetricBreakdown(String metric, MetricsQuery q, String by) async => [
        for (final r in (await _db.rpc('admin_metric_breakdown', params: {
          'p_metric': metric,
          'p_from': _day(q.from),
          'p_to': _day(q.to),
          'p_by': by,
          'p_platform': q.platform,
          'p_branch': q.branch,
        })) as List)
          BreakdownRow.fromJson(Map<String, dynamic>.from(r as Map)),
      ];

  /// Admin: where the family stands today.
  Future<Map<String, dynamic>> adminSnapshot() async =>
      Map<String, dynamic>.from(await _db.rpc('admin_snapshot') as Map);

  /// Admin: every account with its person, devices and activity.
  Future<List<UserRow>> adminUsers() async =>
      [for (final r in (await _db.rpc('admin_users')) as List) UserRow.fromJson(Map<String, dynamic>.from(r as Map))];

  /// "I'm here": last seen, and a day of activity for the metrics.
  Future<void> touchActivity(String platform, {int? build}) =>
      _db.rpc('touch_activity', params: {'p_platform': platform, 'p_build': ?build});

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

  Future<AppSettings> settings() => cachedRead(
        _key('settings'),
        () => _db.from('app_settings').select().maybeSingle(),
        (raw) => raw == null ? const AppSettings() : AppSettings.fromJson(Map<String, dynamic>.from(raw as Map)),
      );

  Future<void> updateSettings(Map<String, dynamic> changes) async {
    await _db.from('app_settings').update(changes).eq('id', true);
  }

  // ---------------------------------------------------------------- family graph

  Future<FamilyGraph> loadGraph() => cachedRead(
        _key('graph'),
        () async {
          final results = await Future.wait([_all('persons'), _all('unions'), _all('parent_child')]);
          return {'persons': results[0], 'unions': results[1], 'links': results[2]};
        },
        (raw) {
          final m = raw as Map;
          return FamilyGraph(
            persons: jsonRows(m['persons']).map(Person.fromJson),
            unions: jsonRows(m['unions']).map(FamilyUnion.fromJson).toList(),
            links: jsonRows(m['links']).map(ParentLink.fromJson).toList(),
          );
        },
      );

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

  /// Admin: removes the link only; both people stay in the tree.
  Future<void> removeParentChild(String parentId, String childId) =>
      _db.from('parent_child').delete().eq('parent_id', parentId).eq('child_id', childId);

  Future<void> removeUnion(String unionId) => _db.from('unions').delete().eq('id', unionId);

  /// Admin: links in the tree that look wrong.
  Future<List<Map<String, dynamic>>> treeProblems() async =>
      ((await _db.rpc('tree_problems')) as List).cast<Map<String, dynamic>>();

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

  /// Many photo links in a few requests (for the tree, where everyone shows).
  Future<Map<String, String>> photoUrls(List<String> paths) async {
    final result = <String, String>{};
    for (var i = 0; i < paths.length; i += 200) {
      final batch = paths.sublist(i, i + 200 > paths.length ? paths.length : i + 200);
      final signed = await _db.storage.from(photosBucket).createSignedUrlsResult(batch, 60 * 60 * 6);
      for (final s in signed.whereType<SignedUrlSuccess>()) {
        result[s.path] = s.signedUrl;
      }
    }
    return result;
  }

  // ---------------------------------------------------------------- details

  Future<PersonDetails> details(String personId) => cachedRead(
        _key('details:$personId'),
        () => Future.wait([
          _db.from('person_education').select().eq('person_id', personId).order('start_year'),
          _db.from('person_occupations').select().eq('person_id', personId).order('start_year'),
          _db.from('person_skills').select().eq('person_id', personId).order('skill'),
          _db.from('person_contacts').select().eq('person_id', personId),
          _db.from('person_health').select().eq('person_id', personId),
        ]),
        (raw) {
          final r = [for (final part in raw as List) jsonRows(part)];
          return PersonDetails(
            education: r[0].map(Education.fromJson).toList(),
            occupations: r[1].map(Occupation.fromJson).toList(),
            skills: r[2].map(Skill.fromJson).toList(),
            contact: r[3].isEmpty ? null : Contact.fromJson(r[3].first),
            health: r[4].isEmpty ? null : Health.fromJson(r[4].first),
          );
        },
      );

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

  Future<Map<String, Member>> memberDirectory() => cachedRead(
        _key('members'),
        () => _db.rpc('member_directory'),
        (raw) => {for (final r in jsonRows(raw)) r['user_id'] as String: Member.fromJson(r)},
      );

  Future<List<Post>> feed({int limit = 60}) => cachedRead(
        _key('feed'),
        () => _db.from('posts').select(Post.select).order('created_at', ascending: false).limit(limit),
        (raw) => jsonRows(raw).map(Post.fromJson).toList(),
      );

  /// One moment or announcement; null when it was removed.
  Future<Post?> post(String id) async {
    final row = await _db.from('posts').select(Post.select).eq('id', id).maybeSingle();
    return row == null ? null : Post.fromJson(row);
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

  /// A photo for a suggested person or edit, kept in the member's own uploads
  /// folder until an admin approves the request (which then uses its path).
  Future<String> uploadPendingPhoto(PickedImage img) => _upload(img, 0);

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

  Future<List<FamilyEvent>> events() => cachedRead(
        _key('events'),
        () => _db.from('events').select(FamilyEvent.select).order('starts_at').limit(500),
        (raw) => jsonRows(raw).map(FamilyEvent.fromJson).toList(),
      );

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
      .order('created_at', ascending: false)
      .limit(100)
      // Live inserts can arrive out of order; newest first, always.
      .map((rows) => rows.map(AppNotification.fromJson).whereType<AppNotification>().toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

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

  // ---------------------------------------------------------------- welfare fund

  static const receiptsBucket = 'receipts';

  Future<FundOverview> fundOverview() async {
    final j = await _db.rpc('fund_overview');
    return j == null ? const FundOverview() : FundOverview.fromJson((j as Map).cast<String, dynamic>());
  }

  /// Causes the user may see, with confirmed totals.
  Future<List<FundCause>> fundCauses() async {
    final r = await Future.wait<dynamic>([
      _db.from('fund_causes').select().order('created_at', ascending: false),
      _db.rpc('fund_cause_totals'),
    ]);
    final totals = {for (final t in (r[1] as List)) (t as Map)['cause_id'] as String: t.cast<String, dynamic>()};
    return [for (final c in (r[0] as List)) FundCause.fromJson((c as Map).cast<String, dynamic>(), totals: totals[c['id']])];
  }

  /// Your own contributions; the committee gets everyone's.
  Future<List<Contribution>> contributions() async {
    final rows = await _db.from('fund_contributions').select().order('created_at', ascending: false).limit(300);
    return rows.map(Contribution.fromJson).toList();
  }

  Future<void> recordContribution({
    String? causeId,
    required double amount,
    required PayMethod method,
    bool showName = true,
    PickedImage? receipt,
  }) async {
    String? path;
    if (receipt != null) {
      final ext = receipt.extension.toLowerCase().replaceAll('jpeg', 'jpg');
      path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _db.storage.from(receiptsBucket).uploadBinary(
            path,
            Uint8List.fromList(receipt.bytes),
            fileOptions: FileOptions(contentType: ext == 'pdf' ? 'application/pdf' : (ext == 'jpg' ? 'image/jpeg' : 'image/$ext')),
          );
    }
    await _db.from('fund_contributions').insert({
      'cause_id': causeId,
      'amount': amount,
      'method': method.name,
      'show_name': showName,
      'receipt_path': path,
    });
  }

  Future<String> receiptUrl(String path) => _db.storage.from(receiptsBucket).createSignedUrl(path, 60 * 10);

  Future<void> reviewContribution(String id, ContributionStatus status) =>
      _db.from('fund_contributions').update({'status': status.name}).eq('id', id);

  Future<void> withdrawContribution(String id) => _db.from('fund_contributions').delete().eq('id', id);

  Future<void> createCause(Map<String, dynamic> cause) => _db.from('fund_causes').insert(cause);

  Future<void> updateCause(String id, Map<String, dynamic> changes) =>
      _db.from('fund_causes').update(changes).eq('id', id);

  Future<void> recordPayout({String? causeId, required double amount, String? note}) =>
      _db.from('fund_payouts').insert({'cause_id': causeId, 'amount': amount, 'note': note, 'recorded_by': userId});

  Future<void> updateFundSettings(Map<String, dynamic> changes) =>
      _db.from('fund_settings').update(changes).eq('id', true);

  Future<void> setTreasurer(String userId, bool on) =>
      _db.rpc('admin_set_treasurer', params: {'p_user_id': userId, 'p_on': on});

  // ---------------------------------------------------------------- mentorship

  Future<Mentorship> mentorship() async {
    final r = await Future.wait([
      _db.from('mentors').select().order('created_at'),
      _db.from('mentee_requests').select().order('created_at', ascending: false),
      _db.from('mentor_asks').select().order('created_at', ascending: false).limit(100),
      _db.from('opportunities').select().order('created_at', ascending: false).limit(100),
    ]);
    return Mentorship(
      mentors: r[0].map(Mentor.fromJson).toList(),
      students: r[1].map(MenteeRequest.fromJson).toList(),
      asks: r[2].map(MentorAsk.fromJson).toList(),
      opportunities: r[3].map(Opportunity.fromJson).toList(),
    );
  }

  Future<void> setMentor({required String areas, String? note}) =>
      _db.from('mentors').upsert({'user_id': userId, 'areas': areas.trim(), 'note': note});

  Future<void> stopMentoring() => _db.from('mentors').delete().eq('user_id', userId!);

  Future<void> setMenteeRequest({required String field, required String message}) =>
      _db.from('mentee_requests').upsert({'user_id': userId, 'field': field.trim(), 'message': message.trim()});

  Future<void> removeMenteeRequest() => _db.from('mentee_requests').delete().eq('user_id', userId!);

  Future<void> askMentor(String mentorUserId, String message) =>
      _db.from('mentor_asks').insert({'mentor_user_id': mentorUserId, 'message': message.trim()});

  Future<void> deleteAsk(String id) => _db.from('mentor_asks').delete().eq('id', id);

  Future<void> shareOpportunity({required String title, String? details, String? url, DateTime? deadline}) =>
      _db.from('opportunities').insert({
        'title': title.trim(),
        'details': details,
        'url': url,
        'deadline': deadline == null
            ? null
            : '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}',
      });

  Future<void> deleteOpportunity(String id) => _db.from('opportunities').delete().eq('id', id);

  // ---------------------------------------------------------------- polls

  Future<List<Poll>> polls() async {
    final r = await Future.wait<dynamic>([
      _db.from('polls').select('*, poll_options(id, label, sort_order)').order('created_at', ascending: false).limit(100),
      _db.from('poll_votes').select('poll_id, option_id'),
      _db.rpc('poll_results'),
    ]);
    final mine = {for (final v in (r[1] as List)) (v as Map)['poll_id'] as String: v['option_id'] as String};
    final counts = <String, int>{};
    final totals = <String, (int, int)>{};
    for (final row in (r[2] as List)) {
      final m = row as Map;
      counts[m['option_id'] as String] = m['votes'] as int;
      totals[m['poll_id'] as String] = (m['total'] as int, m['eligible'] as int);
    }
    return [
      for (final p in (r[0] as List).cast<Map<String, dynamic>>())
        Poll(
          id: p['id'] as String,
          question: p['question'] as String,
          createdBy: p['created_by'] as String,
          createdAt: DateTime.parse(p['created_at'] as String).toLocal(),
          context: p['context'] as String?,
          closesAt: p['closes_at'] == null ? null : DateTime.parse(p['closes_at'] as String).toLocal(),
          closed: p['closed'] as bool? ?? false,
          options: [
            for (final o in ((p['poll_options'] as List).cast<Map<String, dynamic>>()
              ..sort((a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int))))
              PollOption(id: o['id'] as String, label: o['label'] as String, votes: counts[o['id']] ?? 0),
          ],
          myOptionId: mine[p['id']],
          resultsVisible: totals.containsKey(p['id']),
          total: totals[p['id']]?.$1 ?? 0,
          eligible: totals[p['id']]?.$2 ?? 0,
        ),
    ];
  }

  Future<void> createPoll({required String question, String? context, DateTime? closesAt, required List<String> options}) async {
    final row = await _db
        .from('polls')
        .insert({'question': question.trim(), 'context': context, 'closes_at': closesAt?.toUtc().toIso8601String()})
        .select('id')
        .single();
    await _db.from('poll_options').insert([
      for (final (i, o) in options.indexed) {'poll_id': row['id'], 'label': o.trim(), 'sort_order': i},
    ]);
  }

  Future<void> vote(String pollId, String optionId) =>
      _db.from('poll_votes').upsert({'poll_id': pollId, 'user_id': userId, 'option_id': optionId});

  Future<void> closePoll(String id) => _db.from('polls').update({'closed': true}).eq('id', id);

  Future<void> deletePoll(String id) => _db.from('polls').delete().eq('id', id);

  // ---------------------------------------------------------------- elders' stories

  static const storiesBucket = 'stories';

  Future<List<Story>> stories() async {
    final rows = await _db.from('stories').select().order('created_at', ascending: false);
    return rows.map(Story.fromJson).toList();
  }

  Future<String> storyAudioUrl(String path) => _db.storage.from(storiesBucket).createSignedUrl(path, 60 * 60 * 6);

  static String audioMime(String ext) => switch (ext.toLowerCase()) {
        'm4a' || 'mp4' || 'aac' => 'audio/mp4',
        'mp3' => 'audio/mpeg',
        'wav' => 'audio/wav',
        'ogg' || 'oga' || 'opus' => 'audio/ogg',
        'webm' => 'audio/webm',
        '3gp' => 'audio/3gpp',
        _ => 'audio/mpeg',
      };

  Future<void> addStory({
    required Uint8List audio,
    required String extension,
    required String title,
    String? speakerId,
    String? speakerName,
    required String language,
    int? durationSeconds,
    String? sourceNote,
    String? transcript,
  }) async {
    final ext = extension.toLowerCase();
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from(storiesBucket).uploadBinary(path, audio, fileOptions: FileOptions(contentType: audioMime(ext)));
    try {
      await _db.from('stories').insert({
        'title': title.trim(),
        'speaker_id': speakerId,
        'speaker_name': speakerId == null ? speakerName?.trim() : null,
        'language': language,
        'audio_path': path,
        'duration_seconds': durationSeconds,
        'source_note': sourceNote,
        'transcript': transcript,
      });
    } catch (_) {
      await _db.storage.from(storiesBucket).remove([path]);
      rethrow;
    }
  }

  Future<void> updateStory(String id, Map<String, dynamic> changes) => _db.from('stories').update(changes).eq('id', id);

  Future<void> deleteStory(Story s) async {
    await _db.from('stories').delete().eq('id', s.id);
    await _db.storage.from(storiesBucket).remove([s.audioPath]);
  }

  // ---------------------------------------------------------------- import, export & backup

  /// Contact and health rows for everyone (admins can read them all).
  Future<({Map<String, Map<String, dynamic>> contacts, Map<String, Map<String, dynamic>> health})> allDetails() async {
    final r = await Future.wait([_allBy('person_contacts', 'person_id'), _allBy('person_health', 'person_id')]);
    return (
      contacts: {for (final c in r[0]) c['person_id'] as String: c},
      health: {for (final h in r[1]) h['person_id'] as String: h},
    );
  }

  /// Adds the reviewed import. Returns counts of people, parents, couples and skipped links.
  Future<Map<String, dynamic>> adminImport(Map<String, dynamic> plan) async =>
      Map<String, dynamic>.from(await _db.rpc('admin_import', params: {'p_data': plan}) as Map);

  Future<List<Backup>> backups() async {
    final rows = await _db.rpc('admin_backups') as List;
    return rows.map((r) => Backup.fromJson(Map<String, dynamic>.from(r as Map))).toList();
  }

  Future<void> backupNow() => _db.rpc('admin_backup_now');

  Future<Object?> backupData(int slot) => _db.rpc('admin_backup', params: {'p_slot': slot});

  /// Puts a stored backup back (slot -1 is the restore point). With [dryRun]
  /// nothing changes; the counts say what would. Returns per-table
  /// {added, updated, skipped}.
  Future<Map<String, dynamic>> restoreBackup(int slot, {bool undoChanges = false, bool dryRun = true}) async =>
      Map<String, dynamic>.from(await _db.rpc('admin_restore_backup',
          params: {'p_slot': slot, 'p_overwrite': undoChanges, 'p_dry_run': dryRun}) as Map);

  /// The same for a downloaded backup file.
  Future<Map<String, dynamic>> restoreData(Object data, {bool undoChanges = false, bool dryRun = true}) async =>
      Map<String, dynamic>.from(await _db.rpc('admin_restore',
          params: {'p_data': data, 'p_overwrite': undoChanges, 'p_dry_run': dryRun}) as Map);

  // ---------------------------------------------------------------- push notifications

  Future<void> registerPushToken(String token, String platform) =>
      _db.rpc('register_push_token', params: {'p_token': token, 'p_platform': platform});

  // ---------------------------------------------------------------- Android app

  Future<AndroidRelease?> androidRelease() async {
    final r = await _db.rpc('android_release');
    return r == null ? null : AndroidRelease.fromJson(Map<String, dynamic>.from(r as Map));
  }

  /// Public download link (the 'releases' bucket is public).
  String releaseUrl(String path) => _db.storage.from('releases').getPublicUrl(path);

  /// Admin: uploads a new APK and tells members with the Android app.
  /// Each version gets its own file name, so nobody downloads a cached old one.
  Future<void> publishAndroid({
    required Uint8List bytes,
    required int build,
    required String version,
    String? notes,
    String? previousPath,
  }) async {
    final path = 'bua-family-$version.apk';
    await _db.storage.from('releases').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'application/vnd.android.package-archive'),
        );
    await _db.rpc('admin_publish_android',
        params: {'p_build': build, 'p_version': version, 'p_path': path, 'p_notes': notes});
    if (previousPath != null && previousPath != path) {
      try {
        await _db.storage.from('releases').remove([previousPath]);
      } catch (_) {}
    }
  }

  /// Counts a notification as delivered (for the admin's push status).
  Future<void> pushAck(String notificationId) => _db.rpc('push_ack', params: {'p_id': notificationId});

  Future<void> unregisterPushToken(String token) => _db.from('push_tokens').delete().eq('token', token);

  Future<Map<String, dynamic>> pushStatus() async =>
      Map<String, dynamic>.from(await _db.rpc('push_status') as Map);

  /// Admin: save the Firebase service account.
  Future<void> setPush({required String serviceAccount}) => _db.rpc('admin_set_push', params: {
        'p_service_account': serviceAccount,
        // The 'push' Edge Function in this same project.
        'p_function_url': _db.rest.url.replaceFirst(RegExp(r'/rest/v1/?$'), '/functions/v1/push'),
      });

  Future<void> sendTestPush() => _db.rpc('send_test_push');
}
