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

enum DmKind { text, photo, voice }

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

  bool get deleted => deletedAt != null;

  /// The words: a text, or a photo's caption ('' when there is none).
  String get text => kind == DmKind.text ? body : (body == photoMark || body == voiceMark ? '' : body);

  factory DmMessage.fromJson(Map<String, dynamic> j) => DmMessage(
        id: j['id'] as String,
        threadId: j['thread_id'] as String,
        authorId: j['author_id'] as String,
        body: j['body'] as String,
        createdAt: _ts(j['created_at']),
        kind: DmKind.values.asNameMap()[j['kind']] ?? DmKind.text,
        mediaPath: j['media_path'] as String?,
        durationMs: (j['duration_ms'] as num?)?.toInt(),
        replyTo: j['reply_to'] as String?,
        deletedAt: _tsOrNull(j['deleted_at']),
        waveform: (j['waveform'] as List?)?.map((v) => (v as num).toInt()).toList(),
      );
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
