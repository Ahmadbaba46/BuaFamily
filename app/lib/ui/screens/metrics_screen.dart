import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../../models/fund.dart' show naira;
import '../../models/metrics.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'import_export_screen.dart' show saveBytes;

final adminSnapshotProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(repositoryProvider).adminSnapshot());

/// (comma-separated metric keys, query) → series and totals.
final metricsProvider = FutureProvider.autoDispose.family<MetricsResult, (String, MetricsQuery)>(
  (ref, a) => ref.watch(repositoryProvider).adminMetrics(a.$1.split(','), a.$2),
);

/// (metric, query, 'member' | 'branch' | 'platform') → breakdown.
final breakdownProvider = FutureProvider.autoDispose.family<List<BreakdownRow>, (String, MetricsQuery, String)>(
  (ref, a) => ref.watch(repositoryProvider).adminMetricBreakdown(a.$1, a.$2, a.$3),
);

/// The metrics an admin chose to see as tiles (kept on this device).
class MetricTiles extends Notifier<List<String>> {
  static const _key = 'metric_tiles';

  @override
  List<String> build() {
    SharedPreferences.getInstance().then((p) {
      final saved = p.getStringList(_key);
      if (saved != null && saved.isNotEmpty) state = saved;
    }).catchError((_) {});
    return defaultTiles;
  }

  Future<void> set(List<String> tiles) async {
    state = tiles;
    try {
      await (await SharedPreferences.getInstance()).setStringList(_key, tiles);
    } catch (_) {}
  }
}

final metricTilesProvider = NotifierProvider<MetricTiles, List<String>>(MetricTiles.new);

enum _Period { d7, d30, d90, d365, custom }

/// Admin: how the family uses the app, over any period, by day, week or
/// month, compared with the period before, by platform or branch.
class MetricsScreen extends ConsumerStatefulWidget {
  const MetricsScreen({super.key, this.today});

  /// For tests.
  final DateTime? today;

  @override
  ConsumerState<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends ConsumerState<MetricsScreen> {
  _Period _period = _Period.d30;
  late MetricsQuery _query;
  String _selected = 'active_members';
  bool _compare = false;
  bool _table = false;
  String _by = 'member';

  DateTime get _today {
    final t = widget.today ?? DateTime.now();
    return DateTime(t.year, t.month, t.day);
  }

  @override
  void initState() {
    super.initState();
    _query = _queryFor(30);
  }

  MetricsQuery _queryFor(int days) => MetricsQuery(
        from: _today.subtract(Duration(days: days - 1)),
        to: _today,
        bucket: MetricsQuery.bucketFor(days),
      );

  Future<void> _setPeriod(_Period p) async {
    if (p == _Period.custom) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: _today,
        initialDateRange: DateTimeRange(start: _query.from, end: _query.to),
      );
      if (range == null) return;
      final days = range.end.difference(range.start).inDays + 1;
      setState(() {
        _period = p;
        _query = _query.copyWith(from: range.start, to: range.end, bucket: MetricsQuery.bucketFor(days));
      });
      return;
    }
    final days = switch (p) { _Period.d7 => 7, _Period.d30 => 30, _Period.d90 => 90, _ => 365 };
    setState(() {
      _period = p;
      _query = _queryFor(days).copyWith(platform: () => _query.platform, branch: () => _query.branch);
    });
  }

  String _format(String metric, double v) {
    if (metricDef(metric).kind == MetricKind.money) return naira(v);
    return NumberFormat.decimalPattern('en').format(v.round());
  }

  String _bucketLabel(AppLocalizations l, DateTime d) =>
      _query.bucket == MetricBucket.month ? '${l.monthShort(d)} ${d.year}' : l.dayMonth(d);

  Future<void> _exportCsv(MetricsResult r, List<String> metrics) async {
    final l = context.l10n;
    final lines = [
      ['date', ...metrics].join(','),
      for (var i = 0; i < r.buckets.length; i++)
        [
          DateFormat('yyyy-MM-dd').format(r.buckets[i]),
          for (final m in metrics) (r.series[m] ?? const [])[i].toStringAsFixed(metricDef(m).kind == MetricKind.money ? 2 : 0),
        ].join(','),
    ];
    final from = DateFormat('yyyyMMdd').format(_query.from);
    final to = DateFormat('yyyyMMdd').format(_query.to);
    await saveBytes(context, 'bua-metrics-$from-$to.csv', utf8.encode('${lines.join('\n')}\n'), 'text/csv');
    if (mounted) showSnack(context, l.saved);
  }

  Future<void> _chooseTiles() async {
    final l = context.l10n;
    final current = {...ref.read(metricTilesProvider)};
    final chosen = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(c).height * 0.75,
            child: Column(children: [
              ListTile(title: Text(l.customiseTiles), subtitle: Text(l.customiseTilesHint)),
              Expanded(
                child: ListView(children: [
                  for (final g in MetricGroup.values) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(l.metricGroup(g).toUpperCase(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bua.inkMuted)),
                    ),
                    for (final m in metricCatalog.where((m) => m.group == g))
                      CheckboxListTile(
                        dense: true,
                        value: current.contains(m.key),
                        title: Text(l.metric(m.key)),
                        onChanged: (v) => set(() => v == true ? current.add(m.key) : current.remove(m.key)),
                      ),
                  ],
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () => Navigator.pop(c, current),
                  child: Text(l.save),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    if (chosen != null && chosen.isNotEmpty) {
      // Keep the catalogue's order.
      await ref.read(metricTilesProvider.notifier).set([
        for (final m in metricCatalog)
          if (chosen.contains(m.key)) m.key,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tiles = ref.watch(metricTilesProvider);
    final metrics = {...tiles, _selected}.toList();
    final result = ref.watch(metricsProvider((metrics.join(','), _query)));
    final snapshot = ref.watch(adminSnapshotProvider).value;
    final branches = [for (final b in (snapshot?['branches'] as List? ?? const [])) b as String];

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/admin')),
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.metricsTitle, style: Theme.of(context).textTheme.titleLarge),
          Text(l.metricsSub, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Bua.inkSubtle)),
        ]),
        actions: [
          IconButton(tooltip: l.customiseTiles, icon: const Icon(Icons.tune), onPressed: _chooseTiles),
          IconButton(
            tooltip: l.exportCsv,
            icon: const Icon(Icons.download_outlined),
            onPressed: result.value == null ? null : () => _exportCsv(result.value!, metrics),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminSnapshotProvider);
          ref.invalidate(metricsProvider);
          ref.invalidate(breakdownProvider);
        },
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
          _filters(l, branches),
          const SizedBox(height: 12),
          if (snapshot != null) _SnapshotCard(snapshot: snapshot),
          const SizedBox(height: 12),
          AsyncBody(
            value: result,
            onRetry: () => ref.invalidate(metricsProvider),
            builder: (r) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _tilesGrid(l, r, tiles),
              const SizedBox(height: 12),
              _mainChart(l, r),
              const SizedBox(height: 12),
              _breakdown(l),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _filters(AppLocalizations l, List<String> branches) {
    String periodLabel(_Period p) => switch (p) {
          _Period.d7 => l.period7,
          _Period.d30 => l.period30,
          _Period.d90 => l.period90,
          _Period.d365 => l.period365,
          _Period.custom => _period == _Period.custom
              ? '${l.dayMonth(_query.from)} – ${l.dayMonth(_query.to)}'
              : l.periodCustom,
        };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final p in _Period.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(periodLabel(p)),
                selected: _period == p,
                labelStyle: TextStyle(color: _period == p ? Colors.white : Bua.ink, fontWeight: FontWeight.w500),
                onSelected: (_) => _setPeriod(p),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        PillSegmented<MetricBucket>(
          values: MetricBucket.values,
          labelOf: (b) => switch (b) {
            MetricBucket.day => l.byDay,
            MetricBucket.week => l.byWeek,
            MetricBucket.month => l.byMonth,
          },
          selected: _query.bucket,
          height: 34,
          onChanged: (b) => setState(() => _query = _query.copyWith(bucket: b)),
        ),
        _dropdown<String?>(
          icon: Icons.devices,
          value: _query.platform,
          options: {null: l.allPlatforms, 'android': l.platformAndroid, 'web': l.platformWeb},
          onChanged: (v) => setState(() => _query = _query.copyWith(platform: () => v)),
        ),
        if (branches.isNotEmpty)
          _dropdown<String?>(
            icon: Icons.account_tree_outlined,
            value: _query.branch,
            options: {null: l.allBranches, for (final b in branches) b: b},
            onChanged: (v) => setState(() => _query = _query.copyWith(branch: () => v)),
          ),
      ]),
    ]);
  }

  Widget _dropdown<T>({
    required IconData icon,
    required T value,
    required Map<T, String> options,
    required ValueChanged<T> onChanged,
  }) =>
      PopupMenuButton<T>(
        initialValue: value,
        onSelected: onChanged,
        itemBuilder: (_) => [
          for (final e in options.entries) CheckedPopupMenuItem(value: e.key, checked: e.key == value, child: Text(e.value)),
        ],
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Bua.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: value == null ? Bua.lineStrong : Bua.green),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: value == null ? Bua.inkMuted : Bua.green),
            const SizedBox(width: 6),
            Text(options[value] ?? '', style: const TextStyle(fontSize: 13)),
            const Icon(Icons.arrow_drop_down, size: 18, color: Bua.inkMuted),
          ]),
        ),
      );

  String _change(AppLocalizations l, MetricsResult r, String m) {
    final c = r.change(m);
    if (c == null) return (r.totals[m] ?? 0) > 0 ? l.newThisPeriod : '';
    if (c.abs() < 0.005) return l.noChange;
    final pct = '${c > 0 ? '+' : '−'}${(c.abs() * 100).round()}%';
    return l.vsPrevious(pct);
  }

  Widget _tilesGrid(AppLocalizations l, MetricsResult r, List<String> tiles) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 3 : 2);
      const gap = 10.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final m in tiles)
          SizedBox(
            width: w,
            child: Material(
              color: Bua.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _selected == m ? Bua.green : Bua.line, width: _selected == m ? 2 : 1),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _selected = m),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.metric(m),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Bua.inkMuted)),
                    const SizedBox(height: 2),
                    Text(_format(m, r.totals[m] ?? 0), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    Row(children: [
                      if ((r.change(m) ?? 0) != 0)
                        Icon(r.change(m)! > 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: Bua.inkSubtle),
                      Expanded(
                        child: Text(_change(l, r, m),
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Bua.inkSubtle)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Sparkline(values: r.series[m] ?? const []),
                  ]),
                ),
              ),
            ),
          ),
      ]);
    });
  }

  Widget _mainChart(AppLocalizations l, MetricsResult r) {
    final m = _selected;
    final values = r.series[m] ?? const <double>[];
    final labels = [for (final b in r.buckets) _bucketLabel(l, b)];
    // The period before, same length and step, for the dashed line.
    final prevQuery = _query.copyWith(
      from: _query.from.subtract(Duration(days: _query.days)),
      to: _query.to.subtract(Duration(days: _query.days)),
    );
    final prev = _compare ? ref.watch(metricsProvider((m, prevQuery))).value?.series[m] : null;
    final prevAligned = prev != null && prev.length == values.length ? prev : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.metric(m), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('${_format(m, r.totals[m] ?? 0)} · ${_change(l, r, m)}',
                  style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
            ]),
          ),
          PillSegmented<bool>(
            values: const [false, true],
            labelOf: (t) => t ? l.showTable : l.showChart,
            selected: _table,
            height: 32,
            onChanged: (v) => setState(() => _table = v),
          ),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: Text(l.comparePrevious, style: const TextStyle(fontSize: 13))),
          Switch(value: _compare, onChanged: (v) => setState(() => _compare = v)),
        ]),
        if (values.every((v) => v == 0))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(l.noDataYet, textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkSubtle)),
          )
        else if (_table)
          _table_(l, m, labels, values, prevAligned)
        else ...[
          TrendChart(
            values: values,
            labels: labels,
            previous: prevAligned,
            asLine: metricDef(m).asLine,
            format: (v) => _format(m, v),
            previousLabel: l.previousPeriod,
          ),
          if (prevAligned != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(spacing: 16, children: [
                _legend(l.metric(m), ChartColors.series, dashed: false),
                _legend(l.previousPeriod, ChartColors.previous, dashed: true),
              ]),
            ),
        ],
      ]),
    );
  }

  Widget _legend(String label, Color color, {required bool dashed}) => Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 18,
          child: dashed
              ? Row(children: [
                  for (var i = 0; i < 3; i++) ...[
                    Container(width: 4, height: 2, color: color),
                    if (i < 2) const SizedBox(width: 3),
                  ],
                ])
              : Container(height: 2, color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Bua.inkMuted)),
      ]);

  Widget _table_(AppLocalizations l, String m, List<String> labels, List<double> values, List<double>? prev) => Column(
        children: [
          for (var i = labels.length - 1; i >= 0; i--)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(child: Text(labels[i], style: const TextStyle(fontSize: 13))),
                if (prev != null)
                  SizedBox(
                    width: 90,
                    child: Text(_format(m, prev[i]),
                        textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
                  ),
                SizedBox(
                  width: 90,
                  child: Text(_format(m, values[i]),
                      textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
        ],
      );

  Widget _breakdown(AppLocalizations l) {
    final rows = ref.watch(breakdownProvider((_selected, _query, _by)));
    String label(BreakdownRow r) => switch (_by) {
          'platform' => switch (r.key) { 'android' => l.platformAndroid, 'web' => l.platformWeb, _ => l.unknownLabel },
          'branch' => r.label.isEmpty ? l.noBranch : r.label,
          _ => r.label.isEmpty ? l.unknownLabel : r.label,
        };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(l.breakdownBy, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          PillSegmented<String>(
            values: const ['member', 'branch', 'platform'],
            labelOf: (b) => switch (b) { 'branch' => l.byBranch, 'platform' => l.byPlatform, _ => l.byMember },
            selected: _by,
            height: 32,
            onChanged: (v) => setState(() => _by = v),
          ),
        ]),
        const SizedBox(height: 10),
        AsyncBody(
          value: rows,
          onRetry: () => ref.invalidate(breakdownProvider),
          builder: (list) => list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l.noDataYet, textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkSubtle)),
                )
              : BreakdownBars(rows: [for (final r in list) (label(r), r.value)], format: (v) => _format(_selected, v)),
        ),
      ]),
    );
  }
}

/// Where the family stands today: accounts from sign-up to active, and the tree.
class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.snapshot});

  final Map<String, dynamic> snapshot;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    int n(String k) => (snapshot[k] as num?)?.toInt() ?? 0;
    final accounts = n('accounts');
    final people = n('people');
    int pct(int part, int whole) => whole == 0 ? 0 : (part * 100 / whole).round();
    final funnel = [
      (l.funnelAccounts, n('accounts')),
      (l.funnelApproved, n('approved')),
      (l.funnelLinked, n('linked')),
      (l.funnelActive30, n('active_30d')),
      (l.funnelPush, n('push_on')),
      (l.funnelAndroid, n('android_app')),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.snapshotTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        // Accounts, step by step: each bar is a share of all accounts.
        BreakdownBars(
          rows: [for (final f in funnel) (f.$1, f.$2.toDouble())],
          format: (v) => accounts == 0 ? '${v.round()}' : '${v.round()} · ${pct(v.round(), accounts)}%',
        ),
        const Divider(height: 24, color: Bua.line),
        Text(l.treeQuality, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Bua.inkMuted)),
        const SizedBox(height: 4),
        Text(l.treePeople(people, n('living')), style: const TextStyle(fontSize: 14)),
        Text(
          [
            l.withPhotoPct(pct(n('with_photo'), people)),
            l.withBirthPct(pct(n('with_birth_date'), people)),
            l.withAccountPct(pct(n('with_account'), people)),
          ].join(' · '),
          style: const TextStyle(fontSize: 13, color: Bua.inkSubtle),
        ),
        const Divider(height: 24, color: Bua.line),
        Wrap(spacing: 20, runSpacing: 8, children: [
          _fact(l.fundBalanceLabel, naira((snapshot['fund_balance'] as num?) ?? 0)),
          _fact(l.openBloodLabel, '${n('open_blood_requests')}'),
          _fact(l.pendingSuggestionsLabel, '${n('pending_suggestions')}'),
        ]),
      ]),
    );
  }

  Widget _fact(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
      ]);
}
