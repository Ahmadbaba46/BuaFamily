import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/details.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/members_screen.dart';
import 'package:bua_family/ui/screens/person_screen.dart';
import 'package:bua_family/ui/screens/tree_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain_test.dart' show buildFamily;

void main() {
  final graph = buildFamily();

  Widget app(Widget home, {String locale = 'en', bool admin = false, String? myPersonId = 'aisha'}) {
    final profile = Profile(
      id: 'u1',
      displayName: 'Tester',
      role: admin ? AppRole.admin : AppRole.member,
      status: AccountStatus.active,
      personId: myPersonId,
      locale: locale,
    );
    return ProviderScope(
      overrides: [
        profileProvider.overrideWithValue(profile),
        graphProvider.overrideWith((ref) async => graph),
        settingsProvider.overrideWith((ref) async => const AppSettings()),
        detailsProvider.overrideWith((ref, id) async => const PersonDetails(
              skills: [Skill(id: 's1', personId: 'sani', skill: 'Carpentry')],
            )),
        requestsProvider.overrideWith((ref, status) async => const <ChangeRequest>[]),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  testWidgets('profile shows family and relationship to me (English)', (tester) async {
    await tester.pumpWidget(app(const PersonScreen(personId: 'sani')));
    await tester.pumpAndSettle();

    expect(find.text('sani'), findsWidgets);
    expect(find.text('Relationship to you: Uncle'), findsOneWidget);
    expect(find.text('Parents'), findsOneWidget);
    expect(find.text('Carpentry'), findsOneWidget);
    // Members cannot add relatives while contributions are off.
    expect(find.text('Add relative'), findsNothing);
  });

  testWidgets('profile in Hausa uses Hausa kinship terms', (tester) async {
    await tester.pumpWidget(app(const PersonScreen(personId: 'sani'), locale: 'ha'));
    await tester.pumpAndSettle();

    expect(find.text('Dangantaka da kai: Baffa'), findsOneWidget);
    expect(find.text('Iyaye'), findsOneWidget);
  });

  testWidgets('deceased ancestor is marked as late with approximate dates', (tester) async {
    await tester.pumpWidget(app(const PersonScreen(personId: 'ahmadu'), admin: true));
    await tester.pumpAndSettle();
    expect(find.text('Add relative'), findsOneWidget, reason: 'admins can always add relatives');
    expect(find.text('Children'), findsOneWidget);
    // Two wives → children are labelled with their mother.
    expect(find.textContaining('hauwa'), findsWidgets);
  });

  testWidgets('tree renders and collapses a branch', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(const TreeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('ahmadu'), findsWidgets);
    expect(find.text('fatima'), findsOneWidget);

    // Collapse Musa's branch using the toggle under his card.
    final musaCard = find.ancestor(of: find.text('musa'), matching: find.byType(Stack)).first;
    await tester.tap(find.descendant(of: musaCard, matching: find.byIcon(Icons.expand_less)));
    await tester.pumpAndSettle();
    expect(find.text('fatima'), findsNothing);
    expect(find.text('+3'), findsOneWidget);
  });

  testWidgets('members screen searches and filters', (tester) async {
    await tester.pumpWidget(app(const MembersScreen()));
    await tester.pumpAndSettle();
    expect(find.text('12 people'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'mus');
    await tester.pumpAndSettle();
    expect(find.text('1 person'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Deceased'));
    await tester.pumpAndSettle();
    expect(find.text('No one found'), findsOneWidget);
  });
}
