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
    this.phone,
    this.smsOptIn = false,
    this.smsBirthdays = true,
    this.smsEvents = true,
    this.mutedNotifications = const [],
    this.isTreasurer = false,
    this.lastSeenAt,
    this.lastPlatform,
    this.appBuild,
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

  /// International format without "+", e.g. 2348031234567.
  final String? phone;
  final bool smsOptIn;
  final bool smsBirthdays;
  final bool smsEvents;

  /// Notification kinds (database names) this member chose not to receive.
  final List<String> mutedNotifications;

  /// Treasurers confirm welfare fund contributions with the admins.
  final bool isTreasurer;

  /// When the member last opened the app, from which platform ('android',
  /// 'web'), and for the Android app which build.
  final DateTime? lastSeenAt;
  final String? lastPlatform;
  final int? appBuild;

  /// Admins and treasurers manage the welfare fund.
  bool get isCommittee => isActive && (isAdmin || isTreasurer);

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
        phone: j['phone'] as String?,
        smsOptIn: j['sms_opt_in'] as bool? ?? false,
        smsBirthdays: j['sms_birthdays'] as bool? ?? true,
        smsEvents: j['sms_events'] as bool? ?? true,
        mutedNotifications: [for (final k in (j['muted_notifications'] as List? ?? const [])) k as String],
        isTreasurer: j['is_treasurer'] as bool? ?? false,
        lastSeenAt: DateTime.tryParse(j['last_seen_at'] as String? ?? '')?.toLocal(),
        lastPlatform: j['last_platform'] as String?,
        appBuild: (j['app_build'] as num?)?.toInt(),
      );
}

/// An account as the admin's users list shows it.
class UserRow {
  const UserRow({
    required this.profile,
    this.personName,
    this.devices = const {},
    this.activeDays30 = 0,
    this.posts = 0,
    this.comments = 0,
  });

  final Profile profile;

  /// The person in the tree the account is linked to.
  final String? personName;

  /// Devices with notifications on, by platform ('android', 'web').
  final Map<String, int> devices;
  final int activeDays30;
  final int posts;
  final int comments;

  String get name => profile.displayName.isNotEmpty ? profile.displayName : (profile.email ?? '?');
  bool get hasPush => devices.values.any((n) => n > 0);

  factory UserRow.fromJson(Map<String, dynamic> j) => UserRow(
        profile: Profile.fromJson(j),
        personName: j['person_name'] as String?,
        devices: {for (final e in (j['devices'] as Map? ?? const {}).entries) e.key as String: (e.value as num).toInt()},
        activeDays30: (j['active_days_30'] as num?)?.toInt() ?? 0,
        posts: (j['posts'] as num?)?.toInt() ?? 0,
        comments: (j['comments'] as num?)?.toInt() ?? 0,
      );
}

class AppSettings {
  const AppSettings({
    this.familyName = 'Bua',
    this.memberContributionsEnabled = false,
    this.rootPersonId,
    this.smsEnabled = false,
    this.smsSenderId,
    this.smsChannel = 'generic',
    this.weeklyBackup = true,
    this.pushEnabled = false,
    this.developerName,
    this.developerCompany,
    this.developerPhone,
    this.developerEmail,
    this.developerWebsite,
    this.hijriOffset = 0,
    this.islamicGreetings = true,
  });

  final String familyName;
  final bool memberContributionsEnabled;
  final String? rootPersonId;
  final bool smsEnabled;
  final String? smsSenderId;

  /// 'generic' or 'dnd' (Termii routes).
  final String smsChannel;

  /// Whether the database keeps a weekly backup.
  final bool weeklyBackup;

  /// An admin has set up push notifications.
  final bool pushEnabled;

  /// Who made the app, for the About page.
  final String? developerName;
  final String? developerCompany;
  final String? developerPhone;
  final String? developerEmail;
  final String? developerWebsite;

  /// Days added to the calculated Islamic calendar to match the moon sighting.
  final int hijriOffset;

  /// Ramadan, Eid and new year greetings to everyone.
  final bool islamicGreetings;

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        familyName: j['family_name'] as String? ?? 'Bua',
        memberContributionsEnabled: j['member_contributions_enabled'] as bool? ?? false,
        rootPersonId: j['root_person_id'] as String?,
        smsEnabled: j['sms_enabled'] as bool? ?? false,
        smsSenderId: j['sms_sender_id'] as String?,
        smsChannel: j['sms_channel'] as String? ?? 'generic',
        weeklyBackup: j['weekly_backup'] as bool? ?? true,
        pushEnabled: j['push_enabled'] as bool? ?? false,
        developerName: j['developer_name'] as String?,
        developerCompany: j['developer_company'] as String?,
        developerPhone: j['developer_phone'] as String?,
        developerEmail: j['developer_email'] as String?,
        developerWebsite: j['developer_website'] as String?,
        hijriOffset: (j['hijri_offset'] as num?)?.toInt() ?? 0,
        islamicGreetings: j['islamic_greetings'] as bool? ?? true,
      );
}

enum RequestKind { createPerson, updatePerson, addParentChild, addUnion, removeParentChild, removeUnion }

enum RequestStatus { pending, approved, rejected }

const _kindNames = {
  RequestKind.createPerson: 'create_person',
  RequestKind.updatePerson: 'update_person',
  RequestKind.addParentChild: 'add_parent_child',
  RequestKind.addUnion: 'add_union',
  RequestKind.removeParentChild: 'remove_parent_child',
  RequestKind.removeUnion: 'remove_union',
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
