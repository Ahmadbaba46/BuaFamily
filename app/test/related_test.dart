import 'package:bua_family/domain/relation_path.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/family_graph.dart';
import 'package:bua_family/models/person.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/how_related_screen.dart';
import 'package:bua_family/ui/screens/memorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain_test.dart' show buildFamily;

void main() {
  final graph = buildFamily();

  Widget app(Widget home, {FamilyGraph? g, String locale = 'en'}) => ProviderScope(
        overrides: [
          profileProvider.overrideWithValue(const Profile(
            id: 'u1',
            displayName: 'Aisha',
            role: AppRole.member,
            status: AccountStatus.active,
            personId: 'aisha',
          )),
          graphProvider.overrideWith((ref) async => g ?? graph),
          photosOfProvider.overrideWith((ref, id) async => const <Photo>[]),
          memoriesProvider.overrideWith((ref, id) async => [
                Memory(
                  id: 'm1',
                  personId: id,
                  authorId: 'u2',
                  body: 'He taught me to read.',
                  createdAt: DateTime.now().subtract(const Duration(hours: 2)),
                ),
              ]),
          remembranceReminderProvider.overrideWith((ref, id) async => true),
          membersProvider.overrideWith((ref) async => const {
                'u2': Member(userId: 'u2', displayName: 'Bello', personId: 'bello'),
              }),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  group('relation path', () {
    test('cousins meet at their shared grandfather', () {
      final path = relationPath(graph, 'aisha', 'usman')!;
      expect(path.map((s) => s.personId), ['aisha', 'musa', 'ahmadu', 'sani', 'usman']);
      expect(path.map((s) => s.link), [PathLink.childOf, PathLink.childOf, PathLink.parentOf, PathLink.parentOf, null]);
      expect(sharedAncestor(path), 'ahmadu');
    });

    test('blood links are preferred, marriages used when needed', () {
      // Amina is Aisha's mother (blood), not reached through Musa's marriage.
      expect(relationPath(graph, 'aisha', 'amina')!.map((s) => s.personId), ['aisha', 'amina']);
      // Zainab is Ahmadu's other wife: through the marriage.
      final p = relationPath(graph, 'musa', 'zainab')!;
      expect(p.map((s) => s.personId), ['musa', 'ahmadu', 'zainab']);
      expect(p[1].link, PathLink.spouseOf);
      expect(sharedAncestor(p), isNull);
    });

    test('unconnected people have no path', () {
      expect(relationPath(graph, 'aisha', 'stranger'), isNull);
      expect(relationPath(graph, 'aisha', 'aisha')!.length, 1);
    });
  });

  testWidgets('how related shows the label, side and each step', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const HowRelatedScreen(toId: 'usman')));
    await tester.pumpAndSettle();

    expect(find.text('usman is your'), findsOneWidget);
    expect(find.text('First cousin'), findsOneWidget);
    expect(find.text('father’s side'), findsOneWidget);
    expect(find.text('aisha (you)'), findsOneWidget);
    expect(find.text('daughter of'), findsOneWidget);
    expect(find.text('son of'), findsOneWidget);
    expect(find.text('father of'), findsNWidgets(2));
    expect(find.text('Shared grandfather'), findsOneWidget);

    await tester.tap(find.byTooltip('Swap'));
    await tester.pumpAndSettle();
    expect(find.text("aisha is usman's"), findsOneWidget);
  });

  testWidgets('memorial page shows prayer, life story, memories and reminder', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final g = FamilyGraph(
      persons: [
        Person(
          id: 'musa',
          firstName: 'Musa',
          lastName: 'Bua',
          sex: Sex.male,
          isLiving: false,
          birthDate: DateTime(1940, 3, 12),
          deathDate: DateTime(2010, 10, 3),
          biography: 'A teacher in Kaduna for forty years.',
        ),
        const Person(id: 'bello', firstName: 'Bello', lastName: 'Bua', sex: Sex.male),
      ],
      unions: const [],
      links: const [],
    );
    await tester.pumpWidget(app(const MemorialScreen(personId: 'musa'), g: g));
    await tester.pumpAndSettle();

    expect(find.text('IN LOVING MEMORY'), findsOneWidget);
    expect(find.text('Musa Bua'), findsOneWidget);
    expect(find.text('March 12, 1940 – October 3, 2010'), findsOneWidget);
    expect(find.text('Allah ya jikansa da rahama'), findsOneWidget);
    expect(find.text('HIS LIFE'), findsOneWidget);
    expect(find.text('A teacher in Kaduna for forty years.'), findsOneWidget);
    expect(find.text('PRAYERS & MEMORIES · 1'), findsOneWidget);
    expect(find.textContaining('He taught me to read.'), findsOneWidget);
    expect(find.text('Remind me every 3 October'), findsOneWidget);
  });
}
