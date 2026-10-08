import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/contributions.dart';
import 'package:bua_family/models/fund.dart';
import 'package:bua_family/models/social.dart' show Member;
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/fund_cause_screen.dart';
import 'package:bua_family/ui/screens/welfare_fund_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

import 'domain_test.dart' show buildFamily;

class _PayoutRepo extends FamilyRepository {
  _PayoutRepo()
      : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final done = <String>[];

  @override
  Future<num> eventPayoutDone(String eventId) async {
    done.add(eventId);
    return 45000;
  }
}

void main() {
  final now = DateTime.now();
  final causes = [
    FundCause(id: 'c1', title: 'School fees support', createdAt: now, target: 600000, raised: 450000, contributors: 42,
        closesOn: DateTime(2026, 10, 31), names: const ['Aisha Bua', 'Sani Bua'], description: 'Helps 9 students.'),
    FundCause(id: 'c2', title: "Sani Bua's hospital bills", createdAt: now, target: 500000, raised: 180000, contributors: 14, urgent: true),
    FundCause(id: 'c3', title: 'Help with rent', createdAt: now, target: 50000, status: CauseStatus.proposed, createdBy: 'u2'),
  ];
  final contributions = [
    Contribution(id: 'k1', userId: 'u1', amount: 20000, method: PayMethod.transfer, createdAt: now, causeId: 'c1'),
    Contribution(id: 'k2', userId: 'u2', amount: 5000, method: PayMethod.cash, createdAt: now, causeId: 'c2', receiptPath: 'u2/r.jpg'),
  ];

  Widget app(Widget home, {bool treasurer = false, List<EventPayoutDue>? payouts, FamilyRepository? repo}) =>
      ProviderScope(
        overrides: [
          if (repo != null) repositoryProvider.overrideWithValue(repo),
          if (payouts != null) eventPayoutsDueProvider.overrideWith((ref) async => payouts),
          profileProvider.overrideWithValue(Profile(
            id: 'u1',
            displayName: 'Aisha',
            role: AppRole.member,
            status: AccountStatus.active,
            personId: 'aisha',
            isTreasurer: treasurer,
          )),
          graphProvider.overrideWith((ref) async => buildFamily()),
          membersProvider.overrideWith((ref) async => const {
                'u2': Member(userId: 'u2', displayName: 'Usman', personId: 'usman'),
              }),
          fundOverviewProvider.overrideWith((ref) async => FundOverview(
                balance: 1240000,
                treasurers: const ['Hajiya Amina Bua'],
                updatedAt: now,
                bankName: 'Family Bank',
                accountNumber: '0123456789',
                accountName: 'Bua Family Welfare',
              )),
          fundCausesProvider.overrideWith((ref) async => treasurer ? causes : causes.take(2).toList()),
          contributionsProvider.overrideWith((ref) async => treasurer ? contributions : contributions.take(1).toList()),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  test('naira formatting', () {
    expect(naira(1240000), '₦1,240,000');
    expect(naira(2500.5), '₦2,500.5');
  });

  test('cause totals are merged from the database', () {
    final c = FundCause.fromJson(
      {'id': 'c', 'title': 'T', 'created_at': '2026-10-03T10:00:00Z', 'target_amount': 600000, 'status': 'open'},
      totals: {'raised': 150000, 'contributors': 3, 'names': ['A']},
    );
    expect(c.progress, 0.25);
    expect(c.contributors, 3);
    expect(c.names, ['A']);
  });

  testWidgets('members see the balance, causes and their own contributions', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const WelfareFundScreen()));
    await tester.pumpAndSettle();

    expect(find.text('₦1,240,000'), findsOneWidget);
    expect(find.textContaining('Treasurer: Hajiya Amina Bua'), findsOneWidget);
    expect(find.text('URGENT'), findsOneWidget);
    expect(find.text("Sani Bua's hospital bills"), findsOneWidget);
    expect(find.text('My contributions'), findsOneWidget);
    expect(find.text('Waiting for the treasurer'), findsOneWidget);
    expect(find.textContaining('To confirm'), findsNothing);
    expect(find.text('Help with rent'), findsNothing);
  });

  testWidgets('treasurers see what to confirm and support requests', (tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const WelfareFundScreen(), treasurer: true));
    await tester.pumpAndSettle();

    expect(find.text('To confirm · 2'), findsOneWidget);
    expect(find.text('Confirm'), findsNWidgets(2));
    expect(find.text('Receipt'), findsOneWidget);
    expect(find.text('Support requests'), findsOneWidget);
    expect(find.text('Help with rent'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('cause page shows progress, how to pay and the form', (tester) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const FundCauseScreen(causeId: 'c1')));
    await tester.pumpAndSettle();

    expect(find.text('School fees support'), findsOneWidget);
    expect(find.textContaining('42 contributors'), findsOneWidget);
    expect(find.textContaining('closes October 31, 2026'), findsOneWidget);
    expect(find.text('Aisha Bua, Sani Bua'), findsOneWidget);
    expect(find.text('0123456789'), findsOneWidget);
    expect(find.text('Copy account number'), findsOneWidget);
    expect(find.text('Record contribution'), findsOneWidget);
    expect(find.text('Cash to treasurer'), findsOneWidget);
  });

  testWidgets('treasurers see gifts paid in the app to pass on to hosts', (tester) async {
    tester.view.physicalSize = const Size(390, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _PayoutRepo();
    await tester.pumpWidget(app(const WelfareFundScreen(), treasurer: true, repo: repo, payouts: const [
      EventPayoutDue(eventId: 'e1', title: 'Naming of Fatima', receiverId: 'u2', amount: 45000, payments: 3),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('To pass on to hosts'), findsOneWidget);
    expect(find.text('Naming of Fatima'), findsOneWidget);
    expect(find.text('To usman · 3 payments'), findsOneWidget);
    expect(find.text('₦45,000'), findsOneWidget);
    await tester.tap(find.text('Sent to host'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Have you sent ₦45,000 to usman?'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.done, ['e1']);
  });
}
