DateTime _ts(Object? v) => DateTime.parse(v as String).toLocal();
DateTime? _tsOrNull(Object? v) => v == null ? null : _ts(v);

/// A private conversation between two family members.
class DmThread {
  const DmThread({
    required this.id,
    required this.userA,
    required this.userB,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
    this.lastMessageBy,
    this.aReadAt,
    this.bReadAt,
  });

  final String id;
  final String userA;
  final String userB;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final String? lastMessageBy;
  final DateTime? aReadAt;
  final DateTime? bReadAt;

  /// The other person in the conversation.
  String otherThan(String? me) => me == userA ? userB : userA;

  /// Something new from the other person since [me] last looked.
  bool unreadFor(String? me) {
    if (lastMessageAt == null || lastMessageBy == null || lastMessageBy == me) return false;
    final read = me == userA ? aReadAt : bReadAt;
    return read == null || read.isBefore(lastMessageAt!);
  }

  /// For sorting: the latest activity.
  DateTime get activeAt => lastMessageAt ?? createdAt;

  factory DmThread.fromJson(Map<String, dynamic> j) => DmThread(
        id: j['id'] as String,
        userA: j['user_a'] as String,
        userB: j['user_b'] as String,
        createdAt: _ts(j['created_at']),
        lastMessageAt: _tsOrNull(j['last_message_at']),
        lastMessage: j['last_message'] as String?,
        lastMessageBy: j['last_message_by'] as String?,
        aReadAt: _tsOrNull(j['a_read_at']),
        bReadAt: _tsOrNull(j['b_read_at']),
      );
}

class DmMessage {
  const DmMessage({required this.id, required this.threadId, required this.authorId, required this.body, required this.createdAt});

  final String id;
  final String threadId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  factory DmMessage.fromJson(Map<String, dynamic> j) => DmMessage(
        id: j['id'] as String,
        threadId: j['thread_id'] as String,
        authorId: j['author_id'] as String,
        body: j['body'] as String,
        createdAt: _ts(j['created_at']),
      );
}
