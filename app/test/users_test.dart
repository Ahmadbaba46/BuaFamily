import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/users_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

import 'domain_test.dart' show buildFamily;

class _FakeRepo extends FamilyRepository {
  _FakeRepo()
      : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final deleted = <String>[];
  final updates = <(String, AccountStatus?)>[];

  @override
  Future<void> adminDeleteAccount(String userId) async => deleted.add(userId);

  @override
  Future<void> adminUpdateAccount(String userId,
          {AccountStatus? status, AppRole? role, String? personId, bool unlink = false}) async =>
      updates.add((userId, status));
}

void main() {
  final now = DateTime(2026, 10, 4, 12);

  UserRow user(String id, String name,
          {AccountStatus status = AccountStatus.active,
          AppRole role = AppRole.member,
          String? personId,
          String? personName,
          DateTime? seen,
          String? platform,
          Map<String, int> devices = const {},
          int days = 0,
          bool treasurer = false,
          String? phone,
          String? requested,
          String? note,
          DateTime? created}) =>
      UserRow(
        profile: Profile(
          id: id,
          displayName: name,
          email: '${name.toLowerCase()}@example.com',
          role: role,
          status: status,
          personId: personId,
          lastSeenAt: seen,
          lastPlatform: platform,
          isTreasurer: treasurer,
          phone: phone,
          requestedPersonId: requested,
          claimNote: note,
          createdAt: created ?? DateTime(2026, 10, 1),
        ),
        personName: personName,
        devices: devices,
        activeDays30: days,
      );

  final users = [
    user('a', 'Ahmad', role: AppRole.admin, personId: 'musa', personName: 'Musa Bua',
        seen: now.subtract(const Duration(hours: 1)), platform: 'android', devices: {'android': 1}, days: 20),
    user('b', 'Bilkisu', personId: 'aisha', personName: 'Aisha Bua', seen: now.subtract(const Duration(days: 2)),
        platform: 'web', devices: {'web': 1}, days: 5, treasurer: true, phone: '2348031234567'),
    user('c', 'Chiroma', seen: now.subtract(const Duration(days: 45)), platform: 'web', days: 0),
    user('d', 'Dije', status: AccountStatus.pending, created: DateTime(2026, 10, 3)),
    user('e', 'Ese', status: AccountStatus.suspended, personId: 'sani', personName: 'Sani Bua'),
  ];
  final claimant = user('f', 'Fati', requested: 'fatima', note: 'I am Aisha\'s daughter', seen: now, platform: 'web');

  test('search covers name, email, phone and the linked person', () {
    expect(users.where((u) => userMatches(u, 'aisha')).map((u) => u.profile.id), ['b']);
    expect(users.where((u) => userMatches(u, 'chiroma@')).map((u) => u.profile.id), ['c']);
    expect(users.where((u) => userMatches(u, '0803 123')).map((u) => u.profile.id), ['b']);
  });

  test('filters', () {
    List<String> ids(UserFilter f) => users.where((u) => userInFilter(u, f, now)).map((u) => u.profile.id).toList();
    expect(ids(UserFilter.waiting), ['d']);
    expect(ids(UserFilter.notLinked), ['c', 'd']);
    expect(ids(UserFilter.noPush), ['c', 'd', 'e']);
    expect(ids(UserFilter.inactive), ['c', 'd', 'e']);
    expect(ids(UserFilter.treasurers), ['b']);
    expect(users.where((u) => userOnPlatform(u, UserPlatform.android)).map((u) => u.profile.id), ['a']);
  });

  test('sorting', () {
    List<String> sorted(UserSort s) => ([...users]..sort((a, b) => compareUsers(a, b, s))).map((u) => u.profile.id).toList();
    expect(sorted(UserSort.lastActive).take(3), ['a', 'b', 'c']);
    expect(sorted(UserSort.mostActive).first, 'a');
    expect(sorted(UserSort.newest).first, 'd');
    expect(sorted(UserSort.name), ['a', 'b', 'c', 'd', 'e']);
  });

  Widget app({_FakeRepo? repo}) => ProviderScope(
        overrides: [
          if (repo != null) repositoryProvider.overrideWithValue(repo),
          profilesProvider.overrideWith((ref) async => [for (final u in users) u.profile]),
          adminUsersProvider.overrideWith((ref) async => users),
          graphProvider.overrideWith((ref) async => buildFamily()),
          profileProvider.overrideWithValue(users.first.profile),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: UsersView(now: now)),
        ),
      );

  testWidgets('the users page searches, filters and opens details', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('5 accounts'), findsOneWidget);
    // Waiting accounts come first, as cards.
    expect(find.text('Dije'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Dije')).dy, lessThan(tester.getTopLeft(find.text('Ahmad')).dy));

    await tester.ensureVisible(find.text('Not in the tree 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not in the tree 2'));
    await tester.pumpAndSettle();
    expect(find.text('2 accounts'), findsOneWidget);
    expect(find.text('Bilkisu'), findsNothing);

    await tester.ensureVisible(find.text('All 5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All 5'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'aisha');
    await tester.pumpAndSettle();
    expect(find.text('1 account'), findsOneWidget);
    await tester.tap(find.text('Bilkisu'));
    await tester.pumpAndSettle();
    expect(find.text('Linked to Aisha Bua'), findsWidgets);
    expect(find.text('Active on 5 of the last 30 days'), findsOneWidget);
    expect(find.text('Remove as treasurer'), findsOneWidget);
  });

  testWidgets('claims show at the top with confirm, link someone else and decline', (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        adminUsersProvider.overrideWith((ref) async => [...users, claimant]),
        graphProvider.overrideWith((ref) async => buildFamily()),
        profileProvider.overrideWithValue(users.first.profile),
        profilesProvider.overrideWith((ref) async => [for (final u in [...users, claimant]) u.profile]),
      ],
      child: MaterialApp(
        localizationsDelegates: localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: UsersView(now: now, initialFilter: UserFilter.claims)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Claims 1'), findsOneWidget);
    expect(find.text('Fati'), findsOneWidget);
    expect(find.text('Says this is them in the tree'), findsOneWidget);
    expect(find.textContaining(RegExp('fatima', caseSensitive: false)), findsWidgets);
    expect(find.textContaining('child of'), findsOneWidget);
    expect(find.text('“I am Aisha\'s daughter”'), findsOneWidget);
    expect(find.text('Confirm & link'), findsOneWidget);
    expect(find.text('Link someone else'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    // Only open claims of approved, unlinked members count.
    expect(userInFilter(claimant, UserFilter.claims, now), isTrue);
    expect(users.where((u) => userInFilter(u, UserFilter.claims, now)), isEmpty);
  });

  testWidgets('admins decline or delete a waiting account', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    await tester.pumpWidget(app(repo: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(repo.updates, [('d', AccountStatus.suspended)]);

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Delete Dije's account for good?"), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.deleted, ['d']);
    expect(find.text("Dije's account was deleted."), findsOneWidget);
  });

  testWidgets('no delete button for admins or yourself', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Chiroma'));
    await tester.tap(find.text('Chiroma'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account'), findsWidgets);
    expect(find.text('Suspend'), findsOneWidget);
    Navigator.of(tester.element(find.text('Suspend'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ahmad'));
    await tester.pumpAndSettle();
    expect(find.text('Suspend'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Delete account'), findsNothing);
  });
}
