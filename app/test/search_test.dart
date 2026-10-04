import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/person.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'domain_test.dart' show buildFamily;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'recent_searches': ['wedding']}));

  test('Hausa letters match their plain forms', () {
    expect(searchFold("Ɗan Ƙasa Ɓoyayye Ƴar'uwa"), 'dan kasa boyayye yaruwa');
    const p = Person(id: 'x', firstName: 'Ɗahiru', lastName: 'Bua', sex: Sex.male);
    expect(p.matches('dahiru'), isTrue);
    expect(p.matches('ɗahiru bua'), isTrue);
    expect(p.matches('kabir'), isFalse);
  });

  test('the match is in bold', () {
    final span = highlight('Barka da Sallah', 'sallah', const TextStyle());
    expect(span.children!.map((c) => (c as TextSpan).text), ['Barka da ', 'Sallah', '']);
    expect(highlight('Nothing here', 'zz', const TextStyle()).children, isNull);
  });

  Widget app(Widget home, {List<String> queries = const []}) => ProviderScope(
        overrides: [
          profileProvider.overrideWithValue(const Profile(
            id: 'u1',
            displayName: 'Aisha',
            role: AppRole.member,
            status: AccountStatus.active,
          )),
          graphProvider.overrideWith((ref) async => buildFamily()),
          searchProvider.overrideWith((ref, q) async {
            if (q.length < 2) return const [];
            return [
              SearchHit(kind: 'post', id: 'p1', link: '/posts/p1', snippet: 'Barka da Sallah, everyone!', at: DateTime(2026, 3, 20)),
              SearchHit(kind: 'event', id: 'e1', link: '/events/e1', title: 'Sallah visit to Kano', at: DateTime(2026, 3, 21)),
              SearchHit(kind: 'event', id: 'e2', link: '/events/e2', title: 'Sallah lunch'),
              SearchHit(kind: 'event', id: 'e3', link: '/events/e3', title: 'Sallah football'),
              SearchHit(kind: 'event', id: 'e4', link: '/events/e4', title: 'Sallah durbar'),
            ];
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  testWidgets('one box finds people and everything else, grouped, with filters', (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const SearchScreen()));
    await tester.pumpAndSettle();
    // Before typing: recent searches and tips.
    expect(find.text('wedding'), findsOneWidget);
    expect(find.textContaining('Try a name'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Sallah');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Moments'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Show all 4'), findsOneWidget);
    expect(find.text('Sallah durbar', findRichText: true), findsNothing);

    await tester.tap(find.text('Show all 4'));
    await tester.pumpAndSettle();
    expect(find.text('Sallah durbar', findRichText: true), findsOneWidget);
    expect(find.text('Moments'), findsNothing);
  });

  testWidgets('people come from the tree', (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final person = buildFamily().persons.values.first;
    await tester.pumpWidget(app(SearchScreen(initialQuery: person.firstName)));
    await tester.pumpAndSettle();
    expect(find.text('People'), findsOneWidget);
    expect(find.text(person.displayName), findsWidgets);
  });
}
