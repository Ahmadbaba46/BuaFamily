import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import '../models/family_graph.dart';

/// Geometry used by the layout. All values in logical pixels.
class TreeMetrics {
  const TreeMetrics({
    this.nodeWidth = 150,
    this.nodeHeight = 68,
    this.siblingGap = 20,
    this.spouseGap = 14,
    this.levelGap = 64,
    this.padding = 40,
  });

  final double nodeWidth;
  final double nodeHeight;
  final double siblingGap;
  final double spouseGap;
  final double levelGap;
  final double padding;
}

class TreeNode {
  const TreeNode({
    required this.personId,
    required this.offset,
    required this.isSpouse,
    required this.isRepeat,
    required this.hiddenDescendants,
    required this.depth,
  });

  final String personId;
  final Offset offset; // top-left
  /// Married into this line (drawn beside a descendant).
  final bool isSpouse;

  /// Already shown elsewhere in the tree (e.g. cousin marriages); not expanded again.
  final bool isRepeat;

  /// > 0 when this node is collapsed and has children that are not drawn.
  final int hiddenDescendants;
  final int depth;
}

/// A connector line (polyline) between nodes.
class TreeEdge {
  const TreeEdge(this.points, {this.isMarriage = false});
  final List<Offset> points;
  final bool isMarriage;
}

class TreeLayout {
  const TreeLayout({required this.nodes, required this.edges, required this.size});
  final List<TreeNode> nodes;
  final List<TreeEdge> edges;
  final Size size;

  TreeNode? nodeFor(String personId) =>
      nodes.where((n) => n.personId == personId && !n.isRepeat).firstOrNull;
}

/// Lays out the descendants of [rootId] top-down. Each row shows a descendant
/// followed by their spouses (in order). Children hang below the spouse they
/// were born to, so households with several wives stay readable.
///
/// [collapsed] persons are drawn but their descendants are hidden.
TreeLayout layoutDescendants(
  FamilyGraph graph,
  String rootId, {
  Set<String> collapsed = const {},
  TreeMetrics m = const TreeMetrics(),
}) {
  final visited = <String>{};
  final root = _build(graph, rootId, collapsed, visited, 0);
  if (root == null) return const TreeLayout(nodes: [], edges: [], size: Size.zero);

  _measure(root, m);
  final nodes = <TreeNode>[];
  final edges = <TreeEdge>[];
  _place(root, m.padding, m.padding, m, nodes, edges);

  var maxX = 0.0, maxY = 0.0;
  for (final n in nodes) {
    maxX = math.max(maxX, n.offset.dx + m.nodeWidth);
    maxY = math.max(maxY, n.offset.dy + m.nodeHeight);
  }
  return TreeLayout(nodes: nodes, edges: edges, size: Size(maxX + m.padding, maxY + m.padding));
}

class _Group {
  _Group(this.otherParentId, this.children);
  final String? otherParentId;
  final List<_Unit> children;
}

class _Unit {
  _Unit(this.personId, this.depth, {this.isRepeat = false});
  final String personId;
  final int depth;
  final bool isRepeat;
  final List<String> spouseIds = [];
  final List<_Group> groups = [];
  int hidden = 0;
  double width = 0;
  double rowWidth = 0;
  double childrenWidth = 0;
}

_Unit? _build(FamilyGraph g, String id, Set<String> collapsed, Set<String> visited, int depth) {
  if (g[id] == null) return null;
  if (!visited.add(id)) return _Unit(id, depth, isRepeat: true);

  final unit = _Unit(id, depth);
  for (final s in g.spousesOf(id)) {
    unit.spouseIds.add(s.id);
  }
  if (collapsed.contains(id)) {
    unit.hidden = g.descendantCount(id);
    return unit;
  }
  g.childrenByOtherParent(id).forEach((otherId, kids) {
    if (kids.isEmpty) return;
    final units = <_Unit>[];
    for (final k in kids) {
      final u = _build(g, k.id, collapsed, visited, depth + 1);
      if (u != null) units.add(u);
    }
    if (units.isNotEmpty) unit.groups.add(_Group(otherId, units));
  });
  return unit;
}

void _measure(_Unit u, TreeMetrics m) {
  u.rowWidth = (1 + u.spouseIds.length) * m.nodeWidth + u.spouseIds.length * m.spouseGap;
  final kids = u.groups.expand((g) => g.children).toList();
  for (final k in kids) {
    _measure(k, m);
  }
  u.childrenWidth = kids.isEmpty
      ? 0
      : kids.fold<double>(0, (s, k) => s + k.width) + (kids.length - 1) * m.siblingGap;
  u.width = math.max(u.rowWidth, u.childrenWidth);
}

void _place(_Unit u, double left, double top, TreeMetrics m, List<TreeNode> nodes, List<TreeEdge> edges) {
  final rowLeft = left + (u.width - u.rowWidth) / 2;
  nodes.add(TreeNode(
    personId: u.personId,
    offset: Offset(rowLeft, top),
    isSpouse: false,
    isRepeat: u.isRepeat,
    hiddenDescendants: u.hidden,
    depth: u.depth,
  ));

  final midY = top + m.nodeHeight / 2;
  final centers = <String, double>{u.personId: rowLeft + m.nodeWidth / 2};
  for (var i = 0; i < u.spouseIds.length; i++) {
    final x = rowLeft + (i + 1) * (m.nodeWidth + m.spouseGap);
    nodes.add(TreeNode(
      personId: u.spouseIds[i],
      offset: Offset(x, top),
      isSpouse: true,
      isRepeat: false,
      hiddenDescendants: 0,
      depth: u.depth,
    ));
    centers[u.spouseIds[i]] = x + m.nodeWidth / 2;
    // Marriage line from the previous box to this spouse.
    edges.add(TreeEdge([Offset(x - m.spouseGap, midY), Offset(x, midY)], isMarriage: true));
  }

  if (u.groups.isEmpty) return;

  final childTop = top + m.nodeHeight + m.levelGap;
  var x = left + (u.width - u.childrenWidth) / 2;
  final groupCount = u.groups.length;
  for (var gi = 0; gi < groupCount; gi++) {
    final group = u.groups[gi];
    // Stagger bus heights so lines from different spouses do not overlap.
    final busY = top + m.nodeHeight + m.levelGap * (0.25 + 0.5 * (gi + 1) / (groupCount + 1));
    final originX = centers[group.otherParentId] ?? centers[u.personId]!;
    final childCenters = <double>[];
    for (final child in group.children) {
      _place(child, x, childTop, m, nodes, edges);
      childCenters.add(x + (child.width - child.rowWidth) / 2 + m.nodeWidth / 2);
      x += child.width + m.siblingGap;
    }
    final busLeft = math.min(originX, childCenters.first);
    final busRight = math.max(originX, childCenters.last);
    edges.add(TreeEdge([Offset(originX, top + m.nodeHeight), Offset(originX, busY)]));
    edges.add(TreeEdge([Offset(busLeft, busY), Offset(busRight, busY)]));
    for (final cx in childCenters) {
      edges.add(TreeEdge([Offset(cx, busY), Offset(cx, childTop)]));
    }
  }
}

/// Persons deeper than [depth] generations below [rootId] that have children —
/// a sensible default set to collapse so a large tree opens readable.
Set<String> collapseBeyondDepth(FamilyGraph g, String rootId, int depth) {
  final result = <String>{};
  final seen = <String>{rootId};
  var frontier = [rootId];
  for (var d = 0; frontier.isNotEmpty; d++) {
    final next = <String>[];
    for (final id in frontier) {
      final kids = g.childLinksOf(id).map((l) => l.childId).where(seen.add).toList();
      if (d >= depth && kids.isNotEmpty) {
        result.add(id);
        continue;
      }
      next.addAll(kids);
    }
    frontier = next;
  }
  return result;
}
