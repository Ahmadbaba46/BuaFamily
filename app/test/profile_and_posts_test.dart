import 'dart:async';

import 'package:bua_family/data/repository.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

import 'domain_test.dart' show buildFamily;

class _FakeAuth extends AuthController {
  _FakeAuth({this.fail})
      : super(FamilyRepository(
            SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false))));

  final Object? fail;
  int deleted = 0;

  @override
  Future<void> deleteAccount() async {
    if (fail != null) throw fail!;
    deleted++;
  }
}

void main() {
  final now = DateTime(2026, 10, 3, 12);

  Widget app(Widget home, {String? personId, String? requestedPersonId, AuthController? auth}) => ProviderScope(
        overrides: [
          if (auth != null) authProvider.overrideWith((ref) => auth),
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

  testWidgets('members can delete their account, after reading what goes and what stays', (tester) async {
    tall(tester);
    final auth = _FakeAuth();
    await tester.pumpWidget(app(const MoreScreen(), auth: auth));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete my account'), 200);
    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    expect(find.textContaining('Kept for the family'), findsOneWidget);
    // Not until they tick that they understand.
    final delete = find.widgetWithText(FilledButton, 'Delete my account');
    expect(tester.widget<FilledButton>(delete).onPressed, isNull);
    await tester.tap(find.text("I understand this can't be undone"));
    await tester.pump();
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(auth.deleted, 1);
  });

  testWidgets('the only admin is told to hand over first', (tester) async {
    tall(tester);
    final auth = _FakeAuth(fail: Exception('You are the only admin. Make someone else an admin first.'));
    await tester.pumpWidget(app(const MoreScreen(), auth: auth));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete my account'), 200);
    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I understand this can't be undone"));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete my account'));
    await tester.pumpAndSettle();
    expect(find.text('You are the only admin. Make someone else an admin first.'), findsOneWidget);
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
