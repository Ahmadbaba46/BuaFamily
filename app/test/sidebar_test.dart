import 'dart:async';

import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/community.dart';
import 'package:bua_family/models/fund.dart';
import 'package:bua_family/models/help.dart';
import 'package:bua_family/models/notification.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/models/story.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/widgets/app_sidebar.dart';
import 'package:bua_family/ui/widgets/hero_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'domain_test.dart' show buildFamily;

void main() {
  final now = DateTime.now();

  Widget app(GoRouter router, {AppRole role = AppRole.member}) => ProviderScope(
        overrides: [
          profileProvider.overrideWithValue(
              Profile(id: 'u1', displayName: 'Aisha', role: role, status: AccountStatus.active, personId: 'aisha')),
          graphProvider.overrideWith((ref) async => buildFamily()),
          photoUrlProvider.overrideWith((ref, path) => Completer<String>().future),
          eventsProvider.overrideWith((ref) async => [
                FamilyEvent(id: 'e1', title: 'Naming', startsAt: now.add(const Duration(days: 3)), createdBy: 'x'),
                FamilyEvent(id: 'e2', title: 'Old', startsAt: now.subtract(const Duration(days: 30)), createdBy: 'x'),
              ]),
          albumsProvider.overrideWith((ref) async => const <Album>[]),
          storiesProvider.overrideWith((ref) async => const <Story>[]),
          bloodRequestsProvider.overrideWith((ref) async => [
                BloodRequest(id: 'b1', bloodGroup: 'O+', hospital: 'ABUTH', requestedBy: 'x', createdAt: now),
              ]),
          fundCausesProvider.overrideWith((ref) async => [
                FundCause(id: 'f1', title: 'School fees', createdAt: now),
                FundCause(id: 'f2', title: 'Done', createdAt: now, status: CauseStatus.closed),
              ]),
          pollsProvider.overrideWith((ref) async => const <Poll>[]),
          notificationsProvider.overrideWith((ref) => Stream.value([
                AppNotification(id: 'n1', kind: NotificationKind.test, createdAt: now),
                AppNotification(id: 'n2', kind: NotificationKind.test, createdAt: now),
              ])),
          requestsProvider.overrideWith((ref, s) async => const <ChangeRequest>[]),
          profilesProvider.overrideWith((ref) async => const <Profile>[]),
        ],
        child: MaterialApp.router(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );

  GoRouter router() {
    late final GoRouter r;
    Widget page(String name) => Scaffold(body: Row(children: [
          SizedBox(width: 280, child: AppSidebar(router: r)),
          Expanded(child: Text('Page $name')),
        ]));
    r = GoRouter(initialLocation: '/home', routes: [
      for (final p in ['/home', '/members', '/events', '/fund', '/blood', '/admin', '/person/aisha'])
        GoRoute(path: p, builder: (_, _) => page(p)),
    ]);
    return r;
  }

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('the sidebar lists every part of the app with what is waiting there', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(router()));
    await tester.pumpAndSettle();
    Finder row(String label) => find.ancestor(of: find.text(label), matching: find.byType(Row)).first;
    String? badgeOf(String label) => tester
        .widgetList<Text>(find.descendant(of: row(label), matching: find.byType(Text)))
        .map((t) => t.data)
        .where((t) => t != label)
        .firstOrNull;

    expect(find.text('aisha'), findsOneWidget); // you, at the top
    expect(badgeOf('Members'), '12');
    expect(badgeOf('Events'), '1');
    expect(badgeOf('Blood donors'), '1');
    expect(badgeOf('Welfare fund'), '1');
    expect(badgeOf('Notifications'), '2');
    expect(find.text('Check the tree'), findsNothing); // admins only

    await tester.tap(find.text('Welfare fund'));
    await tester.pumpAndSettle();
    expect(find.text('Page /fund'), findsOneWidget);
  });

  testWidgets('admins also see their tools', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(router(), role: AppRole.admin));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Check the tree'), 100);
    expect(find.text('Check the tree'), findsOneWidget);
  });

  testWidgets('pages with a coloured band keep a bar at the top once it scrolls away', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HeroPage(
          title: 'Musa Bua',
          color: Colors.green,
          bandHeight: 150,
          onBack: () {},
          child: ListView(children: [
            const SizedBox(height: 150, child: Text('Band')),
            for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('Row $i')),
          ]),
        ),
      ),
    ));
    expect(find.text('Musa Bua'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Musa Bua'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });
}
