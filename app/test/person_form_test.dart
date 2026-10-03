import 'dart:async';

import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/person_form_screen.dart';
import 'package:bua_family/ui/widgets/request_card.dart';
import 'package:bua_family/ui/widgets/social.dart' show StoragePhoto;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain_test.dart' show buildFamily;

void main() {
  Widget app(Widget home, {AppRole role = AppRole.admin}) => ProviderScope(
        overrides: [
          profileProvider.overrideWithValue(Profile(
              id: 'u1', displayName: 'Aisha', role: role, status: AccountStatus.active, personId: 'aisha')),
          graphProvider.overrideWith((ref) async => buildFamily()),
          settingsProvider.overrideWith((ref) async => const AppSettings(memberContributionsEnabled: true)),
          // Photos never finish loading in tests; that's fine for these checks.
          photoUrlProvider.overrideWith((ref, path) => Completer<String>().future),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('adding a relative offers a photo', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const PersonFormScreen(relationType: 'child', relationTo: 'musa')));
    await tester.pumpAndSettle();
    expect(find.text('Add photo'), findsOneWidget);
  });

  testWidgets('members suggesting a relative can add a photo too', (tester) async {
    tall(tester);
    await tester.pumpWidget(
        app(const PersonFormScreen(relationType: 'child', relationTo: 'musa'), role: AppRole.member));
    await tester.pumpAndSettle();
    expect(find.text('Add photo'), findsOneWidget);
  });

  testWidgets('a suggested photo is shown to the admin reviewing it', (tester) async {
    final request = ChangeRequest(
      id: 'r1',
      kind: RequestKind.createPerson,
      payload: const {
        'person': {'first_name': 'Maryam', 'last_name': 'Bua', 'photo_path': 'uploads/u2/1.jpg'},
      },
      status: RequestStatus.pending,
      requestedBy: 'u2',
      createdAt: DateTime(2026, 10, 3),
    );
    await tester.pumpWidget(app(Scaffold(body: RequestCard(request: request, graph: buildFamily()))));
    await tester.pump();
    expect(find.text('Photo'), findsOneWidget);
    expect(find.byType(StoragePhoto), findsOneWidget);
  });
}
