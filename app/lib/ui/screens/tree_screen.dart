import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/tree_layout.dart';
import '../../l10n/l10n.dart';
import '../../models/family_graph.dart';
import '../../models/person.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _metrics = TreeMetrics(nodeWidth: 136, nodeHeight: 58, siblingGap: 16, spouseGap: 14, levelGap: 64);
const _initialDepth = 3;
const _toggleOverhang = 10.0;

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

  void _fit(TreeLayout layout, {bool readable = false, String? centreXOn}) {
    if (_viewport == Size.zero || layout.size == Size.zero) return;
    var scale = math.min(
      1.0,
      math.min(_viewport.width / layout.size.width, _viewport.height / layout.size.height),
    );
    // On first open, keep names legible and let people pan, rather than
    // shrinking a big family to fit the screen.
    if (readable) scale = math.max(scale, 0.85);
    // The layout centres each parent over its children, so centring the whole
    // layout keeps the root in view.
    var dx = (_viewport.width - layout.size.width * scale) / 2;
    final anchor = centreXOn == null ? null : layout.nodeFor(centreXOn);
    if (anchor != null && layout.size.width * scale > _viewport.width) {
      // Wide tree: show the viewer's own branch first.
      final x = (anchor.offset.dx + _metrics.nodeWidth / 2) * scale;
      dx = (_viewport.width / 2 - x).clamp(_viewport.width - layout.size.width * scale, 0.0);
    }
    _transform.value = Matrix4.identity()
      ..translateByDouble(dx, 0, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  /// Zoom by [factor] around the centre of the viewport.
  void _zoom(double factor) {
    final c = Offset(_viewport.width / 2, _viewport.height / 2);
    final current = _transform.value.getMaxScaleOnAxis();
    final f = (current * factor).clamp(0.05, 2.5) / current;
    _transform.value = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(f, f, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1)
      ..multiply(_transform.value);
  }

  void _focusOn(String personId) => setState(() {
        _pendingFocus = personId;
        _rootId = null;
      });

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
          _fit(layout, readable: true, centreXOn: ref.read(profileProvider)?.personId);
        }
      });
    }

    final myPersonId = ref.watch(profileProvider)?.personId;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(children: [
              Expanded(child: Text(l.navTree, style: Theme.of(context).textTheme.titleLarge)),
              if (graph != null && graph.persons.isNotEmpty)
                IconButton(
                  tooltip: l.findRelative,
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    final p = await pickPerson(context, graph);
                    if (p != null) _focusOn(p.id);
                  },
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
            ]),
          ),
          if (graph != null && root != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _StartingFromBar(name: graph[root]!.displayName, onChange: () => _chooseRoot(graph)),
            ),
          Expanded(
            child: AsyncBody(
              value: graphAsync,
              onRetry: () => ref.invalidate(graphProvider),
              builder: (g) {
                if (layout == null) return _EmptyTree(canAdd: ref.watch(isAdminProvider));
                return LayoutBuilder(builder: (context, constraints) {
                  _viewport = constraints.biggest;
                  return Stack(children: [
                    const Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
                    Positioned.fill(
                      child: _TreeCanvas(
                        graph: g,
                        layout: layout!,
                        transform: _transform,
                        myPersonId: myPersonId,
                        onToggle: (id) => setState(() {
                          if (!_collapsed.remove(id)) _collapsed.add(id);
                        }),
                      ),
                    ),
                    const Positioned(left: 16, bottom: 16, child: _Legend()),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: _ZoomControls(
                        onZoomIn: () => _zoom(1.25),
                        onZoomOut: () => _zoom(0.8),
                        onCentre: myPersonId == null || g[myPersonId] == null ? null : () => _focusOn(myPersonId),
                      ),
                    ),
                  ]);
                });
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _StartingFromBar extends StatelessWidget {
  const _StartingFromBar({required this.name, required this.onChange});

  final String name;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      height: 46,
      padding: const EdgeInsets.only(left: 12, right: 5),
      decoration: BoxDecoration(
        color: Bua.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Bua.line),
      ),
      child: Row(children: [
        const Icon(Icons.north, size: 18, color: Bua.green),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '${l.startingFrom} '),
              TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w600, color: Bua.ink)),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Bua.inkMuted),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Bua.greenTint,
            foregroundColor: Bua.greenDark,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontFamily: 'NotoSans', fontSize: 13, fontWeight: FontWeight.w600),
          ),
          onPressed: onChange,
          child: Text(l.change),
        ),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget row(Widget mark, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 16, child: Center(child: mark)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Bua.inkMuted)),
        ]);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Bua.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Bua.line),
        boxShadow: const [BoxShadow(color: Color(0x0F17231B), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        row(
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Bua.lateRing, width: 2)),
          ),
          l.lateLabel('other'),
        ),
        const SizedBox(height: 8),
        row(Container(width: 14, height: 3, color: Bua.gold), l.statusMarried),
        const SizedBox(height: 8),
        row(
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4), border: Border.all(color: Bua.green, width: 2)),
          ),
          l.relSelf,
        ),
      ]),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.onZoomIn, required this.onZoomOut, required this.onCentre});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onCentre;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget button(IconData icon, String tip, VoidCallback? onTap, {Color color = Bua.ink}) => IconButton(
          tooltip: tip,
          onPressed: onTap,
          icon: Icon(icon, color: color),
          style: IconButton.styleFrom(minimumSize: const Size(48, 48), shape: const RoundedRectangleBorder()),
        );
    return Container(
      decoration: BoxDecoration(
        color: Bua.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Bua.line),
        boxShadow: const [BoxShadow(color: Color(0x0F17231B), blurRadius: 8, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        button(Icons.add, l.zoomIn, onZoomIn),
        const SizedBox(width: 48, child: Divider(color: Bua.line)),
        button(Icons.remove, l.zoomOut, onZoomOut),
        if (onCentre != null) ...[
          const SizedBox(width: 48, child: Divider(color: Bua.line)),
          button(Icons.my_location, l.centreOnMe, onCentre, color: Bua.green),
        ],
      ]),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFD5DDD3);
    for (var y = 10.0; y < size.height; y += 20) {
      for (var x = 10.0; x < size.width; x += 20) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
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
            child: CustomPaint(painter: _EdgePainter(layout.edges, Bua.connector, Bua.gold)),
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
    final collapsed = node.hiddenDescendants > 0;
    final sub = person.lifespan(approxPrefix: l.approxPrefix());
    final bg = person.isLiving ? Bua.surface : Bua.lateCard;

    final card = Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isMe ? Bua.green : Bua.line, width: isMe ? 2 : 1),
      ),
      elevation: isMe ? 3 : 0,
      shadowColor: Bua.green.withValues(alpha: 0.35),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/person/${person.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            PersonAvatar(person: person, radius: 16, showPhoto: false, gapColor: bg),
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
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Bua.ink,
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
                      style: const TextStyle(fontSize: 10.5, color: Bua.inkSubtle),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );

    return Stack(clipBehavior: Clip.none, children: [
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: _metrics.nodeHeight,
        child: node.isRepeat ? Tooltip(message: l.shownElsewhere, child: Opacity(opacity: 0.7, child: card)) : card,
      ),
      if (isMe)
        Positioned(
          left: 8,
          top: -10,
          child: Container(
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Bua.green, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: Text(l.relSelf,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      if (hasChildren)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: collapsed ? Bua.green : Bua.surface,
              shape: StadiumBorder(side: BorderSide(color: collapsed ? Bua.green : Bua.line)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  child: collapsed
                      ? Text(l.hiddenCount(node.hiddenDescendants),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))
                      : const Icon(Icons.expand_less, size: 16, color: Bua.inkMuted),
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
      ..strokeWidth = 1.6
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
