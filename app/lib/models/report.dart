/// Something a member reported to the admins.
enum ReportKind { post, photo, comment, profile, member, message }

enum ReportReason { childSafety, abuse, spam, other }

enum ReportStatus { open, removed, actioned, dismissed }

const _reasonNames = {
  ReportReason.childSafety: 'child_safety',
  ReportReason.abuse: 'abuse',
  ReportReason.spam: 'spam',
  ReportReason.other: 'other',
};

String reportReasonName(ReportReason r) => _reasonNames[r]!;

class Report {
  const Report({
    required this.id,
    required this.kind,
    required this.targetId,
    required this.reason,
    required this.createdAt,
    this.reporterId,
    this.targetUser,
    this.note,
    this.snapshot = const {},
    this.link,
    this.status = ReportStatus.open,
    this.reviewedAt,
  });

  final String id;
  final ReportKind kind;
  final String targetId;
  final ReportReason reason;
  final DateTime createdAt;
  final String? reporterId;

  /// Whose content it is (their account), when known.
  final String? targetUser;
  final String? note;

  /// A copy of what was reported, taken when it was reported.
  final Map<String, dynamic> snapshot;

  /// Where it is in the app, when it can be opened.
  final String? link;
  final ReportStatus status;
  final DateTime? reviewedAt;

  bool get isOpen => status == ReportStatus.open;

  /// The words that were reported (a moment, comment or message), or the photo's caption.
  String? get text => (snapshot['body'] ?? snapshot['caption']) as String?;

  /// Who wrote or posted it.
  String? get author => snapshot['author'] as String? ?? snapshot['name'] as String?;

  factory Report.fromJson(Map<String, dynamic> j) => Report(
        id: j['id'] as String,
        kind: ReportKind.values.byName(j['kind'] as String),
        targetId: j['target_id'] as String,
        reason: _reasonNames.entries.firstWhere((e) => e.value == j['reason'], orElse: () => _reasonNames.entries.last).key,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        reporterId: j['reporter_id'] as String?,
        targetUser: j['target_user'] as String?,
        note: j['note'] as String?,
        snapshot: (j['snapshot'] as Map?)?.cast<String, dynamic>() ?? const {},
        link: j['link'] as String?,
        status: ReportStatus.values.byName(j['status'] as String),
        reviewedAt: j['reviewed_at'] == null ? null : DateTime.parse(j['reviewed_at'] as String).toLocal(),
      );
}
