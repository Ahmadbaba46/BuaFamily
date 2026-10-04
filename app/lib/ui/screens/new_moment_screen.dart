import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/social.dart';
import '../../state/prefs.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';

/// Share a moment: text, photos, tagged relatives and an optional album.
class NewMomentScreen extends ConsumerStatefulWidget {
  const NewMomentScreen({super.key, this.albumId, this.tagPersonId, this.text});

  final String? albumId;
  final String? tagPersonId;

  /// Starting words, e.g. an Eid greeting.
  final String? text;

  @override
  ConsumerState<NewMomentScreen> createState() => _NewMomentScreenState();
}

class _NewMomentScreenState extends ConsumerState<NewMomentScreen> {
  late final _body = TextEditingController(text: widget.text);
  final _images = <PickedImage>[];
  late final List<String> _people = [?widget.tagPersonId];
  late String? _albumId = widget.albumId;
  bool _saving = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    try {
      final picked = await pickImages(shrink: ref.read(devicePrefsProvider).shrinkUploads);
      if (picked.isNotEmpty) setState(() => _images.addAll(picked));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _tag() async {
    final graph = ref.read(graphProvider).value;
    if (graph == null) return;
    final p = await pickPerson(context, graph, exclude: _people.toSet());
    if (p != null) setState(() => _people.add(p.id));
  }

  Future<void> _post() async {
    final l = context.l10n;
    if (_body.text.trim().isEmpty && _images.isEmpty) {
      showSnack(context, l.postEmptyError);
      return;
    }
    setState(() => _saving = true);
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).createPost(
            body: _body.text,
            albumId: _images.isEmpty ? null : _albumId,
            people: _people,
            images: _images,
          ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ref.invalidate(feedProvider);
      ref.invalidate(albumsProvider);
      if (_albumId != null) ref.invalidate(albumPhotosProvider(_albumId!));
      context.canPop() ? context.pop() : context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider);
    final graph = ref.watch(graphProvider).value;
    final me = profile?.personId == null ? null : graph?[profile!.personId!];
    final familyName = ref.watch(settingsProvider).value?.familyName ?? 'Bua';
    final albums = ref.watch(albumsProvider).value ?? const <Album>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.close,
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(l.shareAMoment, style: Theme.of(context).textTheme.titleMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _post,
              style: FilledButton.styleFrom(minimumSize: const Size(72, 40)),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.post),
            ),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        Row(children: [
          if (me != null) PersonAvatar(person: me) else AuthorAvatar(authorOf(ref, profile?.id ?? '')),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(me?.displayName ?? profile?.displayName ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Row(children: [
                const Icon(Icons.lock_outline, size: 13, color: Bua.inkSubtle),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(l.onlyFamilyCanSee(familyName),
                      style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                ),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        TextField(
          controller: _body,
          minLines: 4,
          maxLines: 10,
          autofocus: widget.albumId == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l.whatsHappening),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (i, img) in _images.indexed)
            _Thumb(
              bytes: Uint8List.fromList(img.bytes),
              label: '${l.removePhoto} ${i + 1}',
              onRemove: () => setState(() => _images.removeAt(i)),
            ),
          SizedBox(
            width: 96,
            height: 96,
            child: OutlinedButton(
              onPressed: _addPhotos,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: Bua.lineStrong),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_photo_alternate_outlined),
                const SizedBox(height: 4),
                Text(l.addPhotos, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        Text(l.whosInIt, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Bua.inkMuted)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final id in _people)
            if (graph?[id] != null)
              PersonChip(person: graph![id]!, onRemove: () => setState(() => _people.remove(id))),
          AddChip(icon: Icons.person_add_alt, label: l.tagFamily, onTap: _tag),
        ]),
        if (_images.isNotEmpty) ...[
          const SizedBox(height: 18),
          LabeledField(
            label: l.alsoAddToAlbum,
            child: DropdownButtonFormField<String?>(
              initialValue: albums.any((a) => a.id == _albumId) ? _albumId : null,
              items: [
                for (final a in albums) DropdownMenuItem(value: a.id, child: Text(a.title)),
                DropdownMenuItem(value: null, child: Text(l.dontAddToAlbum)),
              ],
              onChanged: (v) => setState(() => _albumId = v),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(children: [
          const Icon(Icons.data_saver_on_outlined, size: 16, color: Bua.inkSubtle),
          const SizedBox(width: 8),
          Expanded(child: Text(l.dataSaverNote, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle))),
        ]),
      ]),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.bytes, required this.label, required this.onRemove});

  final Uint8List bytes;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(fit: StackFit.expand, children: [
        ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(bytes, fit: BoxFit.cover)),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: const Color(0xB817231B),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: Semantics(
                label: label,
                button: true,
                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 16, color: Colors.white)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
