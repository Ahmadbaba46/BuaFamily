import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../l10n/l10n.dart';
import '../../models/messages.dart';
import '../../state/providers.dart';
import '../theme.dart';

/// One private message, WhatsApp-style: mine on the right with ticks, the
/// quoted message it replies to, a photo or voice note, or "deleted".
class DmBubble extends StatelessWidget {
  const DmBubble({
    super.key,
    required this.message,
    required this.mine,
    this.status,
    this.quoted,
    this.quotedAuthor,
    this.onLongPress,
    this.onQuoteTap,
  });

  final DmMessage message;
  final bool mine;

  /// Ticks, for my own messages.
  final MessageStatus? status;

  /// The message this one replies to, and who wrote it.
  final DmMessage? quoted;
  final String? quotedAuthor;
  final VoidCallback? onLongPress;
  final VoidCallback? onQuoteTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final m = message;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(m.createdAt));
    final footer = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(time, style: TextStyle(fontSize: 11, color: Bua.inkSubtle)),
      if (mine && status != null && !m.deleted) ...[const SizedBox(width: 3), Ticks(status!)],
    ]);

    final Widget content;
    if (m.deleted) {
      content = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.block, size: 15, color: Bua.inkSubtle),
        const SizedBox(width: 6),
        Flexible(
          child: Text(mine ? l.dmYouDeleted : l.dmDeleted,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Bua.inkSubtle)),
        ),
      ]);
    } else {
      content = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        if (m.kind == DmKind.photo && m.mediaPath != null)
          Padding(padding: const EdgeInsets.only(bottom: 4), child: DmPhoto(path: m.mediaPath!)),
        if (m.kind == DmKind.voice && m.mediaPath != null) VoiceNote(path: m.mediaPath!, durationMs: m.durationMs),
        if (m.text.isNotEmpty) Text(m.text, style: const TextStyle(fontSize: 15, height: 1.4)),
      ]);
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: EdgeInsets.fromLTRB(m.kind == DmKind.photo && !m.deleted ? 5 : 12, 6, 10, 6),
            decoration: BoxDecoration(
              color: mine ? Bua.greenTint : Bua.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(mine ? 16 : 4),
                bottomRight: Radius.circular(mine ? 4 : 16),
              ),
              border: Border.all(color: mine ? Bua.greenIndicator : Bua.line),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              if (quoted != null)
                _Quote(message: quoted!, author: quotedAuthor ?? '', mine: mine, onTap: onQuoteTap),
              Align(alignment: Alignment.centerLeft, child: content),
              const SizedBox(height: 2),
              footer,
            ]),
          ),
        ),
      ),
    );
  }
}

/// One grey tick (sent), two grey (delivered), two blue (read).
class Ticks extends StatelessWidget {
  const Ticks(this.status, {super.key});

  final MessageStatus status;

  static const readBlue = Color(0xFF34B7F1);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      label: switch (status) {
        MessageStatus.sent => l.dmSent,
        MessageStatus.delivered => l.dmDelivered,
        MessageStatus.read => l.dmRead,
      },
      child: Icon(
        status == MessageStatus.sent ? Icons.done : Icons.done_all,
        size: 16,
        color: status == MessageStatus.read ? readBlue : Bua.inkSubtle,
      ),
    );
  }
}

/// What a message is, in a line: its words, 📷 Photo, 🎤 Voice note, or deleted.
String dmSummary(AppLocalizations l, DmMessage m) {
  if (m.deleted) return l.dmDeleted;
  return switch (m.kind) {
    DmKind.photo => m.text.isEmpty ? '📷 ${l.dmPhoto}' : '📷 ${m.text}',
    DmKind.voice => '🎤 ${l.dmVoiceNote}',
    DmKind.text => m.text,
  };
}

class _Quote extends StatelessWidget {
  const _Quote({required this.message, required this.author, required this.mine, this.onTap});

  final DmMessage message;
  final String author;
  final bool mine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
        decoration: BoxDecoration(
          color: (mine ? Bua.surface : Bua.ground).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: Bua.green, width: 3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(author, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bua.green)),
          Text(dmSummary(l, message),
              maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Bua.inkMuted)),
        ]),
      ),
    );
  }
}

/// A photo in a conversation; tap to see it full screen.
class DmPhoto extends ConsumerWidget {
  const DmPhoto({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(dmMediaUrlProvider(path)).value;
    final box = SizedBox(
      width: 240,
      height: 240,
      child: url == null
          ? ColoredBox(color: Bua.track, child: Icon(Icons.image_outlined, color: Bua.inkSubtle))
          : CachedNetworkImage(
              imageUrl: url,
              cacheKey: 'dm:$path',
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => ColoredBox(color: Bua.track, child: Icon(Icons.broken_image_outlined, color: Bua.inkSubtle)),
            ),
    );
    return GestureDetector(
      onTap: url == null
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  body: Center(
                    child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url, cacheKey: 'dm:$path')),
                  ),
                ),
              )),
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: box),
    );
  }
}

String _clock(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// A voice note: play or pause, and how far along.
class VoiceNote extends ConsumerStatefulWidget {
  const VoiceNote({super.key, required this.path, this.durationMs});

  final String path;
  final int? durationMs;

  @override
  ConsumerState<VoiceNote> createState() => _VoiceNoteState();
}

class _VoiceNoteState extends ConsumerState<VoiceNote> {
  AudioPlayer? _player;
  StreamSubscription<Duration>? _pos;
  StreamSubscription<PlayerState>? _state;
  Duration _at = Duration.zero;
  bool _playing = false;
  bool _loading = false;

  Duration get _length => Duration(milliseconds: widget.durationMs ?? 0);

  @override
  void dispose() {
    _pos?.cancel();
    _state?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final player = _player;
    if (player != null) {
      _playing ? await player.pause() : await player.play();
      return;
    }
    setState(() => _loading = true);
    try {
      final p = _player = AudioPlayer();
      _pos = p.positionStream.listen((d) => mounted ? setState(() => _at = d) : null);
      _state = p.playerStateStream.listen((s) {
        if (!mounted) return;
        setState(() => _playing = s.playing && s.processingState != ProcessingState.completed);
        if (s.processingState == ProcessingState.completed) {
          p.pause();
          p.seek(Duration.zero);
        }
      });
      await p.setUrl(await ref.read(repositoryProvider).dmMediaUrl(widget.path));
      unawaited(p.play());
    } catch (_) {
      _player?.dispose();
      _player = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final total = _player?.duration ?? _length;
    final progress = total.inMilliseconds == 0 ? 0.0 : (_at.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    return SizedBox(
      width: 220,
      child: Row(children: [
        IconButton(
          tooltip: _playing ? l.pause : l.play,
          onPressed: _loading ? null : _toggle,
          icon: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 34, color: Bua.green),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: Bua.track, color: Bua.green),
            ),
            const SizedBox(height: 4),
            Text(_clock(_playing || _at > Duration.zero ? _at : total),
                style: TextStyle(fontSize: 11, color: Bua.inkSubtle)),
          ]),
        ),
      ]),
    );
  }
}
