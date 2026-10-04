/// Who is online, and what members did (admins only).
library;

DateTime _ts(Object? v) => DateTime.parse(v as String).toLocal();

class OnlineEntry {
  const OnlineEntry({
    required this.userId,
    required this.name,
    required this.platform,
    required this.startedAt,
    required this.seenAt,
    required this.online,
    this.personId,
    this.page,
  });

  final String userId;
  final String name;
  final String? personId;
  final String platform;
  final String? page;

  /// When this visit began.
  final DateTime startedAt;
  final DateTime seenAt;
  final bool online;

  factory OnlineEntry.fromJson(Map<String, dynamic> j) => OnlineEntry(
        userId: j['user_id'] as String,
        name: j['name'] as String? ?? '',
        personId: j['person_id'] as String?,
        platform: j['platform'] as String? ?? 'web',
        page: j['page'] as String?,
        startedAt: _ts(j['started_at']),
        seenAt: _ts(j['seen_at']),
        online: j['online'] as bool? ?? false,
      );
}

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.at,
    required this.action,
    required this.entity,
    this.userId,
    this.name = '',
    this.personId,
    this.target,
    this.detail = const {},
    this.platform,
  });

  final int id;
  final DateTime at;
  final String? userId;
  final String name;
  final String? personId;

  /// insert | update | delete | view | open | sign_in | sign_out
  final String action;

  /// The table changed, or 'page' / 'session'.
  final String entity;

  /// The row's id, or the page's path.
  final String? target;
  final Map<String, dynamic> detail;
  final String? platform;

  String? get label => detail['label'] as String?;
  String? str(String key) => detail[key] as String?;

  factory ActivityEntry.fromJson(Map<String, dynamic> j) => ActivityEntry(
        id: (j['id'] as num).toInt(),
        at: _ts(j['at']),
        userId: j['user_id'] as String?,
        name: j['name'] as String? ?? '',
        personId: j['person_id'] as String?,
        action: j['action'] as String,
        entity: j['entity'] as String,
        target: j['target'] as String?,
        detail: Map<String, dynamic>.from(j['detail'] as Map? ?? const {}),
        platform: j['platform'] as String?,
      );
}

/// What kind of activity to show.
enum ActivityType {
  all(null, null),
  changes(null, ['insert', 'update', 'delete']),
  pages(['page'], null),
  sessions(['session'], null);

  const ActivityType(this.entities, this.actions);

  final List<String>? entities;
  final List<String>? actions;
}

class ActivityQuery {
  const ActivityQuery({this.type = ActivityType.all, this.userId, this.from, this.search});

  final ActivityType type;
  final String? userId;
  final DateTime? from;
  final String? search;

  List<String>? get entities => type.entities;
  List<String>? get actions => type.actions;

  ActivityQuery copyWith({ActivityType? type, String? Function()? userId, DateTime? Function()? from, String? search}) =>
      ActivityQuery(
        type: type ?? this.type,
        userId: userId == null ? this.userId : userId(),
        from: from == null ? this.from : from(),
        search: search ?? this.search,
      );

  @override
  bool operator ==(Object other) =>
      other is ActivityQuery && other.type == type && other.userId == userId && other.from == from && other.search == search;

  @override
  int get hashCode => Object.hash(type, userId, from, search);
}
