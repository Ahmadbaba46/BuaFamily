import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/family_graph.dart';
import '../../models/person.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/portrait_viewer.dart';

/// The family one generation at a time: a person with their details and
/// their children. Tapping a child goes down to them, with their details and
/// children, and so on. The line back up to where it started stays at the
/// top, and Back goes up one.
class FamilyLineView extends StatefulWidget {
  const FamilyLineView({super.key, required this.graph, required this.rootId, this.focusId, this.myPersonId});

  final FamilyGraph graph;

  /// Where the line starts: the forefather the tree starts from.
  final String rootId;

  /// Open on this person, with the line from [rootId] down to them.
  final String? focusId;
  final String? myPersonId;

  @override
  State<FamilyLineView> createState() => _FamilyLineViewState();
}

class _FamilyLineViewState extends State<FamilyLineView> {
  late List<String> _line = _lineTo(widget.focusId);

  List<String> _lineTo(String? id) {
    if (id == null || id == widget.rootId) return [widget.rootId];
    return widget.graph.lineFrom(widget.rootId, id) ?? [widget.rootId];
  }

  @override
  void didUpdateWidget(FamilyLineView old) {
    super.didUpdateWidget(old);
    // The family was reloaded: keep the line while its people are still there.
    if (!identical(old.graph, widget.graph)) {
      final kept = _line.takeWhile((id) => widget.graph[id] != null).toList();
      _line = kept.isEmpty ? [widget.rootId] : kept;
    }
  }

  void _goTo(int depth) => setState(() => _line = _line.sublist(0, depth + 1));

  void _down(String childId) => setState(() => _line = [..._line, childId]);

  @override
  Widget build(BuildContext context) {
    final g = widget.graph;
    final id = _line.last;
    final person = g[id];
    if (person == null) return const SizedBox.shrink();
    return PopScope(
      canPop: _line.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _line.length > 1) _goTo(_line.length - 2);
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_line.length > 1) _Breadcrumb(graph: g, line: _line, onTap: _goTo),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _Generation(
              key: ValueKey(id),
              graph: g,
              person: person,
              myPersonId: widget.myPersonId,
              onChild: _down,
            ),
          ),
        ),
      ]),
    );
  }
}

/// Forefather › son › grandson …: tap a name to go back up to them.
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.graph, required this.line, required this.onTap});

  final FamilyGraph graph;
  final List<String> line;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final parent = graph[line[line.length - 2]]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 4),
      child: Row(children: [
        IconButton(
          tooltip: l.upTo(parent.displayName),
          icon: Icon(Icons.arrow_upward, color: Bua.green),
          onPressed: () => onTap(line.length - 2),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(children: [
              for (final (i, id) in line.indexed) ...[
                if (i > 0) Icon(Icons.chevron_right, size: 18, color: Bua.inkSubtle),
                if (i == line.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(graph[id]!.firstName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  )
                else
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      textStyle: const TextStyle(fontFamily: 'NotoSans', fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    onPressed: () => onTap(i),
                    child: Text(graph[id]!.firstName),
                  ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

/// One person with their details, then their children (by mother or father
/// when there was more than one marriage).
class _Generation extends StatelessWidget {
  const _Generation({
    super.key,
    required this.graph,
    required this.person,
    required this.myPersonId,
    required this.onChild,
  });

  final FamilyGraph graph;
  final Person person;
  final String? myPersonId;
  final ValueChanged<String> onChild;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final g = graph;
    final kids = g.childrenOf(person.id);
    final groups = g.childrenByOtherParent(person.id)..removeWhere((_, v) => v.isEmpty);
    final byParent = groups.length > 1;

    Widget childRow(Person c) {
      final n = g.childLinksOf(c.id).length;
      final base = personSubtitle(context, c);
      return PersonTile(
        person: c,
        viewPhoto: true,
        highlight: c.id == myPersonId ? Bua.green : null,
        subtitle: [if (base.isNotEmpty) base, l.childCountShort(n)].join(' · '),
        trailing: Icon(Icons.chevron_right, color: Bua.inkSubtle),
        onTap: () => onChild(c.id),
      );
    }

    Widget group(List<Person> people) => Material(
          color: Bua.surface,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (final (i, c) in people.indexed) ...[if (i > 0) const InsetDivider(indent: 68), childRow(c)],
          ]),
        );

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
      _PersonCard(graph: g, person: person, isMe: person.id == myPersonId),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: GroupHeading(l.childrenHeading(kids.length)),
      ),
      if (kids.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Text(l.noChildrenYet, style: TextStyle(color: Bua.inkMuted)),
        )
      else ...[
        for (final MapEntry(key: other, value: people) in groups.entries) ...[
          if (byParent)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: Text(
                other == null
                    ? '${l.otherParent}: ${l.otherParentUnknown}'
                    : l.childrenWithParent(g[other]?.displayName ?? ''),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Bua.inkMuted),
              ),
            ),
          group(people),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(l.familyLineHint,
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
        ),
      ],
    ]);
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.graph, required this.person, required this.isMe});

  final FamilyGraph graph;
  final Person person;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final g = graph;
    final sub = personSubtitle(context, person);
    final parents = g.parentsOf(person.id);
    final spouses = g.spousesOf(person.id);
    final kids = g.childLinksOf(person.id).map((c) => c.childId).toList();
    final grandchildren = {for (final k in kids) ...g.childLinksOf(k).map((c) => c.childId)}.length;
    final descendants = g.descendantCount(person.id);
    final bio = person.biography?.trim() ?? '';

    Widget fact(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Bua.greenTint, borderRadius: BorderRadius.circular(10)),
          child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Bua.greenDark)),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Bua.surface,
        borderRadius: BorderRadius.circular(20),
        border: isMe ? Border.all(color: Bua.green, width: 2) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          GestureDetector(
            onTap: () => showPortrait(context, person),
            child: PersonAvatar(person: person, radius: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(person.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.2)),
              if (sub.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(sub, style: TextStyle(fontSize: 13, color: Bua.inkSubtle)),
                ),
            ]),
          ),
        ]),
        if (parents.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l.parentsNames(parents.map((p) => p.displayName).join(' & ')),
              style: TextStyle(fontSize: 13, color: Bua.inkMuted)),
        ],
        if (spouses.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(l.spouses, style: TextStyle(fontSize: 13, color: Bua.inkMuted)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in spouses)
              ActionChip(
                avatar: PersonAvatar(person: s, radius: 12),
                label: Text(s.displayName),
                onPressed: () => context.push('/person/${s.id}'),
              ),
          ]),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          fact(l.childCountShort(kids.length)),
          if (grandchildren > 0) fact(l.grandchildrenCount(grandchildren)),
          if (descendants > kids.length + grandchildren) fact(l.descendantsCount(descendants)),
        ]),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(bio, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.45)),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => context.push('/person/${person.id}'),
            icon: const Icon(Icons.person_outline, size: 18),
            label: Text(l.openProfile),
          ),
        ),
      ]),
    );
  }
}
