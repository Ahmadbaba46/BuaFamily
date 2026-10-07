import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../data/repository.dart';
import '../../l10n/l10n.dart';
import '../../models/messages.dart';
import '../../models/report.dart';
import '../theme.dart';
import 'common.dart';
import 'dm_bubble.dart';
import 'emoji_panel.dart';
import 'report_sheet.dart';

/// Where a conversation's messages go: a private conversation or a group.
abstract class ChatChannel {
  Future<void> send(String body, {String? replyTo});

  Future<void> sendMedia({
    required DmKind kind,
    required Uint8List bytes,
    required String extension,
    String caption = '',
    int? durationMs,
    List<int>? waveform,
    String? replyTo,
  });

  Future<void> delete(DmMessage m);

  /// My reaction: [emoji], or none (null).
  Future<void> react(String messageId, String? emoji);

  Future<void> markRead();

  TypingSignal typing(void Function(String userId) onTyping);
}

class DmChannel implements ChatChannel {
  DmChannel(this._repo, this.threadId);

  /// Looked up when needed (not while building the screen).
  final FamilyRepository Function() _repo;
  FamilyRepository get repo => _repo();
  final String threadId;

  @override
  Future<void> send(String body, {String? replyTo}) => repo.sendDm(threadId, body, replyTo: replyTo);

  @override
  Future<void> sendMedia({
    required DmKind kind,
    required Uint8List bytes,
    required String extension,
    String caption = '',
    int? durationMs,
    List<int>? waveform,
    String? replyTo,
  }) =>
      repo.sendDmMedia(threadId,
          kind: kind,
          bytes: bytes,
          extension: extension,
          caption: caption,
          durationMs: durationMs,
          waveform: waveform,
          replyTo: replyTo);

  @override
  Future<void> delete(DmMessage m) => repo.deleteDm(m);

  @override
  Future<void> react(String messageId, String? emoji) => repo.reactDm(messageId, threadId, emoji);

  @override
  Future<void> markRead() => repo.markDmRead(threadId);

  @override
  TypingSignal typing(void Function(String userId) onTyping) => repo.dmTyping(threadId, onTyping);
}

class GroupChannel implements ChatChannel {
  GroupChannel(this._repo, this.groupId);

  /// Looked up when needed (not while building the screen).
  final FamilyRepository Function() _repo;
  FamilyRepository get repo => _repo();
  final String groupId;

  @override
  Future<void> send(String body, {String? replyTo}) => repo.sendGroup(groupId, body, replyTo: replyTo);

  @override
  Future<void> sendMedia({
    required DmKind kind,
    required Uint8List bytes,
    required String extension,
    String caption = '',
    int? durationMs,
    List<int>? waveform,
    String? replyTo,
  }) =>
      repo.sendGroupMedia(groupId,
          kind: kind,
          bytes: bytes,
          extension: extension,
          caption: caption,
          durationMs: durationMs,
          waveform: waveform,
          replyTo: replyTo);

  @override
  Future<void> delete(DmMessage m) => repo.deleteGroupMessage(m);

  @override
  Future<void> react(String messageId, String? emoji) => repo.reactGroup(messageId, groupId, emoji);

  @override
  Future<void> markRead() => repo.markGroupRead(groupId);

  @override
  TypingSignal typing(void Function(String userId) onTyping) => repo.groupTyping(groupId, onTyping);
}

/// A conversation, WhatsApp-style: the messages (newest at the bottom), and
/// a box to write with photos, voice notes, emoji and replies. Long-press a
/// message to react, copy, delete or report it; swipe it to reply.
class ChatView extends ConsumerStatefulWidget {
  const ChatView({
    super.key,
    required this.channel,
    required this.messages,
    required this.onRetry,
    required this.me,
    required this.nameOf,
    required this.appBar,
    required this.privateNote,
    this.reactions = const [],
    this.statusOf,
    this.showAuthors = false,
    this.canDelete,
    this.composer,
    this.eventText,
    this.onInfo,
    this.notFound,
    this.backTo = '/messages',
  });

  final ChatChannel channel;
  final AsyncValue<List<DmMessage>> messages;
  final VoidCallback onRetry;
  final List<DmReaction> reactions;
  final String? me;

  /// A name for each person ("You" for me).
  final String Function(String userId) nameOf;

  /// The bar on top, given who is typing right now.
  final PreferredSizeWidget Function(BuildContext context, List<String> typing) appBar;

  /// The note at the top ("Only the two of you can see these messages").
  final String privateNote;

  /// Ticks on my own messages.
  final MessageStatus? Function(DmMessage m)? statusOf;

  /// Groups: the sender's name over others' messages.
  final bool showAuthors;

  /// Who may delete a message for everyone (default: its sender).
  final bool Function(DmMessage m)? canDelete;

  /// Shown instead of the box to write (blocked; only admins send…).
  final Widget? composer;

  /// The words of a group notice ("Musa added Bello").
  final String Function(DmMessage m)? eventText;

  /// Groups: who has my message (read by, delivered to).
  final void Function(DmMessage m)? onInfo;

  /// Shown instead of everything when the conversation isn't there.
  final Widget? notFound;
  final String backTo;

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  bool _sending = false;
  int _seen = -1;

  /// The emoji panel shows in place of the keyboard.
  bool _emoji = false;

  /// The message being answered.
  DmMessage? _replyTo;

  // "typing…": who, until when.
  TypingSignal? _typing;
  final _typers = <String, Timer>{};

  // Recording a voice note.
  AudioRecorder? _recorder;
  DateTime? _recordingSince;
  Duration _recorded = Duration.zero;
  Timer? _recordTicker;
  String _recordExt = 'm4a';
  StreamSubscription<Amplitude>? _amplitude;
  final _levels = <double>[];

  ChatChannel get _channel => widget.channel;

  @override
  void initState() {
    super.initState();
    _text.addListener(() {
      if (_text.text.isNotEmpty) _typing?.typing();
      setState(() {});
    });
    _focus.addListener(() {
      if (_focus.hasFocus && _emoji) setState(() => _emoji = false);
    });
    try {
      _typing = _channel.typing((userId) {
        if (!mounted) return;
        _typers[userId]?.cancel();
        setState(() => _typers[userId] = Timer(const Duration(seconds: 4), () {
              if (mounted) setState(() => _typers.remove(userId));
            }));
      });
    } catch (_) {
      // No live connection: no "typing…", everything else works.
    }
  }

  @override
  void dispose() {
    _typing?.dispose();
    for (final t in _typers.values) {
      t.cancel();
    }
    _recordTicker?.cancel();
    _amplitude?.cancel();
    _recorder?.dispose();
    _text.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await _channel.markRead();
    } catch (_) {
      // Not important enough to bother anyone.
    }
  }

  /// Back to the newest message (the bottom of the list).
  void _toNewest() {
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  void _insertEmoji(String e) {
    final v = _text.value;
    final sel = v.selection.isValid ? v.selection : TextSelection.collapsed(offset: v.text.length);
    _text.value = TextEditingValue(
      text: v.text.replaceRange(sel.start, sel.end, e),
      selection: TextSelection.collapsed(offset: sel.start + e.length),
    );
  }

  void _toggleEmoji() {
    if (_emoji) {
      setState(() => _emoji = false);
      _focus.requestFocus();
    } else {
      _focus.unfocus();
      setState(() => _emoji = true);
    }
  }

  String? _cantSend(Object e) => e is PostgrestException && e.code == '42501' ? context.l10n.cantMessageMember : null;

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final reply = _replyTo?.id;
    final ok = await guarded(context, () => _channel.send(body, replyTo: reply), onError: _cantSend);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) {
        _text.clear();
        _replyTo = null;
      }
    });
    if (ok) _toNewest();
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
      () => _channel.sendMedia(
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
    if (ok) _toNewest();
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
    _levels.clear();
    _amplitude = rec.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((a) {
      if (mounted && _recordingSince != null) setState(() => _levels.add(levelFromDb(a.current)));
    });
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
    await _amplitude?.cancel();
    _amplitude = null;
    final waveform = compactWaveform(_levels);
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
      () => _channel.sendMedia(
          kind: DmKind.voice,
          bytes: bytes,
          extension: _recordExt,
          durationMs: length.inMilliseconds,
          waveform: waveform,
          replyTo: reply),
      onError: _cantSend,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) _replyTo = null;
    });
    if (ok) _toNewest();
  }

  bool _mayDelete(DmMessage m) => widget.canDelete?.call(m) ?? m.authorId == widget.me;

  /// Long press: react (the quick ones, or any with +), or copy, delete, report.
  Future<void> _messageMenu(DmMessage m, String? myReaction) async {
    final mine = m.authorId == widget.me;
    if (m.deleted && !mine) return;
    final l = context.l10n;
    unawaited(HapticFeedback.selectionClick());
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!m.deleted)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                for (final e in quickReactions)
                  _ReactionChoice(emoji: e, chosen: e == myReaction, onTap: () => Navigator.pop(c, 'react:$e')),
                IconButton.filledTonal(
                  tooltip: l.dmMoreReactions,
                  onPressed: () => Navigator.pop(c, 'more'),
                  icon: const Icon(Icons.add),
                ),
              ]),
            ),
          if (!m.deleted && m.text.isNotEmpty)
            ListTile(leading: const Icon(Icons.copy), title: Text(l.copyText), onTap: () => Navigator.pop(c, 'copy')),
          if (mine && !m.deleted && widget.onInfo != null)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l.groupMessageInfo),
              onTap: () => Navigator.pop(c, 'info'),
            ),
          if (_mayDelete(m) && !m.deleted)
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
    if (!mounted || choice == null) return;
    if (choice.startsWith('react:')) {
      final e = choice.substring(6);
      await _react(m, e == myReaction ? null : e);
      return;
    }
    switch (choice) {
      case 'more':
        final e = await pickEmoji(context);
        if (e != null && mounted) await _react(m, e);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: m.text));
        if (mounted) showSnack(context, l.copied);
      case 'info':
        widget.onInfo?.call(m);
      case 'delete':
        if (!await confirm(context, l.dmConfirmDelete) || !mounted) return;
        await guarded(context, () => _channel.delete(m));
      case 'report':
        await reportToAdmins(context, ref, ReportKind.message, m.id);
    }
  }

  Future<void> _react(DmMessage m, String? emoji) =>
      guarded(context, () => _channel.react(m.id, emoji), onError: _cantSend);

  /// Who reacted with what; tapping your own takes it off.
  Future<void> _showReactions(DmMessage m, List<DmReaction> list) async {
    final l = context.l10n;
    final remove = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l.dmReactions, style: Theme.of(c).textTheme.titleMedium),
          ),
          for (final r in list)
            ListTile(
              title: Text(widget.nameOf(r.userId)),
              subtitle: r.userId == widget.me ? Text(l.dmTapToRemove) : null,
              trailing: Text(r.emoji, style: const TextStyle(fontSize: 24)),
              onTap: r.userId == widget.me ? () => Navigator.pop(c, true) : null,
            ),
        ]),
      ),
    );
    if (remove == true && mounted) await _react(m, null);
  }

  Widget _bubble(DmMessage m, DmMessage? previous, Map<String, DmMessage> byId, List<DmReaction> reacts) {
    if (m.kind == DmKind.event) {
      return KeyedSubtree(key: ValueKey(m.id), child: ChatNotice(widget.eventText?.call(m) ?? ''));
    }
    final me = widget.me;
    final mine = m.authorId == me;
    final quoted = m.replyTo == null ? null : byId[m.replyTo];
    // In a group, the sender's name on the first of their messages in a row.
    final firstOfRun = previous == null || previous.authorId != m.authorId || previous.kind == DmKind.event;
    final bubble = DmBubble(
      message: m,
      mine: mine,
      status: mine ? widget.statusOf?.call(m) : null,
      author: widget.showAuthors && !mine && firstOfRun ? widget.nameOf(m.authorId) : null,
      quoted: quoted,
      quotedAuthor: quoted == null ? null : widget.nameOf(quoted.authorId),
      reactions: reacts,
      onLongPress: () => _messageMenu(m, reacts.where((r) => r.userId == me).firstOrNull?.emoji),
      onReactionsTap: () => _showReactions(m, reacts),
    );
    if (m.deleted) return KeyedSubtree(key: ValueKey(m.id), child: bubble);
    return SwipeToReply(
      key: ValueKey(m.id),
      onReply: () {
        unawaited(HapticFeedback.selectionClick());
        setState(() => _replyTo = m);
        if (!_emoji) _focus.requestFocus();
      },
      child: bubble,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final messages = widget.messages;
    final reactions = <String, List<DmReaction>>{};
    for (final r in widget.reactions) {
      (reactions[r.messageId] ??= []).add(r);
    }

    // Read as soon as something new shows.
    final count = messages.value?.length ?? -1;
    if (count != _seen && messages.hasValue) {
      _seen = count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _markRead();
      });
    }
    final byId = {for (final m in messages.value ?? const <DmMessage>[]) m.id: m};

    return PopScope(
      canPop: !_emoji,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _emoji = false);
      },
      child: Scaffold(
        appBar: widget.appBar(context, _typers.keys.toList()),
        body: widget.notFound ??
            Column(children: [
              Expanded(
                child: AsyncBody(
                  value: messages,
                  onRetry: widget.onRetry,
                  // Newest at the bottom, drawn from the bottom up: it opens on the
                  // last message and the keyboard pushes the messages up.
                  builder: (list) {
                    final items = <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.lock_outline, size: 14, color: Bua.inkSubtle),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(widget.privateNote,
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
                        if (i == 0 || !DateUtils.isSameDay(list[i - 1].createdAt, m.createdAt)) _DayChip(m.createdAt),
                        _bubble(
                          m,
                          i == 0 || !DateUtils.isSameDay(list[i - 1].createdAt, m.createdAt) ? null : list[i - 1],
                          byId,
                          reactions[m.id] ?? const [],
                        ),
                      ],
                    ];
                    return ListView(
                      controller: _scroll,
                      reverse: true,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      children: items.reversed.toList(),
                    );
                  },
                ),
              ),
              widget.composer ?? _composer(l),
            ]),
      ),
    );
  }

  Widget _composer(AppLocalizations l) => SafeArea(
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
                      Text(l.dmReplyingTo(widget.nameOf(_replyTo!.authorId)),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bua.green)),
                      Text(dmSummary(l, _replyTo!),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Bua.inkMuted)),
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
                Text(_clockOf(_recorded),
                    semanticsLabel: l.dmRecording(_clockOf(_recorded)),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                Expanded(
                  child: VoiceWave(
                    levels: [
                      for (var i = 0; i < 36; i++)
                        (() {
                          final k = _levels.length - 36 + i;
                          return k < 0 ? 0 : (_levels[k] * 100).round();
                        })(),
                    ],
                    progress: 1,
                    played: Bua.danger,
                  ),
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
                IconButton(
                  tooltip: _emoji ? l.dmKeyboard : l.dmEmoji,
                  onPressed: _toggleEmoji,
                  icon: Icon(_emoji ? Icons.keyboard_outlined : Icons.emoji_emotions_outlined, color: Bua.inkMuted),
                ),
                Expanded(
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
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
            if (_emoji && _recordingSince == null) EmojiPanel(onPick: _insertEmoji),
          ]),
        ),
      );
}

/// A bar at the bottom in place of the box to write: why you can't, and
/// perhaps a button.
class ChatComposerNote extends StatelessWidget {
  const ChatComposerNote({super.key, required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Bua.surface, border: Border(top: BorderSide(color: Bua.line))),
          child: Column(children: [
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
            ?action,
          ]),
        ),
      );
}

/// A line in the middle of a conversation: a group notice.
class ChatNotice extends StatelessWidget {
  const ChatNotice(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Bua.track.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
          child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Bua.inkMuted)),
        ),
      );
}

String _clockOf(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

class _ReactionChoice extends StatelessWidget {
  const _ReactionChoice({required this.emoji, required this.chosen, required this.onTap});

  final String emoji;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(shape: BoxShape.circle, color: chosen ? Bua.greenTint : null),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}

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
