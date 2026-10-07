import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../l10n/l10n.dart';
import '../../models/messages.dart';
import '../../services/media_store.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'emoji_panel.dart';

/// One private message, WhatsApp-style: as wide as its words (up to a limit),
/// the time and ticks tucked in at the end, the message it replies to, a photo
/// or voice note, reactions underneath, or "deleted".
class DmBubble extends StatelessWidget {
  const DmBubble({
    super.key,
    required this.message,
    required this.mine,
    this.status,
    this.author,
    this.quoted,
    this.quotedAuthor,
    this.reactions = const [],
    this.onLongPress,
    this.onQuoteTap,
    this.onReactionsTap,
  });

  final DmMessage message;
  final bool mine;

  /// Ticks, for my own messages.
  final MessageStatus? status;

  /// In a group, who sent it (over the first of their messages in a row).
  final String? author;

  /// The message this one replies to, and who wrote it.
  final DmMessage? quoted;
  final String? quotedAuthor;
  final List<DmReaction> reactions;
  final VoidCallback? onLongPress;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onReactionsTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final m = message;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(m.createdAt));
    final showTicks = mine && status != null && !m.deleted;
    final footer = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(time, style: TextStyle(fontSize: 11, color: Bua.inkSubtle)),
        if (showTicks) ...[const SizedBox(width: 3), Ticks(status!)],
      ],
    );
    // Room kept at the end of the last line for the time (as on WhatsApp).
    final painter = TextPainter(
      text: TextSpan(text: time, style: DefaultTextStyle.of(context).style.merge(const TextStyle(fontSize: 11))),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final timeWidth = painter.width;
    painter.dispose();
    final footerRoom = timeWidth + (showTicks ? 19 : 0) + 8;
    final big = !m.deleted && m.kind == DmKind.text && isBigEmoji(m.text);

    Widget withTime(Widget text) => Stack(
      children: [
        text,
        Positioned(right: 0, bottom: 0, child: footer),
      ],
    );

    Widget words(String text, {TextStyle? style}) => withTime(
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text),
            WidgetSpan(child: SizedBox(width: footerRoom, height: 14)),
          ],
        ),
        style: style ?? const TextStyle(fontSize: 15, height: 1.35),
      ),
    );

    final List<Widget> content;
    if (m.deleted) {
      content = [
        words(
          mine ? l.dmYouDeleted : l.dmDeleted,
          style: TextStyle(fontSize: 14, height: 1.35, fontStyle: FontStyle.italic, color: Bua.inkSubtle),
        ),
      ];
    } else if (big) {
      content = [
        Text(m.text, style: const TextStyle(fontSize: 46, height: 1.15)),
        Align(alignment: Alignment.centerRight, child: footer),
      ];
    } else {
      content = [
        if (m.kind == DmKind.photo && m.mediaPath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: DmPhoto(path: m.mediaPath!),
          ),
        if (m.kind == DmKind.voice && m.mediaPath != null)
          VoiceNote(path: m.mediaPath!, durationMs: m.durationMs, waveform: m.waveform, seed: m.id.hashCode),
        if (m.text.isNotEmpty) words(m.text) else Align(alignment: Alignment.centerRight, child: footer),
      ];
    }

    final maxWidth = math.min(MediaQuery.sizeOf(context).width * 0.8, 420.0);
    final bubble = Container(
      padding: big
          ? const EdgeInsets.fromLTRB(4, 0, 4, 2)
          : EdgeInsets.fromLTRB(m.kind == DmKind.photo && !m.deleted ? 4 : 10, 6, m.kind == DmKind.photo ? 4 : 8, 5),
      decoration: big
          ? null
          : BoxDecoration(
              color: mine ? Bua.greenTint : Bua.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(mine ? 14 : 4),
                bottomRight: Radius.circular(mine ? 4 : 14),
              ),
              border: Border.all(color: mine ? Bua.greenIndicator : Bua.line),
            ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (author != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(author!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: authorColor(author!))),
            ),
          if (quoted != null) _Quote(message: quoted!, author: quotedAuthor ?? '', mine: mine, onTap: onQuoteTap),
            ...content,
          ],
        ),
      ),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            // The reactions overlap the bubble's bottom edge, inside the stack
            // so they can be tapped.
            child: Stack(
              children: [
                Padding(padding: EdgeInsets.only(bottom: reactions.isEmpty ? 0 : 18), child: bubble),
                if (reactions.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    right: mine ? 8 : null,
                    left: mine ? null : 8,
                    child: ReactionsPill(reactions: reactions, onTap: onReactionsTap),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A steady colour for each sender's name in a group, as on WhatsApp.
Color authorColor(String name) {
  const colors = [
    Color(0xFF1F7A4D),
    Color(0xFF9C4A1A),
    Color(0xFF2F5FA8),
    Color(0xFF8A3B8F),
    Color(0xFFA23B4F),
    Color(0xFF34707A),
    Color(0xFF7A6A1F),
  ];
  return colors[name.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) & 0xffff) % colors.length];
}

/// The emoji under a message, most used first, with how many.
class ReactionsPill extends StatelessWidget {
  const ReactionsPill({super.key, required this.reactions, this.onTap});

  final List<DmReaction> reactions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final r in reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    final emojis = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Bua.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Bua.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emojis.take(3).join(), style: const TextStyle(fontSize: 14)),
            if (reactions.length > 1) ...[
              const SizedBox(width: 3),
              Text('${reactions.length}', style: TextStyle(fontSize: 12, color: Bua.inkMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Drag a message sideways to answer it (as on WhatsApp).
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({super.key, required this.child, required this.onReply});

  final Widget child;
  final VoidCallback onReply;

  static const trigger = 64.0;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  late final AnimationController _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))
    ..addListener(() => setState(() => _dx = _from * (1 - _back.value)));
  double _dx = 0;
  double _from = 0;
  bool _fired = false;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _end() {
    if (_dx >= SwipeToReply.trigger) widget.onReply();
    _from = _dx;
    _fired = false;
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dx / SwipeToReply.trigger).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (d) {
        _back.stop();
        setState(() => _dx = (_dx + d.delta.dx).clamp(0.0, SwipeToReply.trigger * 1.4));
        if (!_fired && _dx >= SwipeToReply.trigger) _fired = true;
      },
      onHorizontalDragEnd: (_) => _end(),
      onHorizontalDragCancel: _end,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_dx > 4)
            Positioned(
              left: 4,
              child: Opacity(
                opacity: progress,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Bua.track,
                  child: Icon(Icons.reply, size: 18, color: progress >= 1 ? Bua.green : Bua.inkSubtle),
                ),
              ),
            ),
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        ],
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
    DmKind.text || DmKind.event => m.text,
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
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
        decoration: BoxDecoration(
          color: (mine ? Bua.surface : Bua.ground).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: Bua.green, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              author,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bua.green),
            ),
            Text(
              dmSummary(l, message),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Bua.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// A photo in a conversation (kept on the phone once seen); tap for full screen.
class DmPhoto extends ConsumerWidget {
  const DmPhoto({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final photo = ref.watch(dmMediaProvider(path));
    final Widget child = switch (photo) {
      AsyncData(:final value) => Image.memory(value, width: 240, fit: BoxFit.cover, gaplessPlayback: true),
      AsyncError() => InkWell(
        onTap: () => ref.invalidate(dmMediaProvider(path)),
        child: SizedBox(
          width: 240,
          height: 180,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, color: Bua.inkSubtle),
              Text(l.retry, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
            ],
          ),
        ),
      ),
      _ => SizedBox(
        width: 240,
        height: 180,
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
    };
    return GestureDetector(
      onTap: photo.value == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  body: Center(child: InteractiveViewer(child: Image.memory(photo.value!))),
                ),
              ),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ColoredBox(
          color: Bua.track,
          child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 320), child: child),
        ),
      ),
    );
  }
}

String _clock(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// The bars of a voice note: measured levels, or (for older notes) a steady
/// made-up shape. The played part is green; tap or drag to jump.
class VoiceWave extends StatelessWidget {
  const VoiceWave({super.key, required this.levels, required this.progress, this.onSeek, this.played});

  /// 0–100 each.
  final List<int> levels;
  final double progress;
  final ValueChanged<double>? onSeek;
  final Color? played;

  static List<int> madeUp(int seed, {int bars = 40}) {
    var x = seed & 0x7fffffff;
    return [
      for (var i = 0; i < bars; i++)
        (() {
          x = (x * 1103515245 + 12345) & 0x7fffffff;
          final wave = 0.55 + 0.35 * (i % 7 < 4 ? (i % 7) / 4 : (7 - i % 7) / 3);
          return ((0.25 + 0.75 * ((x % 1000) / 1000)) * wave * 100).round();
        })(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Not a LayoutBuilder: the bubble sizes itself to its content.
    void seek(Offset p) {
      final width = context.size?.width ?? 0;
      if (width > 0) onSeek?.call((p.dx / width).clamp(0.0, 1.0));
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onSeek == null ? null : (d) => seek(d.localPosition),
      onHorizontalDragUpdate: onSeek == null ? null : (d) => seek(d.localPosition),
      child: SizedBox(
        height: 30,
        child: Row(
          children: [
            for (final (i, v) in levels.indexed)
              Expanded(
                child: Center(
                  child: Container(
                    width: 2.6,
                    height: 4 + 24 * (v.clamp(0, 100) / 100),
                    decoration: BoxDecoration(
                      color: (i + 0.5) / levels.length <= progress
                          ? (played ?? Bua.green)
                          : Bua.inkSubtle.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A voice note: play or pause, its waveform, and how long it is.
class VoiceNote extends ConsumerStatefulWidget {
  const VoiceNote({super.key, required this.path, this.durationMs, this.waveform, this.seed = 0});

  final String path;
  final int? durationMs;
  final List<int>? waveform;
  final int seed;

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
  late final List<int> _levels = (widget.waveform?.isNotEmpty ?? false)
      ? widget.waveform!
      : VoiceWave.madeUp(widget.seed);

  Duration get _length => _player?.duration ?? Duration(milliseconds: widget.durationMs ?? 0);

  @override
  void dispose() {
    _pos?.cancel();
    _state?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<AudioPlayer?> _load() async {
    if (_player != null) return _player;
    setState(() => _loading = true);
    try {
      final p = AudioPlayer();
      final repo = ref.read(repositoryProvider);
      if (kIsWeb) {
        await p.setUrl(await repo.dmMediaUrl(widget.path));
      } else {
        // Played from the copy on the phone (downloaded once).
        var file = await MediaStore.instance.file(widget.path);
        if (file == null) {
          await repo.dmMediaBytes(widget.path);
          file = await MediaStore.instance.file(widget.path);
        }
        file == null ? await p.setUrl(await repo.dmMediaUrl(widget.path)) : await p.setFilePath(file.path);
      }
      _pos = p.positionStream.listen((d) => mounted ? setState(() => _at = d) : null);
      _state = p.playerStateStream.listen((s) {
        if (!mounted) return;
        setState(() => _playing = s.playing && s.processingState != ProcessingState.completed);
        if (s.processingState == ProcessingState.completed) {
          p.pause();
          p.seek(Duration.zero);
        }
      });
      return _player = p;
    } catch (_) {
      if (mounted) showSnackSafe(context);
      return null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    final p = await _load();
    if (p == null) return;
    _playing ? await p.pause() : unawaited(p.play());
  }

  Future<void> _seek(double f) async {
    final p = await _load();
    if (p == null) return;
    await p.seek(_length * f);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final total = _length;
    final progress = total.inMilliseconds == 0 ? 0.0 : (_at.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    return SizedBox(
      width: 236,
      child: Row(
        children: [
          IconButton(
            tooltip: _playing ? l.pause : l.play,
            onPressed: _loading ? null : _toggle,
            icon: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 32, color: Bua.green),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                VoiceWave(levels: _levels, progress: progress, onSeek: _seek),
                Text(
                  _clock(_playing || _at > Duration.zero ? _at : total),
                  style: TextStyle(fontSize: 11, color: Bua.inkSubtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showSnackSafe(BuildContext context) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(context.l10n.dmCantPlay)));
}
