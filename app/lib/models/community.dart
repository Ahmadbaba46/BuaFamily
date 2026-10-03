/// Mentorship and polls.
library;

DateTime _ts(Object? v) => DateTime.parse(v as String).toLocal();

class Mentor {
  const Mentor({required this.userId, required this.areas, this.note});

  final String userId;
  final String areas;
  final String? note;

  factory Mentor.fromJson(Map<String, dynamic> j) =>
      Mentor(userId: j['user_id'] as String, areas: j['areas'] as String, note: j['note'] as String?);
}

class MenteeRequest {
  const MenteeRequest({required this.userId, required this.field, required this.message, required this.createdAt});

  final String userId;
  final String field;
  final String message;
  final DateTime createdAt;

  factory MenteeRequest.fromJson(Map<String, dynamic> j) => MenteeRequest(
        userId: j['user_id'] as String,
        field: j['field'] as String,
        message: j['message'] as String,
        createdAt: _ts(j['created_at']),
      );
}

class MentorAsk {
  const MentorAsk({
    required this.id,
    required this.mentorUserId,
    required this.fromUserId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String mentorUserId;
  final String fromUserId;
  final String message;
  final DateTime createdAt;

  factory MentorAsk.fromJson(Map<String, dynamic> j) => MentorAsk(
        id: j['id'] as String,
        mentorUserId: j['mentor_user_id'] as String,
        fromUserId: j['from_user_id'] as String,
        message: j['message'] as String,
        createdAt: _ts(j['created_at']),
      );
}

class Opportunity {
  const Opportunity({
    required this.id,
    required this.title,
    required this.postedBy,
    required this.createdAt,
    this.details,
    this.url,
    this.deadline,
  });

  final String id;
  final String title;
  final String postedBy;
  final DateTime createdAt;
  final String? details;
  final String? url;
  final DateTime? deadline;

  factory Opportunity.fromJson(Map<String, dynamic> j) => Opportunity(
        id: j['id'] as String,
        title: j['title'] as String,
        postedBy: j['posted_by'] as String,
        createdAt: _ts(j['created_at']),
        details: j['details'] as String?,
        url: j['url'] as String?,
        deadline: j['deadline'] == null ? null : DateTime.parse(j['deadline'] as String),
      );
}

/// Everything shown on the mentorship page.
class Mentorship {
  const Mentorship({
    this.mentors = const [],
    this.students = const [],
    this.asks = const [],
    this.opportunities = const [],
  });

  final List<Mentor> mentors;
  final List<MenteeRequest> students;

  /// Asks you sent or received.
  final List<MentorAsk> asks;
  final List<Opportunity> opportunities;
}

class PollOption {
  const PollOption({required this.id, required this.label, this.votes = 0});

  final String id;
  final String label;
  final int votes;
}

class Poll {
  const Poll({
    required this.id,
    required this.question,
    required this.createdBy,
    required this.createdAt,
    this.context,
    this.closesAt,
    this.closed = false,
    this.options = const [],
    this.myOptionId,
    this.resultsVisible = false,
    this.total = 0,
    this.eligible = 0,
  });

  final String id;
  final String question;
  final String createdBy;
  final DateTime createdAt;
  final String? context;
  final DateTime? closesAt;

  /// Closed early by the creator or an admin.
  final bool closed;
  final List<PollOption> options;
  final String? myOptionId;

  /// Counts are shown once you've voted or the poll has closed.
  final bool resultsVisible;
  final int total;
  final int eligible;

  bool isOpen(DateTime now) => !closed && (closesAt == null || closesAt!.isAfter(now));

  /// When it stopped taking votes.
  DateTime decidedAt(DateTime now) => closesAt != null && closesAt!.isBefore(now) ? closesAt! : createdAt;

  PollOption? get leader {
    if (options.isEmpty || total == 0) return null;
    return options.reduce((a, b) => b.votes > a.votes ? b : a);
  }

  int percent(PollOption o) => total == 0 ? 0 : (o.votes * 100 / total).round();
}
