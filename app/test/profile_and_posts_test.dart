import 'dart:async';

import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/help.dart';
import 'package:bua_family/models/notification.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/more_screen.dart';
import 'package:bua_family/ui/screens/notifications_screen.dart';
import 'package:bua_family/ui/screens/post_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain_test.dart' show buildFamily;

void main() {
  final now = DateTime(2026, 10, 3, 12);

  Widget app(Widget home, {String? personId, String? requestedPersonId}) => ProviderScope(
        overrides: [
          profileProvider.overrideWithValue(Profile(
            id: 'u1',
            displayName: 'Aisha',
            role: AppRole.member,
            status: AccountStatus.active,
            personId: personId,
            requestedPersonId: requestedPersonId,
          )),
          graphProvider.overrideWith((ref) async => buildFamily()),
          settingsProvider.overrideWith((ref) async => const AppSettings()),
          membersProvider.overrideWith((ref) async => {
                'u1': const Member(userId: 'u1', displayName: 'Aisha'),
                'u2': const Member(userId: 'u2', displayName: 'Musa', personId: 'musa'),
              }),
          bloodRequestsProvider.overrideWith((ref) async => const <BloodRequest>[]),
          requestsProvider.overrideWith((ref, s) async => const <ChangeRequest>[]),
          myLikesProvider.overrideWith((ref) async => const <String>{}),
          postProvider.overrideWith((ref, id) async => id == 'p1'
              ? Post(id: 'p1', authorId: 'u2', createdAt: now, body: 'Sallah day', commentCount: 1)
              : null),
          commentsProvider.overrideWith((ref, t) async => [
                Comment(id: 'c1', authorId: 'u1', body: 'Lovely photos', createdAt: now),
              ]),
          photoUrlProvider.overrideWith((ref, path) => Completer<String>().future),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('a notification opens the post with its comments', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const PostScreen(postId: 'p1')));
    await tester.pumpAndSettle();
    expect(find.text('Sallah day'), findsOneWidget);
    expect(find.text('Lovely photos'), findsOneWidget);
  });

  testWidgets('a removed post says so', (tester) async {
    await tester.pumpWidget(app(const PostScreen(postId: 'gone')));
    await tester.pumpAndSettle();
    expect(find.text('This post was removed.'), findsOneWidget);
  });

  testWidgets('accounts not yet in the tree are invited to find themselves', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const MoreScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Member · Find yourself in the tree'), findsOneWidget);
  });

  testWidgets('a claim waits for an admin', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const MoreScreen(), requestedPersonId: 'musa'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Waiting for an admin to link you to musa'), findsOneWidget);
  });

  test('comment notifications say who commented', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    AppNotification n(Map<String, dynamic> data) =>
        AppNotification(id: 'x', kind: NotificationKind.comment, createdAt: now, data: data);
    expect(notificationText(l, n({'name': 'Musa Bua', 'body': 'Lovely'})), 'Musa Bua commented: “Lovely”');
    expect(notificationText(l, n({'name': 'Musa Bua', 'body': 'Lovely', 'also': true})),
        'Musa Bua also commented: “Lovely”');
    expect(notificationText(l, n({'body': 'Lovely'})), 'New comment: “Lovely”');
    expect(
        notificationText(
            l,
            AppNotification(
                id: 'y',
                kind: NotificationKind.accountRequest,
                createdAt: now,
                data: const {'name': 'Aisha', 'person': 'Aisha Bua'})),
        'Aisha says they are Aisha Bua in the tree');
  });
}
