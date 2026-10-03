import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/details.dart';
import 'package:bua_family/models/family_graph.dart';
import 'package:bua_family/models/person.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/prefs.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/app_settings_screen.dart';
import 'package:bua_family/ui/screens/edit_profile_screen.dart';
import 'package:bua_family/ui/screens/reminders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final graph = FamilyGraph(
    persons: [
      Person(id: 'aisha', firstName: 'Aisha', lastName: 'Bua', sex: Sex.female, birthDate: DateTime(1980, 5, 1)),
      Person(id: 'musa', firstName: 'Musa', lastName: 'Bua', sex: Sex.male, isLiving: false,
          birthDate: DateTime(1940, 3, 12), deathDate: DateTime(2010, 10, 3)),
      Person(id: 'kabir', firstName: 'Kabir', lastName: 'Bua', sex: Sex.male, birthDate: DateTime(2005, 10, 3)),
      Person(id: 'sani', firstName: 'Sani', lastName: 'Bua', sex: Sex.male, birthDate: DateTime(1945, 10, 8)),
      Person(id: 'fatima', firstName: 'Fatima', lastName: 'Bua', sex: Sex.female, birthDate: DateTime(2002, 10, 22)),
      Person(id: 'bello', firstName: 'Bello', lastName: 'Bua', sex: Sex.male, birthDate: DateTime(1978, 2, 2)),
      Person(id: 'halima', firstName: 'Halima', lastName: 'Bua', sex: Sex.female, birthDate: DateTime(1985, 2, 2)),
      Person(id: 'old', firstName: 'Old', sex: Sex.male, birthDate: DateTime(1900, 10, 4), birthDateApprox: true),
    ],
    unions: [
      FamilyUnion(id: 'u1', partner1Id: 'bello', partner2Id: 'halima', startDate: DateTime(2014, 10, 6)),
    ],
    links: const [
      ParentLink(id: 'l1', parentId: 'musa', childId: 'aisha', kind: ParentKind.biological),
      ParentLink(id: 'l2', parentId: 'aisha', childId: 'fatima', kind: ParentKind.biological),
    ],
  );

  Widget app(Widget home, {List<String> muted = const []}) => ProviderScope(
        overrides: [
          profileProvider.overrideWithValue(Profile(
            id: 'u1',
            displayName: 'Aisha',
            role: AppRole.member,
            status: AccountStatus.active,
            personId: 'aisha',
            mutedNotifications: muted,
          )),
          graphProvider.overrideWith((ref) async => graph),
          eventsProvider.overrideWith((ref) async => [
                FamilyEvent(id: 'e1', title: 'Naming ceremony', startsAt: DateTime(2026, 10, 10, 8), createdBy: 'x'),
              ]),
          detailsProvider.overrideWith((ref, id) async => const PersonDetails(
                contact: Contact(personId: 'aisha', phone: '0803 123 4567', city: 'Kaduna', visibility: Audience.family),
                health: Health(personId: 'aisha', bloodGroup: 'O+', genotype: 'AS', bloodDonor: true),
                skills: [Skill(id: 's1', personId: 'aisha', skill: 'Nursing')],
              )),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  testWidgets('reminders group today, this week and coming up', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(RemindersScreen(now: DateTime(2026, 10, 3, 9))));
    await tester.pumpAndSettle();

    expect(find.text('Today · Saturday, 3 October'), findsOneWidget);
    expect(find.text('Kabir Bua turns 21'), findsOneWidget);
    expect(find.text('16 years since Musa Bua passed'), findsOneWidget);
    expect(find.text('Greet'), findsOneWidget);
    expect(find.text('Pray'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Bello & Halima · 12 years married'), findsOneWidget);
    expect(find.text('Sani Bua turns 81'), findsOneWidget);
    expect(find.text('Naming ceremony'), findsOneWidget);
    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('Fatima Bua turns 24'), findsOneWidget);
    expect(find.textContaining('Your daughter'), findsOneWidget);
    expect(find.textContaining('Old'), findsNothing, reason: 'approximate dates are skipped');
  });

  testWidgets('settings reflect muted notifications', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const AppSettingsScreen(), muted: const ['tagged']));
    await tester.pumpAndSettle();

    Switch switchFor(String title) => tester.widget<Switch>(
          find.descendant(of: find.widgetWithText(Row, title), matching: find.byType(Switch)),
        );
    expect(switchFor('Announcements & events').value, isTrue);
    expect(switchFor("When I'm tagged in photos").value, isFalse);
    expect(switchFor('Urgent blood requests').onChanged, isNull, reason: 'always on');
    expect(switchFor('Shrink photos before upload').value, isTrue);

    // Data saver is a device setting.
    await tester.tap(find.text('Load photos only when I tap them'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(AppSettingsScreen)));
    expect(container.read(devicePrefsProvider).tapToLoadPhotos, isTrue);
  });

  test('notification groups cover every mutable kind', () {
    final all = notificationGroups.values.expand((k) => k).toSet();
    expect(all, containsAll(['event', 'announcement', 'event_reminder', 'birthday', 'remembrance', 'memory', 'tagged', 'comment']));
    expect(all.contains('blood_request'), isFalse);
  });

  testWidgets('edit my details is filled from my record', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const EditProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Edit my details'), findsOneWidget);
    expect(find.text('ask an admin'), findsOneWidget);
    expect(find.text('0803 123 4567'), findsOneWidget);
    expect(find.text('Kaduna'), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);
    expect(find.text('AS'), findsOneWidget);
    expect(find.text('Nursing'), findsOneWidget);
    expect(find.text('Whole family'), findsNWidgets(2));
  });
}
