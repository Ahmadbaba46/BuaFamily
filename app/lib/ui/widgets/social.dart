import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/kinship.dart';
import '../../l10n/l10n.dart';
import '../../models/family_graph.dart';
import '../../models/person.dart';
import '../../models/report.dart';
import '../../models/social.dart';
import '../../state/prefs.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'bua.dart';
import 'common.dart';
import 'report_sheet.dart';
import 'share_sheet.dart';

/// Picks photos from the device, resized to save data unless [shrink] is off.
Future<List<PickedImage>> pickImages({bool shrink = true}) async {
  final files = shrink
      ? await ImagePicker().pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 80)
      : await ImagePicker().pickMultiImage();
  return [
    for (final f in files)
      PickedImage(await f.readAsBytes(), f.name.contains('.') ? f.name.split('.').last : 'jpg'),
  ];
}

/// An image from the private photos bucket, with a tinted placeholder.
/// With the data saver on, it loads only when tapped.
class StoragePhoto extends ConsumerStatefulWidget {
  const StoragePhoto(this.path, {super.key, this.fit = BoxFit.cover, this.placeholder = const Color(0xFFD9E4DA)});

  final String path;
  final BoxFit fit;
  final Color placeholder;

  @override
  ConsumerState<StoragePhoto> createState() => _StoragePhotoState();
}

class _StoragePhotoState extends ConsumerState<StoragePhoto> {
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    final saver = ref.watch(devicePrefsProvider.select((p) => p.tapToLoadPhotos));
    if (saver && !_requested) {
      return Semantics(
        button: true,
        label: context.l10n.tapToLoad,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _requested = true),
          child: ColoredBox(
            color: widget.placeholder,
            child: Center(child: Icon(Icons.download_for_offline_outlined, color: Bua.inkMuted)),
          ),
        ),
      );
    }
    final url = ref.watch(photoUrlProvider(widget.path)).value;
    final image = cachedPhoto(widget.path, url);
    return ColoredBox(
      color: widget.placeholder,
      child: image == null
          ? const SizedBox.expand()
          : Image(
              image: image,
              fit: widget.fit,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, _, _) => Center(child: Icon(Icons.broken_image_outlined, color: Bua.inkSubtle)),
            ),
    );
  }
}

/// Name, linked person and relation of an author, resolved once per build.
class Author {
  Author(this.member, FamilyGraph? graph, String? myPersonId)
      : person = member?.personId == null ? null : graph?[member!.personId!],
        _graph = graph,
        _me = myPersonId;

  final Member? member;
  final Person? person;
  final FamilyGraph? _graph;
  final String? _me;

  String get name => person?.displayName ?? member?.displayName ?? '';

  /// "Your brother", or null when unrelated / unknown / yourself.
  String? relation(AppLocalizations l) {
    if (person == null || _me == null || _graph == null || person!.id == _me) return null;
    final k = kinshipOf(_graph, _me, person!.id);
    if (k.type == KinType.none) return null;
    return l.kinshipToYou(k);
  }
}

Author authorOf(WidgetRef ref, String userId) {
  final members = ref.watch(membersProvider).value;
  return Author(members?[userId], ref.watch(graphProvider).value, ref.watch(profileProvider)?.personId);
}

class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar(this.author, {super.key, this.radius = 20});

  final Author author;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (author.person != null) return PersonAvatar(person: author.person!, radius: radius);
    final initials = author.name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2).map((s) => s[0]);
    return CircleAvatar(
      radius: radius,
      backgroundColor: Bua.unknownBg,
      child: Text(initials.join().toUpperCase(),
          style: TextStyle(color: Bua.unknownFg, fontWeight: FontWeight.w700, fontSize: radius * 0.66)),
    );
  }
}

/// "Ma sha Allah · 24", toggled optimistically.
class LikeButton extends ConsumerStatefulWidget {
  const LikeButton({super.key, required this.target, required this.count, this.expand = true});

  final Target target;
  final int count;
  final bool expand;

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton> {
  bool? _liked;
  int _delta = 0;

  @override
  void didUpdateWidget(LikeButton old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) {
      _liked = null;
      _delta = 0;
    }
  }

  Future<void> _toggle(bool liked) async {
    setState(() {
      _liked = !liked;
      _delta += liked ? -1 : 1;
    });
    try {
      await ref.read(repositoryProvider).setLiked(widget.target, !liked);
      ref.invalidate(myLikesProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = liked;
        _delta += liked ? 1 : -1;
      });
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liked = _liked ?? (ref.watch(myLikesProvider).value?.contains(widget.target.id) ?? false);
    final count = widget.count + _delta;
    final l = context.l10n;
    return Semantics(
      toggled: liked,
      child: _ActionButton(
        icon: liked ? Icons.favorite : Icons.favorite_border,
        label: count > 0 ? '${l.maShaAllah} · $count' : l.maShaAllah,
        active: liked,
        onTap: () => _toggle(liked),
      ),
    );
  }
}

class CommentButton extends StatelessWidget {
  const CommentButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      _ActionButton(icon: Icons.chat_bubble_outline, label: label, onTap: onTap);
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.active = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Bua.greenTint : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: active ? Bua.greenDark : Bua.inkMuted),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: active ? Bua.greenDark : Bua.inkMuted)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Comments (or memories / wishes) in a bottom sheet.
Future<void> showComments(BuildContext context, Target target, {String? title, String? hint}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Bua.ground,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title ?? context.l10n.comments, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(child: CommentThread(target: target, hint: hint, scrollable: true)),
        ]),
      ),
    ),
  );
}

/// List of comments with a box to add one. Used in sheets and on event pages.
class CommentThread extends ConsumerStatefulWidget {
  const CommentThread({super.key, required this.target, this.hint, this.scrollable = false});

  final Target target;
  final String? hint;
  final bool scrollable;

  @override
  ConsumerState<CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends ConsumerState<CommentThread> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await guarded(context, () => ref.read(repositoryProvider).addComment(widget.target, body));
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _text.clear();
      ref.invalidate(commentsProvider(widget.target));
      ref.invalidate(feedProvider);
      ref.invalidate(eventsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final comments = ref.watch(commentsProvider(widget.target));
    final me = ref.watch(profileProvider);
    final rows = comments.value ?? const <Comment>[];

    final list = <Widget>[
      if (comments.isLoading && rows.isEmpty)
        const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
      else if (rows.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(l.noCommentsYet, style: TextStyle(color: Bua.inkSubtle)),
        ),
      for (final c in rows)
        _CommentRow(comment: c, mine: c.authorId == me?.id, canDelete: c.authorId == me?.id || (me?.isAdmin ?? false)),
    ];
    final input = Padding(
      padding: EdgeInsets.only(top: 8, bottom: widget.scrollable ? MediaQuery.viewInsetsOf(context).bottom + 12 : 0),
      child: TextField(
        controller: _text,
        minLines: 1,
        maxLines: 4,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _send(),
        decoration: InputDecoration(
          hintText: widget.hint ?? l.writeComment,
          suffixIcon: IconButton(
            tooltip: l.send,
            onPressed: _sending ? null : _send,
            icon: Icon(Icons.send, color: Bua.green),
          ),
        ),
      ),
    );
    if (widget.scrollable) {
      return Column(children: [Expanded(child: ListView(children: list)), input]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...list, input]);
  }
}

class _CommentRow extends ConsumerWidget {
  const _CommentRow({required this.comment, required this.mine, required this.canDelete});

  final Comment comment;
  final bool mine;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final author = authorOf(ref, comment.authorId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AuthorAvatar(author, radius: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(author.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                Text(l.ago(comment.createdAt), style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
              ]),
              const SizedBox(height: 2),
              Text(comment.body, style: const TextStyle(fontSize: 14, height: 1.4)),
            ]),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: l.commentOptions,
          padding: EdgeInsets.zero,
          icon: Icon(Icons.more_vert, size: 18, color: Bua.inkSubtle),
          onSelected: (v) async {
            if (v == 'report') return reportToAdmins(context, ref, ReportKind.comment, comment.id);
            final ok = await guarded(context, () => ref.read(repositoryProvider).deleteComment(comment.id));
            if (ok) {
              ref.invalidate(commentsProvider);
              ref.invalidate(feedProvider);
            }
          },
          itemBuilder: (_) => [
            if (!mine) PopupMenuItem(value: 'report', child: Text(l.reportAction)),
            if (canDelete) PopupMenuItem(value: 'delete', child: Text(l.delete)),
          ],
        ),
      ]),
    );
  }
}

/// A moment or announcement in the feed.
class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final author = authorOf(ref, post.authorId);
    final graph = ref.watch(graphProvider).value;
    final profile = ref.watch(profileProvider);
    final isAdmin = profile?.isAdmin ?? false;
    final canDelete = post.authorId == profile?.id || isAdmin;
    final relation = author.relation(l);
    final addedToAlbum = post.body.isEmpty && post.albumId != null && post.photos.isNotEmpty;

    final meta = <InlineSpan>[
      if (addedToAlbum) ...[
        TextSpan(text: '${l.addedPhotosTo(post.photos.length)} '),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => context.push('/albums/${post.albumId}'),
            child: Text(post.albumTitle ?? '',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Bua.green)),
          ),
        ),
        TextSpan(text: ' · ${l.ago(post.createdAt)}'),
      ] else
        TextSpan(text: [?relation, l.ago(post.createdAt)].join(' · ')),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 10),
          child: Row(children: [
            GestureDetector(
              onTap: author.person == null ? null : () => context.push('/person/${author.person!.id}'),
              child: AuthorAvatar(author),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(author.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text.rich(TextSpan(children: meta), style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
              ]),
            ),
            PopupMenuButton<String>(
                tooltip: l.postOptions,
                icon: Icon(Icons.more_horiz, color: Bua.inkMuted),
                onSelected: (v) async {
                  final repo = ref.read(repositoryProvider);
                  if (v == 'share') {
                    await showShareSheet(context,
                        link: shareLink('post', post.id, lang: Localizations.localeOf(context).languageCode));
                  } else if (v == 'pin') {
                    if (await guarded(context, () => repo.setPinned(postId: post.id, pinned: !post.pinned))) {
                      ref.invalidate(feedProvider);
                    }
                  } else if (v == 'report') {
                    await reportToAdmins(context, ref, ReportKind.post, post.id);
                  } else if (v == 'delete') {
                    if (!await confirm(context, l.confirmDeletePost) || !context.mounted) return;
                    if (await guarded(context, () => repo.deletePost(post))) {
                      ref.invalidate(feedProvider);
                      ref.invalidate(albumsProvider);
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'share', child: Text(l.shareLabel)),
                  if (isAdmin) PopupMenuItem(value: 'pin', child: Text(post.pinned ? l.unpin : l.pinToHome)),
                  if (post.authorId != profile?.id) PopupMenuItem(value: 'report', child: Text(l.reportAction)),
                  if (canDelete) PopupMenuItem(value: 'delete', child: Text(l.deletePost)),
                ],
              ),
          ]),
        ),
        if (post.kind == PostKind.announcement)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Pill(l.announcement, icon: Icons.campaign_outlined, background: Bua.goldTint, color: Bua.goldInk),
            ),
          ),
        if (post.body.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(post.body, style: const TextStyle(fontSize: 15, height: 1.5)),
          ),
        if (post.photos.isNotEmpty) _PostPhotos(post: post, graph: graph),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(children: [
            Expanded(child: LikeButton(target: Target.post(post.id), count: post.likeCount)),
            const SizedBox(width: 4),
            Expanded(
              child: CommentButton(
                label: l.commentsCount(post.commentCount),
                onTap: () => showComments(context, Target.post(post.id)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _PostPhotos extends StatelessWidget {
  const _PostPhotos({required this.post, required this.graph});

  final Post post;
  final FamilyGraph? graph;

  @override
  Widget build(BuildContext context) {
    final photos = post.photos;
    void open(Photo p) => context.push('/photo/${p.id}?post=${post.id}');

    if (photos.length == 1) {
      final names = post.people.map((id) => graph?[id]?.firstName).whereType<String>().toList();
      return GestureDetector(
        onTap: () => open(photos.first),
        child: SizedBox(
          height: 260,
          child: Stack(fit: StackFit.expand, children: [
            StoragePhoto(photos.first.storagePath),
            if (names.isNotEmpty)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: const Color(0xB817231B), borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(names.join(', '),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
              ),
          ]),
        ),
      );
    }

    final shown = photos.length == 2 ? photos : photos.take(3).toList();
    final extra = photos.length - shown.length;
    return SizedBox(
      height: photos.length == 2 ? 180 : 120,
      child: Row(children: [
        for (final (i, p) in shown.indexed) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: GestureDetector(
              onTap: () => open(p),
              child: Stack(fit: StackFit.expand, children: [
                StoragePhoto(p.storagePath),
                if (extra > 0 && i == shown.length - 1)
                  ColoredBox(
                    color: const Color(0x9917231B),
                    child: Center(
                      child: Text('+$extra',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

/// Removable chip for a tagged person.
class PersonChip extends StatelessWidget {
  const PersonChip({super.key, required this.person, this.onRemove, this.onTap});

  final Person person;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Bua.surfaceMuted,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, 4, onRemove == null ? 12 : 2, 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            PersonAvatar(person: person, radius: 13, showPhoto: false),
            const SizedBox(width: 8),
            Text(person.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (onRemove != null)
              IconButton(
                tooltip: context.l10n.untag,
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                onPressed: onRemove,
                icon: Icon(Icons.close, color: Bua.inkMuted),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Dashed-looking outlined button used for "Tag family", "Add photos".
class AddChip extends StatelessWidget {
  const AddChip({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: Bua.lineStrong),
      ),
    );
  }
}

/// Gold card for pinned announcements and events on Home.
class PinnedCard extends StatelessWidget {
  const PinnedCard({
    super.key,
    required this.icon,
    required this.label,
    required this.title,
    required this.meta,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String title;
  final String meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Bua.goldTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Bua.goldLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconTile(icon, background: Bua.surface, color: Bua.goldInk),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bua.goldInk)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.35)),
                const SizedBox(height: 2),
                Text(meta, style: TextStyle(fontSize: 12, color: Bua.goldInkDark)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
