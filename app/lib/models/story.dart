DateTime _ts(Object? v) => DateTime.parse(v as String).toLocal();

/// A recorded elder's story.
class Story {
  const Story({
    required this.id,
    required this.title,
    required this.audioPath,
    required this.addedBy,
    required this.createdAt,
    this.speakerId,
    this.speakerName,
    this.language = 'ha',
    this.durationSeconds,
    this.sourceNote,
    this.transcript,
  });

  final String id;
  final String title;
  final String audioPath;
  final String addedBy;
  final DateTime createdAt;

  /// Someone in the tree, or just [speakerName].
  final String? speakerId;
  final String? speakerName;

  /// 'ha', 'en' or 'other'.
  final String language;
  final int? durationSeconds;

  /// "Recorded 1979 on cassette, digitised by Bello"
  final String? sourceNote;
  final String? transcript;

  factory Story.fromJson(Map<String, dynamic> j) => Story(
        id: j['id'] as String,
        title: j['title'] as String,
        audioPath: j['audio_path'] as String,
        addedBy: j['added_by'] as String,
        createdAt: _ts(j['created_at']),
        speakerId: j['speaker_id'] as String?,
        speakerName: j['speaker_name'] as String?,
        language: j['language'] as String? ?? 'ha',
        durationSeconds: j['duration_seconds'] as int?,
        sourceNote: j['source_note'] as String?,
        transcript: j['transcript'] as String?,
      );
}

/// A saved weekly snapshot of the family's data.
class Backup {
  const Backup({required this.slot, required this.takenAt, required this.sizeBytes});

  final int slot;
  final DateTime takenAt;
  final int sizeBytes;

  factory Backup.fromJson(Map<String, dynamic> j) =>
      Backup(slot: j['slot'] as int, takenAt: _ts(j['taken_at']), sizeBytes: j['size_bytes'] as int? ?? 0);
}

/// "12:40" / "1:02:05".
String clockDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
