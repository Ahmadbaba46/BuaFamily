import 'dart:async';

import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/details.dart';
import 'package:bua_family/models/messages.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/group_screens.dart';
import 'package:bua_family/ui/screens/messages_screen.dart';
import 'package:bua_family/ui/widgets/dm_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

import 'domain_test.dart' show buildFamily;

class _FakeRepo extends FamilyRepository {
  _FakeRepo()
      : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final created = <(String, List<String>)>[];
  final sent = <(String, String, String?)>[];
  final added = <List<String>>[];
  final muted = <bool>[];
  final left = <String>[];
  final deleted = <String>[];
  final read = <String>[];

  @override
  Future<String> createGroup(String name, List<String> members, {String? about}) async {
    created.add((name, members));
    return 'g-new';
  }

  @override
  Future<void> sendGroup(String groupId, String body, {String? replyTo}) async => sent.add((groupId, body, replyTo));

  @override
  Future<void> addToGroup(String groupId, List<String> users) async => added.add(users);

  @override
  Future<void> muteGroup(String groupId, bool muted) async => this.muted.add(muted);

  @override
  Future<void> leaveGroup(String groupId) async => left.add(groupId);

  @override
  Future<void> deleteGroupMessage(DmMessage m) async => deleted.add(m.id);

  @override
  Future<void> markGroupRead(String groupId) async => read.add(groupId);

  @override
  Future<void> markDmDelivered() async {}

  @override
  TypingSignal groupTyping(String groupId, void Function(String userId) onTyping) =>
      TypingSignal(() async {}, () async {});
}

void main() {
  final now = DateTime.now();
  final group = ChatGroup(
    id: 'g1',
    name: 'Cousins',
    about: 'For the cousins',
    createdAt: now.subtract(const Duration(days: 1)),
    lastMessageAt: now.subtract(const Duration(minutes: 1)),
    lastMessage: 'Salam everyone',
    lastMessageBy: 'u2',
    lastMessageKind: 'text',
  );
  GroupMember member(String user, {bool admin = false, DateTime? read, DateTime? delivered, bool muted = false}) =>
      GroupMember(
        groupId: 'g1',
        userId: user,
        admin: admin,
        joinedAt: now.subtract(const Duration(days: 1)),
        readAt: read,
        deliveredAt: delivered,
        muted: muted,
      );

  Widget app(
    Widget home, {
    required _FakeRepo repo,
    List<ChatGroup> groups = const [],
    List<GroupMember> members = const [],
    List<DmMessage> messages = const [],
  }) =>
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          profileProvider.overrideWithValue(
              const Profile(id: 'u1', displayName: 'Aisha', role: AppRole.member, status: AccountStatus.active, personId: 'aisha')),
          graphProvider.overrideWith((ref) async => buildFamily()),
          settingsProvider.overrideWith((ref) async => const AppSettings()),
          membersProvider.overrideWith((ref) async => {
                'u1': const Member(userId: 'u1', displayName: 'Aisha', personId: 'aisha'),
                'u2': const Member(userId: 'u2', displayName: 'Musa', personId: 'musa'),
                'u3': const Member(userId: 'u3', displayName: 'Bello', personId: 'bello'),
              }),
          dmThreadsProvider.overrideWith((ref) => Stream.value(const [])),
          blockedProvider.overrideWith((ref) async => const {}),
          groupsProvider.overrideWith((ref) => Stream.value(groups)),
          myGroupMembershipsProvider
              .overrideWith((ref) => Stream.value({for (final m in members.where((m) => m.userId == 'u1')) m.groupId: m})),
          groupMembersProvider.overrideWith((ref, id) => Stream.value(members)),
          groupMessagesProvider.overrideWith((ref, id) => Stream.value(messages)),
          groupReactionsProvider.overrideWith((ref, id) => Stream.value(const [])),
          detailsProvider.overrideWith((ref, id) async => const PersonDetails()),
        ],
        child: MaterialApp.router(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, _) => home),
            GoRoute(path: '/groups/new', builder: (_, _) => const NewGroupScreen()),
            GoRoute(path: '/groups/:id', builder: (_, s) => Scaffold(body: Text('group ${s.pathParameters['id']}'))),
            GoRoute(path: '/messages', builder: (_, _) => const Scaffold(body: Text('messages'))),
          ]),
        ),
      );

  test('ticks in a group: read when everyone has read it, delivered when it is on every phone', () {
    final sent = now.subtract(const Duration(minutes: 10));
    final later = now.subtract(const Duration(minutes: 5));
    final earlier = now.subtract(const Duration(minutes: 20));
    expect(groupStatus([member('u1'), member('u2', read: later), member('u3', read: later)], sent, 'u1'),
        MessageStatus.read);
    expect(groupStatus([member('u1'), member('u2', read: later), member('u3', delivered: later)], sent, 'u1'),
        MessageStatus.delivered);
    expect(groupStatus([member('u1'), member('u2', read: later), member('u3', delivered: earlier)], sent, 'u1'),
        MessageStatus.sent);
    // Someone who joined after it was sent doesn't count.
    final newcomer = GroupMember(groupId: 'g1', userId: 'u3', joinedAt: now);
    expect(groupStatus([member('u1'), member('u2', read: later), newcomer], sent, 'u1'), MessageStatus.read);
    expect(group.unreadFor(member('u1', read: earlier)), isTrue);
    expect(group.unreadFor(member('u1', read: now)), isFalse);
  });

  testWidgets('groups sit with conversations in Messages', (tester) async {
    await tester.pumpWidget(app(const MessagesScreen(),
        repo: _FakeRepo(), groups: [group], members: [member('u1', read: now.subtract(const Duration(hours: 1)))]));
    await tester.pumpAndSettle();
    expect(find.text('Cousins'), findsOneWidget);
    expect(find.text('musa: Salam everyone'), findsOneWidget);
    expect(find.byTooltip('New group'), findsOneWidget);
  });

  testWidgets('start a group: a name and who is in it', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const NewGroupScreen(), repo: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create group'));
    await tester.pump();
    expect(find.text('Give the group a name'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Group name'), 'Cousins');
    await tester.tap(find.text('Create group'));
    await tester.pump();
    expect(find.text('Choose at least one person'), findsOneWidget);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'musa'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'bello'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.text('Create group · 2'));
    await tester.pumpAndSettle();
    expect(repo.created.single.$1, 'Cousins');
    expect(repo.created.single.$2.toSet(), {'u2', 'u3'});
    expect(find.text('group g-new'), findsOneWidget);
  });

  testWidgets('a group: who wrote what, notices, ticks and who has read it', (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    final t0 = now.subtract(const Duration(hours: 2));
    await tester.pumpWidget(app(
      const GroupChatScreen(groupId: 'g1'),
      repo: repo,
      groups: [group],
      members: [
        member('u1', admin: true),
        member('u2', read: now),
        member('u3', delivered: now.subtract(const Duration(minutes: 30))),
      ],
      messages: [
        DmMessage(
            id: 'e1', threadId: 'g1', authorId: 'u1', body: 'created', kind: DmKind.event, createdAt: t0,
            event: const {'type': 'created', 'name': 'Cousins'}),
        DmMessage(
            id: 'e2', threadId: 'g1', authorId: 'u1', body: 'added', kind: DmKind.event, createdAt: t0,
            event: const {'type': 'added', 'user': 'u2'}),
        DmMessage(id: 'm1', threadId: 'g1', authorId: 'u2', body: 'Salam everyone', createdAt: now.subtract(const Duration(hours: 1))),
        DmMessage(id: 'm2', threadId: 'g1', authorId: 'u2', body: 'How is everyone?', createdAt: now.subtract(const Duration(minutes: 59))),
        DmMessage(id: 'm3', threadId: 'g1', authorId: 'u1', body: 'Lafiya lau', createdAt: now.subtract(const Duration(minutes: 40))),
        DmMessage(id: 'm4', threadId: 'g1', authorId: 'u3', body: 'Hi all', createdAt: now.subtract(const Duration(minutes: 20))),
      ],
    ));
    await tester.pumpAndSettle();

    // The bar: the group, and who is in it.
    expect(find.text('Cousins'), findsOneWidget);
    expect(find.text('musa, bello, You'), findsOneWidget);
    // Notices, in words.
    expect(find.text('You created the group “Cousins”'), findsOneWidget);
    expect(find.text('You added musa'), findsOneWidget);
    // Others' names over the first of their messages in a row only.
    expect(find.text('musa'), findsOneWidget);
    expect(find.text('bello'), findsOneWidget);
    // Musa read my message, Bello's phone has it: two grey ticks.
    expect(find.byWidgetPredicate((w) => w is Ticks && w.status == MessageStatus.delivered), findsOneWidget);
    expect(repo.read, contains('g1'));

    // Message info: who read it, who has it.
    await tester.longPress(find.textContaining('Lafiya lau'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message info'));
    await tester.pumpAndSettle();
    expect(find.text('Read by'), findsOneWidget);
    expect(find.text('Delivered to'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'musa'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'bello'), findsOneWidget);
    Navigator.of(tester.element(find.text('Read by'))).pop();
    await tester.pumpAndSettle();

    // As a group admin I can delete someone else's message.
    await tester.longPress(find.textContaining('Hi all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete for everyone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.deleted, ['m4']);

    // Writing.
    await tester.enterText(find.byType(TextField), 'See you all at the naming');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(repo.sent.single, ('g1', 'See you all at the naming', null));
  });

  testWidgets('when only admins may send, members see why they cannot', (tester) async {
    final adminsOnly = ChatGroup(id: 'g1', name: 'Elders', createdAt: now, onlyAdminsSend: true);
    await tester.pumpWidget(app(const GroupChatScreen(groupId: 'g1'),
        repo: _FakeRepo(), groups: [adminsOnly], members: [member('u1'), member('u2', admin: true)]));
    await tester.pumpAndSettle();
    expect(find.text('Only group admins can send messages.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('group info: members, mute, add people, leave', (tester) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo();
    await tester.pumpWidget(app(const GroupInfoScreen(groupId: 'g1'),
        repo: repo, groups: [group], members: [member('u1', admin: true), member('u2')]));
    await tester.pumpAndSettle();
    expect(find.text('Cousins'), findsOneWidget);
    expect(find.text('For the cousins'), findsOneWidget);
    expect(find.text('2 members'), findsWidgets);
    expect(find.text('Group admin'), findsOneWidget);
    expect(find.text('Only admins can send messages'), findsOneWidget, reason: 'a group admin can change it');

    await tester.tap(find.text('Mute notifications'));
    await tester.pumpAndSettle();
    expect(repo.muted, [true]);

    await tester.tap(find.text('Add members'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CheckboxListTile, 'musa'), findsNothing, reason: 'already in it');
    await tester.tap(find.widgetWithText(CheckboxListTile, 'bello'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 selected'));
    await tester.pumpAndSettle();
    expect(repo.added, [
      ['u3'],
    ]);

    await tester.ensureVisible(find.text('Leave group'));
    await tester.tap(find.text('Leave group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.left, ['g1']);
    expect(find.text('messages'), findsOneWidget);
  });
}
