import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../data/repository.dart' show TypingSignal;
import '../../l10n/l10n.dart';
import '../../models/messages.dart';
import '../../models/person.dart' show searchFold;
import '../../models/report.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
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

  /// The message being answered.
  DmMessage? _replyTo;

  // "typing…"
  TypingSignal? _typing;
  bool _otherTyping = false;
  Timer? _typingOff;

  // Recording a voice note.
  AudioRecorder? _recorder;
  DateTime? _recordingSince;
  Duration _recorded = Duration.zero;
  Timer? _recordTicker;
  String _recordExt = 'm4a';

  @override
  void initState() {
    super.initState();
    _text.addListener(() {
      if (_text.text.isNotEmpty) _typing?.typing();
      setState(() {});
    });
    try {
      _typing = ref.read(repositoryProvider).dmTyping(widget.threadId, (_) {
        if (!mounted) return;
        setState(() => _otherTyping = true);
        _typingOff?.cancel();
        _typingOff = Timer(const Duration(seconds: 4), () => mounted ? setState(() => _otherTyping = false) : null);
      });
    } catch (_) {
      // No live connection: no "typing…", everything else works.
    }
  }

  @override
  void dispose() {
    _typing?.dispose();
    _typingOff?.cancel();
    _recordTicker?.cancel();
    _recorder?.dispose();
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

  String? _cantSend(Object e) => e is PostgrestException && e.code == '42501' ? context.l10n.cantMessageMember : null;

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final reply = _replyTo?.id;
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).sendDm(widget.threadId, body, replyTo: reply),
      onError: _cantSend,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) {
        _text.clear();
        _replyTo = null;
      }
    });
  }

  Future<void> _sendPhoto() async {
    final l = context.l10n;
    final source = kIsWeb
        ? ImageSource.gallery
        : await showModalBottomSheet<ImageSource>(
            context: context,
            showDragHandle: true,
            builder: (c) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(l.takePhoto),
                  onTap: () => Navigator.pop(c, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l.chooseFromGallery),
                  onTap: () => Navigator.pop(c, ImageSource.gallery),
                ),
              ]),
            ),
          );
    if (source == null || !mounted) return;
    final f = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
    if (f == null || !mounted) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    final caption = TextEditingController(text: _text.text.trim());
    final send = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(bytes, height: 260, fit: BoxFit.cover)),
          const SizedBox(height: 12),
          TextField(
            controller: caption,
            maxLength: 4000,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(hintText: l.dmAddCaption, counterText: ''),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton.icon(onPressed: () => Navigator.pop(c, true), icon: const Icon(Icons.send, size: 18), label: Text(l.send)),
        ],
      ),
    );
    final words = caption.text;
    caption.dispose();
    if (send != true || !mounted) return;
    setState(() => _sending = true);
    final reply = _replyTo?.id;
    final name = f.name.toLowerCase();
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).sendDmMedia(widget.threadId,
          kind: DmKind.photo,
          bytes: bytes,
          extension: name.contains('.') ? name.split('.').last : 'jpg',
          caption: words,
          replyTo: reply),
      onError: _cantSend,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) {
        _text.clear();
        _replyTo = null;
      }
    });
  }

  Future<void> _startRecording() async {
    final l = context.l10n;
    final rec = _recorder ??= AudioRecorder();
    try {
      if (!await rec.hasPermission()) {
        if (mounted) showSnack(context, l.micDenied);
        return;
      }
      final aac = await rec.isEncoderSupported(AudioEncoder.aacLc);
      _recordExt = aac ? 'm4a' : (kIsWeb ? 'webm' : 'ogg');
      final path =
          kIsWeb ? '' : '${(await getTemporaryDirectory()).path}/dm_${DateTime.now().millisecondsSinceEpoch}.$_recordExt';
      await rec.start(
        RecordConfig(encoder: aac ? AudioEncoder.aacLc : AudioEncoder.opus, bitRate: 48000, numChannels: 1),
        path: path,
      );
    } catch (e) {
      if (mounted) showError(context, e);
      return;
    }
    if (!mounted) return;
    setState(() {
      _recordingSince = DateTime.now();
      _recorded = Duration.zero;
    });
    _recordTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _recordingSince != null) {
        setState(() => _recorded = DateTime.now().difference(_recordingSince!));
        _typing?.typing();
      }
    });
  }

  Future<void> _stopRecording({required bool send}) async {
    _recordTicker?.cancel();
    final length = _recordingSince == null ? Duration.zero : DateTime.now().difference(_recordingSince!);
    setState(() => _recordingSince = null);
    String? out;
    try {
      out = await _recorder?.stop();
    } catch (_) {
      out = null;
    }
    if (!send || out == null || length < const Duration(milliseconds: 700) || !mounted) return;
    final bytes = await XFile(out).readAsBytes();
    if (!mounted) return;
    setState(() => _sending = true);
    final reply = _replyTo?.id;
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).sendDmMedia(widget.threadId,
          kind: DmKind.voice, bytes: bytes, extension: _recordExt, durationMs: length.inMilliseconds, replyTo: reply),
      onError: _cantSend,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) _replyTo = null;
    });
  }

  Future<void> _messageMenu(DmMessage m, bool mine) async {
    final l = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!m.deleted)
            ListTile(leading: const Icon(Icons.reply), title: Text(l.dmReply), onTap: () => Navigator.pop(c, 'reply')),
          if (!m.deleted && m.text.isNotEmpty)
            ListTile(leading: const Icon(Icons.copy), title: Text(l.copyText), onTap: () => Navigator.pop(c, 'copy')),
          if (mine && !m.deleted)
            ListTile(
              leading: Icon(Icons.delete_outline, color: Bua.danger),
              title: Text(l.dmDeleteForEveryone),
              onTap: () => Navigator.pop(c, 'delete'),
            ),
          if (!mine)
            ListTile(
              leading: Icon(Icons.flag_outlined, color: Bua.danger),
              title: Text(l.reportMessage),
              onTap: () => Navigator.pop(c, 'report'),
            ),
        ]),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'reply':
        setState(() => _replyTo = m);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: m.text));
        if (mounted) showSnack(context, l.copied);
      case 'delete':
        if (!await confirm(context, l.dmConfirmDelete) || !mounted) return;
        await guarded(context, () => ref.read(repositoryProvider).deleteDm(m));
      case 'report':
        await reportToAdmins(context, ref, ReportKind.message, m.id);
    }
  }

  Future<void> _memberMenu(String action, String other, String name) async {
    final l = context.l10n;
    final repo = ref.read(repositoryProvider);
    switch (action) {
      case 'report':
        await reportToAdmins(context, ref, ReportKind.member, other);
      case 'block':
        if (!await confirm(context, l.confirmBlock(name)) || !mounted) return;
        if (await guarded(context, () => repo.block(other))) {
          ref.invalidate(blockedProvider);
          if (mounted) showSnack(context, l.blockedNote(name));
        }
      case 'unblock':
        if (await guarded(context, () => repo.unblock(other))) ref.invalidate(blockedProvider);
    }
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

    final otherId = thread == null || me == null ? null : thread.otherThan(me);
    final other = otherId == null ? null : authorOf(ref, otherId);
    final relation = other?.relation(l);
    final iBlocked = otherId != null && (ref.watch(blockedProvider).value?.contains(otherId) ?? false);
    final byId = {for (final m in messages.value ?? const <DmMessage>[]) m.id: m};
    String nameOf(String userId) => userId == me ? l.you : (other?.name ?? '');

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
                      if (_otherTyping)
                        Text(l.dmTyping,
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Bua.green))
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
              onSelected: (v) => _memberMenu(v, otherId, other!.name),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'report', child: Text(l.reportMember)),
                PopupMenuItem(value: iBlocked ? 'unblock' : 'block', child: Text(iBlocked ? l.unblock : l.block)),
              ],
            ),
        ],
      ),
      body: threads.hasValue && thread == null
          ? Center(child: Text(l.conversationNotFound, style: TextStyle(color: Bua.inkSubtle)))
          : Column(children: [
              Expanded(
                child: AsyncBody(
                  value: messages,
                  onRetry: () => ref.invalidate(dmMessagesProvider(widget.threadId)),
                  builder: (list) => ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.lock_outline, size: 14, color: Bua.inkSubtle),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(l.dmPrivate,
                                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                          ),
                        ]),
                      ),
                      if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(l.startConversation,
                              textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
                        ),
                      for (final (i, m) in list.indexed) ...[
                        if (i == 0 || !DateUtils.isSameDay(list[i - 1].createdAt, m.createdAt))
                          _DayChip(m.createdAt),
                        DmBubble(
                          key: ValueKey(m.id),
                          message: m,
                          mine: m.authorId == me,
                          status: m.authorId == me && thread != null ? thread.statusOf(m.createdAt, me) : null,
                          quoted: m.replyTo == null ? null : byId[m.replyTo],
                          quotedAuthor: m.replyTo == null || byId[m.replyTo] == null ? null : nameOf(byId[m.replyTo]!.authorId),
                          onLongPress: () => _messageMenu(m, m.authorId == me),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (iBlocked)
                SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Bua.surface, border: Border(top: BorderSide(color: Bua.line))),
                    child: Column(children: [
                      Text(l.youBlocked(other?.name ?? ''),
                          textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
                      TextButton(onPressed: () => _memberMenu('unblock', otherId, other?.name ?? ''), child: Text(l.unblock)),
                    ]),
                  ),
                )
              else
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    decoration: BoxDecoration(color: Bua.surface, border: Border(top: BorderSide(color: Bua.line))),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_replyTo != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                          decoration: BoxDecoration(
                            color: Bua.ground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(left: BorderSide(color: Bua.green, width: 3)),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(l.dmReplyingTo(nameOf(_replyTo!.authorId)),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bua.green)),
                                Text(dmSummary(l, _replyTo!),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: Bua.inkMuted)),
                              ]),
                            ),
                            IconButton(
                              tooltip: l.cancel,
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _replyTo = null),
                            ),
                          ]),
                        ),
                      if (_recordingSince != null)
                        Row(children: [
                          IconButton(
                            tooltip: l.dmCancelRecording,
                            onPressed: () => _stopRecording(send: false),
                            icon: Icon(Icons.delete_outline, color: Bua.danger),
                          ),
                          Icon(Icons.fiber_manual_record, size: 14, color: Bua.danger),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(l.dmRecording(_clockOf(_recorded)),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                          IconButton.filled(
                            tooltip: l.send,
                            onPressed: () => _stopRecording(send: true),
                            icon: const Icon(Icons.send),
                          ),
                        ])
                      else
                        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          IconButton(
                            tooltip: l.dmSendPhoto,
                            onPressed: _sending ? null : _sendPhoto,
                            icon: Icon(Icons.photo_camera_outlined, color: Bua.inkMuted),
                          ),
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
                          if (_text.text.trim().isEmpty)
                            IconButton.filled(
                              tooltip: l.dmVoiceNote,
                              onPressed: _sending ? null : _startRecording,
                              icon: const Icon(Icons.mic),
                            )
                          else
                            IconButton.filled(tooltip: l.send, onPressed: _sending ? null : _send, icon: const Icon(Icons.send)),
                        ]),
                    ]),
                  ),
                ),
            ]),
    );
  }
}

String _clockOf(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Today / Yesterday / the date, between messages of different days.
class _DayChip extends StatelessWidget {
  const _DayChip(this.at);

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final label = DateUtils.isSameDay(at, now)
        ? l.today
        : DateUtils.isSameDay(at, now.subtract(const Duration(days: 1)))
            ? l.yesterday
            : l.formatDate(at);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Bua.track, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(fontSize: 12, color: Bua.inkMuted)),
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
