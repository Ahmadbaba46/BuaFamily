import 'package:bua_family/domain/kinship.dart';
import 'package:bua_family/domain/tree_layout.dart';
import 'package:bua_family/models/family_graph.dart';
import 'package:bua_family/models/person.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test family:
///
///   Ahmadu (m) ── Hauwa (f)          Ahmadu ── Zainab (f)
///        │                                 │
///   Musa (m) ── Amina (f)               Sani (m)
///        │                                 │
///   Aisha (f), Bello (m)                Usman (m)
///        │                                 │
///   Fatima (f)                          Kabir (m)
FamilyGraph buildFamily() {
  Person p(String id, Sex sex, [int? year]) =>
      Person(id: id, firstName: id, sex: sex, birthDate: year == null ? null : DateTime(year));
  var n = 0;
  ParentLink link(String parent, String child, [ParentKind kind = ParentKind.biological]) =>
      ParentLink(id: 'l${n++}', parentId: parent, childId: child, kind: kind);
  FamilyUnion union(String a, String b, [int? order]) =>
      FamilyUnion(id: 'u${n++}', partner1Id: a, partner2Id: b, sortOrder: order);

  return FamilyGraph(
    persons: [
      p('ahmadu', Sex.male, 1920),
      p('hauwa', Sex.female),
      p('zainab', Sex.female),
      p('musa', Sex.male, 1950),
      p('amina', Sex.female),
      p('sani', Sex.male, 1955),
      p('aisha', Sex.female, 1980),
      p('bello', Sex.male, 1978),
      p('usman', Sex.male, 1982),
      p('fatima', Sex.female, 2005),
      p('kabir', Sex.male, 2008),
      p('stranger', Sex.male),
    ],
    unions: [
      union('ahmadu', 'zainab', 2),
      union('ahmadu', 'hauwa', 1),
      union('musa', 'amina'),
    ],
    links: [
      link('ahmadu', 'musa'),
      link('hauwa', 'musa'),
      link('ahmadu', 'sani'),
      link('zainab', 'sani'),
      link('musa', 'aisha'),
      link('amina', 'aisha'),
      link('musa', 'bello'),
      link('amina', 'bello'),
      link('sani', 'usman'),
      link('aisha', 'fatima'),
      link('usman', 'kabir'),
    ],
  );
}

void main() {
  final g = buildFamily();
  Kinship k(String a, String b) => kinshipOf(g, a, b);

  group('FamilyGraph', () {
    test('spouses follow sort order', () {
      expect(g.spousesOf('ahmadu').map((p) => p.id), ['hauwa', 'zainab']);
    });

    test('children grouped by mother in spouse order', () {
      final groups = g.childrenByOtherParent('ahmadu');
      expect(groups.keys.toList(), ['hauwa', 'zainab']);
      expect(groups['hauwa']!.map((p) => p.id), ['musa']);
      expect(groups['zainab']!.map((p) => p.id), ['sani']);
    });

    test('siblings include half siblings, ordered by birth', () {
      expect(g.siblingsOf('musa').map((p) => p.id), ['sani']);
      expect(g.siblingsOf('aisha').map((p) => p.id), ['bello']);
    });

    test('suggested root is the founding ancestor', () {
      expect(g.suggestedRoot(), 'ahmadu');
      expect(g.descendantCount('ahmadu'), 7);
    });

    test('search matches all words in any order', () {
      final g2 = FamilyGraph(persons: [
        const Person(id: '1', firstName: 'Aisha', lastName: 'Bua', title: 'Hajiya'),
        const Person(id: '2', firstName: 'Musa', lastName: 'Bua'),
      ], unions: const [], links: const []);
      expect(g2.search('bua aisha').map((p) => p.id), ['1']);
      expect(g2.search('hajiya').map((p) => p.id), ['1']);
      expect(g2.search('').length, 2);
    });
  });

  group('kinship', () {
    test('direct line', () {
      expect(k('aisha', 'aisha').type, KinType.self);
      expect(k('aisha', 'musa').type, KinType.parent);
      expect(k('musa', 'aisha').type, KinType.child);
      final gp = k('aisha', 'ahmadu');
      expect(gp.type, KinType.grandparent);
      expect(gp.generations, 2);
      expect(gp.side, FamilySide.paternal);
      expect(k('fatima', 'ahmadu').generations, 3);
      expect(k('ahmadu', 'fatima').type, KinType.grandchild);
    });

    test('full and half siblings', () {
      final full = k('aisha', 'bello');
      expect(full.type, KinType.sibling);
      expect(full.isHalf, isFalse);
      expect(full.sex, Sex.male);

      final half = k('musa', 'sani');
      expect(half.type, KinType.sibling);
      expect(half.halfVia, Sex.male, reason: 'shared father only');
    });

    test('uncles, nephews and cousins', () {
      final uncle = k('aisha', 'sani');
      expect(uncle.type, KinType.uncleAunt);
      expect(uncle.generations, 1);
      expect(uncle.side, FamilySide.paternal);

      expect(k('sani', 'aisha').type, KinType.nephewNiece);

      final cousin = k('aisha', 'usman');
      expect(cousin.type, KinType.cousin);
      expect(cousin.cousinDegree, 1);
      expect(cousin.removed, 0);

      final removed = k('fatima', 'usman');
      expect(removed.type, KinType.cousin);
      expect(removed.cousinDegree, 1);
      expect(removed.removed, 1);

      final second = k('fatima', 'kabir');
      expect(second.cousinDegree, 2);
      expect(second.removed, 0);
    });

    test('marriage relations', () {
      expect(k('ahmadu', 'hauwa').type, KinType.spouse);
      expect(k('hauwa', 'zainab').type, KinType.coSpouse);
      expect(k('hauwa', 'sani').type, KinType.stepChild);
      expect(k('sani', 'hauwa').type, KinType.stepParent);
      expect(k('amina', 'ahmadu').type, KinType.parentInLaw);
      expect(k('ahmadu', 'amina').type, KinType.childInLaw);
      expect(k('amina', 'sani').type, KinType.siblingInLaw);
      expect(k('amina', 'usman').type, KinType.relatedByMarriage);
      expect(k('aisha', 'stranger').type, KinType.none);
    });
  });

  group('tree layout', () {
    test('places every descendant and spouse once, without overlaps', () {
      final layout = layoutDescendants(g, 'ahmadu');
      final ids = layout.nodes.map((n) => n.personId).toList();
      expect(ids.toSet(), {
        'ahmadu', 'hauwa', 'zainab', 'musa', 'amina', 'sani',
        'aisha', 'bello', 'usman', 'fatima', 'kabir',
      });
      expect(ids.length, ids.toSet().length);

      const m = TreeMetrics();
      for (var i = 0; i < layout.nodes.length; i++) {
        for (var j = i + 1; j < layout.nodes.length; j++) {
          final a = layout.nodes[i].offset, b = layout.nodes[j].offset;
          final overlap = (a.dx - b.dx).abs() < m.nodeWidth && (a.dy - b.dy).abs() < m.nodeHeight;
          expect(overlap, isFalse, reason: '${layout.nodes[i].personId} overlaps ${layout.nodes[j].personId}');
        }
      }
    });

    test('generations go downwards and spouses sit beside', () {
      final layout = layoutDescendants(g, 'ahmadu');
      final ahmadu = layout.nodeFor('ahmadu')!;
      final hauwa = layout.nodes.firstWhere((n) => n.personId == 'hauwa');
      final musa = layout.nodeFor('musa')!;
      final fatima = layout.nodeFor('fatima')!;
      expect(hauwa.offset.dy, ahmadu.offset.dy);
      expect(hauwa.isSpouse, isTrue);
      expect(hauwa.offset.dx, greaterThan(ahmadu.offset.dx));
      expect(musa.offset.dy, greaterThan(ahmadu.offset.dy));
      expect(fatima.depth, 3);
    });

    test('collapsed nodes hide descendants and report the count', () {
      final layout = layoutDescendants(g, 'ahmadu', collapsed: {'musa'});
      expect(layout.nodes.any((n) => n.personId == 'aisha'), isFalse);
      expect(layout.nodeFor('musa')!.hiddenDescendants, 3);
      expect(layout.nodes.any((n) => n.personId == 'kabir'), isTrue);
    });

    test('collapseBeyondDepth collapses parents below the given depth', () {
      expect(collapseBeyondDepth(g, 'ahmadu', 2), {'aisha', 'usman'});
      expect(collapseBeyondDepth(g, 'ahmadu', 0), {'ahmadu'});
    });

    test('a person reachable twice is drawn once plus a repeat marker', () {
      // Cousin marriage: Aisha marries her cousin Usman.
      final g2 = FamilyGraph(
        persons: [...g.persons.values],
        unions: [...g.unions, const FamilyUnion(id: 'ux', partner1Id: 'aisha', partner2Id: 'usman')],
        links: g.links,
      );
      final layout = layoutDescendants(g2, 'ahmadu');
      final usman = layout.nodes.where((n) => n.personId == 'usman').toList();
      expect(usman.length, 2);
      expect(layout.nodes.where((n) => n.personId == 'kabir').length, 1);
    });

    test('unknown root gives an empty layout', () {
      expect(layoutDescendants(g, 'nobody').nodes, isEmpty);
    });
  });
}
