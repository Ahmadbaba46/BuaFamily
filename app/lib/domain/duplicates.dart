import '../models/family_graph.dart';
import '../models/person.dart';

/// Why two records may be the same person.
enum DuplicateReason { sameName, similarName, sameParents, sameSpouse, sameBirthYear, sameLastName }

class DuplicatePair {
  const DuplicatePair(this.a, this.b, this.score, this.reasons);

  final Person a;
  final Person b;

  /// Higher is more likely; pairs below [minScore] aren't suggested.
  final int score;
  final List<DuplicateReason> reasons;

  /// The pair in a fixed order (as not_duplicates stores it).
  (String, String) get key => a.id.compareTo(b.id) < 0 ? (a.id, b.id) : (b.id, a.id);
}

const minScore = 4;

/// Common spellings of the same name, folded to one.
const _variants = {
  'mohammed': 'muhammad', 'mohammad': 'muhammad', 'muhammed': 'muhammad', 'mohamed': 'muhammad',
  'muhamad': 'muhammad', 'muhammadu': 'muhammad', 'mamman': 'muhammad',
  'aishatu': 'aisha', 'aishah': 'aisha', 'ayesha': 'aisha',
  'fatimah': 'fatima', 'fatimatu': 'fatima', 'fatsima': 'fatima',
  'abubakr': 'abubakar', 'abubakir': 'abubakar',
  'uthman': 'usman', 'usmanu': 'usman', 'othman': 'usman', 'osman': 'usman',
  'ibrahima': 'ibrahim', 'ibrahimu': 'ibrahim',
  'zainabu': 'zainab', 'zaynab': 'zainab',
  'hawwa': 'hauwa', 'hauwau': 'hauwa',
  'yusufu': 'yusuf', 'yussuf': 'yusuf', 'yusif': 'yusuf',
  'mariam': 'maryam', 'maryamu': 'maryam', 'mairo': 'maryam',
  'khadijah': 'khadija', 'hadiza': 'khadija', 'hadizatu': 'khadija', 'khadijat': 'khadija',
  'halimah': 'halima', 'halimatu': 'halima',
  'abdullahi': 'abdullah', 'abdallah': 'abdullah',
  'sulaiman': 'suleiman', 'sulaimanu': 'suleiman', 'suleimanu': 'suleiman',
  'ismaila': 'ismail', 'ismaili': 'ismail',
  'idrisu': 'idris', 'adamu': 'adam', 'musa': 'musa', 'isah': 'isa', 'isa': 'isa',
  'kabir': 'kabiru', 'bashiru': 'bashir', 'nasiru': 'nasir', 'sani': 'sani',
};

/// A name reduced for comparing: no accents or apostrophes, letters only,
/// doubled letters as one, common spellings joined.
String nameKey(String? name) {
  final letters = searchFold(name ?? '').replaceAll(RegExp(r'[^a-z]'), '');
  final v = _variants[letters] ?? letters;
  return v.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);
}

/// Edit distance of at most one (a typo or one letter more or less).
bool _closeTo(String a, String b) {
  if (a == b) return true;
  if ((a.length - b.length).abs() > 1 || a.length < 4 || b.length < 4) return false;
  var i = 0, j = 0, edits = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (++edits > 1) return false;
    if (a.length > b.length) {
      i++;
    } else if (b.length > a.length) {
      j++;
    } else {
      i++;
      j++;
    }
  }
  return edits + (a.length - i) + (b.length - j) <= 1;
}

/// Likely duplicates in the tree, most likely first. [notDuplicates] are pairs
/// an admin said are different people.
List<DuplicatePair> findDuplicates(FamilyGraph g, {Set<(String, String)> notDuplicates = const {}}) {
  final people = g.persons.values.toList();
  // Compare only people whose first names start alike.
  final byStart = <String, List<Person>>{};
  for (final p in people) {
    final k = nameKey(p.firstName);
    if (k.isEmpty) continue;
    byStart.putIfAbsent(k.substring(0, k.length < 2 ? k.length : 2), () => []).add(p);
  }

  final out = <DuplicatePair>[];
  for (final group in byStart.values) {
    for (var x = 0; x < group.length; x++) {
      for (var y = x + 1; y < group.length; y++) {
        final pair = _compare(g, group[x], group[y]);
        if (pair != null && !notDuplicates.contains(pair.key)) out.add(pair);
      }
    }
  }
  out.sort((p, q) => q.score.compareTo(p.score));
  return out;
}

DuplicatePair? _compare(FamilyGraph g, Person a, Person b) {
  if (a.sex != Sex.unknown && b.sex != Sex.unknown && a.sex != b.sex) return null;
  final fa = nameKey(a.firstName), fb = nameKey(b.firstName);
  final reasons = <DuplicateReason>[];
  var score = 0;
  if (fa == fb) {
    score += 3;
    reasons.add(DuplicateReason.sameName);
  } else if (_closeTo(fa, fb)) {
    score += 2;
    reasons.add(DuplicateReason.similarName);
  } else {
    return null;
  }

  // Already related to each other: two different people.
  if (g.parentsOf(a.id).any((p) => p.id == b.id) ||
      g.parentsOf(b.id).any((p) => p.id == a.id) ||
      g.spousesOf(a.id).any((p) => p.id == b.id)) {
    return null;
  }

  final ya = a.birthDate?.year, yb = b.birthDate?.year;
  if (ya != null && yb != null) {
    final gap = (ya - yb).abs();
    if (gap > 5) return null;
    if (gap <= 1) {
      score += 2;
      reasons.add(DuplicateReason.sameBirthYear);
    }
  }

  final la = nameKey(a.lastName), lb = nameKey(b.lastName);
  if (la.isNotEmpty && lb.isNotEmpty) {
    if (la != lb) score -= 2;
    if (la == lb) {
      score += 1;
      reasons.add(DuplicateReason.sameLastName);
    }
  }

  final pa = {for (final p in g.parentsOf(a.id)) p.id};
  final pb = {for (final p in g.parentsOf(b.id)) p.id};
  if (pa.intersection(pb).isNotEmpty) {
    score += 3;
    reasons.add(DuplicateReason.sameParents);
  }
  final sa = {for (final p in g.spousesOf(a.id)) p.id};
  final sb = {for (final p in g.spousesOf(b.id)) p.id};
  if (sa.intersection(sb).isNotEmpty) {
    score += 3;
    reasons.add(DuplicateReason.sameSpouse);
  }

  // Siblings often share a name only by accident when both have full records:
  // twins and namesakes. Two complete, different birth dates are a strong no.
  if (a.birthDate != null && b.birthDate != null && !a.birthDateApprox && !b.birthDateApprox && a.birthDate != b.birthDate) {
    score -= 3;
  }
  return score >= minScore ? DuplicatePair(a, b, score, reasons) : null;
}
