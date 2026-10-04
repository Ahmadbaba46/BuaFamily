import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/person.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/hero_page.dart';
import '../widgets/social.dart';

String _sexKey(Sex s) => switch (s) {
      Sex.male => 'male',
      Sex.female => 'female',
      Sex.unknown => 'other',
    };

/// Memorial page for someone who has died: life story, photos, prayers and
/// memories, and an optional yearly reminder.
class MemorialScreen extends ConsumerWidget {
  const MemorialScreen({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final graph = ref.watch(graphProvider);
    final p = graph.value?[personId];
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: graph.isLoading ? const Center(child: CircularProgressIndicator()) : Center(child: Text(l.noResults)),
      );
    }
    final photos = ref.watch(photosOfProvider(personId)).value ?? const <Photo>[];
    final dates = [
      if (p.birthDate != null) l.formatDate(p.birthDate!, approx: p.birthDateApprox),
      if (p.deathDate != null) l.formatDate(p.deathDate!, approx: p.deathDateApprox),
    ].join(' – ');
    final sex = _sexKey(p.sex);

    return Scaffold(
      body: HeroPage(
        title: p.displayName,
        color: Bua.memorial,
        bandHeight: 330,
        onBack: () => context.canPop() ? context.pop() : context.go('/person/$personId'),
        child: ListView(padding: EdgeInsets.zero, children: [
        PatternBand(
          height: 330,
          color: Bua.memorial,
          child: SafeArea(
            bottom: false,
            child: Stack(children: [
              Positioned(
                left: 4,
                top: 4,
                child: BackButton(
                  color: Colors.white,
                  onPressed: () => context.canPop() ? context.pop() : context.go('/person/$personId'),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(l.inLovingMemory.toUpperCase(),
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Bua.goldOnDark)),
                    const SizedBox(height: 14),
                    PersonAvatar(person: p, radius: 44, gapColor: Bua.memorial),
                    const SizedBox(height: 12),
                    Text(p.displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                    if (dates.isNotEmpty)
                      Text(dates, style: const TextStyle(fontSize: 14, color: Color(0xFFD7DED9))),
                    const SizedBox(height: 8),
                    Text(l.memorialPrayer(sex),
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Bua.goldOnDark)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SectionCard(title: l.lifeOf(sex), padding: const EdgeInsets.fromLTRB(0, 6, 0, 6), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  (p.biography?.trim().isNotEmpty ?? false) ? p.biography!.trim() : l.noLifeStory,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: (p.biography?.trim().isNotEmpty ?? false) ? Bua.inkBody : Bua.inkSubtle,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextButton(
                    onPressed: () => context.push('/person/$personId'),
                    child: Text(l.seeFullProfile),
                  ),
                ),
              ),
            ]),
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SectionCard(
                title: l.photos,
                trailing: TextButton(
                  onPressed: () => context.push('/albums/of/$personId'),
                  child: Text(l.allPhotos(photos.length)),
                ),
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      for (final (i, ph) in photos.take(3).indexed) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/photo/${ph.id}?of=$personId'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: StoragePhoto(ph.storagePath, placeholder: const Color(0xFFE8DDC8)),
                              ),
                            ),
                          ),
                        ),
                      ],
                      for (var i = photos.length; i < 3; i++) ...[const SizedBox(width: 6), const Spacer()],
                    ]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _Memories(personId: personId),
            if (p.deathDate != null && !p.deathDateApprox) ...[
              const SizedBox(height: 12),
              _ReminderToggle(personId: personId, deathDate: p.deathDate!),
            ],
          ]),
        ),
      ]),
      ),
    );
  }
}

class _Memories extends ConsumerStatefulWidget {
  const _Memories({required this.personId});

  final String personId;

  @override
  ConsumerState<_Memories> createState() => _MemoriesState();
}

class _MemoriesState extends ConsumerState<_Memories> {
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
    final ok = await guarded(context, () => ref.read(repositoryProvider).addMemory(widget.personId, body));
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _text.clear();
      ref.invalidate(memoriesProvider(widget.personId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final memories = ref.watch(memoriesProvider(widget.personId));
    final rows = memories.value ?? const <Memory>[];
    final me = ref.watch(profileProvider);

    return SectionCard(
      title: l.prayersMemories(rows.length),
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (memories.isLoading && rows.isEmpty)
              const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))
            else if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l.noMemoriesYet, style: TextStyle(color: Bua.inkSubtle)),
              ),
            for (final m in rows)
              _MemoryRow(memory: m, canDelete: m.authorId == me?.id || (me?.isAdmin ?? false)),
            const SizedBox(height: 8),
            TextField(
              controller: _text,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: l.addPrayerMemory,
                suffixIcon: IconButton(
                  tooltip: l.send,
                  onPressed: _sending ? null : _send,
                  icon: Icon(Icons.send, color: Bua.green),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _MemoryRow extends ConsumerWidget {
  const _MemoryRow({required this.memory, required this.canDelete});

  final Memory memory;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final author = authorOf(ref, memory.authorId);
    final now = DateTime.now();
    final when = now.difference(memory.createdAt).inDays < 7 ? l.ago(memory.createdAt) : l.formatDate(memory.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AuthorAvatar(author, radius: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '${author.name} ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: memory.body),
              ]),
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),
            Text(when, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
          ]),
        ),
        if (canDelete)
          IconButton(
            tooltip: l.delete,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 18, color: Bua.inkSubtle),
            onPressed: () async {
              if (await guarded(context, () => ref.read(repositoryProvider).deleteMemory(memory.id))) {
                ref.invalidate(memoriesProvider(memory.personId));
              }
            },
          ),
      ]),
    );
  }
}

class _ReminderToggle extends ConsumerWidget {
  const _ReminderToggle({required this.personId, required this.deathDate});

  final String personId;
  final DateTime deathDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final on = ref.watch(remembranceReminderProvider(personId)).value ?? false;
    final day = l.localeName == 'ha'
        ? l.formatDate(DateTime(2000, deathDate.month, deathDate.day)).replaceAll(', 2000', '')
        : DateFormat('d MMMM', 'en').format(deathDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: ToggleRow(
        title: l.remindMeEvery(day),
        subtitle: l.remindMeEverySub,
        value: on,
        onChanged: (v) async {
          if (await guarded(context, () => ref.read(repositoryProvider).setRemembranceReminder(personId, v))) {
            ref.invalidate(remembranceReminderProvider(personId));
          }
        },
      ),
    );
  }
}
