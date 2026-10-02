enum AppRole { admin, member }

enum AccountStatus { pending, active, suspended }

/// A signed-in user's account (not the same as a [Person] in the tree).
class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.role,
    required this.status,
    this.email,
    this.personId,
    this.requestedPersonId,
    this.claimNote,
    this.locale = 'en',
    this.createdAt,
  });

  final String id;
  final String displayName;
  final String? email;
  final AppRole role;
  final AccountStatus status;
  final String? personId;
  final String? requestedPersonId;
  final String? claimNote;
  final String locale;
  final DateTime? createdAt;

  bool get isAdmin => role == AppRole.admin && status == AccountStatus.active;
  bool get isActive => status == AccountStatus.active;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        displayName: j['display_name'] as String? ?? '',
        email: j['email'] as String?,
        role: AppRole.values.byName(j['role'] as String),
        status: AccountStatus.values.byName(j['status'] as String),
        personId: j['person_id'] as String?,
        requestedPersonId: j['requested_person_id'] as String?,
        claimNote: j['claim_note'] as String?,
        locale: j['locale'] as String? ?? 'en',
        createdAt: j['created_at'] == null ? null : DateTime.tryParse(j['created_at'] as String),
      );
}

class AppSettings {
  const AppSettings({
    this.familyName = 'Bua',
    this.memberContributionsEnabled = false,
    this.rootPersonId,
  });

  final String familyName;
  final bool memberContributionsEnabled;
  final String? rootPersonId;

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        familyName: j['family_name'] as String? ?? 'Bua',
        memberContributionsEnabled: j['member_contributions_enabled'] as bool? ?? false,
        rootPersonId: j['root_person_id'] as String?,
      );
}

enum RequestKind { createPerson, updatePerson, addParentChild, addUnion }

enum RequestStatus { pending, approved, rejected }

const _kindNames = {
  RequestKind.createPerson: 'create_person',
  RequestKind.updatePerson: 'update_person',
  RequestKind.addParentChild: 'add_parent_child',
  RequestKind.addUnion: 'add_union',
};

extension RequestKindDb on RequestKind {
  String get dbName => _kindNames[this]!;
  static RequestKind parse(String v) => _kindNames.entries.firstWhere((e) => e.value == v).key;
}

/// A member's proposal, applied only when an admin approves it.
class ChangeRequest {
  const ChangeRequest({
    required this.id,
    required this.kind,
    required this.payload,
    required this.status,
    required this.requestedBy,
    required this.createdAt,
    this.targetPersonId,
    this.reviewNote,
    this.resultPersonId,
  });

  final String id;
  final RequestKind kind;
  final Map<String, dynamic> payload;
  final RequestStatus status;
  final String requestedBy;
  final DateTime createdAt;
  final String? targetPersonId;
  final String? reviewNote;
  final String? resultPersonId;

  factory ChangeRequest.fromJson(Map<String, dynamic> j) => ChangeRequest(
        id: j['id'] as String,
        kind: RequestKindDb.parse(j['kind'] as String),
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        status: RequestStatus.values.byName(j['status'] as String),
        requestedBy: j['requested_by'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        targetPersonId: j['target_person_id'] as String?,
        reviewNote: j['review_note'] as String?,
        resultPersonId: j['result_person_id'] as String?,
      );
}
