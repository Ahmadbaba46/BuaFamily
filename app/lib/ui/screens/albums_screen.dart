import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/person.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';

Future<void> createAlbum(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final name = TextEditingController();
  final title = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l.newAlbum),
      content: TextField(
        controller: name,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l.albumName),
        onSubmitted: (v) => Navigator.pop(c, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, name.text), child: Text(l.create)),
      ],
    ),
  );
  name.dispose();
  if (title == null || title.trim().isEmpty || !context.mounted) return;
  String? id;
  final ok = await guarded(context, () async => id = await ref.read(repositoryProvider).createAlbum(title));
  if (ok && context.mounted) {
    ref.invalidate(albumsProvider);
    context.push('/albums/$id');
  }
}

class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final albums = ref.watch(albumsProvider);
    final myPersonId = ref.watch(profileProvider)?.personId;
    final mine = myPersonId == null ? null : ref.watch(photosOfProvider(myPersonId)).value;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        title: Text(l.albums, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => createAlbum(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l.newAlbum),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(albumsProvider.future),
        child: AsyncBody(
          value: albums,
          onRetry: () => ref.invalidate(albumsProvider),
          builder: (list) => ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
            if (myPersonId != null) ...[
              Material(
                color: Bua.green,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push('/albums/of/$myPersonId'),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      const IconTile(Icons.person_pin_outlined, background: Color(0x26FFFFFF), color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.photosOfYou,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          Text(l.photosTaggedIn(mine?.length ?? 0),
                              style: const TextStyle(fontSize: 12, color: Bua.greenOnDark)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                child: Text(l.albumsEmpty,
                    textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkSubtle, height: 1.5)),
              ),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 600 ? 3 : 2;
              const gap = 12.0;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(spacing: gap, runSpacing: gap, children: [
                for (final a in list) SizedBox(width: w, child: _AlbumTile(album: a)),
              ]);
            }),
          ]),
        ),
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final years = album.minYear == null
        ? null
        : album.minYear == album.maxYear
            ? '${album.minYear}'
            : '${album.minYear} – ${album.maxYear}';
    return Material(
      color: Bua.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/albums/${album.id}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AspectRatio(
            aspectRatio: 1,
            child: album.coverPath == null
                ? const ColoredBox(
                    color: Bua.surfaceMuted,
                    child: Icon(Icons.photo_library_outlined, size: 36, color: Bua.inkSubtle),
                  )
                : StoragePhoto(album.coverPath!),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text([l.photoCount(album.photoCount), ?years].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Photos of one album, or every photo a person is tagged in.
class AlbumScreen extends ConsumerStatefulWidget {
  const AlbumScreen({super.key, this.albumId, this.personId}) : assert((albumId == null) != (personId == null));

  final String? albumId;
  final String? personId;

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final graph = ref.watch(graphProvider).value;
    final provider =
        widget.albumId != null ? albumPhotosProvider(widget.albumId!) : photosOfProvider(widget.personId!);
    final photos = ref.watch(provider);
    final album = widget.albumId == null
        ? null
        : ref.watch(albumsProvider).value?.where((a) => a.id == widget.albumId).firstOrNull;
    final person = widget.personId == null ? null : graph?[widget.personId!];
    final isMe = widget.personId != null && widget.personId == ref.watch(profileProvider)?.personId;
    final title = album?.title ?? (isMe ? l.photosOfYou : person?.displayName ?? l.photos);
    final source = widget.albumId != null ? 'album=${widget.albumId}' : 'of=${widget.personId}';

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/albums')),
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (photos.value case final list?)
            Text(
              [
                l.photoCount(list.length),
                if (widget.albumId != null && list.isNotEmpty)
                  l.addedByRelatives(list.map((p) => p.uploadedBy).toSet().length),
              ].join(' · '),
              style: const TextStyle(fontSize: 12, color: Bua.inkSubtle),
            ),
        ]),
      ),
      floatingActionButton: widget.albumId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/new-moment?album=${widget.albumId}'),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l.addPhotos),
            ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: AsyncBody(
          value: photos,
          onRetry: () => ref.invalidate(provider),
          builder: (all) {
            // People tagged most often in this album, for the filter row.
            final counts = <String, int>{};
            for (final p in all) {
              for (final id in p.people) {
                if (id != widget.personId) counts[id] = (counts[id] ?? 0) + 1;
              }
            }
            final people = (counts.keys.map((id) => graph?[id]).whereType<Person>().toList()
                  ..sort((a, b) => counts[b.id]!.compareTo(counts[a.id]!)))
                .take(12)
                .toList();
            final shown = _filter == null ? all : all.where((p) => p.people.contains(_filter)).toList();

            // Group by decade, oldest first in albums, newest first for a person.
            final groups = <int, List<Photo>>{};
            for (final p in shown) {
              groups.putIfAbsent(p.year ~/ 10 * 10, () => []).add(p);
            }
            final sorted = groups.keys.toList()..sort();
            final decades = widget.personId == null ? sorted : sorted.reversed.toList();

            return ListView(padding: const EdgeInsets.only(bottom: 96), children: [
              if (people.isNotEmpty)
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(l.everyone),
                          selected: _filter == null,
                          onSelected: (_) => setState(() => _filter = null),
                        ),
                      ),
                      for (final p in people)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: PersonAvatar(person: p, radius: 10, showPhoto: false),
                            label: Text(p.firstName),
                            selected: _filter == p.id,
                            onSelected: (_) => setState(() => _filter = _filter == p.id ? null : p.id),
                          ),
                        ),
                    ],
                  ),
                ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(child: Text(l.noPhotos, style: const TextStyle(color: Bua.inkSubtle))),
                ),
              for (final d in decades) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Text('${d}s',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Bua.inkMuted)),
                ),
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 5 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                  children: [
                    for (final p in groups[d]!)
                      Semantics(
                        button: true,
                        label: p.caption ?? '${l.photos} ${p.year}',
                        child: GestureDetector(
                          onTap: () => context.push('/photo/${p.id}?$source'),
                          child: Stack(fit: StackFit.expand, children: [
                            StoragePhoto(p.storagePath, placeholder: const Color(0xFFE8DDC8)),
                            if (p.takenYear != null)
                              Positioned(
                                left: 6,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: const Color(0xB817231B), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${p.takenYear}',
                                      style: const TextStyle(fontSize: 11, color: Colors.white)),
                                ),
                              ),
                          ]),
                        ),
                      ),
                  ],
                ),
              ],
            ]);
          },
        ),
      ),
    );
  }
}
