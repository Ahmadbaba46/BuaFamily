import 'person.dart';

enum UnionStatus { married, divorced, widowed, separated }

enum ParentKind { biological, adopted, foster, step }

class FamilyUnion {
  const FamilyUnion({
    required this.id,
    required this.partner1Id,
    required this.partner2Id,
    this.status = UnionStatus.married,
    this.startDate,
    this.sortOrder,
  });

  final String id;
  final String partner1Id;
  final String partner2Id;
  final UnionStatus status;
  final DateTime? startDate;
  final int? sortOrder;

  factory FamilyUnion.fromJson(Map<String, dynamic> j) => FamilyUnion(
        id: j['id'] as String,
        partner1Id: j['partner1_id'] as String,
        partner2Id: j['partner2_id'] as String,
        status: UnionStatus.values.byName(j['status'] as String? ?? 'married'),
        startDate: j['start_date'] == null ? null : DateTime.tryParse(j['start_date'] as String),
        sortOrder: j['sort_order'] as int?,
      );

  String? partnerOf(String personId) => partner1Id == personId
      ? partner2Id
      : partner2Id == personId
          ? partner1Id
          : null;
}

class ParentLink {
  const ParentLink({
    required this.id,
    required this.parentId,
    required this.childId,
    this.kind = ParentKind.biological,
  });

  final String id;
  final String parentId;
  final String childId;
  final ParentKind kind;

  factory ParentLink.fromJson(Map<String, dynamic> j) => ParentLink(
        id: j['id'] as String,
        parentId: j['parent_id'] as String,
        childId: j['child_id'] as String,
        kind: ParentKind.values.byName(j['kind'] as String? ?? 'biological'),
      );
}

/// The whole family in memory, with fast lookups. Up to a few thousand people
/// fits comfortably on a phone, so the app loads it once and works locally.
class FamilyGraph {
  FamilyGraph({
    required Iterable<Person> persons,
    required this.unions,
    required this.links,
  }) : persons = {for (final p in persons) p.id: p} {
    for (final l in links) {
      _parents.putIfAbsent(l.childId, () => []).add(l);
      _children.putIfAbsent(l.parentId, () => []).add(l);
    }
    for (final u in unions) {
      _unions.putIfAbsent(u.partner1Id, () => []).add(u);
      _unions.putIfAbsent(u.partner2Id, () => []).add(u);
    }
  }

  static final empty = FamilyGraph(persons: const [], unions: const [], links: const []);

  final Map<String, Person> persons;
  final List<FamilyUnion> unions;
  final List<ParentLink> links;

  final Map<String, List<ParentLink>> _parents = {};
  final Map<String, List<ParentLink>> _children = {};
  final Map<String, List<FamilyUnion>> _unions = {};

  Person? operator [](String id) => persons[id];

  List<ParentLink> parentLinksOf(String id) => _parents[id] ?? const [];
  List<ParentLink> childLinksOf(String id) => _children[id] ?? const [];

  List<Person> parentsOf(String id) => _people(parentLinksOf(id).map((l) => l.parentId));

  Person? fatherOf(String id) => _firstWithSex(parentsOf(id), Sex.male);
  Person? motherOf(String id) => _firstWithSex(parentsOf(id), Sex.female);

  /// Children ordered by birth date (unknown dates last).
  List<Person> childrenOf(String id) =>
      _byBirth(_people(childLinksOf(id).map((l) => l.childId)));

  /// Unions of [id], ordered by sort_order then start date.
  List<FamilyUnion> unionsOf(String id) {
    final list = [...?_unions[id]];
    list.sort((a, b) {
      final so = (a.sortOrder ?? 1 << 20).compareTo(b.sortOrder ?? 1 << 20);
      if (so != 0) return so;
      return (a.startDate ?? DateTime(9999)).compareTo(b.startDate ?? DateTime(9999));
    });
    return list;
  }

  List<Person> spousesOf(String id) => _people(unionsOf(id).map((u) => u.partnerOf(id)!));

  /// Children of [id] grouped by their other parent (null key = unknown).
  /// Keys follow the order of [spousesOf], unknown last.
  Map<String?, List<Person>> childrenByOtherParent(String id) {
    final result = <String?, List<Person>>{for (final s in spousesOf(id)) s.id: []};
    for (final child in childrenOf(id)) {
      final other = parentLinksOf(child.id)
          .map((l) => l.parentId)
          .where((p) => p != id)
          .firstOrNull;
      result.putIfAbsent(other, () => []).add(child);
    }
    final unknown = result.remove(null);
    if (unknown != null) result[null] = unknown;
    return result;
  }

  /// Siblings (full and half), ordered by birth.
  List<Person> siblingsOf(String id) {
    final parentIds = parentLinksOf(id).map((l) => l.parentId).toSet();
    final ids = <String>{};
    for (final p in parentIds) {
      for (final l in childLinksOf(p)) {
        if (l.childId != id) ids.add(l.childId);
      }
    }
    return _byBirth(_people(ids));
  }

  /// Parents shared between two people.
  Set<String> sharedParents(String a, String b) => parentLinksOf(a)
      .map((l) => l.parentId)
      .toSet()
      .intersection(parentLinksOf(b).map((l) => l.parentId).toSet());

  /// Number of descendants (each counted once).
  int descendantCount(String id) {
    final seen = <String>{};
    final stack = [id];
    while (stack.isNotEmpty) {
      for (final l in childLinksOf(stack.removeLast())) {
        if (seen.add(l.childId)) stack.add(l.childId);
      }
    }
    return seen.length;
  }

  /// The best default root for the tree: the parentless person with the most
  /// descendants.
  String? suggestedRoot() {
    String? best;
    var bestCount = -1;
    for (final p in persons.values) {
      if (parentLinksOf(p.id).isNotEmpty) continue;
      final c = descendantCount(p.id);
      if (c > bestCount || (c == bestCount && p.sex == Sex.male && persons[best]?.sex != Sex.male)) {
        best = p.id;
        bestCount = c;
      }
    }
    return best;
  }

  List<Person> search(String query) {
    final list = persons.values.where((p) => p.matches(query)).toList();
    list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return list;
  }

  List<Person> _people(Iterable<String> ids) =>
      ids.map((id) => persons[id]).whereType<Person>().toList();

  static Person? _firstWithSex(List<Person> people, Sex sex) =>
      people.where((p) => p.sex == sex).firstOrNull;

  static List<Person> _byBirth(List<Person> people) {
    people.sort((a, b) => (a.birthDate ?? DateTime(9999)).compareTo(b.birthDate ?? DateTime(9999)));
    return people;
  }
}
