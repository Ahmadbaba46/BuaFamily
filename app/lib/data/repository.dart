import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/account.dart';
import '../models/details.dart';
import '../models/family_graph.dart';
import '../models/person.dart';

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
}
