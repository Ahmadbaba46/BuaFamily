import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/services/invites.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/join_screen.dart';
import 'package:bua_family/ui/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

class FakeRepo extends FamilyRepository {
  FakeRepo({this.info})
      : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final Map<String, dynamic>? info;
  final redeemed = <String>[];

  @override
  Future<Map<String, dynamic>?> inviteInfo(String code) async => info;
  @override
  Future<void> redeemInvite(String code) async => redeemed.add(code);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget app(Widget home, FakeRepo repo) => ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('sign in with a phone number instead of email', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const SignInScreen(), FakeRepo()));
    await tester.pumpAndSettle();
    expect(find.text('Password'), findsOneWidget);
    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();
    expect(find.text('Password'), findsNothing);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Send me a code'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '123');
    await tester.tap(find.text('Send me a code'));
    await tester.pump();
    expect(find.text('Enter a valid phone number'), findsOneWidget);
  });

  testWidgets('an invite shows who it is for, and is remembered for after signing up', (tester) async {
    tall(tester);
    final repo = FakeRepo(info: {'valid': true, 'person': 'Zara Bua', 'invited_by': 'Ahmad', 'family': 'Bua'});
    await tester.pumpWidget(app(const JoinScreen(code: 'welcome123'), repo));
    await tester.pumpAndSettle();
    expect(find.text('Ahmad invited you to the Bua family app.'), findsOneWidget);
    expect(find.text('This invite is for Zara Bua.'), findsOneWidget);
    expect(find.text('Join the family'), findsOneWidget);

    await rememberInvite('welcome123');
    expect(await redeemRememberedInvite(repo), isTrue);
    expect(repo.redeemed, ['welcome123']);
    expect(await redeemRememberedInvite(repo), isFalse); // only once
  });

  testWidgets('a used invite says so', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const JoinScreen(code: 'old'), FakeRepo(info: {'valid': false, 'family': 'Bua'})));
    await tester.pumpAndSettle();
    expect(find.textContaining('already been used or has expired'), findsOneWidget);
    expect(find.text('Join the family'), findsNothing);
  });

  test('invite links open the join page on the website', () {
    expect(inviteLink('abc'), 'https://buafamily.vercel.app/#/join/abc');
  });
}
