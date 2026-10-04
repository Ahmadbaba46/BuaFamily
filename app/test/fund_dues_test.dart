import 'dart:io';

import 'package:bua_family/domain/fund_pdf.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/fund.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/dues_screen.dart';
import 'package:bua_family/ui/screens/fund_report_screen.dart';
import 'package:bua_family/ui/screens/welfare_fund_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/widgets.dart' as pw;

import 'domain_test.dart' show buildFamily;

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    await initializeDateFormatting('en');
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  final plan = DuesPlan(id: 'p1', title: 'Monthly dues', amount: 2000, startsOn: DateTime(2026, 1, 1));
  final standings = [
    DuesStanding(planId: 'p1', userId: 'u1', name: 'Aisha', periodsDue: 3, paid: 2000, owed: 4000, owedPeriods: 2,
        paidThrough: DateTime(2026, 8, 1), nextDue: DateTime(2026, 9, 1), pending: 1000),
    DuesStanding(planId: 'p1', userId: 'u2', name: 'Usman', periodsDue: 3, paid: 8000, paidThrough: DateTime(2026, 11, 1)),
    const DuesStanding(planId: 'p1', userId: 'u3', name: 'Kabir', exempt: true),
  ];
  final report = FundReport.fromJson({
    'from': '2026-01-01',
    'to': '2026-12-31',
    'family': 'Bua',
    'opening': 100000,
    'in': 58000,
    'out': 20000,
    'closing': 138000,
    'payments': 6,
    'contributors': 4,
    'sources': [
      {'kind': 'dues', 'id': 'p1', 'title': 'Monthly dues', 'in': 18000, 'out': 0},
      {'kind': 'cause', 'id': 'c1', 'title': 'School fees support', 'in': 40000, 'out': 20000},
    ],
    'months': [
      {'month': '2026-09-01', 'in': 30000, 'out': 0},
      {'month': '2026-10-01', 'in': 28000, 'out': 20000},
    ],
    'transactions': [
      {'date': '2026-09-03', 'kind': 'in', 'amount': 30000, 'method': 'transfer', 'name': 'Aisha Bua', 'title': 'School fees support'},
      {'date': '2026-10-05', 'kind': 'out', 'amount': 20000, 'name': 'Fees for 2 pupils', 'title': 'School fees support'},
    ],
    'dues': [
      {'plan_id': 'p1', 'title': 'Monthly dues', 'amount': 2000, 'period': 'monthly', 'members': 12, 'owing': 5, 'owed': 14000, 'collected': 18000},
    ],
  });

  test('reports and standings read from the database', () {
    expect(report.closing, report.opening + report.moneyIn - report.moneyOut);
    expect(report.sources.first.title, 'Monthly dues');
    expect(report.transactions!.last.isIn, isFalse);
    expect(report.dues!.single.owing, 5);
    final s = DuesStanding.fromJson({
      'plan_id': 'p1', 'user_id': 'u1', 'owed': 4000, 'owed_periods': 2, 'paid_through': '2026-08-01',
      'next_due': '2026-09-01', 'exempt': false,
    });
    expect(s.paidUp, isFalse);
    expect(standingText(l, s), 'You owe ₦4,000 · 2 periods unpaid');
    expect(standingText(l, standings[1]), 'Paid up to November 2026');
    expect(standingText(l, standings[2]), 'Exempt');
  });

  test('the report and the statement print to PDF', () async {
    final regular = pw.Font.ttf(File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync().buffer.asByteData());
    final bold = pw.Font.ttf(File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync().buffer.asByteData());
    final pdf = await fundReportPdf(report, l, regular: regular, bold: bold, generatedAt: DateTime(2026, 10, 4));
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    final statement = await memberStatementPdf(
      l: l,
      family: 'Bua',
      name: 'Aisha',
      dues: [(plan, standings.first)],
      contributions: [
        Contribution(id: 'k', userId: 'u1', amount: 2000, method: PayMethod.cash, createdAt: DateTime(2026, 8, 2), duesPlanId: 'p1'),
      ],
      titles: const {'p1': 'Monthly dues'},
      regular: regular,
      bold: bold,
      generatedAt: DateTime(2026, 10, 4),
    );
    expect(statement.length, greaterThan(1000));
  });

  Widget app(Widget home, {bool treasurer = false}) => ProviderScope(
        overrides: [
          profileProvider.overrideWithValue(Profile(
            id: 'u1',
            displayName: 'Aisha',
            role: AppRole.member,
            status: AccountStatus.active,
            isTreasurer: treasurer,
          )),
          graphProvider.overrideWith((ref) async => buildFamily()),
          fundOverviewProvider.overrideWith((ref) async => const FundOverview(balance: 138000)),
          fundCausesProvider.overrideWith((ref) async => const []),
          contributionsProvider.overrideWith((ref) async => const []),
          duesPlansProvider.overrideWith((ref) async => [plan]),
          myDuesProvider.overrideWith((ref) async => [standings.first]),
          allDuesProvider.overrideWith((ref) async => standings),
          fundReportProvider.overrideWith((ref, p) async => report),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('members see what they owe and can pay', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const WelfareFundScreen()));
    await tester.pumpAndSettle();
    expect(find.text('My dues'), findsOneWidget);
    expect(find.text('₦2,000 a month'), findsOneWidget);
    expect(find.text('You owe ₦4,000 · 2 periods unpaid'), findsOneWidget);
    expect(find.text('₦1,000 waiting for confirmation'), findsOneWidget);
    expect(find.text('Pay dues'), findsOneWidget);
    expect(find.text('My statement (PDF)'), findsOneWidget);
  });

  testWidgets('the committee sees everyone, filters and summary', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const DuesScreen(), treasurer: true));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 owe · ₦4,000 outstanding'), findsOneWidget);
    expect(find.text('Usman'), findsOneWidget);
    await tester.tap(find.text('Owing 1'));
    await tester.pumpAndSettle();
    expect(find.text('Usman'), findsNothing);
    expect(find.text('Aisha'), findsOneWidget);
    await tester.tap(find.text('Aisha'));
    await tester.pumpAndSettle();
    expect(find.text('Record a payment from Aisha'), findsOneWidget);
    expect(find.text('Exempt from this plan'), findsOneWidget);
  });

  testWidgets('the report shows balances, sources, months and transactions', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(FundReportScreen(today: DateTime(2026, 10, 4)), treasurer: true));
    await tester.pumpAndSettle();
    expect(find.text('₦138,000'), findsOneWidget);
    expect(find.text('6 payments from 4 members'), findsOneWidget);
    expect(find.text('By cause and dues'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('5 of 12 owe · ₦14,000 outstanding'), findsOneWidget);
    expect(find.text('Fees for 2 pupils'), findsOneWidget);
  });
}
