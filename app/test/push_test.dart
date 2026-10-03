import 'dart:async';

import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/notification.dart';
import 'package:bua_family/services/push.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/admin_screen.dart';
import 'package:bua_family/ui/screens/notification_settings_screen.dart';
import 'package:bua_family/ui/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

class FakePlatform implements PushPlatform {
  FakePlatform({this.current = PushPermission.notAsked, this.answer = PushPermission.granted});

  PushPermission current;
  PushPermission answer;
  int asked = 0;
  final refreshes = StreamController<String>.broadcast();

  @override
  bool get available => true;
  @override
  String get platform => 'android';
  @override
  Future<PushPermission> permission() async => current;
  @override
  Future<PushPermission> requestPermission() async {
    asked++;
    return current = answer;
  }

  @override
  Future<String?> token() async => 'device-token-0123456789abcdef';
  @override
  Future<void> deleteToken() async {}
  @override
  Stream<String> get onTokenRefresh => refreshes.stream;
  @override
  Stream<String> get onOpen => const Stream.empty();
}

class FakeRepo extends FamilyRepository {
  FakeRepo()
      : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final registered = <(String, String)>[];
  final unregistered = <String>[];

  @override
  Future<void> registerPushToken(String token, String platform) async => registered.add((token, platform));
  @override
  Future<void> unregisterPushToken(String token) async => unregistered.add(token);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer container(FakePlatform platform, FakeRepo repo) {
    final c = ProviderContainer(overrides: [
      pushPlatformProvider.overrideWithValue(platform),
      repositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('turning on asks permission once and registers this device', () async {
    final platform = FakePlatform();
    final repo = FakeRepo();
    final c = container(platform, repo);
    c.read(pushControllerProvider);
    await pumpEventQueue();

    expect(await c.read(pushControllerProvider.notifier).enable(), PushResult.on);
    expect(platform.asked, 1);
    expect(repo.registered.single, ('device-token-0123456789abcdef', 'android'));
    expect(c.read(pushControllerProvider).on, isTrue);

    // A new token from Firebase is registered too.
    platform.refreshes.add('rotated-token-0123456789abcdef');
    await pumpEventQueue();
    expect(repo.registered.last.$1, 'rotated-token-0123456789abcdef');

    // Remembered on this device: after restarting, it re-registers itself.
    final again = FakeRepo();
    final c2 = container(FakePlatform(current: PushPermission.granted), again);
    await c2.read(pushControllerProvider.notifier).resume();
    expect(again.registered, hasLength(1));
    expect(c2.read(pushControllerProvider).on, isTrue);
  });

  test('blocked permission is reported, nothing registered', () async {
    final repo = FakeRepo();
    final c = container(FakePlatform(answer: PushPermission.denied), repo);
    expect(await c.read(pushControllerProvider.notifier).enable(), PushResult.blocked);
    expect(repo.registered, isEmpty);
    expect(c.read(pushControllerProvider).permission, PushPermission.denied);
  });

  test('turning off or signing out forgets this device', () async {
    final repo = FakeRepo();
    final c = container(FakePlatform(current: PushPermission.granted), repo);
    await c.read(pushControllerProvider.notifier).enable();
    await c.read(pushControllerProvider.notifier).disable();
    expect(repo.unregistered, ['device-token-0123456789abcdef']);
    expect(c.read(pushControllerProvider).on, isFalse);

    // Off is remembered: nothing is registered on the next start.
    final again = FakeRepo();
    await container(FakePlatform(current: PushPermission.granted), again).read(pushControllerProvider.notifier).resume();
    expect(again.registered, isEmpty);
  });

  Widget app(Widget home, {required FakePlatform platform, required FakeRepo repo, bool pushEnabled = true}) =>
      ProviderScope(
        overrides: [
          pushPlatformProvider.overrideWithValue(platform),
          repositoryProvider.overrideWithValue(repo),
          profileProvider.overrideWithValue(
              const Profile(id: 'me', displayName: 'Aisha', role: AppRole.admin, status: AccountStatus.active)),
          settingsProvider.overrideWith((ref) async => AppSettings(pushEnabled: pushEnabled)),
          notificationsProvider.overrideWith((ref) => Stream.value(const <AppNotification>[])),
          smsStatusProvider.overrideWith((ref) async => const SmsStatus()),
          pushStatusProvider.overrideWith((ref) async => pushEnabled
              ? {'project_id': 'bua-family', 'devices': 12, 'members': 9, 'sent_7d': 40}
              : <String, dynamic>{}),
          requestsProvider.overrideWith((ref, s) async => const <ChangeRequest>[]),
          profilesProvider.overrideWith((ref) async => const <Profile>[]),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('the inbox invites members to turn on notifications', (tester) async {
    tall(tester);
    final repo = FakeRepo();
    await tester.pumpWidget(app(const NotificationsScreen(), platform: FakePlatform(), repo: repo));
    await tester.pumpAndSettle();
    expect(find.text('Get notified on this phone'), findsOneWidget);

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(repo.registered, hasLength(1));
    expect(find.text('Notifications are on for this device.'), findsOneWidget);
    expect(find.text('Get notified on this phone'), findsNothing);
  });

  testWidgets('"Not now" hides the invitation for good', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const NotificationsScreen(), platform: FakePlatform(), repo: FakeRepo()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Get notified on this phone'), findsNothing);
    expect((await SharedPreferences.getInstance()).getBool('push_prompt_dismissed'), isTrue);
  });

  testWidgets('the device switch explains when push is not set up', (tester) async {
    tall(tester);
    await tester.pumpWidget(
        app(const NotificationSettingsScreen(), platform: FakePlatform(), repo: FakeRepo(), pushEnabled: false));
    await tester.pumpAndSettle();
    expect(find.text('Notifications on this phone'), findsOneWidget);
    expect(find.text("An admin hasn't set up phone notifications yet."), findsOneWidget);
    expect(find.text('Get notified on this phone'), findsNothing);
  });

  testWidgets('admins see push status and can send a test', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const AdminScreen(initialTab: 2), platform: FakePlatform(), repo: FakeRepo()));
    await tester.pumpAndSettle();
    expect(find.text('Phone notifications'), findsOneWidget);
    expect(find.text('Saved · bua-family'), findsOneWidget);
    expect(find.text('9 members on 12 devices · 40 sent this week'), findsOneWidget);
    expect(find.text('Send me a test notification'), findsOneWidget);
  });

  testWidgets('admins are guided through setup', (tester) async {
    tall(tester);
    await tester.pumpWidget(
        app(const AdminScreen(initialTab: 2), platform: FakePlatform(), repo: FakeRepo(), pushEnabled: false));
    await tester.pumpAndSettle();
    expect(find.text('Choose the key file (.json)'), findsOneWidget);
    expect(find.textContaining('console.firebase.google.com'), findsOneWidget);
    expect(find.text('Send me a test notification'), findsNothing);
  });
}
