import 'package:bua_family/domain/family_files.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/family_graph.dart';
import 'package:bua_family/models/person.dart';
import 'package:bua_family/models/social.dart' show Member;
import 'package:bua_family/models/story.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/import_export_screen.dart';
import 'package:bua_family/ui/screens/new_story_screen.dart';
import 'package:bua_family/ui/screens/stories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain_test.dart' show buildFamily;

void main() {
  final now = DateTime.now();
  final stories = [
    Story(
      id: 's1',
      title: 'How the family came to Kano',
      audioPath: 'u1/kano.m4a',
      addedBy: 'u1',
      createdAt: now,
      speakerId: 'hauwa',
      durationSeconds: 760,
      sourceNote: 'recorded 1979 on cassette',
      transcript: 'Kakanmu ya zo Kano daga Katsina',
    ),
    Story(id: 's2', title: 'Building the family house', audioPath: 'u2/house.m4a', addedBy: 'u2',
        createdAt: now, speakerName: 'Sani Bua', durationSeconds: 492),
  ];

  Widget app(Widget home, {bool admin = false}) => ProviderScope(
        overrides: [
          profileProvider.overrideWithValue(Profile(
            id: 'u1',
            displayName: 'Aisha',
            role: admin ? AppRole.admin : AppRole.member,
            status: AccountStatus.active,
            personId: 'aisha',
          )),
          graphProvider.overrideWith((ref) async => buildFamily()),
          membersProvider.overrideWith((ref) async => const {'u2': Member(userId: 'u2', displayName: 'Usman')}),
          settingsProvider.overrideWith((ref) async => const AppSettings()),
          storiesProvider.overrideWith((ref) async => stories),
          backupsProvider.overrideWith((ref) async => [
                Backup(slot: 3, takenAt: DateTime(2026, 9, 28, 2), sizeBytes: 52000),
                Backup(slot: 2, takenAt: DateTime(2026, 9, 21, 2), sizeBytes: 51000),
              ]),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  test('durations read like a clock', () {
    expect(clockDuration(const Duration(seconds: 760)), '12:40');
    expect(clockDuration(const Duration(seconds: 3725)), '1:02:05');
  });

  testWidgets('stories: the latest is ready to play, the rest are listed', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const StoriesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('How the family came to Kano'), findsOneWidget);
    expect(find.textContaining('recorded 1979 on cassette'), findsOneWidget);
    expect(find.text('0:00 / 12:40'), findsOneWidget);
    expect(find.text('Sani Bua · 8:12 · Hausa'), findsOneWidget);
    // Members listen; admins record.
    expect(find.text('Record an elder’s story'), findsNothing);
    expect(find.textContaining('Admins record the elders'), findsOneWidget);

    expect(find.textContaining('Kakanmu'), findsNothing);
    await tester.tap(find.text('Transcript'));
    await tester.pump();
    expect(find.textContaining('Kakanmu'), findsOneWidget);
  });

  testWidgets('admins see the record button', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const StoriesScreen(), admin: true));
    await tester.pumpAndSettle();
    expect(find.text('Record an elder’s story'), findsOneWidget);
    expect(find.textContaining('Admins record the elders'), findsNothing);
  });

  testWidgets('a new story needs a recording, a title and a speaker', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const NewStoryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Tap to start recording'), findsOneWidget);
    await tester.tap(find.text('Save story'));
    await tester.pump();
    expect(find.text('Record or choose a recording first.'), findsOneWidget);
  });

  testWidgets('import, export and backup page', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const ImportExportScreen(), admin: true));
    await tester.pumpAndSettle();

    expect(find.text('Family tree (GEDCOM)'), findsOneWidget);
    expect(find.text('Printable tree (PDF)'), findsOneWidget);
    expect(find.text('Choose a GEDCOM or CSV file'), findsOneWidget);
    expect(find.text('Weekly backup is on'), findsOneWidget);
    expect(find.text('Last backup Monday, 28 September'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Earlier backups'), findsOneWidget);
  });

  testWidgets('reviewing an import', (tester) async {
    tall(tester);
    final g = FamilyGraph(persons: const [Person(id: 'a', firstName: 'Musa', lastName: 'Bua')], unions: const [], links: const []);
    final plan = planImport(
      parseFamilyCsv('id,first_name,last_name,father_id\n1,Musa,Bua,\n2,Bashir,Bua,1\n3,Rukayya,Bua,1\n'),
      g,
    );
    await tester.pumpWidget(app(ImportReviewScreen(plan: plan), admin: true));
    await tester.pumpAndSettle();

    expect(find.text('2 new · 1 already in the tree · 2 relationships'), findsOneWidget);
    expect(find.text('Same as Musa Bua in the tree'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('1 new · 1 already in the tree · 1 relationship'), findsOneWidget);

    await tester.tap(find.text('Not the same person'));
    await tester.pump();
    expect(find.text('2 new · 0 already in the tree · 1 relationship'), findsOneWidget);
  });
}
