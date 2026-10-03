import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/notification.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required AppSettings settings, required SmsStatus status}) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profileProvider.overrideWithValue(
            const Profile(id: 'me', displayName: 'Admin', role: AppRole.admin, status: AccountStatus.active)),
        settingsProvider.overrideWith((ref) async => settings),
        smsStatusProvider.overrideWith((ref) async => status),
        requestsProvider.overrideWith((ref, s) async => const <ChangeRequest>[]),
        profilesProvider.overrideWith((ref) async => const <Profile>[]),
      ],
      child: const MaterialApp(
        localizationsDelegates: localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdminScreen(initialTab: 2),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('SMS card guides setup until a key and sender ID are saved', (tester) async {
    await pump(tester, settings: const AppSettings(), status: const SmsStatus());
    expect(find.text('Send SMS to the family'), findsOneWidget);
    expect(find.textContaining('Get an API key'), findsOneWidget);
    expect(find.text('Not set'), findsNWidgets(2), reason: 'key and sender ID');
    expect(find.text('Send a test SMS to me'), findsNothing);
  });

  testWidgets('SMS card shows status and a test button once set up', (tester) async {
    await pump(
      tester,
      settings: const AppSettings(smsEnabled: true, smsSenderId: 'BuaFamily'),
      status: const SmsStatus(keySaved: true, subscribers: 37, sent7d: 112, failed7d: 2, lastError: '400 DND'),
    );
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('BuaFamily'), findsOneWidget);
    expect(find.text('37 subscribed · 112 sent this week · 2 failed'), findsOneWidget);
    expect(find.text('Last error: 400 DND'), findsOneWidget);
    expect(find.text('Send a test SMS to me'), findsOneWidget);
  });
}
