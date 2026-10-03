import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../l10n/l10n.dart';
import '../../models/story.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';

String languageName(AppLocalizations l, String code) => switch (code) {
      'ha' => l.hausa,
      'en' => l.english,
      _ => l.otherLanguage,
    };

String storySpeaker(WidgetRef ref, Story s) {
  final p = s.speakerId == null ? null : ref.watch(graphProvider).value?[s.speakerId!];
  return p?.displayName ?? s.speakerName ?? '';
}

/// Recorded stories from the family's elders.
class StoriesScreen extends ConsumerStatefulWidget {
  const StoriesScreen({super.key});

  @override
  ConsumerState<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends ConsumerState<StoriesScreen> {
  // Created on first play, so opening the page costs nothing.
  AudioPlayer? _player;
  String? _selectedId;
  String? _loadedId;
  bool _loading = false;
  bool _showTranscript = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _play(Story s) async {
    final player = _player ??= AudioPlayer();
    if (_loadedId == s.id) {
      player.playing ? await player.pause() : unawaited(player.play());
      return;
    }
    setState(() {
      _selectedId = s.id;
      _loading = true;
      _showTranscript = false;
    });
    final ok = await guarded(context, () async {
      await player.stop();
      await player.setUrl(await ref.read(repositoryProvider).storyAudioUrl(s.audioPath));
      _loadedId = s.id;
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) unawaited(player.play());
  }

  Future<void> _edit(Story s) async {
    final l = context.l10n;
    final v = await showFormDialog(context, title: l.editDetails, fields: [
      TextSpec('title', l.storyTitle, initial: s.title, required: true),
      TextSpec('source', l.sourceNote, initial: s.sourceNote),
      TextSpec('transcript', l.transcriptOptional, initial: s.transcript, multiline: true),
    ]);
    if (v == null || !mounted) return;
    String? opt(Object? x) => (x as String?)?.trim().isEmpty ?? true ? null : (x as String).trim();
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).updateStory(s.id, {
        'title': (v['title'] as String).trim(),
        'source_note': opt(v['source']),
        'transcript': opt(v['transcript']),
      }),
    );
    if (ok) ref.invalidate(storiesProvider);
  }

  Future<void> _delete(Story s) async {
    final l = context.l10n;
    if (!await confirm(context, l.deleteStoryConfirm) || !mounted) return;
    if (_loadedId == s.id) {
      await _player?.stop();
      _loadedId = null;
    }
    if (!mounted) return;
    final ok = await guarded(context, () => ref.read(repositoryProvider).deleteStory(s));
    if (ok) ref.invalidate(storiesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final stories = ref.watch(storiesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        titleSpacing: 0,
        toolbarHeight: 68,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.storiesTitle, style: Theme.of(context).textTheme.titleLarge),
          Text(l.storiesSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Bua.inkSubtle)),
        ]),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(storiesProvider.future),
        child: AsyncBody(
          value: stories,
          onRetry: () => ref.invalidate(storiesProvider),
          builder: (all) {
            final selected = all.where((s) => s.id == _selectedId).firstOrNull ?? all.firstOrNull;
            final others = all.where((s) => s.id != selected?.id).toList();
            return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
              if (selected != null) ...[
                _NowPlaying(
                  story: selected,
                  player: _loadedId == selected.id ? _player : null,
                  loading: _loading,
                  showTranscript: _showTranscript,
                  onPlay: () => _play(selected),
                  onTranscript: () => setState(() => _showTranscript = !_showTranscript),
                  onEdit: () => _edit(selected),
                  onDelete: () => _delete(selected),
                ),
                const SizedBox(height: 12),
              ],
              if (others.isNotEmpty) ...[
                Material(
                  color: Bua.surface,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    for (final (i, s) in others.indexed) ...[
                      if (i > 0) const InsetDivider(indent: 72),
                      _StoryRow(story: s, onTap: () => _play(s)),
                    ],
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              if (all.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(l.noStoriesYet, textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkSubtle)),
                ),
              DashedBox(
                onTap: () => context.push('/stories/new'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  child: Column(children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Bua.danger,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Bua.danger.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: const Icon(Icons.mic_none, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 14),
                    Text(l.recordStory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(l.recordHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Bua.inkMuted)),
                  ]),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _NowPlaying extends ConsumerWidget {
  const _NowPlaying({
    required this.story,
    required this.player,
    required this.loading,
    required this.showTranscript,
    required this.onPlay,
    required this.onTranscript,
    required this.onEdit,
    required this.onDelete,
  });

  final Story story;
  final AudioPlayer? player;
  final bool loading;
  final bool showTranscript;
  final VoidCallback onPlay;
  final VoidCallback onTranscript;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(profileProvider);
    final canEdit = me != null && (story.addedBy == me.id || me.isAdmin);
    final total = story.durationSeconds == null ? null : Duration(seconds: story.durationSeconds!);
    final p = player;

    Widget controls(bool playing, Duration position, Duration? duration) {
      final length = duration ?? total;
      final progress = length == null || length.inMilliseconds == 0
          ? 0.0
          : (position.inMilliseconds / length.inMilliseconds).clamp(0.0, 1.0);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          '${(playing ? l.nowPlaying : l.listen).toUpperCase()} · ${languageName(l, story.language).toUpperCase()}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: Bua.goldOnDark),
        ),
        const SizedBox(height: 10),
        Text(story.title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white, height: 1.25)),
        const SizedBox(height: 2),
        Text(
          [storySpeaker(ref, story), if (story.sourceNote?.isNotEmpty ?? false) story.sourceNote!].join(' · '),
          style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xCCFFFFFF)),
        ),
        const SizedBox(height: 14),
        _Waveform(
          seed: story.id.hashCode,
          progress: progress,
          onSeek: p == null || length == null
              ? null
              : (f) => p.seek(Duration(milliseconds: (length.inMilliseconds * f).round())),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Material(
            color: Bua.goldOnDark,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: loading ? null : onPlay,
              child: SizedBox(
                width: 52,
                height: 52,
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Bua.memorial),
                      )
                    : Icon(playing ? Icons.pause : Icons.play_arrow, color: Bua.memorial, size: 28,
                        semanticLabel: playing ? 'Pause' : l.listen),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              length == null ? clockDuration(position) : '${clockDuration(position)} / ${clockDuration(length)}',
              style: const TextStyle(fontSize: 13, color: Color(0xE6FFFFFF), fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
          if (story.transcript?.isNotEmpty ?? false)
            OutlinedButton(
              onPressed: onTranscript,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0x80FFFFFF)),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(l.transcript),
            ),
          if (canEdit)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xCCFFFFFF)),
              onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l.editDetails)),
                PopupMenuItem(value: 'delete', child: Text(l.deleteStory)),
              ],
            ),
        ]),
        if (showTranscript && (story.transcript?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(14)),
            child: Text('“${story.transcript!.trim()}”',
                style: const TextStyle(fontSize: 14, height: 1.5, fontStyle: FontStyle.italic, color: Colors.white)),
          ),
        ],
      ]);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 18),
      decoration: BoxDecoration(color: Bua.memorial, borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: p == null
            ? controls(false, Duration.zero, null)
            : StreamBuilder<PlayerState>(
                stream: p.playerStateStream,
                builder: (context, state) => StreamBuilder<Duration>(
                  stream: p.positionStream,
                  builder: (context, pos) => controls(
                    (state.data?.playing ?? false) && state.data?.processingState != ProcessingState.completed,
                    pos.data ?? Duration.zero,
                    p.duration,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Decorative sound bars; the played part is gold. Tap to jump.
class _Waveform extends StatelessWidget {
  const _Waveform({required this.seed, required this.progress, this.onSeek});

  final int seed;
  final double progress;
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final count = (c.maxWidth / 7).floor().clamp(10, 60);
      var x = seed & 0x7fffffff;
      final heights = [
        for (var i = 0; i < count; i++)
          (() {
            x = (x * 1103515245 + 12345) & 0x7fffffff;
            final wave = 0.55 + 0.35 * (i % 7 < 4 ? (i % 7) / 4 : (7 - i % 7) / 3);
            return (0.25 + 0.75 * ((x % 1000) / 1000)) * wave;
          })(),
      ];
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onSeek == null ? null : (d) => onSeek!((d.localPosition.dx / c.maxWidth).clamp(0.0, 1.0)),
        child: SizedBox(
          height: 40,
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            for (final (i, h) in heights.indexed)
              Expanded(
                child: Center(
                  child: Container(
                    width: 3.5,
                    height: 40 * h,
                    decoration: BoxDecoration(
                      color: (i + 0.5) / count <= progress ? Bua.goldOnDark : const Color(0x55FFFFFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      );
    });
  }
}

class _StoryRow extends ConsumerWidget {
  const _StoryRow({required this.story, required this.onTap});

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final meta = [
      storySpeaker(ref, story),
      if (story.durationSeconds != null) clockDuration(Duration(seconds: story.durationSeconds!)),
      languageName(l, story.language),
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: Bua.greenTint, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow, color: Bua.green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(story.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(meta, style: const TextStyle(fontSize: 13, color: Bua.inkMuted)),
            ]),
          ),
        ]),
      ),
    );
  }
}
