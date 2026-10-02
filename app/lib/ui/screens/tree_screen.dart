import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/tree_layout.dart';
import '../../l10n/l10n.dart';
import '../../models/family_graph.dart';
import '../../models/person.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';

const _metrics = TreeMetrics();
const _initialDepth = 3;
const _toggleOverhang = 12.0;

class TreeScreen extends ConsumerStatefulWidget {
  const TreeScreen({super.key, this.focusId});

  /// When set, the tree is rooted at this person's eldest ancestor and
  /// centred on them.
  final String? focusId;

  @override
  ConsumerState<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends ConsumerState<TreeScreen> {
  final _transform = TransformationController();
  String? _rootId; // chosen by the user in this session
  String? _layoutRoot; // root that [_collapsed] was computed for
  Set<String> _collapsed = {};
  String? _pendingFocus;
  Size _viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    _pendingFocus = widget.focusId;
  }

  @override
  void didUpdateWidget(TreeScreen old) {
    super.didUpdateWidget(old);
    if (widget.focusId != old.focusId && widget.focusId != null) {
      _pendingFocus = widget.focusId;
      _rootId = null;
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  String? _resolveRoot(FamilyGraph g) {
    final focus = _pendingFocus;
    if (focus != null && g[focus] != null) {
      _rootId = _eldestAncestor(g, focus);
    }
    final settingsRoot = ref.read(settingsProvider).value?.rootPersonId;
    for (final candidate in [_rootId, settingsRoot, g.suggestedRoot()]) {
      if (candidate != null && g[candidate] != null) return candidate;
    }
    return null;
  }

  /// Follow fathers (then any parent) upwards.
  String _eldestAncestor(FamilyGraph g, String id) {
    final seen = <String>{id};
    var cur = id;
    while (true) {
      final next = g.fatherOf(cur) ?? g.parentsOf(cur).firstOrNull;
      if (next == null || !seen.add(next.id)) return cur;
      cur = next.id;
    }
  }

  void _expandPathTo(FamilyGraph g, String id) {
    final stack = [id];
    final seen = <String>{};
    while (stack.isNotEmpty) {
      final cur = stack.removeLast();
      for (final p in g.parentsOf(cur)) {
        if (seen.add(p.id)) {
          _collapsed.remove(p.id);
          stack.add(p.id);
        }
      }
    }
    // A spouse is drawn beside their partner; make sure that row is visible too.
    for (final s in g.spousesOf(id)) {
      if (seen.add(s.id)) _expandPathToSpouse(g, s.id);
    }
  }

  void _expandPathToSpouse(FamilyGraph g, String id) {
    for (final p in g.parentsOf(id)) {
      _collapsed.remove(p.id);
      _expandPathToSpouse(g, p.id);
    }
  }

  void _centerOn(TreeLayout layout, String personId) {
    final node = layout.nodes.where((n) => n.personId == personId).firstOrNull;
    if (node == null || _viewport == Size.zero) return;
    final c = node.offset + Offset(_metrics.nodeWidth / 2, _metrics.nodeHeight / 2);
    _transform.value = Matrix4.identity()
      ..translateByDouble(_viewport.width / 2 - c.dx, _viewport.height / 2 - c.dy, 0, 1);
  }

  void _fit(TreeLayout layout) {
    if (_viewport == Size.zero || layout.size == Size.zero) return;
    final scale = math.min(
      1.0,
      math.min(_viewport.width / layout.size.width, _viewport.height / layout.size.height),
    );
    final dx = (_viewport.width - layout.size.width * scale) / 2;
    _transform.value = Matrix4.identity()
      ..translateByDouble(math.max(0, dx), 0, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  Future<void> _chooseRoot(FamilyGraph g) async {
    final p = await pickPerson(context, g);
    if (p == null) return;
    setState(() {
      _rootId = p.id;
      _layoutRoot = null;
      _pendingFocus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final graphAsync = ref.watch(graphProvider);
    ref.watch(settingsProvider);
    final graph = graphAsync.value;
    final root = graph == null ? null : _resolveRoot(graph);

    TreeLayout? layout;
    if (graph != null && root != null) {
      if (_layoutRoot != root) {
        _collapsed = collapseBeyondDepth(graph, root, _initialDepth);
        _layoutRoot = root;
      }
      if (_pendingFocus != null) _expandPathTo(graph, _pendingFocus!);
      layout = layoutDescendants(graph, root, collapsed: _collapsed, m: _metrics);
      final focus = _pendingFocus;
      _pendingFocus = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || layout == null) return;
        if (focus != null) {
          _centerOn(layout, focus);
        } else if (_transform.value.isIdentity()) {
          _fit(layout);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(root == null ? l.navTree : graph![root]!.displayName),
        actions: [
          if (graph != null && graph.persons.isNotEmpty)
            IconButton(
              tooltip: l.chooseRoot,
              icon: const Icon(Icons.swap_vert),
              onPressed: () => _chooseRoot(graph),
            ),
          if (layout != null)
            PopupMenuButton<String>(
              onSelected: (v) => setState(() {
                switch (v) {
                  case 'fit':
                    _fit(layout!);
                  case 'expand':
                    _collapsed = {};
                  case 'collapse':
                    _collapsed = collapseBeyondDepth(graph!, root!, _initialDepth);
                  case 'refresh':
                    ref.invalidate(graphProvider);
                }
              }),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'fit', child: Text(l.fitToScreen)),
                PopupMenuItem(value: 'expand', child: Text(l.expandAll)),
                PopupMenuItem(value: 'collapse', child: Text(l.collapseDeep)),
                PopupMenuItem(value: 'refresh', child: Text(l.refresh)),
              ],
            ),
        ],
      ),
      body: AsyncBody(
        value: graphAsync,
        onRetry: () => ref.invalidate(graphProvider),
        builder: (g) {
          if (layout == null) return _EmptyTree(canAdd: ref.watch(isAdminProvider));
          return LayoutBuilder(builder: (context, constraints) {
            _viewport = constraints.biggest;
            return _TreeCanvas(
              graph: g,
              layout: layout!,
              transform: _transform,
              myPersonId: ref.watch(profileProvider)?.personId,
              onToggle: (id) => setState(() {
                if (!_collapsed.remove(id)) _collapsed.add(id);
              }),
            );
          });
        },
      ),
    );
  }
}

class _EmptyTree extends StatelessWidget {
  const _EmptyTree({required this.canAdd});

  final bool canAdd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.park_outlined, size: 64),
        const SizedBox(height: 12),
        Text(l.treeEmpty),
        if (canAdd) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/new-person'),
            icon: const Icon(Icons.person_add),
            label: Text(l.addFirstPerson),
          ),
        ],
      ]),
    );
  }
}

class _TreeCanvas extends StatelessWidget {
  const _TreeCanvas({
    required this.graph,
    required this.layout,
    required this.transform,
    required this.myPersonId,
    required this.onToggle,
  });

  final FamilyGraph graph;
  final TreeLayout layout;
  final TransformationController transform;
  final String? myPersonId;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InteractiveViewer(
      transformationController: transform,
      constrained: false,
      minScale: 0.05,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(400),
      child: SizedBox.fromSize(
        size: layout.size,
        child: Stack(children: [
          Positioned.fill(
            child: CustomPaint(painter: _EdgePainter(layout.edges, scheme.outline, scheme.tertiary)),
          ),
          for (final n in layout.nodes)
            Positioned(
              left: n.offset.dx,
              top: n.offset.dy,
              width: _metrics.nodeWidth,
              // Extra room below the card for the expand/collapse toggle, so it
              // stays inside the hit-testable area.
              height: _metrics.nodeHeight + _toggleOverhang,
              child: _NodeCard(
                person: graph[n.personId]!,
                node: n,
                isMe: n.personId == myPersonId,
                hasChildren: !n.isSpouse && !n.isRepeat && graph.childLinksOf(n.personId).isNotEmpty,
                onToggle: () => onToggle(n.personId),
              ),
            ),
        ]),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.person,
    required this.node,
    required this.isMe,
    required this.hasChildren,
    required this.onToggle,
  });

  final Person person;
  final TreeNode node;
  final bool isMe;
  final bool hasChildren;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final collapsed = node.hiddenDescendants > 0;
    final sub = person.lifespan(approxPrefix: l.approxPrefix());

    final card = Material(
      color: node.isSpouse ? scheme.surfaceContainerLow : scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isMe ? scheme.primary : scheme.outlineVariant,
          width: isMe ? 2.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/person/${person.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [
            PersonAvatar(person: person, radius: 18, showPhoto: false),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontStyle: node.isRepeat ? FontStyle.italic : null,
                    ),
                  ),
                  // Deceased people are marked by the ring on their avatar; the
                  // "Late" label is on their profile, where there is room.
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );

    return Stack(children: [
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: _metrics.nodeHeight,
        child: node.isRepeat ? Tooltip(message: l.shownElsewhere, child: Opacity(opacity: 0.7, child: card)) : card,
      ),
      if (hasChildren)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: collapsed ? scheme.primary : scheme.surfaceContainerHighest,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: collapsed
                      ? Text(l.hiddenCount(node.hiddenDescendants),
                          style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimary))
                      : Icon(Icons.expand_less, size: 16, color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _EdgePainter extends CustomPainter {
  _EdgePainter(this.edges, this.lineColor, this.marriageColor);

  final List<TreeEdge> edges;
  final Color lineColor;
  final Color marriageColor;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final marriage = Paint()
      ..color = marriageColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final e in edges) {
      final path = Path()..moveTo(e.points.first.dx, e.points.first.dy);
      for (final p in e.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, e.isMarriage ? marriage : line);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) => old.edges != edges || old.lineColor != lineColor;
}
