import 'dart:async';

import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/event_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

import 'domain_test.dart' show buildFamily;

class _FakeRepo extends FamilyRepository {
  _FakeRepo()
      : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final added = <String>{};
  final removed = <String>{};
  int albumCalls = 0;

  @override
  Future<void> setAttendance(String eventId, {Iterable<String> add = const [], Iterable<String> remove = const []}) async {
    added.addAll(add);
    removed.addAll(remove);
  }

  @override
  Future<String> eventAlbum(String eventId) async {
    albumCalls++;
    return 'al1';
  }
}

void main() {
  final now = DateTime.now();

  Widget app(FamilyEvent event,
          {required _FakeRepo repo, List<String> came = const [], AppRole role = AppRole.member, List<Album> albums = const []}) =>
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          profileProvider.overrideWithValue(
              Profile(id: 'u1', displayName: 'Aisha', role: role, status: AccountStatus.active, personId: 'aisha')),
          graphProvider.overrideWith((ref) async => buildFamily()),
          settingsProvider.overrideWith((ref) async => const AppSettings()),
          membersProvider.overrideWith((ref) async => const {'u1': Member(userId: 'u1', displayName: 'Aisha')}),
          eventsProvider.overrideWith((ref) async => [event]),
          eventAttendanceProvider.overrideWith((ref, id) async => came),
          albumsProvider.overrideWith((ref) async => albums),
          albumPhotosProvider.overrideWith((ref, id) async => const <Photo>[]),
          commentsProvider.overrideWith((ref, target) async => const <Comment>[]),
          photoUrlProvider.overrideWith((ref, path) => Completer<String>().future),
        ],
        child: MaterialApp.router(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, _) => EventScreen(eventId: event.id)),
            GoRoute(path: '/new-moment', builder: (_, s) => Text('add photos to ${s.uri.queryParameters['album']}')),
          ]),
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('on the day: I mark myself as here, and add photos to the event', (tester) async {
    tall(tester);
    final repo = _FakeRepo();
    final event = FamilyEvent(id: 'e1', title: 'Sallah lunch', startsAt: now.subtract(const Duration(hours: 1)), createdBy: 'x');
    await tester.pumpWidget(app(event, repo: repo, came: const ['musa']));
    await tester.pumpAndSettle();
    expect(find.text('WHO CAME (1)'), findsOneWidget);
    expect(find.text('Mark who came'), findsNothing, reason: 'only the host and admins mark others');
    await tester.tap(find.text("I'm here"));
    await tester.pumpAndSettle();
    expect(repo.added, {'aisha'});

    expect(find.text('PHOTOS FROM THE DAY'), findsOneWidget);
    await tester.tap(find.text('Add photos'));
    await tester.pumpAndSettle();
    expect(repo.albumCalls, 1);
    expect(find.text('add photos to al1'), findsOneWidget);
  });

  testWidgets('already marked: undo', (tester) async {
    tall(tester);
    final repo = _FakeRepo();
    final event = FamilyEvent(id: 'e1', title: 'Sallah lunch', startsAt: now.subtract(const Duration(hours: 1)), createdBy: 'x');
    await tester.pumpWidget(app(event, repo: repo, came: const ['aisha']));
    await tester.pumpAndSettle();
    expect(find.text("You're marked as here."), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repo.removed, {'aisha'});
  });

  testWidgets('admins tick everyone who came', (tester) async {
    tall(tester);
    final repo = _FakeRepo();
    final event = FamilyEvent(id: 'e1', title: 'Sallah lunch', startsAt: now.subtract(const Duration(hours: 1)), createdBy: 'x');
    await tester.pumpWidget(app(event, repo: repo, came: const ['musa'], role: AppRole.admin));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark who came'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'kabir'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'musa'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.added, {'kabir'});
    expect(repo.removed, {'musa'});
  });

  testWidgets('before the day there is nothing to mark yet', (tester) async {
    tall(tester);
    final event = FamilyEvent(id: 'e1', title: 'Reunion', startsAt: now.add(const Duration(days: 30)), createdBy: 'x');
    await tester.pumpWidget(app(event, repo: _FakeRepo()));
    await tester.pumpAndSettle();
    expect(find.text('WHO CAME'), findsNothing);
    expect(find.text('PHOTOS FROM THE DAY'), findsNothing);
  });
}
