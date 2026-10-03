import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/details.dart';
import 'package:bua_family/models/help.dart';
import 'package:bua_family/models/social.dart' show Member;
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/blood_donors_screen.dart';
import 'package:bua_family/ui/screens/who_can_help_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain_test.dart' show buildFamily;

void main() {
  final graph = buildFamily();

  final directory = [
    HelpProfile(
      person: graph['sani']!,
      occupations: const [
        Occupation(personId: 'sani', title: 'Consultant paediatrician', organization: 'AKTH Kano', isCurrent: true),
      ],
      phone: '2348031234567',
    ),
    HelpProfile(
      person: graph['usman']!,
      occupations: const [Occupation(personId: 'usman', title: 'Software developer', location: 'Abuja')],
    ),
    HelpProfile(
      person: graph['fatima']!,
      education: const [Education(personId: 'fatima', institution: 'ABU Zaria', qualification: 'MBBS', field: 'Medicine')],
    ),
    HelpProfile(person: graph['bello']!, skills: const [Skill(personId: 'bello', skill: 'Carpentry')]),
  ];

  Widget app(Widget home, {List<BloodRequest> requests = const [], Health? myHealth, String locale = 'en'}) {
    return ProviderScope(
      overrides: [
        profileProvider.overrideWithValue(const Profile(
          id: 'u1',
          displayName: 'Aisha',
          role: AppRole.member,
          status: AccountStatus.active,
          personId: 'aisha',
        )),
        graphProvider.overrideWith((ref) async => graph),
        helpDirectoryProvider.overrideWith((ref) async => directory),
        bloodDonorsProvider.overrideWith((ref) async => const [
              BloodDonor(personId: 'kabir', bloodGroup: 'O-', town: 'Kano'),
              BloodDonor(personId: 'bello', bloodGroup: 'A+', town: 'Zaria'),
              BloodDonor(personId: 'usman', bloodGroup: 'B+'),
            ]),
        bloodRequestsProvider.overrideWith((ref) async => requests),
        detailsProvider.overrideWith((ref, id) async => PersonDetails(health: myHealth)),
        membersProvider.overrideWith((ref) async => const {
              'u2': Member(userId: 'u2', displayName: 'Usman', personId: 'usman'),
            }),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  test('blood compatibility follows the red-cell rules', () {
    expect(donorGroupsFor('O-'), ['O-']);
    expect(donorGroupsFor('A+'), ['A+', 'A-', 'O+', 'O-']);
    expect(donorGroupsFor('AB+').length, 8);
    expect(canDonate('O-', 'B+'), isTrue);
    expect(canDonate('A+', 'O+'), isFalse);
    expect(canDonate('AB-', 'AB+'), isTrue);
    expect(canDonate('B-', 'A-'), isFalse);
  });

  test('help categories match English and Hausa keywords', () {
    expect(directory[0].inCategory(HelpCategory.health), isTrue);
    expect(directory[2].inCategory(HelpCategory.health), isTrue, reason: 'MBBS student');
    expect(directory[1].inCategory(HelpCategory.tech), isTrue);
    expect(directory[3].inCategory(HelpCategory.trades), isTrue);
    expect(directory[3].inCategory(HelpCategory.health), isFalse);
    final likita = HelpProfile(person: graph['amina']!, skills: const [Skill(personId: 'amina', skill: 'Likitan yara')]);
    expect(likita.inCategory(HelpCategory.health), isTrue);
    expect(directory[0].headline(), 'Consultant paediatrician · AKTH Kano');
    expect(directory[2].headline(), 'MBBS Medicine · ABU Zaria');
    expect(directory[3].headline(), 'Carpentry');
  });

  testWidgets('who can help filters by category and search, with call buttons', (tester) async {
    await tester.pumpWidget(app(const WhoCanHelpScreen()));
    await tester.pumpAndSettle();
    expect(find.text('4 relatives with skills or work listed'), findsOneWidget);

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();
    expect(find.text('2 relatives in health'), findsOneWidget);
    expect(find.text('Consultant paediatrician · AKTH Kano'), findsOneWidget);
    expect(find.text('Your uncle · father’s side'), findsOneWidget);
    expect(find.byTooltip('Call sani'), findsOneWidget, reason: 'shared contact');
    expect(find.text('Profile'), findsOneWidget, reason: 'Fatima has no shared phone');

    await tester.tap(find.text('Health'));
    await tester.enterText(find.byType(TextField), 'carp');
    await tester.pumpAndSettle();
    expect(find.text('1 relative matches “carp”'), findsOneWidget);
    expect(find.text('Carpentry'), findsOneWidget);
  });

  testWidgets('blood donors shows open requests and compatible donors', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(
      const BloodDonorsScreen(),
      myHealth: const Health(personId: 'aisha', bloodGroup: 'O+', bloodDonor: true),
      requests: [
        BloodRequest(
          id: 'r1',
          bloodGroup: 'A+',
          units: 2,
          hospital: 'ABUTH, Zaria',
          requestedBy: 'u2',
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
          patientPersonId: 'sani',
          contactPhone: '2348031234567',
          offers: const ['x', 'y'],
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('2 pints for sani'), findsOneWidget);
    expect(find.text('ABUTH, Zaria · asked by usman'), findsOneWidget);
    expect(find.text('I can donate'), findsOneWidget);
    expect(find.text('Call usman'), findsOneWidget);
    expect(find.text('2 relatives have offered so far.'), findsOneWidget);
    // Matches default to the open request's group (A+): O- and A+ donors, not B+.
    expect(find.text('kabir'), findsOneWidget);
    expect(find.text('bello'), findsOneWidget);
    expect(find.text('usman'), findsNothing);
    expect(find.text("You're on the donor list"), findsOneWidget);
  });

  testWidgets('an incompatible relative cannot offer', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(
      const BloodDonorsScreen(),
      myHealth: const Health(personId: 'aisha', bloodGroup: 'B+'),
      requests: [
        BloodRequest(id: 'r1', bloodGroup: 'O-', hospital: 'AKTH', requestedBy: 'u2', createdAt: DateTime.now(), patientName: 'A neighbour'),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining("can't be given for this request"), findsOneWidget);
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'I can donate'));
    expect(button.onPressed, isNull);
    expect(find.text('Join the donor list'), findsOneWidget);
  });
}
