import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/password_reset_sheet.dart';
import 'package:bua_family/ui/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

class FakeRepo extends FamilyRepository {
  FakeRepo()
      : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final requested = <String>[];
  final resets = <(String, String, String)>[];
  int google = 0;

  @override
  Future<Map<String, dynamic>> requestPasswordResetSms(String phone) async {
    requested.add(phone);
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> resetPasswordWithSms(String phone, String code, String password) async {
    resets.add((phone, code, password));
    return code == '123456' ? {'ok': true, 'email': null} : {'ok': false, 'reason': 'wrong_code'};
  }

  @override
  Future<bool> signInWithGoogle({required bool web, String? webReturn}) async {
    google++;
    return true;
  }
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

  testWidgets('reset by SMS: phone, then code and new password', (tester) async {
    tall(tester);
    final repo = FakeRepo();
    await tester.pumpWidget(app(const Scaffold(body: PasswordResetBySms()), repo));
    await tester.enterText(find.byType(TextField), '0803 555 0001');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(repo.requested, ['2348035550001']);
    expect(find.textContaining('+234 803 555 0001'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '000000');
    await tester.enterText(find.byType(TextField).at(1), 'short');
    await tester.tap(find.text('Set new password'));
    await tester.pumpAndSettle();
    expect(repo.resets, isEmpty);
    expect(find.text('At least 8 characters'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'new-password-1');
    await tester.tap(find.text('Set new password'));
    await tester.pumpAndSettle();
    expect(repo.resets.single, ('2348035550001', '000000', 'new-password-1'));
    expect(find.text("That code isn't right. Check the text message."), findsOneWidget);
  });

  testWidgets('sign-in offers Google and both ways to reset', (tester) async {
    tall(tester);
    final repo = FakeRepo();
    await tester.pumpWidget(app(const SignInScreen(), repo));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(repo.google, 1);

    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Send a code to my phone'), findsOneWidget);
    expect(find.text('Send a link to my email'), findsOneWidget);
    await tester.tap(find.text('Send a code to my phone'));
    await tester.pumpAndSettle();
    expect(find.text('Send code'), findsOneWidget);
  });
}
