import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/metrics.dart';
import 'package:bua_family/ui/screens/metrics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime(2026, 10, 4);

  test('periods pick a sensible step', () {
    expect(MetricsQuery.bucketFor(7), MetricBucket.day);
    expect(MetricsQuery.bucketFor(90), MetricBucket.week);
    expect(MetricsQuery.bucketFor(730), MetricBucket.month);
    final q = MetricsQuery(from: DateTime(2026, 9, 5), to: today);
    expect(q.days, 30);
    expect(q.copyWith(platform: () => 'web').platform, 'web');
    expect(q.copyWith(platform: () => 'web').copyWith(platform: () => null).platform, isNull);
    expect(q.copyWith(bucket: MetricBucket.week), isNot(q));
  });

  test('results read totals and the change against the period before', () {
    final r = MetricsResult.fromJson({
      'buckets': ['2026-10-03', '2026-10-04'],
      'series': {'signups': [1, 2], 'photos': [0, 0]},
      'totals': {'signups': 3, 'photos': 0, 'money_in': 1500.5},
      'previous': {'signups': 2, 'photos': 0},
    });
    expect(r.buckets.last, DateTime(2026, 10, 4));
    expect(r.series['signups'], [1.0, 2.0]);
    expect(r.change('signups'), 0.5);
    expect(r.change('photos'), isNull);
    expect(r.totals['money_in'], 1500.5);
  });

  test('every catalogue metric has a label and the default tiles exist', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final ha = await AppLocalizations.delegate.load(const Locale('ha'));
    for (final m in metricCatalog) {
      expect(l.metric(m.key), isNot(m.key), reason: m.key);
      expect(ha.metric(m.key), isNot(m.key), reason: m.key);
    }
    for (final t in defaultTiles) {
      expect(metricCatalog.any((m) => m.key == t), isTrue, reason: t);
    }
    expect(metricDef('money_in').kind, MetricKind.money);
  });

  testWidgets('the dashboard shows tiles, a chart and a breakdown, and follows the filters', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final queries = <MetricsQuery>[];
    final breakdowns = <(String, String)>[];

    MetricsResult fake(List<String> metrics, MetricsQuery q) {
      final buckets = [for (var i = 0; i < 7; i++) q.to.subtract(Duration(days: 6 - i))];
      return MetricsResult(
        buckets: buckets,
        series: {for (final m in metrics) m: [for (var i = 0; i < 7; i++) (i % 3).toDouble()]},
        totals: {for (final m in metrics) m: m == 'active_members' ? 12 : (m == 'money_in' ? 25000 : 6)},
        previous: {for (final m in metrics) m: m == 'active_members' ? 8 : 0},
      );
    }

    await tester.pumpWidget(ProviderScope(
      overrides: [
        adminSnapshotProvider.overrideWith((ref) async => {
              'accounts': 10,
              'approved': 9,
              'linked': 7,
              'active_30d': 6,
              'push_on': 5,
              'android_app': 3,
              'people': 200,
              'living': 150,
              'with_photo': 50,
              'with_birth_date': 100,
              'with_account': 7,
              'branches': ['Musa', 'Sani'],
              'fund_balance': 120000,
              'open_blood_requests': 1,
              'pending_suggestions': 2,
            }),
        metricsProvider.overrideWith((ref, a) async {
          queries.add(a.$2);
          return fake(a.$1.split(','), a.$2);
        }),
        breakdownProvider.overrideWith((ref, a) async {
          breakdowns.add((a.$1, a.$3));
          return [
            const BreakdownRow(key: 'x', label: 'Ahmad', value: 4),
            const BreakdownRow(key: 'y', label: '', value: 2),
          ];
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MetricsScreen(today: today),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Family metrics'), findsOneWidget);
    expect(find.text('Right now'), findsOneWidget);
    expect(find.text('200 people · 150 living'), findsOneWidget);
    expect(find.text('₦120,000'), findsOneWidget);
    // Last 30 days, daily, by default.
    expect(queries.last.from, DateTime(2026, 9, 5));
    expect(queries.last.bucket, MetricBucket.day);
    // Tiles, and the selected one drives the chart.
    expect(find.text('Active members'), findsNWidgets(2));
    expect(find.text('+50% vs period before'), findsOneWidget);
    expect(find.text('₦25,000'), findsOneWidget);
    expect(find.text('Ahmad'), findsOneWidget);
    expect(breakdowns.last, ('active_members', 'member'));

    await tester.tap(find.text('Sign-ups'));
    await tester.pumpAndSettle();
    expect(find.text('Sign-ups'), findsNWidgets(2));
    expect(breakdowns.last, ('signups', 'member'));

    await tester.tap(find.text('Branch'));
    await tester.pumpAndSettle();
    expect(breakdowns.last, ('signups', 'branch'));
    expect(find.text('No branch'), findsOneWidget);

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    expect(queries.last.from, DateTime(2026, 9, 28));

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    expect(queries.last.bucket, MetricBucket.week);

    // Compare asks for the period just before.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(queries.any((q) => q.to == DateTime(2026, 9, 27) && q.from == DateTime(2026, 9, 21)), isTrue);
    expect(find.text('Period before'), findsWidgets);

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.text('4 Oct'), findsOneWidget);
  });
}
