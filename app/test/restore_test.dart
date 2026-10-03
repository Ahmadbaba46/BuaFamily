import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/story.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/restore_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

class _FakeRepo extends FamilyRepository {
  _FakeRepo()
      : super(SupabaseClient('http://localhost', 'test',
            authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final calls = <(int, bool, bool)>[];

  @override
  Future<Map<String, dynamic>> restoreBackup(int slot, {bool undoChanges = false, bool dryRun = true}) async {
    calls.add((slot, undoChanges, dryRun));
    return {
      'persons': {'added': 2, 'updated': undoChanges ? 1 : 0, 'skipped': 0},
      'parent_child': {'added': 1, 'updated': 0, 'skipped': 0},
      'stories': {'added': 0, 'updated': 0, 'skipped': 1},
      'polls': {'added': 0, 'updated': 0, 'skipped': 0},
    };
  }
}

void main() {
  test('restore counts are grouped for people to read', () {
    final s = RestoreSummary({
      'persons': {'added': 2, 'updated': 1, 'skipped': 0},
      'unions': {'added': 1, 'updated': 0, 'skipped': 0},
      'person_health': {'added': 0, 'updated': 0, 'skipped': 0},
      'stories': {'added': 0, 'updated': 0, 'skipped': 1},
    });
    expect(s.groups['tree']!.added, 3);
    expect(s.groups['details']!.isEmpty, isTrue);
    expect(s.groups['memories']!.skipped, 1);
    expect(s.added, 3);
    expect(s.nothingToDo, isFalse);
    expect(RestoreSummary({'persons': {'added': 0, 'updated': 0, 'skipped': 2}}).nothingToDo, isTrue);
  });

  testWidgets('choosing a backup shows what a restore would do', (tester) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        profileProvider.overrideWithValue(const Profile(
            id: 'u1', displayName: 'Aisha', role: AppRole.admin, status: AccountStatus.active)),
        backupsProvider.overrideWith((ref) async => [
              Backup(slot: 3, takenAt: DateTime(2026, 9, 28, 2), sizeBytes: 52000),
              Backup(slot: -1, takenAt: DateTime(2026, 10, 1, 9), sizeBytes: 53000),
            ]),
      ],
      child: MaterialApp(
        localizationsDelegates: localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RestoreScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Before the last restore ·'), findsOneWidget);
    expect(find.text('A backup file…'), findsOneWidget);
    final restore = find.widgetWithText(FilledButton, 'Restore');
    expect(tester.widget<FilledButton>(restore).onPressed, isNull);

    await tester.tap(find.text('Monday, 28 September · 2:00am'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, (3, false, true));
    expect(find.text('Family tree'), findsOneWidget);
    expect(find.text('3 to bring back · 0 to change back'), findsOneWidget);
    expect(find.text("1 can't go back"), findsOneWidget);
    expect(find.text('Mentorship & polls'), findsNothing);
    expect(tester.widget<FilledButton>(restore).onPressed, isNotNull);

    // Undoing later edits is a separate choice, checked again.
    await tester.tap(find.text('Also undo changes made since'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, (3, true, true));
    expect(find.text('3 to bring back · 1 to change back'), findsOneWidget);
  });
}
