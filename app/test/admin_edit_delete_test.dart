import 'dart:async';

import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/fund.dart';
import 'package:bua_family/models/messages.dart';
import 'package:bua_family/models/notification.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/admin_groups_screen.dart';
import 'package:bua_family/ui/screens/invites_screen.dart';
import 'package:bua_family/ui/screens/members_screen.dart';
import 'package:bua_family/ui/screens/new_event_screen.dart';
import 'package:bua_family/ui/screens/notifications_screen.dart' show notificationText;
import 'package:bua_family/ui/screens/payouts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

import 'domain_test.dart' show buildFamily;

class _FakeRepo extends FamilyRepository {
  _FakeRepo() : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final calls = <String>[];
  Map<String, dynamic>? eventChanges;

  @override
  Future<void> deletePerson(String id) async => calls.add('delete person $id');

  @override
  Future<void> updateEvent(String id, Map<String, dynamic> changes) async {
    calls.add('update event $id');
    eventChanges = changes;
  }

  @override
  Future<List<FundPayout>> payouts() async => [
        FundPayout(id: 'p1', amount: 20000, paidOn: DateTime(2026, 10, 2), causeId: 'c1', note: 'Hospital', recordedBy: 'u1'),
      ];

  @override
  Future<void> updatePayout(String id, {String? causeId, required double amount, String? note}) async =>
      calls.add('update payout $id $amount $causeId');

  @override
  Future<void> deletePayout(String id) async => calls.add('delete payout $id');

  @override
  Future<List<Invite>> invites() async => [
        Invite(code: 'open1', createdAt: DateTime.now(), personId: 'bello', createdBy: 'u1',
            expiresAt: DateTime.now().add(const Duration(days: 7))),
        Invite(code: 'used1', createdAt: DateTime(2026, 9, 1), createdBy: 'u1', usedBy: 'u2', usedAt: DateTime(2026, 9, 2)),
      ];

  @override
  Future<void> deleteInvite(String code) async => calls.add('delete invite $code');

  @override
  Future<List<AdminGroup>> adminGroups() async => [
        AdminGroup(id: 'g1', name: 'Cousins', createdAt: DateTime(2026, 10, 1), createdBy: 'u2', members: const [
          (userId: 'u2', admin: true),
          (userId: 'u3', admin: false),
        ]),
      ];

  @override
  Future<void> deleteGroup(String groupId) async => calls.add('delete group $groupId');

  @override
  Future<void> removeFromGroup(String groupId, String user) async => calls.add('remove $user from $groupId');
}

void main() {
  Widget app(Widget home, _FakeRepo repo, {AppRole role = AppRole.admin}) => ProviderScope(
        key: UniqueKey(),
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          profileProvider.overrideWithValue(Profile(
              id: 'u1', displayName: 'Aisha', role: role, status: AccountStatus.active, personId: 'aisha', isTreasurer: true)),
          graphProvider.overrideWith((ref) async => buildFamily()),
          photoUrlProvider.overrideWith((ref, path) => Completer<String>().future),
          membersProvider.overrideWith((ref) async => {
                'u1': const Member(userId: 'u1', displayName: 'Aisha', personId: 'aisha'),
                'u2': const Member(userId: 'u2', displayName: 'Musa', personId: 'musa'),
                'u3': const Member(userId: 'u3', displayName: 'Bello', personId: 'bello'),
              }),
          fundCausesProvider.overrideWith((ref) async => [
                FundCause(id: 'c1', title: 'Hospital bill', createdAt: DateTime(2026, 9, 1)),
              ]),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('admins delete people from the Members list, one or several at once', (tester) async {
    tall(tester);
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const MembersScreen(), repo, role: AppRole.member));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Options'), findsNothing, reason: 'members only look');

    await tester.pumpWidget(app(const MembersScreen(), repo));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Options'), findsWidgets);

    // One, from its menu.
    await tester.tap(find.descendant(of: find.widgetWithText(InkWell, 'stranger'), matching: find.byTooltip('Options')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from tree'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['delete person stranger']);

    // Several: a long press starts choosing.
    repo.calls.clear();
    await tester.longPress(find.text('bello'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.text('usman'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Delete these 2 people from the family tree'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.calls.toSet(), {'delete person bello', 'delete person usman'});
    expect(find.text('2 people deleted'), findsOneWidget);
    expect(find.text('2 selected'), findsNothing);
  });

  testWidgets('an event can be changed; the end time moves with the start', (tester) async {
    tall(tester);
    final repo = _FakeRepo();
    final starts = DateTime(2026, 11, 20, 10);
    final event = FamilyEvent(
      id: 'e1',
      title: 'Family meeting',
      startsAt: starts,
      endsAt: starts.add(const Duration(hours: 2)),
      createdBy: 'u1',
      place: 'Kano',
    );
    await tester.pumpWidget(app(Navigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => NewEventScreen(editing: event))), repo));
    await tester.pumpAndSettle();
    expect(find.text('Edit event'), findsOneWidget);
    expect(find.text('Those going are told if the date or place changes.'), findsOneWidget);
    expect(find.text('Notify the family'), findsNothing);
    expect(find.text('Kano'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Family meeting'), 'Family meeting (moved)');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['update event e1']);
    expect(repo.eventChanges!['title'], 'Family meeting (moved)');
    expect(repo.eventChanges!['place'], 'Kano');
    expect(DateTime.parse(repo.eventChanges!['ends_at'] as String).difference(DateTime.parse(repo.eventChanges!['starts_at'] as String)),
        const Duration(hours: 2));
    expect(repo.eventChanges!.containsKey('pinned'), isFalse, reason: 'pinning only changes when asked');
  });

  testWidgets('the committee corrects or deletes a payout', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const PayoutsScreen(), repo));
    await tester.pumpAndSettle();
    expect(find.text('₦20,000'), findsOneWidget);
    expect(find.textContaining('Hospital bill · Hospital · recorded by aisha'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '20000'), '18000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['update payout p1 18000.0 c1']);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The balance goes back up'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'delete payout p1');
  });

  testWidgets('admins see invites, and cancel one that should stop working', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const InvitesScreen(), repo));
    await tester.pumpAndSettle();
    expect(find.text('bello'), findsOneWidget);
    expect(find.textContaining('Not used yet'), findsOneWidget);
    expect(find.text('Anyone with the link'), findsOneWidget);
    expect(find.textContaining('Used by musa'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    expect(find.text('Share'), findsOneWidget);
    await tester.tap(find.text('Cancel invite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['delete invite open1']);

    // A used one just comes off the list, without asking.
    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    expect(find.text('Share'), findsNothing);
    await tester.tap(find.text('Remove from list'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'delete invite used1');
  });

  testWidgets('admins see every group (not what was said), remove someone or delete it', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const AdminGroupsScreen(), repo));
    await tester.pumpAndSettle();
    expect(find.text('Cousins'), findsOneWidget);
    expect(find.textContaining('2 members · started by musa'), findsOneWidget);
    expect(find.text('musa, bello'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove someone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bello').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['remove u3 from g1']);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete group'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Delete “Cousins” for everyone?'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'delete group g1');
  });

  test('a moved event reads clearly in both languages', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ha = await AppLocalizations.delegate.load(const Locale('ha'));
    AppNotification n(Map<String, dynamic> data) =>
        AppNotification.fromJson({'id': 'n1', 'kind': 'event_changed', 'created_at': '2026-11-01T10:00:00Z', 'data': data})!;
    final moved = n({'title': 'Family meeting', 'moved': true, 'starts_at': '2026-11-22T09:00:00Z'});
    expect(notificationText(en, moved), startsWith('Family meeting has moved to '));
    expect(notificationText(en, n({'title': 'Family meeting', 'moved': false, 'place': 'Zaria'})),
        'Family meeting has a new place: Zaria');
    expect(notificationText(ha, n({'title': 'Taro', 'moved': false, 'place': 'Zaria'})), 'Taro ya koma sabon wuri: Zaria');
  });
}
