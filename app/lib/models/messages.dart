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
    this.aDeliveredAt,
    this.bDeliveredAt,
    this.lastMessageKind,
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
  final DateTime? aDeliveredAt;
  final DateTime? bDeliveredAt;

  /// 'text', 'photo', 'voice' or 'deleted'.
  final String? lastMessageKind;

  /// Ticks for a message [me] sent at [sentAt]: read, delivered, or just sent.
  MessageStatus statusOf(DateTime sentAt, String? me) {
    final read = me == userA ? bReadAt : aReadAt;
    final delivered = me == userA ? bDeliveredAt : aDeliveredAt;
    if (read != null && !read.isBefore(sentAt)) return MessageStatus.read;
    if (delivered != null && !delivered.isBefore(sentAt)) return MessageStatus.delivered;
    return MessageStatus.sent;
  }

  /// Something sent to [me] that my app hasn't yet said it received.
  bool undeliveredFor(String? me) {
    if (lastMessageAt == null || lastMessageBy == null || lastMessageBy == me) return false;
    final delivered = me == userA ? aDeliveredAt : bDeliveredAt;
    return delivered == null || delivered.isBefore(lastMessageAt!);
  }

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
        aDeliveredAt: _tsOrNull(j['a_delivered_at']),
        bDeliveredAt: _tsOrNull(j['b_delivered_at']),
        lastMessageKind: j['last_message_kind'] as String?,
      );
}

/// WhatsApp's ticks: one grey (sent), two grey (delivered), two blue (read).
enum MessageStatus { sent, delivered, read }

/// What a message is; 'event' is a group notice ("Musa added Bello").
enum DmKind { text, photo, voice, event }

class DmMessage {
  const DmMessage({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.kind = DmKind.text,
    this.mediaPath,
    this.durationMs,
    this.replyTo,
    this.deletedAt,
    this.waveform,
    this.event,
    this.deletedBy,
  });

  /// What a photo or voice note's body holds when it has no words.
  static const photoMark = '📷';
  static const voiceMark = '🎤';

  final String id;
  final String threadId;
  final String authorId;
  final String body;
  final DateTime createdAt;
  final DmKind kind;

  /// The photo or voice note in the 'dm' bucket.
  final String? mediaPath;
  final int? durationMs;

  /// The message this one answers.
  final String? replyTo;
  final DateTime? deletedAt;

  /// A voice note's levels (0–100), measured while recording.
  final List<int>? waveform;

  /// A group notice: {"type": "added", "user": ..., ...}.
  final Map<String, dynamic>? event;

  /// In a group, who deleted it (the sender, or a group admin).
  final String? deletedBy;

  bool get deleted => deletedAt != null;

  /// The words: a text, or a photo's caption ('' when there is none).
  String get text => kind == DmKind.event
      ? ''
      : kind == DmKind.text
          ? body
          : (body == photoMark || body == voiceMark ? '' : body);

  factory DmMessage.fromJson(Map<String, dynamic> j) => DmMessage(
        id: j['id'] as String,
        // A private conversation's, or a group's.
        threadId: (j['thread_id'] ?? j['group_id']) as String,
        authorId: j['author_id'] as String,
        body: j['body'] as String,
        createdAt: _ts(j['created_at']),
        kind: DmKind.values.asNameMap()[j['kind']] ?? DmKind.text,
        mediaPath: j['media_path'] as String?,
        durationMs: (j['duration_ms'] as num?)?.toInt(),
        replyTo: j['reply_to'] as String?,
        deletedAt: _tsOrNull(j['deleted_at']),
        waveform: (j['waveform'] as List?)?.map((v) => (v as num).toInt()).toList(),
        event: j['event'] == null ? null : Map<String, dynamic>.from(j['event'] as Map),
        deletedBy: j['deleted_by'] as String?,
      );
}

/// A group chat.
class ChatGroup {
  const ChatGroup({
    required this.id,
    required this.name,
    required this.createdAt,
    this.about,
    this.photoPath,
    this.onlyAdminsSend = false,
    this.createdBy,
    this.lastMessageAt,
    this.lastMessage,
    this.lastMessageBy,
    this.lastMessageKind,
    this.lastEvent,
  });

  final String id;
  final String name;
  final String? about;

  /// In the 'dm' bucket, under `g/<group>/`.
  final String? photoPath;
  final bool onlyAdminsSend;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final String? lastMessageBy;

  /// 'text', 'photo', 'voice', 'event' or 'deleted'.
  final String? lastMessageKind;

  /// When the last message is a notice, what it says.
  final Map<String, dynamic>? lastEvent;

  DateTime get activeAt => lastMessageAt ?? createdAt;

  /// Something new from someone else since [mine] (my membership) was read.
  bool unreadFor(GroupMember? mine) {
    if (mine == null || lastMessageAt == null || lastMessageBy == null || lastMessageBy == mine.userId) return false;
    if (lastMessageKind == 'event') return false;
    return mine.readAt == null || mine.readAt!.isBefore(lastMessageAt!);
  }

  /// Sent to me and not yet on my phone.
  bool undeliveredFor(GroupMember? mine) {
    if (mine == null || lastMessageAt == null || lastMessageBy == null || lastMessageBy == mine.userId) return false;
    return mine.deliveredAt == null || mine.deliveredAt!.isBefore(lastMessageAt!);
  }

  factory ChatGroup.fromJson(Map<String, dynamic> j) => ChatGroup(
        id: j['id'] as String,
        name: j['name'] as String,
        about: j['about'] as String?,
        photoPath: j['photo_path'] as String?,
        onlyAdminsSend: j['only_admins_send'] as bool? ?? false,
        createdBy: j['created_by'] as String?,
        createdAt: _ts(j['created_at']),
        lastMessageAt: _tsOrNull(j['last_message_at']),
        lastMessage: j['last_message'] as String?,
        lastMessageBy: j['last_message_by'] as String?,
        lastMessageKind: j['last_message_kind'] as String?,
        lastEvent: j['last_event'] == null ? null : Map<String, dynamic>.from(j['last_event'] as Map),
      );
}

/// Someone in a group (or who was: [leftAt]).
class GroupMember {
  const GroupMember({
    required this.groupId,
    required this.userId,
    required this.joinedAt,
    this.admin = false,
    this.addedBy,
    this.leftAt,
    this.readAt,
    this.deliveredAt,
    this.muted = false,
  });

  final String groupId;
  final String userId;
  final bool admin;
  final String? addedBy;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final bool muted;

  bool get current => leftAt == null;

  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
        groupId: j['group_id'] as String,
        userId: j['user_id'] as String,
        admin: j['role'] == 'admin',
        addedBy: j['added_by'] as String?,
        joinedAt: _ts(j['joined_at']),
        leftAt: _tsOrNull(j['left_at']),
        readAt: _tsOrNull(j['read_at']),
        deliveredAt: _tsOrNull(j['delivered_at']),
        muted: j['muted'] as bool? ?? false,
      );
}

/// Ticks on a message [me] sent to a group at [sentAt]: read once everyone
/// who was in it then has read it, delivered once it's on all their phones.
MessageStatus groupStatus(Iterable<GroupMember> members, DateTime sentAt, String? me) {
  final others = members.where((m) => m.current && m.userId != me && !m.joinedAt.isAfter(sentAt)).toList();
  if (others.isEmpty) return MessageStatus.sent;
  bool all(DateTime? Function(GroupMember) at) => others.every((m) => at(m) != null && !at(m)!.isBefore(sentAt));
  if (all((m) => m.readAt)) return MessageStatus.read;
  // Read means it reached their phone too.
  if (all((m) => m.deliveredAt == null || (m.readAt?.isAfter(m.deliveredAt!) ?? false) ? m.readAt : m.deliveredAt)) {
    return MessageStatus.delivered;
  }
  return MessageStatus.sent;
}

/// Someone's emoji on a message (one each).
class DmReaction {
  const DmReaction({required this.messageId, required this.userId, required this.emoji});

  final String messageId;
  final String userId;
  final String emoji;

  factory DmReaction.fromJson(Map<String, dynamic> j) => DmReaction(
        messageId: j['message_id'] as String,
        userId: j['user_id'] as String,
        emoji: j['emoji'] as String,
      );
}

/// Squeezes measured levels into [bars] bars of 0–100.
List<int> compactWaveform(List<double> levels, {int bars = 48}) {
  if (levels.isEmpty) return const [];
  final out = <int>[];
  for (var i = 0; i < bars; i++) {
    final from = (i * levels.length / bars).floor();
    final to = ((i + 1) * levels.length / bars).ceil().clamp(from + 1, levels.length);
    var peak = 0.0;
    for (var j = from; j < to; j++) {
      if (levels[j] > peak) peak = levels[j];
    }
    out.add((peak.clamp(0.0, 1.0) * 100).round());
  }
  return out;
}

/// A level (0–1) from the recorder's decibels (-160 to 0).
double levelFromDb(double db) => ((db + 50) / 50).clamp(0.0, 1.0);
