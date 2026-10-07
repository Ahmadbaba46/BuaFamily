import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/report.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/reports_screen.dart';
import 'package:bua_family/ui/widgets/report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

import 'domain_test.dart' show buildFamily;

class _FakeRepo extends FamilyRepository {
  _FakeRepo() : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final sent = <(ReportKind, String, ReportReason, String?)>[];
  final resolved = <(String, ReportStatus)>[];
  final removed = <String>[];
  final updates = <(String, AccountStatus?)>[];

  @override
  Future<void> reportContent(ReportKind kind, String targetId, ReportReason reason, {String? note}) async =>
      sent.add((kind, targetId, reason, note));

  @override
  Future<void> resolveReport(String id, ReportStatus status) async => resolved.add((id, status));

  @override
  Future<void> removeReported(Report r) async => removed.add(r.id);

  @override
  Future<void> adminUpdateAccount(String userId,
          {AccountStatus? status, AppRole? role, String? personId, bool unlink = false}) async =>
      updates.add((userId, status));
}

void main() {
  final now = DateTime.now();
  final reports = [
    Report(
      id: 'r1',
      kind: ReportKind.comment,
      targetId: 'c1',
      reason: ReportReason.abuse,
      createdAt: now.subtract(const Duration(hours: 1)),
      reporterId: 'u1',
      targetUser: 'u2',
      snapshot: const {'body': 'You are useless', 'author': 'Musa'},
      link: '/posts/p1',
    ),
    Report(
      id: 'r2',
      kind: ReportKind.message,
      targetId: 'm1',
      reason: ReportReason.childSafety,
      createdAt: now.subtract(const Duration(hours: 3)),
      reporterId: 'u1',
      targetUser: 'u2',
      note: 'He keeps messaging my daughter',
      snapshot: const {'body': 'Send me photos', 'author': 'Musa'},
    ),
    Report(
      id: 'r3',
      kind: ReportKind.post,
      targetId: 'p9',
      reason: ReportReason.spam,
      createdAt: now.subtract(const Duration(days: 3)),
      status: ReportStatus.dismissed,
      snapshot: const {'body': 'Buy now', 'author': 'Bello'},
    ),
  ];

  Widget app(Widget home, _FakeRepo repo) => ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          profileProvider.overrideWithValue(
              const Profile(id: 'admin', displayName: 'Admin', role: AppRole.admin, status: AccountStatus.active)),
          graphProvider.overrideWith((ref) async => buildFamily()),
          reportsProvider.overrideWith((ref) async => reports),
          profilesProvider.overrideWith((ref) async => const [
                Profile(id: 'u1', displayName: 'Aisha', role: AppRole.member, status: AccountStatus.active),
                Profile(id: 'u2', displayName: 'Musa', role: AppRole.member, status: AccountStatus.active),
              ]),
          membersProvider.overrideWith((ref) async => {
                'u1': const Member(userId: 'u1', displayName: 'Aisha'),
                'u2': const Member(userId: 'u2', displayName: 'Musa'),
              }),
        ],
        child: MaterialApp.router(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, _) => home),
            GoRoute(path: '/posts/:id', builder: (_, s) => Scaffold(body: Text('post ${s.pathParameters['id']}'))),
          ]),
        ),
      );

  testWidgets('a member reports something, with a reason and a note', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(app(
      Scaffold(
        body: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => reportToAdmins(context, ref, ReportKind.photo, 'ph1'),
            child: const Text('report it'),
          ),
        ),
      ),
      repo,
    ));
    await tester.tap(find.text('report it'));
    await tester.pumpAndSettle();
    expect(find.text('Report to the admins'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send report')).onPressed, isNull,
        reason: 'a reason is needed first');
    await tester.tap(find.text('Child safety concern'));
    await tester.pumpAndSettle();
    expect(find.textContaining('call the police first'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'This photo is not OK');
    await tester.ensureVisible(find.text('Send report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(repo.sent, [(ReportKind.photo, 'ph1', ReportReason.childSafety, 'This photo is not OK')]);
    expect(find.text('Thank you. The admins will look at it.'), findsOneWidget);
  });

  testWidgets('admins see reports, child safety first, and act on them', (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const ReportsScreen(), repo));
    await tester.pumpAndSettle();

    expect(find.text('“Send me photos”'), findsOneWidget, reason: 'admins see the reported private message');
    expect(find.text('Note: He keeps messaging my daughter'), findsOneWidget);
    expect(tester.getTopLeft(find.text('A private message')).dy, lessThan(tester.getTopLeft(find.text('A comment')).dy),
        reason: 'child safety comes first');
    expect(find.text('Handled'), findsOneWidget, reason: 'the dismissed one is under Handled');
    expect(find.text('Dismissed'), findsOneWidget);

    // Suspend the sender of the message.
    await tester.tap(find.text('Suspend account').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.updates, [('u2', AccountStatus.suspended)]);
    expect(repo.resolved, [('r2', ReportStatus.actioned)]);

    // Remove the comment.
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.removed, ['r1']);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('post p1'), findsOneWidget);
  });
}
