import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/community.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';

/// A mentor and the person who asked, writing to each other. The ask is the
/// first message; only the two of them can see any of it.
class MentorConversationScreen extends ConsumerStatefulWidget {
  const MentorConversationScreen({super.key, required this.askId});

  final String askId;

  @override
  ConsumerState<MentorConversationScreen> createState() => _MentorConversationScreenState();
}

class _MentorConversationScreenState extends ConsumerState<MentorConversationScreen> {
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
      await ref.read(repositoryProvider).markMentorAskRead(widget.askId);
      if (mounted) ref.invalidate(mentorshipProvider);
    } catch (_) {
      // Not important enough to bother anyone.
    }
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await guarded(context, () => ref.read(repositoryProvider).sendMentorMessage(widget.askId, body));
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _text.clear();
      ref.invalidate(mentorshipProvider);
    }
  }

  Future<void> _delete() async {
    final l = context.l10n;
    if (!await confirm(context, l.deleteConversationConfirm) || !mounted) return;
    if (await guarded(context, () => ref.read(repositoryProvider).deleteAsk(widget.askId))) {
      ref.invalidate(mentorshipProvider);
      if (mounted) context.canPop() ? context.pop() : context.go('/mentors');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final me = ref.watch(profileProvider)?.id;
    final ask = ref.watch(mentorAskProvider(widget.askId));
    final messages = ref.watch(mentorMessagesProvider(widget.askId));
    final mentors = ref.watch(mentorshipProvider).value?.mentors ?? const <Mentor>[];

    // Read as soon as something new shows.
    final count = messages.value?.length ?? -1;
    if (count != _seen && ask.value != null) {
      _seen = count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _markRead();
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }

    final a = ask.value;
    final other = a == null ? null : authorOf(ref, a.otherThan(me));
    final iAmMentor = a != null && a.mentorUserId == me;
    final areas = a == null ? null : mentors.where((m) => m.userId == a.mentorUserId).firstOrNull?.areas;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/mentors')),
        titleSpacing: 0,
        title: other == null
            ? Text(l.conversationTitle, style: Theme.of(context).textTheme.titleLarge)
            : InkWell(
                onTap: other.person == null ? null : () => context.push('/person/${other.person!.id}'),
                child: Row(children: [
                  AuthorAvatar(other, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(other.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(
                        iAmMentor ? l.conversationWithStudent : l.conversationWithMentor(areas ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Bua.inkSubtle),
                      ),
                    ]),
                  ),
                ]),
              ),
        actions: [
          if (a != null)
            PopupMenuButton<String>(
              onSelected: (_) => _delete(),
              itemBuilder: (_) => [PopupMenuItem(value: 'delete', child: Text(l.deleteConversation))],
            ),
        ],
      ),
      body: AsyncBody(
        value: ask,
        onRetry: () => ref.invalidate(mentorAskProvider(widget.askId)),
        builder: (a) => a == null
            ? Center(child: Text(l.conversationGone, style: const TextStyle(color: Bua.inkSubtle)))
            : Column(children: [
                Expanded(
                  child: ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.lock_outline, size: 14, color: Bua.inkSubtle),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(l.conversationPrivate,
                              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                        ),
                      ]),
                    ),
                    ChatBubble(text: a.message, at: a.createdAt, mine: a.fromUserId == me),
                    for (final m in messages.value ?? const <MentorMessage>[])
                      ChatBubble(text: m.body, at: m.createdAt, mine: m.authorId == me),
                  ]),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    decoration: const BoxDecoration(
                      color: Bua.surface,
                      border: Border(top: BorderSide(color: Bua.line)),
                    ),
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
                      IconButton.filled(
                        tooltip: l.send,
                        onPressed: _sending ? null : _send,
                        icon: const Icon(Icons.send),
                      ),
                    ]),
                  ),
                ),
              ]),
      ),
    );
  }
}
