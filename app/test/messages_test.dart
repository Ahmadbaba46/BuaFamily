import 'dart:async';

import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/details.dart';
import 'package:bua_family/models/messages.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/admin_screen.dart';
import 'package:bua_family/ui/screens/messages_screen.dart';
import 'package:bua_family/ui/screens/person_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

import 'domain_test.dart' show buildFamily;

class _FakeRepo extends FamilyRepository {
  _FakeRepo()
      : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final sent = <(String, String)>[];
  final opened = <String>[];
  final read = <String>[];

  @override
  Future<void> sendDm(String threadId, String body) async => sent.add((threadId, body));

  @override
  Future<void> markDmRead(String threadId) async => read.add(threadId);

  @override
  Future<String> dmOpen(String userId) async {
    opened.add(userId);
    return 't-$userId';
  }
}

void main() {
  final now = DateTime.now();
  final threads = [
    DmThread(
      id: 't1',
      userA: 'u1',
      userB: 'u2',
      createdAt: now.subtract(const Duration(days: 2)),
      lastMessageAt: now.subtract(const Duration(minutes: 5)),
      lastMessage: 'Are you coming to the naming?',
      lastMessageBy: 'u2',
      aReadAt: now.subtract(const Duration(hours: 1)),
    ),
    DmThread(
      id: 't2',
      userA: 'u1',
      userB: 'u3',
      createdAt: now.subtract(const Duration(days: 3)),
      lastMessageAt: now.subtract(const Duration(days: 1)),
      lastMessage: 'Thanks!',
      lastMessageBy: 'u1',
    ),
  ];

  Widget app(Widget home,
          {_FakeRepo? repo, List<DmMessage> messages = const [], AppSettings settings = const AppSettings()}) =>
      ProviderScope(
        overrides: [
          if (repo != null) repositoryProvider.overrideWithValue(repo),
          profileProvider.overrideWithValue(
              const Profile(id: 'u1', displayName: 'Aisha', role: AppRole.member, status: AccountStatus.active, personId: 'aisha')),
          graphProvider.overrideWith((ref) async => buildFamily()),
          settingsProvider.overrideWith((ref) async => settings),
          membersProvider.overrideWith((ref) async => {
                'u1': const Member(userId: 'u1', displayName: 'Aisha', personId: 'aisha'),
                'u2': const Member(userId: 'u2', displayName: 'Musa', personId: 'musa'),
                'u3': const Member(userId: 'u3', displayName: 'Bello', personId: 'bello'),
              }),
          dmThreadsProvider.overrideWith((ref) => Stream.value(threads)),
          dmMessagesProvider.overrideWith((ref, id) => Stream.value(messages)),
          photoUrlProvider.overrideWith((ref, path) => Completer<String>().future),
          detailsProvider.overrideWith((ref, id) async => const PersonDetails()),
          requestsProvider.overrideWith((ref, s) async => const []),
        ],
        child: MaterialApp.router(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, _) => home),
            GoRoute(
              path: '/messages/:id',
              builder: (_, s) => Scaffold(body: Text('conversation ${s.pathParameters['id']}')),
            ),
          ]),
        ),
      );

  test('a conversation is unread when the other person wrote after I last looked', () {
    expect(threads[0].unreadFor('u1'), isTrue);
    expect(threads[0].unreadFor('u2'), isFalse, reason: 'they wrote it');
    expect(threads[1].unreadFor('u1'), isFalse, reason: 'I wrote last');
    expect(threads[1].unreadFor('u3'), isTrue, reason: 'never opened');
    expect(threads[0].otherThan('u1'), 'u2');
    expect(threads[0].otherThan('u2'), 'u1');
  });

  testWidgets('my conversations, with who, the last message and what is new', (tester) async {
    await tester.pumpWidget(app(const MessagesScreen()));
    await tester.pumpAndSettle();
    expect(find.text('musa'), findsOneWidget);
    expect(find.text('Are you coming to the naming?'), findsOneWidget);
    expect(find.text('You: Thanks!'), findsOneWidget);
    expect(find.text('New message'), findsOneWidget);
  });

  testWidgets('a new message: choose who, then the conversation opens', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const MessagesScreen(), repo: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New message'));
    await tester.pumpAndSettle();
    expect(find.text('Message who?'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'aisha'), findsNothing, reason: 'not yourself');
    await tester.enterText(find.byType(TextField), 'bel');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'musa'), findsNothing);
    await tester.tap(find.widgetWithText(ListTile, 'bello'));
    await tester.pumpAndSettle();
    expect(repo.opened, ['u3']);
    expect(find.text('conversation t-u3'), findsOneWidget);
  });

  testWidgets('a conversation: read, written to, and marked as read', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const DmScreen(threadId: 't1'), repo: repo, messages: [
      DmMessage(id: 'm1', threadId: 't1', authorId: 'u1', body: 'Salam Baba', createdAt: now.subtract(const Duration(hours: 2))),
      DmMessage(id: 'm2', threadId: 't1', authorId: 'u2', body: 'Are you coming to the naming?', createdAt: now),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('musa'), findsOneWidget);
    expect(find.text('Only the two of you can see these messages.'), findsOneWidget);
    expect(find.text('Salam Baba'), findsOneWidget);
    expect(repo.read, contains('t1'));
    await tester.enterText(find.byType(TextField), 'Insha Allah, yes');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(repo.sent, [('t1', 'Insha Allah, yes')]);
  });

  testWidgets('a relative with an account has a Message button', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const PersonScreen(personId: 'musa'), repo: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(repo.opened, ['u2']);
    expect(find.text('conversation t-u2'), findsOneWidget);
  });

  testWidgets('admins turn messages off for everyone', (tester) async {
    final saved = <Map<String, dynamic>>[];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: AdminMessagesCard(settings: const AppSettings(), save: (c) async => saved.add(c))),
    ));
    expect(find.text('Private messages'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(saved.last, {'messages_enabled': false});
  });

  testWidgets('while messages are off, they are nowhere to be found', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const off = AppSettings(messagesEnabled: false);
    await tester.pumpWidget(app(const MessagesGate(child: MessagesScreen()), settings: off));
    await tester.pumpAndSettle();
    expect(find.text('Messages are turned off by the family admins.'), findsOneWidget);
    expect(find.text('Are you coming to the naming?'), findsNothing);

    await tester.pumpWidget(app(const PersonScreen(personId: 'musa'), settings: off));
    await tester.pumpAndSettle();
    expect(find.text('Message'), findsNothing);
  });
}
