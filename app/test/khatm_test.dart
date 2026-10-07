import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/khatm.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/khatm_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

import 'domain_test.dart' show buildFamily;

class _FakeRepo extends FamilyRepository {
  _FakeRepo() : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final taken = <int?>[];
  final read = <(int, bool)>[];
  final released = <int>[];
  final started = <Map<String, Object?>>[];

  @override
  Future<int> takeJuz(String khatmId, {int? juz}) async {
    taken.add(juz);
    return juz ?? 4;
  }

  @override
  Future<void> markJuzRead(String khatmId, int juz, {bool read = true}) async => this.read.add((juz, read));

  @override
  Future<void> releaseJuz(String khatmId, int juz) async => released.add(juz);

  @override
  Future<String> startKhatm(
      {required String title, KhatmPurpose purpose = KhatmPurpose.memorial, String? personId, String? note, DateTime? dueOn}) async {
    started.add({'title': title, 'person': personId, 'purpose': purpose});
    return 'k-new';
  }
}

void main() {
  final khatm = Khatm(
    id: 'k1',
    title: 'Khatm for Ahmadu',
    createdAt: DateTime(2026, 10, 1),
    personId: 'ahmadu',
    createdBy: 'u2',
    dueOn: DateTime(2026, 10, 20),
    parts: [
      KhatmPart(juz: 1, userId: 'u1', claimedAt: DateTime(2026, 10, 1), doneAt: DateTime(2026, 10, 2)),
      KhatmPart(juz: 2, userId: 'u1', claimedAt: DateTime(2026, 10, 1)),
      KhatmPart(juz: 3, userId: 'u2', claimedAt: DateTime(2026, 10, 1)),
      const KhatmPart(juz: 7), // given back
    ],
  );

  test('progress: read, taken, free, and who reads what', () {
    expect(khatm.readCount, 1);
    expect(khatm.takenCount, 3);
    expect(khatm.freeCount, 27);
    expect(khatm.partsOf('u1').map((p) => p.juz), [1, 2]);
    expect(khatm.readers, {'u1': 2, 'u2': 1});
    expect(khatm.part(30).taken, isFalse);
    expect(khatm.open, isTrue);
  });

  Widget app(Widget home, _FakeRepo repo) => ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          profileProvider.overrideWithValue(
              const Profile(id: 'u1', displayName: 'Aisha', role: AppRole.member, status: AccountStatus.active)),
          graphProvider.overrideWith((ref) async => buildFamily()),
          khatmsProvider.overrideWith((ref) async => [khatm]),
          membersProvider.overrideWith((ref) async => {
                'u1': const Member(userId: 'u1', displayName: 'Aisha Bua'),
                'u2': const Member(userId: 'u2', displayName: 'Musa Bua'),
              }),
        ],
        child: MaterialApp.router(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, _) => home),
            GoRoute(path: '/khatm/:id', builder: (_, s) => Scaffold(body: Text('khatm ${s.pathParameters['id']}'))),
          ]),
        ),
      );

  Finder juz(String n) => find.descendant(of: find.byType(GridView), matching: find.text(n));

  testWidgets('the 30 juz: take a free one, read your own', (tester) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const KhatmScreen(khatmId: 'k1'), repo));
    await tester.pumpAndSettle();
    expect(find.text('Khatm for Ahmadu'), findsOneWidget);
    expect(find.text('1 of 30 read · 3 taken'), findsOneWidget);
    expect(find.text('Free'), findsNWidgets(28), reason: '27 free tiles and the legend');

    // A free juz.
    await tester.tap(juz('10'));
    await tester.pumpAndSettle();
    expect(find.text('Take juz 10?'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.taken, [10]);

    // My unread juz: read it.
    await tester.tap(juz('2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I've read it"));
    await tester.pumpAndSettle();
    expect(repo.read, [(2, true)]);

    // Someone else's: nothing to do (not the starter, not an admin).
    await tester.tap(juz('3'));
    await tester.pumpAndSettle();
    expect(find.text("I've read it"), findsNothing);

    await tester.tap(find.text('Take the next free juz'));
    await tester.pumpAndSettle();
    expect(repo.taken, [10, null]);
    expect(find.text('Juz 4 is yours. May Allah make it easy.'), findsOneWidget);
    expect(find.text('Aisha Bua'), findsOneWidget, reason: 'the readers list');
  });

  testWidgets('starting a khatm for a relative who has passed', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const NewKhatmScreen(personId: 'ahmadu'), repo));
    await tester.pumpAndSettle();
    expect(find.text('Khatm for ahmadu'), findsOneWidget, reason: 'the name is suggested');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Start a khatm'));
    await tester.tap(find.widgetWithText(FilledButton, 'Start a khatm'));
    await tester.pumpAndSettle();
    expect(repo.started, [
      {'title': 'Khatm for ahmadu', 'person': 'ahmadu', 'purpose': KhatmPurpose.memorial},
    ]);
    expect(find.text('khatm k-new'), findsOneWidget);
  });
}
