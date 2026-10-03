import 'package:collection/collection.dart';

import '../models/family_graph.dart';

/// How one person in a path relates to the next one.
enum PathLink { childOf, parentOf, spouseOf }

class PathStep {
  const PathStep(this.personId, this.link);

  final String personId;

  /// How this person relates to the next one in the path; null for the last.
  final PathLink? link;
}

/// The shortest chain of parent, child and marriage links from [a] to [b],
/// preferring blood links over marriages when both are equally short.
/// Returns null when they are not connected.
List<PathStep>? relationPath(FamilyGraph g, String a, String b) {
  if (g[a] == null || g[b] == null) return null;
  if (a == b) return [PathStep(a, null)];
  // Dijkstra: blood links cost 2, marriages 3.
  final dist = <String, int>{a: 0};
  final prev = <String, (String, PathLink)>{};
  final queue = PriorityQueue<(int, String)>((x, y) => x.$1.compareTo(y.$1))..add((0, a));
  while (queue.isNotEmpty) {
    final (d, id) = queue.removeFirst();
    if (id == b) break;
    if (d > (dist[id] ?? 1 << 30)) continue;
    void relax(String next, PathLink link, int cost) {
      final nd = d + cost;
      if (nd < (dist[next] ?? 1 << 30)) {
        dist[next] = nd;
        prev[next] = (id, link);
        queue.add((nd, next));
      }
    }

    for (final p in g.parentLinksOf(id)) {
      relax(p.parentId, PathLink.childOf, 2);
    }
    for (final c in g.childLinksOf(id)) {
      relax(c.childId, PathLink.parentOf, 2);
    }
    for (final s in g.spousesOf(id)) {
      relax(s.id, PathLink.spouseOf, 3);
    }
  }
  if (!prev.containsKey(b)) return null;
  final steps = <PathStep>[PathStep(b, null)];
  var cur = b;
  while (cur != a) {
    final (from, link) = prev[cur]!;
    steps.add(PathStep(from, link));
    cur = from;
  }
  return steps.reversed.toList();
}

/// The person where the path stops going up and starts going down: the
/// shared ancestor of two blood relatives. Null if there is none.
String? sharedAncestor(List<PathStep> path) {
  for (var i = 1; i < path.length - 1; i++) {
    if (path[i - 1].link == PathLink.childOf && path[i].link == PathLink.parentOf) return path[i].personId;
  }
  return null;
}
