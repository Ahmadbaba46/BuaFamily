import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/fund.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/admin_screen.dart';
import 'package:bua_family/ui/screens/fund_cause_screen.dart';
import 'package:bua_family/ui/screens/online_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

class _FakeRepo extends FamilyRepository {
  _FakeRepo({this.statuses = const ['paid']})
      : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final List<String> statuses;
  final started = <(double, String?, bool)>[];
  final keys = <String>[];
  final fundChanges = <Map<String, dynamic>>[];
  int checks = 0;

  @override
  Future<({String reference, String checkoutUrl})> startOnlinePayment(
      {required double amount, String? causeId, String? duesPlanId, bool showName = true}) async {
    started.add((amount, causeId, showName));
    return (reference: 'bua-1', checkoutUrl: 'https://checkout.korapay.com/x');
  }

  @override
  Future<String> checkOnlinePayment(String reference) async {
    final s = statuses[checks < statuses.length ? checks : statuses.length - 1];
    checks++;
    return s;
  }

  @override
  Future<void> setKorapayKey(String secretKey) async => keys.add(secretKey);

  @override
  Future<void> updateFundSettings(Map<String, dynamic> changes) async => fundChanges.add(changes);
}

void main() {
  final cause = FundCause(id: 'c1', title: 'Hospital bill', createdAt: DateTime(2026, 10, 1), target: 100000);

  Widget app(Widget home, _FakeRepo repo, {bool online = true, KorapayStatus? korapay}) => ProviderScope(
        key: UniqueKey(),
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          fundOverviewProvider.overrideWith((ref) async => FundOverview(
              bankName: 'Jaiz', accountNumber: '0123456789', accountName: 'Bua Family', onlinePayments: online)),
          fundCausesProvider.overrideWith((ref) async => [cause]),
          korapayStatusProvider.overrideWith((ref) async => korapay ?? const KorapayStatus()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, _) => home),
            GoRoute(path: '/fund', builder: (_, _) => const Scaffold(body: Text('the fund'))),
            GoRoute(path: '/fund/paid/:ref', builder: (_, s) => OnlinePaymentScreen(reference: s.pathParameters['ref']!)),
          ]),
        ),
      );

  testWidgets('a member pays a cause in the app and sees it confirmed', (tester) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const FundCauseScreen(causeId: 'c1'), repo));
    await tester.pumpAndSettle();
    expect(find.text('Record a payment I made'), findsOneWidget, reason: 'recording a payment is still there');

    await tester.tap(find.text('Pay now (card or transfer)'));
    await tester.pumpAndSettle();
    expect(repo.started, isEmpty, reason: 'needs an amount');
    expect(find.text('Enter at least ₦100.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '5000');
    await tester.tap(find.text('Pay now (card or transfer)'));
    await tester.pumpAndSettle();
    expect(repo.started, [(5000.0, 'c1', true)]);
    expect(find.text('Payment received. Thank you!'), findsOneWidget);
    await tester.tap(find.text('Back to the welfare fund'));
    await tester.pumpAndSettle();
    expect(find.text('the fund'), findsOneWidget);
  });

  testWidgets('without online payments, only recording', (tester) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const FundCauseScreen(causeId: 'c1'), _FakeRepo(), online: false));
    await tester.pumpAndSettle();
    expect(find.text('Pay now (card or transfer)'), findsNothing);
    expect(find.text('Record contribution'), findsWidgets);
  });

  testWidgets('not finished yet: checks again', (tester) async {
    final repo = _FakeRepo(statuses: ['waiting', 'paid']);
    await tester.pumpWidget(app(const OnlinePaymentScreen(reference: 'bua-1'), repo));
    await tester.pumpAndSettle();
    expect(find.text('Not finished yet'), findsOneWidget);
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(find.text('Payment received. Thank you!'), findsOneWidget);
    expect(repo.checks, 2);
  });

  testWidgets('admins set up Korapay and switch it on', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const Scaffold(body: SingleChildScrollView(child: AdminPaymentsCard())), repo,
        korapay: const KorapayStatus()));
    await tester.pumpAndSettle();
    expect(find.text('Not set up: enter your Korapay secret key'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull, reason: 'no switching on without a key');
    await tester.tap(find.text('Enter secret key'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' sk_test_abc ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.keys, ['sk_test_abc']);

    await tester.pumpWidget(app(const Scaffold(body: SingleChildScrollView(child: AdminPaymentsCard())), repo,
        korapay: const KorapayStatus(keySaved: true, mode: 'test', paid30d: 3, amount30d: 15000)));
    await tester.pumpAndSettle();
    expect(find.text('Test mode: no real money moves'), findsOneWidget);
    expect(find.text('3 paid in the app in the last 30 days, ₦15,000'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repo.fundChanges, [{'online_payments': true}]);
  });
}
