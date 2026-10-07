import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/khatm.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';

/// Quran khatms: the 30 juz shared out among the family.
class KhatmsScreen extends ConsumerWidget {
  const KhatmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final khatms = ref.watch(khatmsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        title: Text(l.khatmTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/khatm/new'),
        icon: const Icon(Icons.add),
        label: Text(l.startKhatm),
      ),
      body: AsyncBody(
        value: khatms,
        onRetry: () => ref.invalidate(khatmsProvider),
        builder: (all) {
          final open = all.where((k) => k.open).toList();
          final done = all.where((k) => k.complete).toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(khatmsProvider.future),
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
              Text(l.khatmIntro, style: TextStyle(fontSize: 13, height: 1.45, color: Bua.inkMuted)),
              const SizedBox(height: 12),
              if (open.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(children: [
                    Icon(Icons.menu_book_outlined, size: 44, color: Bua.inkSubtle),
                    const SizedBox(height: 8),
                    Text(l.noKhatmsYet, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
                  ]),
                ),
              for (final k in open) ...[KhatmCard(khatm: k), const SizedBox(height: 10)],
              if (done.isNotEmpty) ...[
                Padding(padding: const EdgeInsets.fromLTRB(4, 16, 4, 8), child: GroupHeading(l.khatmsCompleted)),
                for (final k in done) ...[KhatmCard(khatm: k), const SizedBox(height: 10)],
              ],
            ]),
          );
        },
      ),
    );
  }
}

/// One khatm in a list: what it's for and how far along.
class KhatmCard extends ConsumerWidget {
  const KhatmCard({super.key, required this.khatm});

  final Khatm khatm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final k = khatm;
    final me = ref.watch(profileProvider)?.id;
    final mine = k.partsOf(me);
    final person = k.personId == null ? null : ref.watch(graphProvider).value?[k.personId!];
    return Material(
      color: Bua.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/khatm/${k.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              if (person != null) ...[PersonAvatar(person: person, radius: 18), const SizedBox(width: 10)],
              Expanded(child: Text(k.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              if (k.complete) Pill(l.khatmComplete, icon: Icons.check),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: k.readCount / Khatm.juzCount,
                minHeight: 8,
                backgroundColor: Bua.track,
                color: Bua.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              [
                l.khatmProgress(k.readCount, k.takenCount),
                if (k.open && k.dueOn != null) l.khatmDue(l.formatDate(k.dueOn!)),
                if (mine.isNotEmpty) l.khatmYourJuz(mine.map((p) => p.juz).join(', ')),
              ].join(' · '),
              style: TextStyle(fontSize: 13, color: Bua.inkSubtle),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A khatm: the 30 juz, who has each, and taking or reading one.
class KhatmScreen extends ConsumerWidget {
  const KhatmScreen({super.key, required this.khatmId});

  final String khatmId;

  Future<void> _act(BuildContext context, WidgetRef ref, Future<void> Function() action, {String? done}) async {
    final ok = await guarded(context, action);
    if (!ok) return;
    ref.invalidate(khatmsProvider);
    if (done != null && context.mounted) showSnack(context, done);
  }

  Future<void> _tapJuz(BuildContext context, WidgetRef ref, Khatm k, KhatmPart part, String? me, bool manage) async {
    final l = context.l10n;
    final repo = ref.read(repositoryProvider);
    if (!k.open) return;
    if (!part.taken) {
      if (await confirm(context, l.khatmTakeConfirm(part.juz)) && context.mounted) {
        await _act(context, ref, () => repo.takeJuz(k.id, juz: part.juz), done: l.khatmTaken(part.juz));
      }
      return;
    }
    final mine = part.userId == me;
    if (!mine && !manage) return;
    final reader = authorOf(ref, part.userId!).name;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(mine ? l.juzNumber(part.juz) : l.juzOf(part.juz, reader),
                style: Theme.of(c).textTheme.titleMedium),
          ),
          if (!part.done)
            ListTile(
              leading: Icon(Icons.check_circle_outline, color: Bua.green),
              title: Text(mine ? l.khatmMarkRead : l.khatmMarkReadFor(reader)),
              onTap: () => Navigator.pop(c, 'read'),
            )
          else
            ListTile(
              leading: const Icon(Icons.undo),
              title: Text(l.khatmMarkUnread),
              onTap: () => Navigator.pop(c, 'unread'),
            ),
          if (!part.done)
            ListTile(
              leading: const Icon(Icons.reply_outlined),
              title: Text(mine ? l.khatmGiveBack : l.khatmFree),
              onTap: () => Navigator.pop(c, 'release'),
            ),
        ]),
      ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case 'read':
        await _act(context, ref, () => repo.markJuzRead(k.id, part.juz), done: l.khatmReadThanks);
      case 'unread':
        await _act(context, ref, () => repo.markJuzRead(k.id, part.juz, read: false));
      case 'release':
        await _act(context, ref, () => repo.releaseJuz(k.id, part.juz));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final all = ref.watch(khatmsProvider);
    final profile = ref.watch(profileProvider);
    final me = profile?.id;
    final k = all.value?.where((x) => x.id == khatmId).firstOrNull;
    final manage = k != null && (k.createdBy == me || (profile?.isAdmin ?? false));
    final person = k?.personId == null ? null : ref.watch(graphProvider).value?[k!.personId!];

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/khatm')),
        title: Text(l.khatmTitle),
        actions: [
          if (k != null && k.open && manage)
            PopupMenuButton<String>(
              onSelected: (_) async {
                if (!await confirm(context, l.khatmCancelConfirm) || !context.mounted) return;
                await _act(context, ref, () => ref.read(repositoryProvider).cancelKhatm(k.id));
                if (context.mounted) context.canPop() ? context.pop() : context.go('/khatm');
              },
              itemBuilder: (_) => [PopupMenuItem(value: 'cancel', child: Text(l.khatmCancel))],
            ),
        ],
      ),
      body: k == null
          ? AsyncBody(
              value: all,
              onRetry: () => ref.invalidate(khatmsProvider),
              builder: (_) => Center(child: Text(l.noResults, style: TextStyle(color: Bua.inkSubtle))),
            )
          : RefreshIndicator(
              onRefresh: () => ref.refresh(khatmsProvider.future),
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
                SectionCard(padding: const EdgeInsets.all(16), children: [
                  Row(children: [
                    if (person != null) ...[PersonAvatar(person: person, radius: 24), const SizedBox(width: 12)],
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(k.title, style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          [
                            l.khatmStartedBy(authorOf(ref, k.createdBy ?? '').name, l.formatDate(k.createdAt)),
                            if (k.dueOn != null && k.open) l.khatmDue(l.formatDate(k.dueOn!)),
                          ].join(' · '),
                          style: TextStyle(fontSize: 12, color: Bua.inkSubtle),
                        ),
                      ]),
                    ),
                  ]),
                  if (k.note?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 10),
                    Text(k.note!, style: TextStyle(fontSize: 14, height: 1.5, color: Bua.inkBody)),
                  ],
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: k.readCount / Khatm.juzCount,
                      minHeight: 10,
                      backgroundColor: Bua.track,
                      color: Bua.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    k.complete
                        ? l.khatmCompleteOn(l.formatDate(k.completedAt!))
                        : k.cancelled
                            ? l.khatmCancelled
                            : l.khatmProgress(k.readCount, k.takenCount),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: k.complete ? Bua.green : Bua.inkMuted),
                  ),
                  if (k.open && k.freeCount > 0) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      onPressed: () async {
                        int? taken;
                        final ok = await guarded(context, () async => taken = await ref.read(repositoryProvider).takeJuz(k.id));
                        if (!ok) return;
                        ref.invalidate(khatmsProvider);
                        if (context.mounted && taken != null) showSnack(context, l.khatmTaken(taken!));
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l.khatmTakeNext),
                    ),
                  ],
                ]),
                const SizedBox(height: 12),
                _Legend(),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (var j = 1; j <= Khatm.juzCount; j++)
                      _JuzTile(
                        part: k.part(j),
                        mine: k.part(j).userId != null && k.part(j).userId == me,
                        reader: k.part(j).userId == null ? null : authorOf(ref, k.part(j).userId!).name,
                        onTap: () => _tapJuz(context, ref, k, k.part(j), me, manage),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (k.readers.isNotEmpty)
                  SectionCard(title: l.khatmReaders(k.readers.length), padding: const EdgeInsets.fromLTRB(16, 6, 16, 12), children: [
                    for (final e in k.readers.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Expanded(child: Text(authorOf(ref, e.key).name, style: const TextStyle(fontSize: 14))),
                          Text(
                            k.partsOf(e.key).map((p) => p.done ? '${p.juz} ✓' : '${p.juz}').join(', '),
                            style: TextStyle(fontSize: 13, color: Bua.inkSubtle),
                          ),
                        ]),
                      ),
                  ]),
              ]),
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget item(Color fill, Color? border, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(4),
              border: border == null ? null : Border.all(color: border),
            ),
          ),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: Bua.inkMuted)),
        ]);
    return Wrap(spacing: 14, runSpacing: 6, children: [
      item(Bua.surface, Bua.line, l.juzFree),
      item(Bua.goldTint, null, l.juzTaken),
      item(Bua.green, null, l.juzRead),
    ]);
  }
}

class _JuzTile extends StatelessWidget {
  const _JuzTile({required this.part, required this.mine, required this.reader, required this.onTap});

  final KhatmPart part;
  final bool mine;
  final String? reader;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fill = part.done ? Bua.green : (part.taken ? Bua.goldTint : Bua.surface);
    final ink = part.done ? Colors.white : (part.taken ? Bua.goldInk : Bua.ink);
    final label = reader == null ? l.juzFree : (mine ? l.you : reader!.split(' ').first);
    return Semantics(
      button: true,
      label: [l.juzNumber(part.juz), ?reader, if (part.done) l.juzRead].join(', '),
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: mine ? Border.all(color: Bua.green, width: 2) : (part.taken ? null : Border.all(color: Bua.line)),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${part.juz}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ink)),
                if (part.done) ...[const SizedBox(width: 2), Icon(Icons.check, size: 14, color: ink)],
              ]),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: part.done ? Colors.white : Bua.inkSubtle)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Starting a khatm, perhaps for a relative who has passed.
class NewKhatmScreen extends ConsumerStatefulWidget {
  const NewKhatmScreen({super.key, this.personId});

  final String? personId;

  @override
  ConsumerState<NewKhatmScreen> createState() => _NewKhatmScreenState();
}

class _NewKhatmScreenState extends ConsumerState<NewKhatmScreen> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  late String? _personId = widget.personId;
  late KhatmPurpose _purpose = KhatmPurpose.memorial;
  DateTime? _due;
  bool _saving = false;

  /// The name is suggested from the person once the family tree has loaded.
  bool _suggested = false;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (_title.text.trim().isEmpty) return showSnack(context, l.khatmNeedsTitle);
    setState(() => _saving = true);
    String? id;
    final ok = await guarded(
      context,
      () async => id = await ref.read(repositoryProvider).startKhatm(
            title: _title.text,
            purpose: _purpose,
            personId: _personId,
            note: _note.text,
            dueOn: _due,
          ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok && id != null) {
      ref.invalidate(khatmsProvider);
      context.pushReplacement('/khatm/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final graph = ref.watch(graphProvider).value;
    final person = _personId == null ? null : graph?[_personId!];
    if (!_suggested && person != null) {
      _suggested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _title.text.isEmpty) _title.text = l.khatmForName(person.displayName);
      });
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.startKhatm)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SectionCard(padding: const EdgeInsets.all(16), children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in KhatmPurpose.values)
              ChoiceChip(
                label: Text(switch (p) {
                  KhatmPurpose.memorial => l.khatmForLate,
                  KhatmPurpose.occasion => l.khatmForOccasion,
                  KhatmPurpose.other => l.khatmForOther,
                }),
                selected: _purpose == p,
                onSelected: (_) => setState(() => _purpose = p),
              ),
          ]),
          const SizedBox(height: 14),
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: person == null ? const Icon(Icons.person_outline) : PersonAvatar(person: person, radius: 18),
              title: Text(person?.displayName ?? l.khatmChoosePerson),
              subtitle: Text(l.khatmPersonHint),
              trailing: person == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      tooltip: l.clear,
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _personId = null),
                    ),
              onTap: graph == null
                  ? null
                  : () async {
                      final p = await pickPerson(context, graph);
                      if (p == null || !mounted) return;
                      setState(() => _personId = p.id);
                      if (_title.text.isEmpty) _title.text = l.khatmForName(p.displayName);
                    },
            ),
          ),
          const SizedBox(height: 8),
          LabeledField(
            label: l.khatmName,
            child: TextField(controller: _title, maxLength: 200, decoration: InputDecoration(hintText: l.khatmNameHint)),
          ),
          const SizedBox(height: 8),
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(_due == null ? l.khatmNoDue : l.khatmDue(l.formatDate(_due!))),
              subtitle: Text(l.khatmDueHint),
              trailing: _due == null
                  ? null
                  : IconButton(tooltip: l.clear, icon: const Icon(Icons.clear), onPressed: () => setState(() => _due = null)),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _due ?? now.add(const Duration(days: 7)),
                  firstDate: now,
                  lastDate: DateTime(now.year + 1, now.month, now.day),
                );
                if (d != null) setState(() => _due = d);
              },
            ),
          ),
          const SizedBox(height: 8),
          LabeledField(
            label: l.khatmNote,
            child: TextField(controller: _note, maxLines: 3, maxLength: 2000, decoration: InputDecoration(hintText: l.khatmNoteHint)),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: _saving ? null : _save,
            child: Text(l.startKhatm),
          ),
          const SizedBox(height: 8),
          Text(l.khatmEveryoneTold, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
        ]),
      ]),
    );
  }
}
