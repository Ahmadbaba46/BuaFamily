import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/messages.dart';
import '../../models/person.dart' show searchFold;
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';

/// Opens the conversation with [userId], starting it if there isn't one.
Future<void> openDmWith(BuildContext context, WidgetRef ref, String userId) async {
  String? id;
  final ok = await guarded(context, () async => id = await ref.read(repositoryProvider).dmOpen(userId));
  if (ok && id != null && context.mounted) context.push('/messages/$id');
}

/// My private conversations, latest first.
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
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
        title: Text(l.messagesTitle),
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
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.forum_outlined, size: 48, color: Bua.inkSubtle),
                  const SizedBox(height: 12),
                  Text(l.noMessagesYet, textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkMuted)),
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
                for (final (i, t) in list.indexed) ...[
                  if (i > 0) const InsetDivider(indent: 72),
                  _ThreadRow(thread: t, me: me),
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
    final last = thread.lastMessage;
    final preview = last == null ? l.startConversation : (thread.lastMessageBy == me ? l.youPrefix(last) : last);
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
                Text(l.ago(thread.activeAt), style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
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
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Bua.green, shape: BoxShape.circle),
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
Future<String?> pickMember(BuildContext context, WidgetRef ref) => showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _MemberPicker(),
    );

class _MemberPicker extends ConsumerStatefulWidget {
  const _MemberPicker();

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
            Text(l.messageWho, style: Theme.of(context).textTheme.titleLarge),
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
                  if (m.userId != me) (m, authorOf(ref, m.userId)),
              ].where((e) => q.isEmpty || searchFold(e.$2.name).contains(q)).toList()
                ..sort((a, b) => a.$2.name.toLowerCase().compareTo(b.$2.name.toLowerCase()));
              if (people.isEmpty) {
                return Center(
                  child: Text(map.length <= 1 ? l.noOtherMembers : l.searchNothing(_query),
                      textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkMuted)),
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

/// One conversation: the messages and a box to write.
class DmScreen extends ConsumerStatefulWidget {
  const DmScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<DmScreen> createState() => _DmScreenState();
}

class _DmScreenState extends ConsumerState<DmScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  int _seen = -1;

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await ref.read(repositoryProvider).markDmRead(widget.threadId);
    } catch (_) {
      // Not important enough to bother anyone.
    }
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await guarded(context, () => ref.read(repositoryProvider).sendDm(widget.threadId, body));
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final me = ref.watch(profileProvider)?.id;
    final threads = ref.watch(dmThreadsProvider);
    final thread = threads.value?.where((t) => t.id == widget.threadId).firstOrNull;
    final messages = ref.watch(dmMessagesProvider(widget.threadId));

    // Read as soon as something new shows.
    final count = messages.value?.length ?? -1;
    if (count != _seen && messages.hasValue) {
      _seen = count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _markRead();
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }

    final other = thread == null ? null : authorOf(ref, thread.otherThan(me));
    final relation = other?.relation(l);

    return Scaffold(
      appBar: AppBar(
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
                      if (relation != null)
                        Text(relation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Bua.inkSubtle)),
                    ]),
                  ),
                ]),
              ),
      ),
      body: threads.hasValue && thread == null
          ? Center(child: Text(l.conversationNotFound, style: const TextStyle(color: Bua.inkSubtle)))
          : Column(children: [
              Expanded(
                child: AsyncBody(
                  value: messages,
                  onRetry: () => ref.invalidate(dmMessagesProvider(widget.threadId)),
                  builder: (list) => ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.lock_outline, size: 14, color: Bua.inkSubtle),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(l.dmPrivate,
                                textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                          ),
                        ]),
                      ),
                      if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(l.startConversation,
                              textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkMuted)),
                        ),
                      for (final m in list) ChatBubble(text: m.body, at: m.createdAt, mine: m.authorId == me),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  decoration: const BoxDecoration(color: Bua.surface, border: Border(top: BorderSide(color: Bua.line))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 4000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: l.writeMessage,
                          counterText: '',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(tooltip: l.send, onPressed: _sending ? null : _send, icon: const Icon(Icons.send)),
                  ]),
                ),
              ),
            ]),
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
