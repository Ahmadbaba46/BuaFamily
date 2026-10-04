import '../l10n/l10n.dart';

/// How a metric adds up over time (mirrors private.metric_kind in the database).
enum MetricKind { count, members, money }

enum MetricGroup { people, tree, sharing, events, helping, reach }

/// One thing the admin can measure. The database computes it
/// (private.metric_events); this is how the app shows it.
class MetricDef {
  const MetricDef(this.key, this.group, {this.kind = MetricKind.count});

  /// The database name, e.g. 'comments'.
  final String key;
  final MetricGroup group;
  final MetricKind kind;

  /// Counts of members are best read as a line; everything else as bars.
  bool get asLine => kind == MetricKind.members;
}

const metricCatalog = <MetricDef>[
  MetricDef('active_members', MetricGroup.people, kind: MetricKind.members),
  MetricDef('active_android', MetricGroup.people, kind: MetricKind.members),
  MetricDef('active_web', MetricGroup.people, kind: MetricKind.members),
  MetricDef('signups', MetricGroup.people),
  MetricDef('people_added', MetricGroup.tree),
  MetricDef('relationships_added', MetricGroup.tree),
  MetricDef('suggestions', MetricGroup.tree),
  MetricDef('suggestions_reviewed', MetricGroup.tree),
  MetricDef('moments', MetricGroup.sharing),
  MetricDef('posting_members', MetricGroup.sharing, kind: MetricKind.members),
  MetricDef('photos', MetricGroup.sharing),
  MetricDef('comments', MetricGroup.sharing),
  MetricDef('likes', MetricGroup.sharing),
  MetricDef('announcements', MetricGroup.sharing),
  MetricDef('stories', MetricGroup.sharing),
  MetricDef('memories', MetricGroup.sharing),
  MetricDef('events', MetricGroup.events),
  MetricDef('rsvps', MetricGroup.events),
  MetricDef('polls', MetricGroup.events),
  MetricDef('votes', MetricGroup.events),
  MetricDef('blood_requests', MetricGroup.helping),
  MetricDef('blood_offers', MetricGroup.helping),
  MetricDef('contributions', MetricGroup.helping),
  MetricDef('money_in', MetricGroup.helping, kind: MetricKind.money),
  MetricDef('money_out', MetricGroup.helping, kind: MetricKind.money),
  MetricDef('causes', MetricGroup.helping),
  MetricDef('mentor_asks', MetricGroup.helping),
  MetricDef('opportunities', MetricGroup.helping),
  MetricDef('notifications', MetricGroup.reach),
  MetricDef('notifications_received', MetricGroup.reach),
  MetricDef('sms_sent', MetricGroup.reach),
];

MetricDef metricDef(String key) => metricCatalog.firstWhere((m) => m.key == key, orElse: () => MetricDef(key, MetricGroup.people));

/// What the dashboard shows until the admin picks their own.
const defaultTiles = ['active_members', 'signups', 'moments', 'comments', 'photos', 'events', 'blood_requests', 'money_in'];

enum MetricBucket { day, week, month }

/// The slice of time and family being looked at.
class MetricsQuery {
  const MetricsQuery({required this.from, required this.to, this.bucket = MetricBucket.day, this.platform, this.branch});

  final DateTime from;

  /// Inclusive.
  final DateTime to;
  final MetricBucket bucket;
  final String? platform;
  final String? branch;

  int get days => to.difference(from).inDays + 1;

  /// A sensible step for a period: daily up to two months, weekly up to a
  /// year, monthly beyond.
  static MetricBucket bucketFor(int days) =>
      days <= 62 ? MetricBucket.day : (days <= 366 ? MetricBucket.week : MetricBucket.month);

  MetricsQuery copyWith({DateTime? from, DateTime? to, MetricBucket? bucket, String? Function()? platform, String? Function()? branch}) =>
      MetricsQuery(
        from: from ?? this.from,
        to: to ?? this.to,
        bucket: bucket ?? this.bucket,
        platform: platform == null ? this.platform : platform(),
        branch: branch == null ? this.branch : branch(),
      );

  @override
  bool operator ==(Object other) =>
      other is MetricsQuery &&
      other.from == from &&
      other.to == to &&
      other.bucket == bucket &&
      other.platform == platform &&
      other.branch == branch;

  @override
  int get hashCode => Object.hash(from, to, bucket, platform, branch);
}

/// Series per metric over the query's buckets, with totals for this period and the one before.
class MetricsResult {
  const MetricsResult({required this.buckets, required this.series, required this.totals, required this.previous});

  final List<DateTime> buckets;
  final Map<String, List<double>> series;
  final Map<String, double> totals;
  final Map<String, double> previous;

  factory MetricsResult.fromJson(Map<String, dynamic> j) {
    double n(Object? v) => (v as num?)?.toDouble() ?? 0;
    Map<String, double> map(Object? m) => {for (final e in (m as Map? ?? const {}).entries) e.key as String: n(e.value)};
    return MetricsResult(
      buckets: [for (final b in (j['buckets'] as List? ?? const [])) DateTime.parse(b as String)],
      series: {
        for (final e in (j['series'] as Map? ?? const {}).entries)
          e.key as String: [for (final v in (e.value as List? ?? const [])) n(v)],
      },
      totals: map(j['totals']),
      previous: map(j['previous']),
    );
  }

  /// Change against the period before, as a fraction (0.25 = +25%); null when
  /// there was nothing before.
  double? change(String metric) {
    final before = previous[metric] ?? 0;
    if (before == 0) return null;
    return ((totals[metric] ?? 0) - before) / before;
  }
}

class BreakdownRow {
  const BreakdownRow({required this.key, required this.label, required this.value});

  final String key;
  final String label;
  final double value;

  factory BreakdownRow.fromJson(Map<String, dynamic> j) => BreakdownRow(
        key: j['key'] as String? ?? '',
        label: j['label'] as String? ?? '',
        value: (j['value'] as num?)?.toDouble() ?? 0,
      );
}

extension MetricLabels on AppLocalizations {
  String metricGroup(MetricGroup g) => switch (g) {
        MetricGroup.people => mgPeople,
        MetricGroup.tree => mgTree,
        MetricGroup.sharing => mgSharing,
        MetricGroup.events => mgEvents,
        MetricGroup.helping => mgHelping,
        MetricGroup.reach => mgReach,
      };

  String metric(String key) => switch (key) {
        'signups' => m_signups,
        'active_members' => m_active_members,
        'active_android' => m_active_android,
        'active_web' => m_active_web,
        'people_added' => m_people_added,
        'relationships_added' => m_relationships_added,
        'suggestions' => m_suggestions,
        'suggestions_reviewed' => m_suggestions_reviewed,
        'moments' => m_moments,
        'announcements' => m_announcements,
        'posting_members' => m_posting_members,
        'photos' => m_photos,
        'comments' => m_comments,
        'likes' => m_likes,
        'stories' => m_stories,
        'memories' => m_memories,
        'events' => m_events,
        'rsvps' => m_rsvps,
        'polls' => m_polls,
        'votes' => m_votes,
        'blood_requests' => m_blood_requests,
        'blood_offers' => m_blood_offers,
        'contributions' => m_contributions,
        'money_in' => m_money_in,
        'money_out' => m_money_out,
        'causes' => m_causes,
        'mentor_asks' => m_mentor_asks,
        'opportunities' => m_opportunities,
        'notifications' => m_notifications,
        'notifications_received' => m_notifications_received,
        'sms_sent' => m_sms_sent,
        _ => key,
      };
}
