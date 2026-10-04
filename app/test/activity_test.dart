import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/activity.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/activity_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

import 'domain_test.dart' show buildFamily;

class FakeRepo extends FamilyRepository {
  FakeRepo(this.entries)
      : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final List<ActivityEntry> entries;
  final queries = <ActivityQuery>[];

  @override
  Future<List<ActivityEntry>> adminActivity(ActivityQuery q, {int? before, int limit = 50}) async {
    queries.add(q);
    return entries.where((e) => q.actions == null || q.actions!.contains(e.action)).where((e) => q.entities == null || q.entities!.contains(e.entity)).toList();
  }
}

void main() {
  final now = DateTime(2026, 10, 4, 15, 0);
  late AppLocalizations l;
  setUpAll(() async => l = await AppLocalizations.delegate.load(const Locale('en')));

  ActivityEntry entry(int id, String action, String entity, {String? target, Map<String, dynamic> detail = const {}}) =>
      ActivityEntry(id: id, at: now.subtract(Duration(minutes: id)), action: action, entity: entity,
          userId: 'u1', name: 'Aisha', target: target, detail: detail, platform: 'android');

  test('pages read as people say them', () {
    final g = buildFamily();
    final someone = g.persons.values.first;
    expect(pageLabel(l, '/home', g), 'Home');
    expect(pageLabel(l, '/person/${someone.id}', g), "${someone.displayName}'s page");
    expect(pageLabel(l, '/person/nobody', g), "a person's page");
    expect(pageLabel(l, '/admin/metrics', g), 'Family metrics');
    expect(pageLabel(l, '/mentors/ask/x', g), 'a mentorship conversation');
    expect(pageLabel(l, '/weird', g), '/weird');
  });

  test('entries say what happened and where to go', () {
    expect(describeActivity(l, entry(1, 'insert', 'posts', target: 'p1'), null), 'added a moment');
    expect(describeActivity(l, entry(1, 'insert', 'posts', detail: {'kind': 'announcement'}), null), 'added an announcement');
    expect(describeActivity(l, entry(1, 'delete', 'persons'), null), 'removed a person');
    expect(describeActivity(l, entry(1, 'insert', 'likes'), null), 'liked something');
    expect(describeActivity(l, entry(1, 'update', 'fund_contributions', detail: {'status': 'confirmed'}), null),
        'confirmed a contribution');
    expect(describeActivity(l, entry(1, 'view', 'page', target: '/tree'), null), 'opened Tree');
    expect(describeActivity(l, entry(1, 'sign_in', 'session'), null), 'signed in');
    expect(describeActivity(l, entry(1, 'insert', 'mentor_messages'), null), 'sent a mentorship message');

    expect(activityLink(entry(1, 'insert', 'posts', target: 'p1')), '/posts/p1');
    expect(activityLink(entry(1, 'insert', 'comments', detail: {'post_id': 'p2'})), '/posts/p2');
    expect(activityLink(entry(1, 'view', 'page', target: '/fund')), '/fund');
    expect(activityLink(entry(1, 'delete', 'persons', target: 'x')), isNull);
    expect(activityLink(entry(1, 'insert', 'mentor_messages')), isNull);
    expect(durationLabel(l, const Duration(minutes: 75)), '1 h 15 min');
  });

  Widget app(Widget home, {FakeRepo? repo}) => ProviderScope(
        overrides: [
          if (repo != null) repositoryProvider.overrideWithValue(repo),
          graphProvider.overrideWith((ref) async => buildFamily()),
          adminUsersProvider.overrideWith((ref) async => [
                UserRow(profile: Profile(id: 'u1', displayName: 'Aisha', role: AppRole.member, status: AccountStatus.active)),
              ]),
          adminOnlineProvider.overrideWith((ref) async => [
                OnlineEntry(userId: 'u1', name: 'Aisha', platform: 'android', page: '/tree',
                    startedAt: now.subtract(const Duration(minutes: 12)), seenAt: now, online: true),
                OnlineEntry(userId: 'u2', name: 'Usman', platform: 'web', page: '/home',
                    startedAt: now.subtract(const Duration(hours: 3)), seenAt: now.subtract(const Duration(hours: 2)), online: false),
              ]),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: home),
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('online now, then earlier', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(OnlineView(now: now)));
    await tester.pump();
    expect(find.text('Online now'), findsOneWidget);
    expect(find.text('Android · on Tree · for 12 min'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.textContaining('last seen'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the log lists what members did and filters it', (tester) async {
    tall(tester);
    final repo = FakeRepo([
      entry(1, 'insert', 'posts', target: 'p1', detail: {'label': 'Family picnic'}),
      entry(2, 'view', 'page', target: '/tree'),
      entry(3, 'sign_in', 'session'),
    ]);
    await tester.pumpWidget(app(ActivityLogView(now: now), repo: repo));
    await tester.pumpAndSettle();
    expect(find.textContaining('added a moment'), findsOneWidget);
    expect(find.textContaining('“Family picnic”'), findsOneWidget);
    expect(find.textContaining('opened Tree'), findsOneWidget);
    expect(repo.queries.last.from, DateTime(2026, 9, 28));

    await tester.tap(find.text('Changes'));
    await tester.pumpAndSettle();
    expect(repo.queries.last.type, ActivityType.changes);
    expect(find.textContaining('opened Tree'), findsNothing);
    expect(find.textContaining('added a moment'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(repo.queries.last.from, DateTime(2026, 10, 4));
  });
}
