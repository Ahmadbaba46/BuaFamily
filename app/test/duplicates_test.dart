import 'package:bua_family/data/repository.dart';
import 'package:bua_family/domain/duplicates.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/family_graph.dart';
import 'package:bua_family/models/person.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/duplicates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

class _FakeRepo extends FamilyRepository {
  _FakeRepo() : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final merged = <(String, String)>[];
  final different = <(String, String)>[];

  @override
  Future<void> mergePersons({required String keepId, required String removeId}) async => merged.add((keepId, removeId));

  @override
  Future<void> markNotDuplicate(String a, String b) async => different.add((a, b));
}

void main() {
  Person p(String id, String first, {String? last, Sex sex = Sex.male, int? year, bool approx = true}) => Person(
        id: id,
        firstName: first,
        lastName: last,
        sex: sex,
        birthDate: year == null ? null : DateTime(year),
        birthDateApprox: approx,
      );
  var n = 0;
  ParentLink link(String parent, String child) =>
      ParentLink(id: 'l${n++}', parentId: parent, childId: child, kind: ParentKind.biological);

  test('names are compared the way people write them', () {
    expect(nameKey('Muhammadu'), nameKey('Mohammed'));
    expect(nameKey("A'isha"), nameKey('Aishatu'));
    expect(nameKey('Ɗahiru'), 'dahiru');
    expect(nameKey('Zainab'), nameKey('Zaynab'));
    expect(nameKey('Abba'), 'aba');
  });

  test('the same person entered twice is found; namesakes and relatives are not', () {
    final g = FamilyGraph(
      persons: [
        p('dad', 'Ahmadu', last: 'Bua', year: 1920),
        p('m1', 'Muhammadu', last: 'Bua', year: 1950),
        p('m2', 'Mohammed', year: 1951), // same son, entered again
        p('m3', 'Muhammad', last: 'Bua', year: 1990), // a grandson named after him
        p('a1', 'Aisha', sex: Sex.female),
        p('a2', 'Aishatu', sex: Sex.female), // no other clue: name only
        p('s1', 'Sani', last: 'Bua'),
        p('s2', 'Sani', last: 'Garba'), // a different family
        p('f1', 'Fatima', sex: Sex.female),
        p('f2', 'Fatima', sex: Sex.male),
      ],
      links: [link('dad', 'm1'), link('dad', 'm2'), link('m1', 'm3')],
      unions: const [],
    );
    final found = findDuplicates(g);
    final keys = {for (final d in found) d.key};
    expect(keys, contains(('m1', 'm2')));
    expect(keys, isNot(contains(('m1', 'm3'))), reason: 'father and son');
    expect(keys, isNot(contains(('m2', 'm3'))), reason: '39 years apart');
    expect(keys, isNot(contains(('s1', 's2'))), reason: 'different surnames');
    expect(keys, isNot(contains(('f1', 'f2'))), reason: 'a woman and a man');
    expect(found.first.key, ('m1', 'm2'), reason: 'the strongest pair first');
    expect(found.first.reasons, containsAll([DuplicateReason.sameName, DuplicateReason.sameParents]));

    expect(findDuplicates(g, notDuplicates: {('m1', 'm2')}).map((d) => d.key), isNot(contains(('m1', 'm2'))),
        reason: 'pairs marked different are not suggested again');
  });

  testWidgets('admins merge a pair, choosing which record to keep, or say they differ', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dad = p('dad', 'Ahmadu', last: 'Bua', year: 1920);
    final g = FamilyGraph(
      persons: [dad, p('m1', 'Muhammadu', last: 'Bua', year: 1950), p('m2', 'Mohammed', year: 1951)],
      links: [link('dad', 'm1'), link('dad', 'm2')],
      unions: const [],
    );
    final repo = _FakeRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        graphProvider.overrideWith((ref) async => g),
        notDuplicatesProvider.overrideWith((ref) async => const {}),
        profilesProvider.overrideWith((ref) async => const [
              Profile(id: 'u1', displayName: 'M', role: AppRole.member, status: AccountStatus.active, personId: 'm2'),
            ]),
      ],
      child: MaterialApp.router(
        localizationsDelegates: localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => const DuplicatesScreen())]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Same parent'), findsOneWidget);
    expect(find.text('Has an account'), findsOneWidget);
    await tester.tap(find.text('Merge'));
    await tester.pumpAndSettle();
    expect(find.text('Which record to keep?'), findsOneWidget);
    await tester.tap(find.text('Keep Mohammed'));
    await tester.pumpAndSettle();
    expect(repo.merged, [('m2', 'm1')]);
    expect(find.text('Muhammadu Bua was merged into Mohammed.'), findsOneWidget);

    await tester.tap(find.text('Different people'));
    await tester.pumpAndSettle();
    expect(repo.different, [('m1', 'm2')]);
  });
}
