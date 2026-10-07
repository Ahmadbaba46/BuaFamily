/// A Quran khatm shared out among the family: 30 juz, each taken and read by
/// someone.
enum KhatmPurpose { memorial, occasion, other }

class KhatmPart {
  const KhatmPart({required this.juz, this.userId, this.claimedAt, this.doneAt});

  final int juz;

  /// Who is reading it; null when it's free.
  final String? userId;
  final DateTime? claimedAt;
  final DateTime? doneAt;

  bool get taken => userId != null;
  bool get done => doneAt != null;

  factory KhatmPart.fromJson(Map<String, dynamic> j) => KhatmPart(
        juz: (j['juz'] as num).toInt(),
        userId: j['user_id'] as String?,
        claimedAt: j['claimed_at'] == null ? null : DateTime.parse(j['claimed_at'] as String).toLocal(),
        doneAt: j['done_at'] == null ? null : DateTime.parse(j['done_at'] as String).toLocal(),
      );
}

class Khatm {
  const Khatm({
    required this.id,
    required this.title,
    required this.createdAt,
    this.purpose = KhatmPurpose.memorial,
    this.personId,
    this.note,
    this.dueOn,
    this.cancelled = false,
    this.completedAt,
    this.createdBy,
    this.parts = const [],
  });

  static const juzCount = 30;
  static const select = '*, khatm_parts(juz, user_id, claimed_at, done_at)';

  final String id;
  final String title;
  final DateTime createdAt;
  final KhatmPurpose purpose;

  /// The relative it is for.
  final String? personId;
  final String? note;

  /// When it should be finished by.
  final DateTime? dueOn;
  final bool cancelled;
  final DateTime? completedAt;
  final String? createdBy;
  final List<KhatmPart> parts;

  bool get complete => completedAt != null;
  bool get open => !cancelled && !complete;

  /// Juz 1–30 with who has it (free ones have no reader).
  KhatmPart part(int juz) => parts.firstWhere((p) => p.juz == juz, orElse: () => KhatmPart(juz: juz));

  int get readCount => parts.where((p) => p.done).length;
  int get takenCount => parts.where((p) => p.taken).length;
  int get freeCount => juzCount - takenCount;

  List<KhatmPart> partsOf(String? userId) =>
      userId == null ? const [] : (parts.where((p) => p.userId == userId).toList()..sort((a, b) => a.juz - b.juz));

  /// Everyone reading, with how many juz each.
  Map<String, int> get readers {
    final m = <String, int>{};
    for (final p in parts) {
      if (p.userId != null) m[p.userId!] = (m[p.userId!] ?? 0) + 1;
    }
    return m;
  }

  factory Khatm.fromJson(Map<String, dynamic> j) => Khatm(
        id: j['id'] as String,
        title: j['title'] as String,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        purpose: KhatmPurpose.values.asNameMap()[j['purpose']] ?? KhatmPurpose.other,
        personId: j['person_id'] as String?,
        note: j['note'] as String?,
        dueOn: j['due_on'] == null ? null : DateTime.parse(j['due_on'] as String),
        cancelled: j['cancelled'] as bool? ?? false,
        completedAt: j['completed_at'] == null ? null : DateTime.parse(j['completed_at'] as String).toLocal(),
        createdBy: j['created_by'] as String?,
        parts: [for (final p in (j['khatm_parts'] as List? ?? const [])) KhatmPart.fromJson((p as Map).cast())],
      );
}
