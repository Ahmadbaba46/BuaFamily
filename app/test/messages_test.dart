import 'dart:async';
import 'dart:typed_data';

import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/details.dart';
import 'package:bua_family/models/messages.dart';
import 'package:bua_family/models/report.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/admin_screen.dart';
import 'package:bua_family/ui/screens/messages_screen.dart';
import 'package:bua_family/ui/screens/person_screen.dart';
import 'package:bua_family/ui/widgets/dm_bubble.dart';
import 'package:bua_family/ui/widgets/emoji_panel.dart';
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
  final replies = <String?>[];
  final deleted = <String>[];
  final pings = <String>[];
  void Function(String)? typingFrom;
  final opened = <String>[];
  final read = <String>[];
  final blocked = <String>[];
  final reported = <(ReportKind, String)>[];
  final reacted = <(String, String?)>[];

  @override
  Future<void> reactDm(String messageId, String threadId, String? emoji) async => reacted.add((messageId, emoji));

  @override
  Future<void> block(String userId) async => blocked.add(userId);

  @override
  Future<void> reportContent(ReportKind kind, String targetId, ReportReason reason, {String? note}) async =>
      reported.add((kind, targetId));

  @override
  Future<void> sendDm(String threadId, String body, {String? replyTo}) async {
    sent.add((threadId, body));
    replies.add(replyTo);
  }

  @override
  Future<void> deleteDm(DmMessage m) async => deleted.add(m.id);

  @override
  Future<void> markDmDelivered() async {}

  @override
  TypingSignal dmTyping(String threadId, void Function(String userId) onTyping) {
    typingFrom = onTyping;
    return TypingSignal(() async => pings.add(threadId), () async {});
  }

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
          {_FakeRepo? repo,
          List<DmMessage> messages = const [],
          AppSettings settings = const AppSettings(),
          Set<String> blocked = const {}}) =>
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
          blockedProvider.overrideWith((ref) async => blocked),
          dmMessagesProvider.overrideWith((ref, id) => Stream.value(messages)),
          dmReactionsProvider.overrideWith((ref, id) => Stream.value(const [])),
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
    expect(find.textContaining('Salam Baba'), findsOneWidget);
    expect(repo.read, contains('t1'));
    await tester.enterText(find.byType(TextField), 'Insha Allah, yes');
    await tester.pump();
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

  testWidgets('report a message, or block the member', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const DmScreen(threadId: 't1'), repo: repo, messages: [
      DmMessage(id: 'm1', threadId: 't1', authorId: 'u1', body: 'Salam Baba', createdAt: now.subtract(const Duration(hours: 2))),
      DmMessage(id: 'm2', threadId: 't1', authorId: 'u2', body: 'Something nasty', createdAt: now),
    ]));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('Salam Baba'));
    await tester.pumpAndSettle();
    expect(find.text('Report this message'), findsNothing, reason: 'not your own messages');
    expect(find.text('Delete for everyone'), findsOneWidget);
    Navigator.of(tester.element(find.text('Delete for everyone'))).pop();
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('Something nasty'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report this message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abuse, harassment or threats'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send report'));
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(repo.reported, [(ReportKind.message, 'm2')]);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.blocked, ['u2']);
  });

  testWidgets('a blocked member: no way to write until unblocked', (tester) async {
    await tester.pumpWidget(app(const DmScreen(threadId: 't1'), repo: _FakeRepo(), blocked: {'u2'}));
    await tester.pumpAndSettle();
    expect(find.text('You blocked musa. Unblock to send messages again.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Unblock'), findsOneWidget);
  });

  test('emoji-only messages show large; voice levels are kept small', () {
    expect(isBigEmoji('❤️'), isTrue);
    expect(isBigEmoji('😂😂👍'), isTrue);
    expect(isBigEmoji('😂😂😂😂'), isFalse);
    expect(isBigEmoji('Salam ❤️'), isFalse);
    expect(isBigEmoji(''), isFalse);
    final w = compactWaveform([for (var i = 0; i < 300; i++) i.isEven ? 1.0 : 0.0]);
    expect(w.length, 48);
    expect(w.every((v) => v >= 0 && v <= 100), isTrue);
    expect(levelFromDb(-60), 0);
    expect(levelFromDb(0), 1);
  });

  testWidgets('WhatsApp-style: ticks, typing…, swipe to reply, reactions, emoji, delete for everyone', (tester) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    // u2 read up to 1 hour ago and their phone received everything up to 10 minutes ago.
    final thread = DmThread(
      id: 't1',
      userA: 'u1',
      userB: 'u2',
      createdAt: now.subtract(const Duration(days: 2)),
      lastMessageAt: now,
      lastMessageBy: 'u1',
      bReadAt: now.subtract(const Duration(hours: 1)),
      bDeliveredAt: now.subtract(const Duration(minutes: 10)),
    );
    expect(thread.statusOf(now.subtract(const Duration(hours: 2)), 'u1'), MessageStatus.read);
    expect(thread.statusOf(now.subtract(const Duration(minutes: 30)), 'u1'), MessageStatus.delivered);
    expect(thread.statusOf(now, 'u1'), MessageStatus.sent);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        profileProvider.overrideWithValue(
            const Profile(id: 'u1', displayName: 'Aisha', role: AppRole.member, status: AccountStatus.active, personId: 'aisha')),
        graphProvider.overrideWith((ref) async => buildFamily()),
        settingsProvider.overrideWith((ref) async => const AppSettings()),
        membersProvider.overrideWith((ref) async => {
              'u1': const Member(userId: 'u1', displayName: 'Aisha', personId: 'aisha'),
              'u2': const Member(userId: 'u2', displayName: 'Musa', personId: 'musa'),
            }),
        dmThreadsProvider.overrideWith((ref) => Stream.value([thread])),
        blockedProvider.overrideWith((ref) async => const {}),
        dmMediaUrlProvider.overrideWith((ref, path) => Completer<String>().future),
        dmReactionsProvider.overrideWith((ref, id) => Stream.value(const [
              DmReaction(messageId: 'm3', userId: 'u2', emoji: '👍'),
              DmReaction(messageId: 'm3', userId: 'u1', emoji: '❤️'),
            ])),
        dmMessagesProvider.overrideWith((ref, id) => Stream.value([
              DmMessage(id: 'm1', threadId: 't1', authorId: 'u1', body: 'Old one', createdAt: now.subtract(const Duration(hours: 2))),
              DmMessage(id: 'm2', threadId: 't1', authorId: 'u2', body: 'Are you coming?', createdAt: now.subtract(const Duration(minutes: 40))),
              DmMessage(id: 'm3', threadId: 't1', authorId: 'u1', body: 'Yes!', createdAt: now.subtract(const Duration(minutes: 30)), replyTo: 'm2'),
              DmMessage(
                  id: 'm4', threadId: 't1', authorId: 'u2', body: '🎤', kind: DmKind.voice, mediaPath: 't1/u2/a.m4a',
                  durationMs: 65000, createdAt: now.subtract(const Duration(minutes: 20))),
              DmMessage(
                  id: 'm5', threadId: 't1', authorId: 'u2', body: 'x', createdAt: now.subtract(const Duration(minutes: 15)),
                  deletedAt: now),
              DmMessage(id: 'm6', threadId: 't1', authorId: 'u1', body: 'On my way', createdAt: now),
            ])),
      ],
      child: MaterialApp(
        localizationsDelegates: localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DmScreen(threadId: 't1'),
      ),
    ));
    await tester.pumpAndSettle();

    // Ticks on my messages: read, delivered, sent.
    Finder ticks(MessageStatus s) => find.byWidgetPredicate((w) => w is Ticks && w.status == s);
    expect(ticks(MessageStatus.read), findsOneWidget);
    expect(ticks(MessageStatus.delivered), findsOneWidget);
    expect(ticks(MessageStatus.sent), findsOneWidget);
    // A reply shows what it answers; a voice note its length; a deleted message says so.
    expect(find.textContaining('Are you coming?'), findsNWidgets(2));
    expect(find.text('1:05'), findsOneWidget);
    expect(find.textContaining('This message was deleted'), findsOneWidget);
    // A voice note shows its waveform; older ones without levels get a steady shape.
    expect(find.byType(VoiceWave), findsOneWidget);
    // Reactions under the message.
    expect(find.byType(ReactionsPill), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);

    // They are typing.
    repo.typingFrom!('u2');
    await tester.pump();
    expect(find.text('typing…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('typing…'), findsNothing);

    // Typing tells them, once every few seconds.
    await tester.enterText(find.byType(TextField), 'Al');
    await tester.enterText(find.byType(TextField), 'Alhamdulillah');
    await tester.pump();
    expect(repo.pings, ['t1']);

    // Swipe their question to reply to it.
    await tester.drag(find.byKey(const ValueKey('m2')), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(find.text('Replying to musa'), findsOneWidget);
    // An emoji from the panel goes in at the cursor.
    await tester.tap(find.byTooltip('Emoji'));
    await tester.pumpAndSettle();
    expect(find.byType(EmojiPanel), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(EmojiPanel), matching: find.text('😀')));
    await tester.pump();
    expect(find.byTooltip('Keyboard'), findsOneWidget);
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(repo.sent.last, ('t1', 'Alhamdulillah😀'));
    expect(repo.replies.last, 'm2');
    expect(find.text('Replying to musa'), findsNothing);

    // An empty box offers a voice note instead of Send.
    expect(find.byTooltip('Voice note'), findsOneWidget);

    // Long press to react; the one I chose again takes it off; tapping the
    // reactions shows who.
    await tester.longPress(find.textContaining('Are you coming?').last);
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsNothing, reason: 'replying is a swipe now');
    await tester.tap(find.text('🙏'));
    await tester.pumpAndSettle();
    expect(repo.reacted.last, ('m2', '🙏'));
    await tester.longPress(find.textContaining('Yes!'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('❤️').last);
    await tester.pumpAndSettle();
    expect(repo.reacted.last, ('m3', null));
    await tester.tap(find.byType(ReactionsPill));
    await tester.pumpAndSettle();
    expect(find.text('Tap yours to remove it'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'musa'), findsOneWidget);
    Navigator.of(tester.element(find.text('Tap yours to remove it'))).pop();
    await tester.pumpAndSettle();

    // Delete my own message for everyone.
    await tester.longPress(find.textContaining('On my way'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete for everyone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.deleted, ['m6']);
  });

  testWidgets('a photo is drawn from its saved copy, and offers a retry if it can\'t load', (tester) async {
    // A 1×1 PNG.
    final png = Uint8List.fromList(const [
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, //
      196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 248, 15, 4, 0, 9, 251, 3, 253, 227, 85, 242, 156, 0, 0, //
      0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
    ]);
    Widget photo(Future<Uint8List> Function() load) => ProviderScope(
          key: UniqueKey(),
          overrides: [dmMediaProvider.overrideWith((ref, path) => load())],
          child: MaterialApp(
            localizationsDelegates: localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: DmPhoto(path: 't1/u2/p.jpg')),
          ),
        );
    await tester.pumpWidget(photo(() async => png));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);

    await tester.pumpWidget(photo(() async => throw Exception('offline')));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
  });
}
