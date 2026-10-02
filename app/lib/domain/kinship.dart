import '../models/family_graph.dart';
import '../models/person.dart';

enum KinType {
  self,
  spouse,
  parent,
  child,
  sibling,
  grandparent, // generations >= 2 up
  grandchild, // generations >= 2 down
  uncleAunt, // parent's sibling (and grand-uncles etc.)
  nephewNiece, // sibling's child (and grand-nephews etc.)
  cousin,
  stepParent, // parent's spouse who is not a parent
  stepChild, // spouse's child who is not one's own
  coSpouse, // spouse's other spouse (e.g. co-wife / kishiya)
  parentInLaw, // spouse's parent
  childInLaw, // child's spouse
  siblingInLaw, // spouse's sibling or sibling's spouse
  relatedByMarriage, // any other marriage-only connection
  none,
}

enum FamilySide { paternal, maternal, unknown }

/// How person B relates to person A ("B is A's ...").
class Kinship {
  const Kinship(
    this.type, {
    this.sex = Sex.unknown,
    this.generations = 0,
    this.cousinDegree = 0,
    this.removed = 0,
    this.halfVia,
    this.side = FamilySide.unknown,
  });

  final KinType type;

  /// Sex of person B, for gendered labels.
  final Sex sex;

  /// For grandparent / grandchild: 2 = grand, 3 = great-grand, ...
  /// For uncleAunt / nephewNiece: 1 = uncle/nephew, 2 = grand-uncle, ...
  final int generations;

  /// For cousins: 1 = first cousin, 2 = second cousin...
  final int cousinDegree;

  /// For cousins: generations removed.
  final int removed;

  /// For half siblings: the sex of the single shared parent.
  final Sex? halfVia;

  /// Which of A's parents the relationship runs through (uncle/aunt, cousin, grandparent).
  final FamilySide side;

  bool get isHalf => halfVia != null;

  @override
  String toString() =>
      'Kinship($type, sex: $sex, gen: $generations, cousin: $cousinDegree, removed: $removed, '
      'half: $halfVia, side: $side)';
}

/// Works out how [b] is related to [a].
Kinship kinshipOf(FamilyGraph g, String a, String b) {
  final pb = g[b];
  final sexB = pb?.sex ?? Sex.unknown;
  if (a == b) return const Kinship(KinType.self);

  if (g.unionsOf(a).any((u) => u.partnerOf(a) == b)) {
    return Kinship(KinType.spouse, sex: sexB);
  }

  final blood = _blood(g, a, b, sexB);
  if (blood != null) return blood;

  // Marriage connections, one step: spouse's blood relative, or blood relative's spouse.
  for (final s in g.spousesOf(a)) {
    if (g.spousesOf(s.id).any((p) => p.id == b)) {
      return Kinship(KinType.coSpouse, sex: sexB);
    }
    final k = _blood(g, s.id, b, sexB);
    if (k == null) continue;
    return switch (k.type) {
      KinType.parent => Kinship(KinType.parentInLaw, sex: sexB),
      KinType.child => Kinship(KinType.stepChild, sex: sexB),
      KinType.sibling => Kinship(KinType.siblingInLaw, sex: sexB),
      _ => Kinship(KinType.relatedByMarriage, sex: sexB),
    };
  }
  for (final s in g.spousesOf(b)) {
    final k = _blood(g, a, s.id, sexB);
    if (k == null) continue;
    return switch (k.type) {
      KinType.parent => Kinship(KinType.stepParent, sex: sexB),
      KinType.child => Kinship(KinType.childInLaw, sex: sexB),
      KinType.sibling => Kinship(KinType.siblingInLaw, sex: sexB),
      _ => Kinship(KinType.relatedByMarriage, sex: sexB),
    };
  }
  return Kinship(KinType.none, sex: sexB);
}

/// Distance (in generations) from [id] to each of its ancestors, including itself at 0.
Map<String, int> _ancestors(FamilyGraph g, String id) {
  final dist = <String, int>{id: 0};
  var frontier = [id];
  var d = 0;
  while (frontier.isNotEmpty) {
    d++;
    final next = <String>[];
    for (final p in frontier) {
      for (final l in g.parentLinksOf(p)) {
        if (!dist.containsKey(l.parentId)) {
          dist[l.parentId] = d;
          next.add(l.parentId);
        }
      }
    }
    frontier = next;
  }
  return dist;
}

Kinship? _blood(FamilyGraph g, String a, String b, Sex sexB) {
  final ancA = _ancestors(g, a);
  final ancB = _ancestors(g, b);

  String? common;
  var best = 1 << 30;
  for (final e in ancA.entries) {
    final db = ancB[e.key];
    if (db == null) continue;
    final total = e.value + db;
    if (total < best) {
      best = total;
      common = e.key;
    }
  }
  if (common == null) return null;

  final up = ancA[common]!; // generations from A up to the common ancestor
  final down = ancB[common]!; // generations from B up to the common ancestor
  final side = up >= 2 ? _side(g, a, common, ancA) : FamilySide.unknown;

  if (up == 0) {
    return down == 1
        ? Kinship(KinType.child, sex: sexB)
        : Kinship(KinType.grandchild, sex: sexB, generations: down);
  }
  if (down == 0) {
    final s = up >= 2 ? side : FamilySide.unknown;
    return up == 1
        ? Kinship(KinType.parent, sex: sexB)
        : Kinship(KinType.grandparent, sex: sexB, generations: up, side: s);
  }
  if (up == 1 && down == 1) {
    final shared = g.sharedParents(a, b);
    if (shared.length >= 2) return Kinship(KinType.sibling, sex: sexB);
    final via = g[shared.first]?.sex ?? Sex.unknown;
    return Kinship(KinType.sibling, sex: sexB, halfVia: via);
  }
  if (down == 1) {
    return Kinship(KinType.uncleAunt, sex: sexB, generations: up - 1, side: side);
  }
  if (up == 1) {
    return Kinship(KinType.nephewNiece, sex: sexB, generations: down - 1);
  }
  final lower = up < down ? up : down;
  return Kinship(
    KinType.cousin,
    sex: sexB,
    cousinDegree: lower - 1,
    removed: (up - down).abs(),
    side: side,
  );
}

/// Which of A's parents leads to [ancestor].
FamilySide _side(FamilyGraph g, String a, String ancestor, Map<String, int> ancA) {
  final target = ancA[ancestor]!;
  for (final parent in g.parentsOf(a)) {
    final fromParent = _ancestors(g, parent.id)[ancestor];
    if (fromParent != null && fromParent == target - 1) {
      return switch (parent.sex) {
        Sex.male => FamilySide.paternal,
        Sex.female => FamilySide.maternal,
        Sex.unknown => FamilySide.unknown,
      };
    }
  }
  return FamilySide.unknown;
}
