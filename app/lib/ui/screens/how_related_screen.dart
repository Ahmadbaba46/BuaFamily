import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/kinship.dart';
import '../../domain/relation_path.dart';
import '../../l10n/l10n.dart';
import '../../models/family_graph.dart';
import '../../models/person.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

String _sexKey(Sex s) => switch (s) {
      Sex.male => 'male',
      Sex.female => 'female',
      Sex.unknown => 'other',
    };

/// Pick two people and see how they are related, step by step.
class HowRelatedScreen extends ConsumerStatefulWidget {
  const HowRelatedScreen({super.key, this.fromId, this.toId});

  /// Defaults to the signed-in person.
  final String? fromId;
  final String? toId;

  @override
  ConsumerState<HowRelatedScreen> createState() => _HowRelatedScreenState();
}

class _HowRelatedScreenState extends ConsumerState<HowRelatedScreen> {
  late String? _a = widget.fromId;
  late String? _b = widget.toId;

  Future<void> _pick(FamilyGraph graph, bool first) async {
    final p = await pickPerson(context, graph);
    if (p != null) setState(() => first ? _a = p.id : _b = p.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final graph = ref.watch(graphProvider).value;
    final me = ref.watch(profileProvider)?.personId;
    final a = _a ?? me;
    final b = _b;
    final pa = a == null ? null : graph?[a];
    final pb = b == null ? null : graph?[b];

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        title: Text(l.howRelated, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: graph == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
              Row(children: [
                Expanded(
                  child: _PersonButton(
                    person: pa,
                    caption: a == me ? l.you : l.change,
                    onTap: () => _pick(graph, true),
                  ),
                ),
                IconButton(
                  tooltip: l.swap,
                  onPressed: pa == null || pb == null
                      ? null
                      : () => setState(() {
                            _a = b;
                            _b = a;
                          }),
                  icon: Icon(Icons.swap_horiz, color: Bua.green),
                ),
                Expanded(
                  child: _PersonButton(person: pb, caption: l.change, onTap: () => _pick(graph, false)),
                ),
              ]),
              const SizedBox(height: 16),
              if (pa != null && pb != null) ..._result(context, graph, pa, pb, me),
            ]),
    );
  }

  List<Widget> _result(BuildContext context, FamilyGraph graph, Person pa, Person pb, String? me) {
    final l = context.l10n;
    final path = relationPath(graph, pa.id, pb.id);
    final k = kinshipOf(graph, pa.id, pb.id);
    final viaMarriage = path?.any((s) => s.link == PathLink.spouseOf) ?? false;
    final label = switch (k.type) {
      KinType.none => path == null ? l.relNone : (viaMarriage ? l.relByMarriage : l.sameDistantRelative),
      _ => l.kinship(k),
    };
    const sided = {KinType.grandparent, KinType.uncleAunt, KinType.cousin};
    final side = !sided.contains(k.type)
        ? null
        : switch (k.side) {
            FamilySide.paternal => l.sideFather,
            FamilySide.maternal => l.sideMother,
            FamilySide.unknown => null,
          };
    final shared = path == null ? null : sharedAncestor(path);

    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Bua.green, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Text(
            pa.id == me ? l.relatedIsYour(pb.firstName) : l.relatedIsOf(pb.firstName, pa.firstName),
            style: TextStyle(fontSize: 14, color: Bua.greenOnDark),
          ),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
          if (side != null) ...[
            const SizedBox(height: 4),
            Text(side, style: TextStyle(fontSize: 14, color: Bua.goldOnDark)),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      if (path == null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l.notConnected, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkSubtle)),
        )
      else if (path.length > 1)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final step in path) ...[
              _PathNode(
                person: graph[step.personId]!,
                isMe: step.personId == me,
                note: step.personId == shared
                    ? l.pathShared(l.kinship(kinshipOf(graph, pa.id, shared!)).toLowerCase())
                    : null,
                highlight: step.personId == pa.id || step.personId == pb.id,
              ),
              if (step.link != null) _PathLinkRow(text: _linkText(l, graph[step.personId]!, step.link!)),
            ],
          ]),
        ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: () => context.go('/tree?focus=${pb.id}'),
        icon: const Icon(Icons.account_tree_outlined),
        label: Text(l.showBothInTree),
      ),
    ];
  }

  String _linkText(AppLocalizations l, Person p, PathLink link) => switch (link) {
        PathLink.childOf => l.pathChildOf(_sexKey(p.sex)),
        PathLink.parentOf => l.pathParentOf(_sexKey(p.sex)),
        PathLink.spouseOf => l.pathSpouseOf(_sexKey(p.sex)),
      };
}

class _PersonButton extends StatelessWidget {
  const _PersonButton({required this.person, required this.caption, required this.onTap});

  final Person? person;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Bua.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Bua.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            if (person != null)
              PersonAvatar(person: person!, radius: 18, showPhoto: false)
            else
              CircleAvatar(radius: 18, backgroundColor: Bua.track, child: Icon(Icons.person_search, size: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(person?.firstName ?? context.l10n.pickSomeone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(caption, style: TextStyle(fontSize: 12, color: Bua.green)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  const _PathNode({required this.person, required this.isMe, this.note, this.highlight = false});

  final Person person;
  final bool isMe;
  final String? note;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return InkWell(
      onTap: () => context.push('/person/${person.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: [
          PersonAvatar(person: person, radius: 18, highlight: highlight ? Bua.green : null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isMe ? l.youSuffix(person.displayName) : person.displayName,
                  style: TextStyle(fontSize: 15, fontWeight: highlight ? FontWeight.w700 : FontWeight.w500)),
              if (note != null)
                Text(note!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Bua.goldInk)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PathLinkRow extends StatelessWidget {
  const _PathLinkRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36),
      child: Row(children: [
        Container(width: 2, height: 26, color: Bua.connector),
        const SizedBox(width: 22),
        Text(text, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Bua.inkSubtle)),
      ]),
    );
  }
}
