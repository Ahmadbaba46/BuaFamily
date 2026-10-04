import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';

/// Full-screen photo with its caption, tagged people, likes and memories.
/// Swipes through the photos of the album, post or person it was opened from.
class PhotoScreen extends ConsumerStatefulWidget {
  const PhotoScreen({super.key, required this.photoId, this.albumId, this.postId, this.personId});

  final String photoId;
  final String? albumId;
  final String? postId;
  final String? personId;

  @override
  ConsumerState<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends ConsumerState<PhotoScreen> {
  PageController? _pages;
  int _index = 0;

  /// Details over the photo: a slim bar, or open with tags and likes. The
  /// photo always keeps the whole screen.
  bool _detailsOpen = false;

  /// Tap the photo to hide everything but it.
  bool _chrome = true;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  AsyncValue<List<Photo>> _photos() {
    if (widget.albumId != null) return ref.watch(albumPhotosProvider(widget.albumId!));
    if (widget.personId != null) return ref.watch(photosOfProvider(widget.personId!));
    return ref
        .watch(feedProvider)
        .whenData((posts) => posts.where((p) => p.id == widget.postId).firstOrNull?.photos ?? const <Photo>[]);
  }

  void _reload() {
    if (widget.albumId != null) ref.invalidate(albumPhotosProvider(widget.albumId!));
    if (widget.personId != null) ref.invalidate(photosOfProvider(widget.personId!));
    ref.invalidate(feedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final photos = _photos();
    final list = photos.value ?? const <Photo>[];
    if (_pages == null && list.isNotEmpty) {
      _index = list.indexWhere((p) => p.id == widget.photoId).clamp(0, list.length - 1);
      _pages = PageController(initialPage: _index);
    }
    final current = list.isEmpty ? null : list[_index.clamp(0, list.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFF101712),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          opacity: _chrome ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(
            ignoring: !_chrome,
            child: AppBar(
              backgroundColor: const Color(0x99101712),
              foregroundColor: Colors.white,
              leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
              centerTitle: true,
              title: list.length > 1
                  ? Text(
                      l.photoXofY(_index + 1, list.length),
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                    )
                  : null,
              actions: [if (current != null) _PhotoMenu(photo: current, onChanged: _reload)],
            ),
          ),
        ),
      ),
      body: photos.isLoading && list.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : current == null
          ? Center(
              child: Text(l.noPhotos, style: const TextStyle(color: Colors.white70)),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _chrome = !_chrome),
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: list.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) => InteractiveViewer(
                        maxScale: 4,
                        child: StoragePhoto(list[i].storagePath, fit: BoxFit.contain, placeholder: Colors.transparent),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedSlide(
                    offset: _chrome ? Offset.zero : const Offset(0, 1),
                    duration: const Duration(milliseconds: 200),
                    child: _PhotoDetails(
                      photo: current,
                      onChanged: _reload,
                      open: _detailsOpen,
                      onOpen: (v) => setState(() => _detailsOpen = v),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PhotoMenu extends ConsumerWidget {
  const _PhotoMenu({required this.photo, required this.onChanged});

  final Photo photo;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider);
    final canEdit = photo.uploadedBy == profile?.id || (profile?.isAdmin ?? false);
    if (!canEdit) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) async {
        final repo = ref.read(repositoryProvider);
        if (v == 'edit') {
          final changed = await _editPhoto(context, photo);
          if (changed == null || !context.mounted) return;
          if (await guarded(context, () => repo.updatePhoto(photo.id, caption: changed.$1, takenYear: changed.$2))) {
            onChanged();
          }
        } else if (v == 'delete') {
          if (!await confirm(context, l.confirmDeletePhoto) || !context.mounted) return;
          if (await guarded(context, () => repo.deletePhoto(photo))) {
            onChanged();
            ref.invalidate(albumsProvider);
            if (context.mounted) context.pop();
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'edit', child: Text(l.editDetails)),
        PopupMenuItem(value: 'delete', child: Text(l.deletePhoto)),
      ],
    );
  }
}

Future<(String?, int?)?> _editPhoto(BuildContext context, Photo photo) {
  final l = context.l10n;
  final caption = TextEditingController(text: photo.caption);
  final year = TextEditingController(text: photo.takenYear?.toString());
  return showDialog<(String?, int?)>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l.editDetails),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: caption,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(labelText: l.caption),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: year,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.yearTaken),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            final y = int.tryParse(year.text.trim());
            Navigator.pop(c, (caption.text.trim().isEmpty ? null : caption.text.trim(), y));
          },
          child: Text(l.save),
        ),
      ],
    ),
  );
}

class _PhotoDetails extends ConsumerWidget {
  const _PhotoDetails({required this.photo, required this.onChanged, required this.open, required this.onOpen});

  final Photo photo;
  final VoidCallback onChanged;

  /// Showing everything; otherwise one slim line over the photo.
  final bool open;
  final ValueChanged<bool> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final graph = ref.watch(graphProvider).value;
    final profile = ref.watch(profileProvider);
    final uploader = authorOf(ref, photo.uploadedBy);
    final album = photo.albumId == null
        ? null
        : ref.watch(albumsProvider).value?.where((a) => a.id == photo.albumId).firstOrNull;

    // Swipe up to open, down to close.
    void drag(DragEndDetails d) {
      final v = d.primaryVelocity ?? 0;
      if (v < -200) onOpen(true);
      if (v > 200) onOpen(false);
    }

    if (!open) {
      final summary = photo.caption?.trim().isNotEmpty ?? false ? photo.caption!.trim() : l.addedBy(uploader.name);
      return GestureDetector(
        onVerticalDragEnd: drag,
        onTap: () => onOpen(true),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00101712), Color(0xCC101712)],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, height: 1.35, color: Colors.white),
                    ),
                  ),
                  for (final (icon, n) in [
                    (Icons.sell_outlined, photo.people.length),
                    (Icons.favorite_border, photo.likeCount),
                    (Icons.chat_bubble_outline, photo.commentCount),
                  ])
                    if (n > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 16, color: Colors.white70),
                            const SizedBox(width: 3),
                            Text('$n', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                  IconButton(
                    tooltip: l.showDetails,
                    onPressed: () => onOpen(true),
                    icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
      decoration: const BoxDecoration(
        color: Bua.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onVerticalDragEnd: drag,
            onTap: () => onOpen(false),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Spacer(),
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(color: Bua.lineStrong, borderRadius: BorderRadius.circular(2)),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: l.hideDetails,
                      onPressed: () => onOpen(false),
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (photo.caption != null) ...[
                      Text(photo.caption!, style: const TextStyle(fontSize: 15, height: 1.45)),
                      const SizedBox(height: 4),
                    ],
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: l.addedBy(uploader.name)),
                          if (photo.takenYear != null) TextSpan(text: ' · ${photo.takenYear}'),
                          if (album != null) ...[
                            const TextSpan(text: ' · '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () => context.push('/albums/${album.id}'),
                                child: Text(
                                  album.title,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Bua.green),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      style: const TextStyle(fontSize: 12, color: Bua.inkSubtle),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.inThisPhoto.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: Bua.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final id in photo.people)
                          if (graph?[id] case final p?)
                            PersonChip(
                              person: p,
                              onTap: () => context.push('/person/${p.id}'),
                              // Who may untag: whoever tagged, the person themselves, or an admin.
                              onRemove:
                                  !(photo.taggedBy[id] == profile?.id ||
                                      id == profile?.personId ||
                                      (profile?.isAdmin ?? false))
                                  ? null
                                  : () async {
                                      if (await guarded(
                                        context,
                                        () => ref.read(repositoryProvider).untagPhoto(photo.id, id),
                                      )) {
                                        onChanged();
                                      }
                                    },
                            ),
                        AddChip(
                          icon: Icons.person_add_alt,
                          label: l.tagSomeone,
                          onTap: () async {
                            if (graph == null) return;
                            final p = await pickPerson(context, graph, exclude: photo.people.toSet());
                            if (p == null || !context.mounted) return;
                            if (await guarded(context, () => ref.read(repositoryProvider).tagPhoto(photo.id, p.id))) {
                              onChanged();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LikeButton(target: Target.photo(photo.id), count: photo.likeCount),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: CommentButton(
                            label: l.memoriesCount(photo.commentCount),
                            onTap: () async {
                              await showComments(
                                context,
                                Target.photo(photo.id),
                                title: l.memoriesCount(photo.commentCount),
                              );
                              onChanged();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
