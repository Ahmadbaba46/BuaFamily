import 'dart:async';

import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/family_graph.dart';
import 'package:bua_family/models/person.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/members_screen.dart';
import 'package:bua_family/ui/screens/person_screen.dart';
import 'package:bua_family/ui/screens/tree_check_screen.dart';
import 'package:bua_family/ui/widgets/request_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

import 'domain_test.dart' show buildFamily;

class FakeRepo extends FamilyRepository {
  FakeRepo()
      : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final removedLinks = <(String, String)>[];
  final submitted = <(RequestKind, Map<String, dynamic>)>[];

  @override
  Future<void> removeParentChild(String parentId, String childId) async => removedLinks.add((parentId, childId));

  @override
  Future<void> submitRequest(RequestKind kind, Map<String, dynamic> payload, {String? targetPersonId}) async =>
      submitted.add((kind, payload));
}

void main() {
  /// Three children whose dates would put them in another order.
  FamilyGraph siblings() => FamilyGraph(
        persons: [
          Person(id: 'dad', firstName: 'Dad', sex: Sex.male),
          Person(id: 'c', firstName: 'Third', birthOrder: 3, birthDate: DateTime(1990)),
          Person(id: 'a', firstName: 'First', birthOrder: 1, birthDate: DateTime(1995)),
          Person(id: 'b', firstName: 'Second', birthOrder: 2),
          Person(id: 'x', firstName: 'Unnumbered', birthDate: DateTime(1980)),
        ],
        unions: const [],
        links: const [
          ParentLink(id: '1', parentId: 'dad', childId: 'c', kind: ParentKind.biological),
          ParentLink(id: '2', parentId: 'dad', childId: 'a', kind: ParentKind.biological),
          ParentLink(id: '3', parentId: 'dad', childId: 'b', kind: ParentKind.biological),
          ParentLink(id: '4', parentId: 'dad', childId: 'x', kind: ParentKind.biological),
        ],
      );

  test('siblings follow their birth order, then date of birth', () {
    expect(siblings().childrenOf('dad').map((p) => p.firstName), ['First', 'Second', 'Third', 'Unnumbered']);
    expect(Person.fromJson({'id': 'z', 'first_name': 'Z', 'birth_order': 2}).birthOrder, 2);
    expect(Person(id: 'z', firstName: 'Z', birthOrder: 4).toJson()['birth_order'], 4);
  });

  test('family order goes down each line, children in birth order', () {
    final names = siblings().familyOrder().map((p) => p.firstName).toList();
    expect(names, ['Dad', 'First', 'Second', 'Third', 'Unnumbered']);
    final family = buildFamily().familyOrder().map((p) => p.id).toList();
    expect(family.first, 'ahmadu');
    expect(family.indexOf('musa'), lessThan(family.indexOf('aisha')));
    expect(family.indexOf('aisha'), lessThan(family.indexOf('fatima')));
    expect(family.last, 'stranger');
  });

  test('ordinals in both languages', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ha = await AppLocalizations.delegate.load(const Locale('ha'));
    expect([1, 2, 3, 4, 11, 12, 13, 21, 22].map(en.ordinal), ['1st', '2nd', '3rd', '4th', '11th', '12th', '13th', '21st', '22nd']);
    expect(ha.ordinal(2), 'na 2');
  });

  Widget app(Widget home, {AppRole role = AppRole.admin, FamilyGraph? graph, FakeRepo? repo, bool contributions = true}) =>
      ProviderScope(
        overrides: [
          if (repo != null) repositoryProvider.overrideWithValue(repo),
          profileProvider.overrideWithValue(
              Profile(id: 'u1', displayName: 'Aisha', role: role, status: AccountStatus.active, personId: 'aisha')),
          graphProvider.overrideWith((ref) async => graph ?? buildFamily()),
          settingsProvider.overrideWith((ref) async => AppSettings(memberContributionsEnabled: contributions)),
          photoUrlProvider.overrideWith((ref, path) => Completer<String>().future),
          treeProblemsProvider.overrideWith((ref) async => [
                {'kind': 'married_in_line', 'a': 'musa', 'b': 'fatima', 'union_id': 'u9'},
                {'kind': 'same_birth_order', 'a': 'aisha', 'b': 'bello'},
              ]),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('admins see what looks wrong in the tree', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const TreeCheckScreen()));
    await tester.pumpAndSettle();
    expect(find.text('musa and fatima are married, but one descends from the other'), findsOneWidget);
    expect(find.text('aisha and bello have the same birth order'), findsOneWidget);
    expect(find.text('Remove link'), findsOneWidget);
  });

  testWidgets('admins remove a relationship, not the person', (tester) async {
    tall(tester);
    final repo = FakeRepo();
    await tester.pumpWidget(app(const PersonScreen(personId: 'aisha'), repo: repo));
    await tester.pumpAndSettle();
    // Parents come first: Musa.
    await tester.tap(find.byTooltip('Remove relationship').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove relationship'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Both stay in the tree'), findsOneWidget);
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(repo.removedLinks, [('musa', 'aisha')]);
  });

  testWidgets('members do not get the remove option', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const PersonScreen(personId: 'aisha'), role: AppRole.member));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove relationship'), findsNothing);
  });

  testWidgets('a removal request reads clearly for the admin', (tester) async {
    final request = ChangeRequest(
      id: 'r1',
      kind: RequestKind.removeUnion,
      payload: const {'partner1_id': 'musa', 'partner2_id': 'amina'},
      status: RequestStatus.pending,
      requestedBy: 'u2',
      createdAt: DateTime(2026, 10, 3),
    );
    await tester.pumpWidget(app(Scaffold(body: RequestCard(request: request, graph: buildFamily()))));
    await tester.pump();
    expect(find.text('Remove the marriage of musa and amina'), findsOneWidget);
  });

  testWidgets('members can be sorted', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const MembersScreen(), graph: siblings()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest first'), warnIfMissed: false);
    await tester.pumpAndSettle();
    final names = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().toList();
    expect(names.indexOf('Unnumbered'), lessThan(names.indexOf('Third')));
    expect(names.indexOf('Third'), lessThan(names.indexOf('First')));
  });
}
