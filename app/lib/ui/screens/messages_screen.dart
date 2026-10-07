import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/messages.dart';
import '../../models/person.dart' show searchFold;
import '../../models/report.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import 'group_screens.dart' show GroupAvatar, groupEventText;
import '../widgets/common.dart';
import '../widgets/chat_view.dart';
import '../widgets/dm_bubble.dart';
import '../widgets/report_sheet.dart';
import '../widgets/social.dart';

/// Opens the conversation with [userId], starting it if there isn't one.
Future<void> openDmWith(BuildContext context, WidgetRef ref, String userId) async {
  String? id;
  final ok = await guarded(context, () async => id = await ref.read(repositoryProvider).dmOpen(userId));
  if (ok && id != null && context.mounted) context.push('/messages/$id');
}

/// Shows [child] while messages are on, and a note when admins turned them off.
class MessagesGate extends ConsumerWidget {
  const MessagesGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(settingsProvider).value?.messagesEnabled ?? true) return child;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
        title: Text(l.messagesTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.speaker_notes_off_outlined, size: 48, color: Bua.inkSubtle),
            const SizedBox(height: 12),
            Text(l.messagesTurnedOff, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
          ]),
        ),
      ),
    );
  }
}

/// My private conversations and groups, latest first.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  Future<void> _new(BuildContext context, WidgetRef ref) async {
    final userId = await pickMember(context, ref);
    if (userId != null && context.mounted) await openDmWith(context, ref, userId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(profileProvider)?.id;
    final threads = ref.watch(dmThreadsProvider);
    final groups = ref.watch(groupsProvider).value ?? const <ChatGroup>[];
    final mine = ref.watch(myGroupMembershipsProvider).value ?? const <String, GroupMember>{};
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
        title: Text(l.messagesTitle),
        actions: [
          IconButton(
            tooltip: l.newGroup,
            onPressed: () => context.push('/groups/new'),
            icon: const Icon(Icons.group_add_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _new(context, ref),
        icon: const Icon(Icons.edit_outlined),
        label: Text(l.newMessage),
      ),
      body: AsyncBody(
        value: threads,
        onRetry: () => ref.invalidate(dmThreadsProvider),
        builder: (list) {
          final rows = <(DateTime, Widget)>[
            for (final t in list) (t.activeAt, _ThreadRow(thread: t, me: me)),
            for (final g in groups) (g.activeAt, _GroupRow(group: g, mine: mine[g.id], me: me)),
          ]..sort((a, b) => b.$1.compareTo(a.$1));
          if (rows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.forum_outlined, size: 48, color: Bua.inkSubtle),
                  const SizedBox(height: 12),
                  Text(l.noMessagesYet, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
                ]),
              ),
            );
          }
          return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
            Material(
              color: Bua.surface,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (final (i, (_, row)) in rows.indexed) ...[
                  if (i > 0) const InsetDivider(indent: 72),
                  row,
                ],
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

class _ThreadRow extends ConsumerWidget {
  const _ThreadRow({required this.thread, required this.me});

  final DmThread thread;
  final String? me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final other = authorOf(ref, thread.otherThan(me));
    final unread = thread.unreadFor(me);
    final mineLast = thread.lastMessageBy == me;
    final last = thread.lastMessage;
    final words = switch (thread.lastMessageKind) {
      'photo' => (last?.isNotEmpty ?? false) ? '📷 $last' : '📷 ${l.dmPhoto}',
      'voice' => '🎤 ${l.dmVoiceNote}',
      'deleted' => l.dmDeleted,
      _ => last,
    };
    final preview = words == null ? l.startConversation : (mineLast ? l.youPrefix(words) : words);
    return InkWell(
      onTap: () => context.push('/messages/${thread.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          AuthorAvatar(other, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(other.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: unread ? FontWeight.w700 : FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                Text(l.ago(thread.activeAt), style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                if (mineLast && thread.lastMessageAt != null && thread.lastMessageKind != 'deleted') ...[
                  Ticks(thread.statusOf(thread.lastMessageAt!, me)),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          color: unread ? Bua.ink : Bua.inkSubtle,
                          fontWeight: unread ? FontWeight.w600 : FontWeight.w400)),
                ),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: Bua.green, shape: BoxShape.circle),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _GroupRow extends ConsumerWidget {
  const _GroupRow({required this.group, required this.mine, required this.me});

  final ChatGroup group;
  final GroupMember? mine;
  final String? me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final unread = group.unreadFor(mine);
    final by = group.lastMessageBy;
    String nameOf(String userId) => userId == me ? l.you : authorOf(ref, userId).name;
    final last = group.lastMessage;
    final words = switch (group.lastMessageKind) {
      'photo' => (last?.isNotEmpty ?? false) ? '📷 $last' : '📷 ${l.dmPhoto}',
      'voice' => '🎤 ${l.dmVoiceNote}',
      'deleted' => l.dmDeleted,
      'event' => groupEventText(l, group.lastEvent, by, nameOf),
      _ => last,
    };
    final preview = words == null
        ? ''
        : group.lastMessageKind == 'event' || by == null
            ? words
            : by == me
                ? l.youPrefix(words)
                : '${nameOf(by)}: $words';
    return InkWell(
      onTap: () => context.push('/groups/${group.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          GroupAvatar(group, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: unread ? FontWeight.w700 : FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                Text(l.ago(group.activeAt), style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Expanded(
                  child: Text(preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          color: unread ? Bua.ink : Bua.inkSubtle,
                          fontWeight: unread ? FontWeight.w600 : FontWeight.w400)),
                ),
                if (mine?.muted ?? false)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.notifications_off_outlined, size: 16, color: Bua.inkSubtle),
                  ),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: Bua.green, shape: BoxShape.circle),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Choose someone in the family to write to (members with an account, not me).
/// [title] instead of "Message who?"; [includeMe] to offer myself too.
Future<String?> pickMember(BuildContext context, WidgetRef ref, {String? title, bool includeMe = false}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _MemberPicker(title: title, includeMe: includeMe),
    );

class _MemberPicker extends ConsumerStatefulWidget {
  const _MemberPicker({this.title, this.includeMe = false});

  final String? title;
  final bool includeMe;

  @override
  ConsumerState<_MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends ConsumerState<_MemberPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final me = ref.watch(profileProvider)?.id;
    final members = ref.watch(membersProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, scroll) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.title ?? l.messageWho, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            TextField(
              autofocus: true,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchByName),
              onChanged: (v) => setState(() => _query = v),
            ),
          ]),
        ),
        Expanded(
          child: AsyncBody(
            value: members,
            onRetry: () => ref.invalidate(membersProvider),
            builder: (map) {
              final q = searchFold(_query.trim());
              final people = [
                for (final m in map.values)
                  if (m.userId != me || widget.includeMe) (m, authorOf(ref, m.userId)),
              ].where((e) => q.isEmpty || searchFold(e.$2.name).contains(q)).toList()
                ..sort((a, b) => a.$2.name.toLowerCase().compareTo(b.$2.name.toLowerCase()));
              if (people.isEmpty) {
                return Center(
                  child: Text(map.length <= 1 ? l.noOtherMembers : l.searchNothing(_query),
                      textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
                );
              }
              return ListView.builder(
                controller: scroll,
                itemCount: people.length,
                itemBuilder: (_, i) {
                  final (Member m, Author a) = people[i];
                  final relation = a.relation(l);
                  return ListTile(
                    leading: AuthorAvatar(a),
                    title: Text(a.name),
                    subtitle: relation == null ? null : Text(relation),
                    onTap: () => Navigator.pop(context, m.userId),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// One conversation: the messages and a box to write, WhatsApp-style.
class DmScreen extends ConsumerWidget {
  const DmScreen({super.key, required this.threadId});

  final String threadId;

  Future<void> _memberMenu(BuildContext context, WidgetRef ref, String action, String other, String name) async {
    final l = context.l10n;
    final repo = ref.read(repositoryProvider);
    switch (action) {
      case 'report':
        await reportToAdmins(context, ref, ReportKind.member, other);
      case 'block':
        if (!await confirm(context, l.confirmBlock(name)) || !context.mounted) return;
        if (await guarded(context, () => repo.block(other))) {
          ref.invalidate(blockedProvider);
          if (context.mounted) showSnack(context, l.blockedNote(name));
        }
      case 'unblock':
        if (await guarded(context, () => repo.unblock(other))) ref.invalidate(blockedProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(profileProvider)?.id;
    final threads = ref.watch(dmThreadsProvider);
    final thread = threads.value?.where((t) => t.id == threadId).firstOrNull;
    final otherId = thread == null || me == null ? null : thread.otherThan(me);
    final other = otherId == null ? null : authorOf(ref, otherId);
    final relation = other?.relation(l);
    final iBlocked = otherId != null && (ref.watch(blockedProvider).value?.contains(otherId) ?? false);

    return ChatView(
      channel: DmChannel(() => ref.read(repositoryProvider), threadId),
      messages: ref.watch(dmMessagesProvider(threadId)),
      onRetry: () => ref.invalidate(dmMessagesProvider(threadId)),
      reactions: ref.watch(dmReactionsProvider(threadId)).value ?? const [],
      me: me,
      nameOf: (userId) => userId == me ? l.you : (other?.name ?? ''),
      statusOf: (m) => thread?.statusOf(m.createdAt, me),
      privateNote: l.dmPrivate,
      notFound: threads.hasValue && thread == null
          ? Center(child: Text(l.conversationNotFound, style: TextStyle(color: Bua.inkSubtle)))
          : null,
      composer: iBlocked
          ? ChatComposerNote(
              text: l.youBlocked(other?.name ?? ''),
              action: TextButton(
                onPressed: () => _memberMenu(context, ref, 'unblock', otherId, other?.name ?? ''),
                child: Text(l.unblock),
              ),
            )
          : null,
      appBar: (context, typing) => AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/messages')),
        titleSpacing: 0,
        title: other == null
            ? Text(l.messagesTitle)
            : InkWell(
                onTap: other.person == null ? null : () => context.push('/person/${other.person!.id}'),
                child: Row(children: [
                  AuthorAvatar(other, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(other.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      if (typing.isNotEmpty)
                        Text(l.dmTyping, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Bua.green))
                      else if (relation != null)
                        Text(relation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Bua.inkSubtle)),
                    ]),
                  ),
                ]),
              ),
        actions: [
          if (otherId != null)
            PopupMenuButton<String>(
              onSelected: (v) => _memberMenu(context, ref, v, otherId, other!.name),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'report', child: Text(l.reportMember)),
                PopupMenuItem(value: iBlocked ? 'unblock' : 'block', child: Text(iBlocked ? l.unblock : l.block)),
              ],
            ),
        ],
      ),
    );
  }
}

/// On Home: messages, with a dot when something is unread.
class MessagesButton extends ConsumerWidget {
  const MessagesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final unread = ref.watch(dmUnreadProvider);
    return IconButton(
      tooltip: unread > 0 ? '${l.messagesTitle}, $unread' : l.messagesTitle,
      onPressed: () => context.push('/messages'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        backgroundColor: Bua.danger,
        child: const Icon(Icons.forum_outlined),
      ),
    );
  }
}
