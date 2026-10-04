// The largest text size (on top of a phone already at 100%) on a small phone:
// nothing runs off the screen.
import 'dart:async';

import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/details.dart';
import 'package:bua_family/models/notification.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/app_settings_screen.dart';
import 'package:bua_family/ui/screens/event_screen.dart';
import 'package:bua_family/ui/screens/home_screen.dart';
import 'package:bua_family/ui/screens/members_screen.dart';
import 'package:bua_family/ui/screens/more_screen.dart';
import 'package:bua_family/ui/screens/person_screen.dart';
import 'package:bua_family/ui/screens/tree_screen.dart';
import 'package:bua_family/ui/screens/messages_screen.dart';
import 'package:bua_family/ui/screens/notifications_screen.dart';
import 'package:bua_family/ui/screens/sign_in_screen.dart';
import 'package:bua_family/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'domain_test.dart' show buildFamily;

void main() {
  final now = DateTime.now();
  final events = [
    FamilyEvent(id: 'e1', title: 'Sallah lunch at the family house', startsAt: now.subtract(const Duration(hours: 1)),
        createdBy: 'u3', place: 'Family house, Kano'),
  ];
  Widget app(Widget home) => ProviderScope(
        overrides: [
          profileProvider.overrideWithValue(const Profile(
              id: 'u1', displayName: 'Aisha', role: AppRole.admin, status: AccountStatus.active, personId: 'aisha')),
          graphProvider.overrideWith((ref) async => buildFamily()),
          settingsProvider.overrideWith((ref) async => const AppSettings()),
          membersProvider.overrideWith((ref) async => const {'u1': Member(userId: 'u1', displayName: 'Aisha', personId: 'aisha')}),
          feedProvider.overrideWith((ref) async => [
                Post(id: 'p2', authorId: 'u1', createdAt: now, body: 'Maryam is home with us. Alhamdulillah.', likeCount: 24, commentCount: 8),
              ]),
          eventsProvider.overrideWith((ref) async => events),
          myLikesProvider.overrideWith((ref) async => <String>{}),
          albumsProvider.overrideWith((ref) async => const <Album>[]),
          commentsProvider.overrideWith((ref, target) async => const <Comment>[]),
          notificationsProvider.overrideWith((ref) => Stream.value(const <AppNotification>[])),
          detailsProvider.overrideWith((ref, id) async => const PersonDetails()),
          requestsProvider.overrideWith((ref, s) async => const []),
          eventAttendanceProvider.overrideWith((ref, id) async => const ['musa']),
          dmMessagesProvider.overrideWith((ref, id) => Stream.value(const [])),
          dmThreadsProvider.overrideWith((ref) => Stream.value(const [])),
          photoUrlProvider.overrideWith((ref, path) => Completer<String>().future),
          bloodRequestsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)), child: child!),
          home: home,
        ),
      );
  for (final (name, screen) in [
    ('home', HomeScreen(now: now)),
    ('person', const PersonScreen(personId: 'musa')),
    ('event', const EventScreen(eventId: 'e1')),
    ('settings', const AppSettingsScreen()),
    ('more', const MoreScreen()),
    ('members', const MembersScreen()),
    ('tree', const TreeScreen()),
    ('messages', const MessagesScreen()),
    ('notifications', NotificationsScreen(now: now)),
    ('signin', const SignInScreen()),
    ('dm', const DmScreen(threadId: 't1')),
  ]) {
    testWidgets('larger text fits: $name', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('larger text fits: family line', (tester) async {
    SharedPreferences.setMockInitialValues({'tree_family_line': true});
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const TreeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Children (2)'), findsOneWidget);
  });
}
