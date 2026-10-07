import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/duplicates.dart';
import '../../l10n/l10n.dart';
import '../../models/family_graph.dart';
import '../../models/person.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';

final notDuplicatesProvider =
    FutureProvider.autoDispose<Set<(String, String)>>((ref) => ref.watch(repositoryProvider).notDuplicates());

String duplicateReasonLabel(AppLocalizations l, DuplicateReason r) => switch (r) {
      DuplicateReason.sameName => l.dupSameName,
      DuplicateReason.similarName => l.dupSimilarName,
      DuplicateReason.sameParents => l.dupSameParents,
      DuplicateReason.sameSpouse => l.dupSameSpouse,
      DuplicateReason.sameBirthYear => l.dupSameBirthYear,
      DuplicateReason.sameLastName => l.dupSameLastName,
    };

/// Admin: people who may be in the tree twice, to merge or to mark as different.
class DuplicatesScreen extends ConsumerWidget {
  const DuplicatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final graph = ref.watch(graphProvider);
    final notDup = ref.watch(notDuplicatesProvider);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        title: Text(l.duplicatesTitle),
      ),
      body: AsyncBody(
        value: graph,
        onRetry: () => ref.invalidate(graphProvider),
        builder: (g) {
          final pairs = findDuplicates(g, notDuplicates: notDup.value ?? const {});
          return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
            Text(l.duplicatesIntro, style: TextStyle(fontSize: 13, height: 1.45, color: Bua.inkMuted)),
            const SizedBox(height: 12),
            if (pairs.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Bua.greenTint, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Icon(Icons.check_circle_outline, color: Bua.green),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.noDuplicates, style: TextStyle(fontSize: 15, color: Bua.greenDark))),
                ]),
              ),
            for (final p in pairs) ...[_PairCard(pair: p, graph: g), const SizedBox(height: 10)],
          ]);
        },
      ),
    );
  }
}

class _PairCard extends ConsumerWidget {
  const _PairCard({required this.pair, required this.graph});

  final DuplicatePair pair;
  final FamilyGraph graph;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final r in pair.reasons) Pill(duplicateReasonLabel(l, r)),
        ]),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: PersonFacts(person: pair.a, graph: graph)),
            VerticalDivider(width: 20, color: Bua.line),
            Expanded(child: PersonFacts(person: pair.b, graph: graph)),
          ]),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
          TextButton(
            onPressed: () async {
              final ok = await guarded(context, () => ref.read(repositoryProvider).markNotDuplicate(pair.a.id, pair.b.id));
              if (ok) ref.invalidate(notDuplicatesProvider);
            },
            child: Text(l.notTheSamePerson),
          ),
          FilledButton.icon(
            onPressed: () => mergeTwo(context, ref, pair.a, pair.b),
            icon: const Icon(Icons.merge, size: 18),
            label: Text(l.mergeAction),
          ),
        ]),
      ]),
    );
  }
}

/// What helps tell two records apart: dates, parents, spouses, children, account.
class PersonFacts extends ConsumerWidget {
  const PersonFacts({super.key, required this.person, required this.graph});

  final Person person;
  final FamilyGraph graph;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = person;
    final parents = graph.parentsOf(p.id);
    final spouses = graph.spousesOf(p.id);
    final kids = graph.childrenOf(p.id).length;
    final account = ref.watch(profilesProvider).value?.any((a) => a.personId == p.id) ?? false;
    final life = p.lifespan(approxPrefix: l.approxPrefix());
    Widget line(String text) => Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(text, style: TextStyle(fontSize: 12.5, height: 1.35, color: Bua.inkMuted)),
        );
    return InkWell(
      onTap: () => context.push('/person/${p.id}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PersonAvatar(person: p, radius: 22),
        const SizedBox(height: 6),
        Text(p.displayName, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
        if (life.isNotEmpty) line(life),
        if (p.birthPlace?.isNotEmpty ?? false) line(p.birthPlace!),
        if (parents.isNotEmpty) line(l.parentsNames(parents.map((x) => x.firstName).join(' & '))),
        if (spouses.isNotEmpty) line('${l.spouses}: ${spouses.map((x) => x.firstName).join(', ')}'),
        line(l.childCountShort(kids)),
        if (account) line(l.hasAccount),
      ]),
    );
  }
}

/// Asks which of the two to keep, then merges the other into it.
Future<void> mergeTwo(BuildContext context, WidgetRef ref, Person a, Person b) async {
  final l = context.l10n;
  final graph = ref.read(graphProvider).value;
  if (graph == null) return;
  final keep = await showDialog<Person>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l.mergeWhichToKeep),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.mergeExplain, style: TextStyle(fontSize: 13, height: 1.45, color: Bua.inkMuted)),
          const SizedBox(height: 12),
          for (final p in [a, b])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(12), alignment: Alignment.centerLeft),
                onPressed: () => Navigator.pop(c, p),
                child: Row(children: [
                  PersonAvatar(person: p, radius: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l.keepPerson(p.displayName))),
                ]),
              ),
            ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel))],
    ),
  );
  if (keep == null || !context.mounted) return;
  final remove = keep.id == a.id ? b : a;
  final ok = await guarded(context, () => ref.read(repositoryProvider).mergePersons(keepId: keep.id, removeId: remove.id));
  if (!ok) return;
  ref.invalidate(graphProvider);
  ref.invalidate(profilesProvider);
  if (context.mounted) showSnack(context, l.mergedNote(remove.displayName, keep.displayName));
}
