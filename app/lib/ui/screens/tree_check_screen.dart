import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/family_graph.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

final treeProblemsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(repositoryProvider).treeProblems());

/// Admin: links in the tree that look wrong (a man's wife who is also his
/// granddaughter, a parent younger than their child...), with a way to fix each.
class TreeCheckScreen extends ConsumerWidget {
  const TreeCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final problems = ref.watch(treeProblemsProvider);
    final graph = ref.watch(graphProvider).value;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        title: Text(l.checkTree, style: Theme.of(context).textTheme.titleMedium),
      ),
      body: AsyncBody(
        value: problems,
        onRetry: () => ref.invalidate(treeProblemsProvider),
        builder: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(treeProblemsProvider.future),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
            Text(l.checkTreeHint, style: TextStyle(fontSize: 14, color: Bua.inkMuted)),
            const SizedBox(height: 16),
            if (list.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Bua.greenTint, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Icon(Icons.check_circle_outline, color: Bua.green),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.treeLooksRight, style: TextStyle(fontSize: 15, color: Bua.greenDark))),
                ]),
              )
            else
              for (final p in list)
                if (graph != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: _ProblemCard(p, graph)),
          ]),
        ),
      ),
    );
  }
}

class _ProblemCard extends ConsumerWidget {
  const _ProblemCard(this.problem, this.graph);

  final Map<String, dynamic> problem;
  final FamilyGraph graph;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = graph[problem['a'] as String];
    final b = graph[problem['b'] as String];
    if (a == null || b == null) return const SizedBox.shrink();
    final kind = problem['kind'] as String;
    final text = switch (kind) {
      'married_in_line' => l.problemMarriedInLine(a.displayName, b.displayName),
      'parent_younger' => l.problemParentYounger(a.displayName, b.displayName),
      'born_after_death' => l.problemBornAfterDeath(a.displayName, b.displayName),
      _ => l.problemSameBirthOrder(a.displayName, b.displayName),
    };
    final unionId = problem['union_id'] as String?;
    final isLink = kind == 'parent_younger' || kind == 'born_after_death';

    Future<void> removeLink() async {
      final question = unionId != null
          ? l.confirmRemoveUnion(a.displayName, b.displayName)
          : l.confirmRemoveParent(a.displayName, b.displayName);
      if (!await confirm(context, question) || !context.mounted) return;
      final repo = ref.read(repositoryProvider);
      final ok = await guarded(
        context,
        () => unionId != null ? repo.removeUnion(unionId) : repo.removeParentChild(a.id, b.id),
      );
      if (!ok || !context.mounted) return;
      ref.invalidate(graphProvider);
      ref.invalidate(treeProblemsProvider);
      showSnack(context, l.relationshipRemoved);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.warning_amber_rounded, color: Bua.goldInk),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4))),
        ]),
        const SizedBox(height: 6),
        Wrap(alignment: WrapAlignment.end, spacing: 4, children: [
          TextButton(onPressed: () => context.push('/person/${a.id}'), child: Text(a.firstName)),
          TextButton(onPressed: () => context.push('/person/${b.id}'), child: Text(b.firstName)),
          if (unionId != null || isLink)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Bua.danger),
              onPressed: removeLink,
              icon: const Icon(Icons.link_off, size: 18),
              label: Text(l.removeLink),
            ),
        ]),
      ]),
    );
  }
}
