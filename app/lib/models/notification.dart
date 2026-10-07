/// An entry in the in-app notification inbox. The text is written by the app
/// from [kind] and [data], in the reader's language.
enum NotificationKind { event, announcement, birthday, eventReminder, tagged, comment, bloodRequest, bloodOffer, remembrance, memory, fundContribution, fundConfirmed, fundRequest, mentorRequest, opportunity, poll, story, test, accountRequest, changeRequest, accountApproved, requestReviewed, appUpdate, mentorReply, occasion, duesReminder, claimReviewed, weeklySummary, adminAlert, directMessage, contentReport }

const _kinds = {
  'event': NotificationKind.event,
  'announcement': NotificationKind.announcement,
  'birthday': NotificationKind.birthday,
  'event_reminder': NotificationKind.eventReminder,
  'tagged': NotificationKind.tagged,
  'comment': NotificationKind.comment,
  'blood_request': NotificationKind.bloodRequest,
  'blood_offer': NotificationKind.bloodOffer,
  'remembrance': NotificationKind.remembrance,
  'memory': NotificationKind.memory,
  'fund_contribution': NotificationKind.fundContribution,
  'fund_confirmed': NotificationKind.fundConfirmed,
  'fund_request': NotificationKind.fundRequest,
  'mentor_request': NotificationKind.mentorRequest,
  'mentor_reply': NotificationKind.mentorReply,
  'occasion': NotificationKind.occasion,
  'dues_reminder': NotificationKind.duesReminder,
  'weekly_summary': NotificationKind.weeklySummary,
  'admin_alert': NotificationKind.adminAlert,
  'direct_message': NotificationKind.directMessage,
  'content_report': NotificationKind.contentReport,
  'claim_reviewed': NotificationKind.claimReviewed,
  'opportunity': NotificationKind.opportunity,
  'poll': NotificationKind.poll,
  'story': NotificationKind.story,
  'test': NotificationKind.test,
  'account_request': NotificationKind.accountRequest,
  'change_request': NotificationKind.changeRequest,
  'account_approved': NotificationKind.accountApproved,
  'request_reviewed': NotificationKind.requestReviewed,
  'app_update': NotificationKind.appUpdate,
};

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.data = const {},
    this.link,
    this.actorId,
    this.readAt,
  });

  final String id;
  final NotificationKind kind;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final String? link;
  final String? actorId;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  String? str(String key) => data[key] as String?;

  DateTime? date(String key) => data[key] == null ? null : DateTime.tryParse(data[key] as String)?.toLocal();

  /// Null for kinds this version of the app does not know yet.
  static AppNotification? fromJson(Map<String, dynamic> j) {
    final kind = _kinds[j['kind']];
    if (kind == null) return null;
    return AppNotification(
      id: j['id'] as String,
      kind: kind,
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      data: (j['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      link: j['link'] as String?,
      actorId: j['actor_id'] as String?,
      readAt: j['read_at'] == null ? null : DateTime.parse(j['read_at'] as String).toLocal(),
    );
  }
}

/// What admins see about SMS sending.
class SmsStatus {
  const SmsStatus({
    this.keySaved = false,
    this.baseUrl,
    this.queued = 0,
    this.sent7d = 0,
    this.failed7d = 0,
    this.subscribers = 0,
    this.lastError,
  });

  final bool keySaved;
  final String? baseUrl;
  final int queued;
  final int sent7d;
  final int failed7d;
  final int subscribers;
  final String? lastError;

  factory SmsStatus.fromJson(Map<String, dynamic> j) => SmsStatus(
        keySaved: j['key_saved'] as bool? ?? false,
        baseUrl: j['base_url'] as String?,
        queued: (j['queued'] as num?)?.toInt() ?? 0,
        sent7d: (j['sent_7d'] as num?)?.toInt() ?? 0,
        failed7d: (j['failed_7d'] as num?)?.toInt() ?? 0,
        subscribers: (j['subscribers'] as num?)?.toInt() ?? 0,
        lastError: j['last_error'] as String?,
      );
}
