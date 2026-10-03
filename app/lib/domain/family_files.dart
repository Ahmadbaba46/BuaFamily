import 'package:collection/collection.dart';

import '../models/family_graph.dart';
import '../models/person.dart';

// =============================================================================
// Reading and writing the family as GEDCOM (genealogy apps) and CSV
// (spreadsheets). Both go through [ImportFile], so an import can be reviewed
// against the tree with [planImport] before anything is added.
// =============================================================================

/// One person read from a file. [key] links them to relationships in the same
/// file; [fields] uses the database's person column names.
class ImportPerson {
  const ImportPerson({required this.key, required this.fields});

  final String key;
  final Map<String, dynamic> fields;

  String get firstName => (fields['first_name'] as String?) ?? '';
  String? get lastName => fields['last_name'] as String?;
  String get name => [fields['title'], firstName, fields['middle_name'], lastName]
      .whereType<String>()
      .where((s) => s.trim().isNotEmpty)
      .join(' ');
  int? get birthYear => DateTime.tryParse((fields['birth_date'] as String?) ?? '')?.year;
}

class ImportLink {
  const ImportLink(this.parent, this.child, [this.kind = ParentKind.biological]);

  final String parent;
  final String child;
  final ParentKind kind;
}

class ImportUnion {
  const ImportUnion(this.a, this.b, [this.status = UnionStatus.married]);

  final String a;
  final String b;
  final UnionStatus status;
}

class ImportFile {
  const ImportFile({this.people = const [], this.parents = const [], this.unions = const []});

  final List<ImportPerson> people;
  final List<ImportLink> parents;
  final List<ImportUnion> unions;
}

/// Contact and health details added to an export when asked for, keyed by
/// person id (rows of person_contacts and person_health).
class ExportDetails {
  const ExportDetails({this.contacts = const {}, this.health = const {}});

  final Map<String, Map<String, dynamic>> contacts;
  final Map<String, Map<String, dynamic>> health;
}

// -----------------------------------------------------------------------------
// Review
// -----------------------------------------------------------------------------

class ImportRow {
  ImportRow(this.person, this.match) : include = true;

  final ImportPerson person;

  /// Someone already in the tree who is the same person.
  Person? match;

  /// For new people: whether to add them.
  bool include;

  bool get isNew => match == null;
}

class ImportPlan {
  ImportPlan(this.file, this.rows);

  final ImportFile file;
  final List<ImportRow> rows;

  int get newCount => rows.where((r) => r.isNew && r.include).length;
  int get matchCount => rows.where((r) => !r.isNew).length;

  int get linkCount {
    final keys = {for (final r in rows) if (!r.isNew || r.include) r.person.key};
    return file.parents.where((l) => keys.contains(l.parent) && keys.contains(l.child)).length +
        file.unions.where((u) => keys.contains(u.a) && keys.contains(u.b)).length;
  }

  /// The argument for the admin_import database function.
  Map<String, dynamic> toJson() => {
        'people': [
          for (final r in rows)
            if (!r.isNew)
              {'key': r.person.key, 'id': r.match!.id}
            else if (r.include)
              {'key': r.person.key, ...r.person.fields},
        ],
        'parents': [
          for (final l in file.parents) {'parent': l.parent, 'child': l.child, 'kind': l.kind.name},
        ],
        'unions': [
          for (final u in file.unions) {'a': u.a, 'b': u.b, 'status': u.status.name},
        ],
      };
}

String _norm(String? s) => (s ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9ɓɗƙƴ]'), '');

/// Matches people in [file] with people already in [graph]: by id when the file
/// came from this app, otherwise by first and last name and birth year.
ImportPlan planImport(ImportFile file, FamilyGraph graph) {
  final byName = groupBy(graph.persons.values, (Person p) => '${_norm(p.firstName)}|${_norm(p.lastName)}');
  final taken = <String>{};
  final rows = <ImportRow>[];
  for (final ip in file.people) {
    Person? match = graph[ip.key];
    if (match == null) {
      final candidates = (byName['${_norm(ip.firstName)}|${_norm(ip.lastName)}'] ?? const <Person>[])
          .where((p) => !taken.contains(p.id))
          .where((p) => ip.birthYear == null || p.birthDate == null || p.birthDate!.year == ip.birthYear)
          .toList();
      if (candidates.length == 1) match = candidates.single;
    }
    if (match != null) taken.add(match.id);
    rows.add(ImportRow(ip, match));
  }
  return ImportPlan(file, rows);
}

// -----------------------------------------------------------------------------
// Dates
// -----------------------------------------------------------------------------

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Puts a date into [fields] as `<prefix>_date` (+ `_approx` when only the
/// year is known). Accepts 1950, 1950-03-04, 4/3/1950 and "c. 1950".
void _putDate(Map<String, dynamic> fields, String prefix, String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return;
  final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(s);
  final dmy = RegExp(r'^(\d{1,2})[/.](\d{1,2})[/.](\d{4})$').firstMatch(s);
  final year = RegExp(r'(\d{4})').firstMatch(s);
  if (iso != null) {
    fields['${prefix}_date'] = _iso(DateTime(int.parse(iso[1]!), int.parse(iso[2]!), int.parse(iso[3]!)));
  } else if (dmy != null) {
    fields['${prefix}_date'] = _iso(DateTime(int.parse(dmy[3]!), int.parse(dmy[2]!), int.parse(dmy[1]!)));
  } else if (year != null) {
    fields['${prefix}_date'] = '${year[1]}-01-01';
    fields['${prefix}_date_approx'] = true;
  }
}

String _csvDate(DateTime? d, bool approx) => d == null ? '' : (approx ? '${d.year}' : _iso(d));

// -----------------------------------------------------------------------------
// CSV
// -----------------------------------------------------------------------------

const _csvColumns = [
  'id', 'title', 'first_name', 'middle_name', 'last_name', 'nickname', 'sex', 'birth_date', 'birth_place',
  'living', 'death_date', 'death_place', 'burial_place', 'branch', 'father_id', 'mother_id', 'spouse_ids',
];
const _csvDetailColumns = ['phone', 'email', 'city', 'country', 'blood_group', 'genotype'];

/// An empty spreadsheet with the columns the import understands, and an example.
String familyCsvTemplate() => _csv([
      _csvColumns,
      ['1', 'Alhaji', 'Ahmadu', '', 'Bua', '', 'male', '1920', 'Katsina', 'no', '1990', 'Kano', 'Kano', '', '', '', '2'],
      ['2', 'Hajiya', 'Hauwa', '', 'Bua', '', 'female', '', '', 'no', '', '', '', '', '', '', '1'],
      ['3', '', 'Musa', '', 'Bua', '', 'male', '1950-03-04', 'Kano', 'yes', '', '', '', '', '1', '2', ''],
    ]);

String exportFamilyCsv(FamilyGraph g, {ExportDetails? details}) {
  final rows = <List<String>>[
    [..._csvColumns, if (details != null) ..._csvDetailColumns],
  ];
  for (final p in g.persons.values.sortedBy((p) => p.birthDate ?? DateTime(9999))) {
    final c = details?.contacts[p.id];
    final h = details?.health[p.id];
    rows.add([
      p.id, p.title ?? '', p.firstName, p.middleName ?? '', p.lastName ?? '', p.nickname ?? '', p.sex.name,
      _csvDate(p.birthDate, p.birthDateApprox), p.birthPlace ?? '', p.isLiving ? 'yes' : 'no',
      _csvDate(p.deathDate, p.deathDateApprox), p.deathPlace ?? '', p.burialPlace ?? '', p.branch ?? '',
      g.fatherOf(p.id)?.id ?? '', g.motherOf(p.id)?.id ?? '', g.spousesOf(p.id).map((s) => s.id).join('|'),
      if (details != null) ...[
        for (final k in ['phone', 'email', 'city', 'country']) '${c?[k] ?? ''}',
        for (final k in ['blood_group', 'genotype']) '${h?[k] ?? ''}',
      ],
    ]);
  }
  return _csv(rows);
}

String _csv(List<List<String>> rows) => '${rows.map((r) => r.map(_cell).join(',')).join('\r\n')}\r\n';

String _cell(String v) => RegExp(r'[",\r\n]').hasMatch(v) || v != v.trim() ? '"${v.replaceAll('"', '""')}"' : v;

/// Splits CSV text into rows (quoted cells, commas or semicolons).
List<List<String>> parseCsvRows(String text) {
  var s = text.startsWith('﻿') ? text.substring(1) : text;
  final firstLine = s.split('\n').first;
  final sep = ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length ? ';' : ',';
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    if (quoted) {
      if (ch == '"') {
        if (i + 1 < s.length && s[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == sep) {
      row.add(cell.toString());
      cell.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < s.length && s[i + 1] == '\n') i++;
      row.add(cell.toString());
      cell.clear();
      if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      cell.write(ch);
    }
  }
  row.add(cell.toString());
  if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
  return rows;
}

class FileFormatException implements Exception {
  const FileFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads a spreadsheet in the template's layout. Headers may be written
/// "First name" or "first_name"; unknown columns are ignored.
ImportFile parseFamilyCsv(String text) {
  final rows = parseCsvRows(text);
  if (rows.isEmpty) throw const FileFormatException('The file is empty.');
  final header = [for (final h in rows.first) h.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_')];
  final col = {for (final (i, h) in header.indexed) h: i};
  if (!col.containsKey('first_name')) throw const FileFormatException('No "first_name" column.');

  String? get(List<String> r, String name) {
    final i = col[name];
    if (i == null || i >= r.length) return null;
    final v = r[i].trim();
    return v.isEmpty ? null : v;
  }

  final people = <ImportPerson>[];
  final parents = <ImportLink>[];
  final unions = <ImportUnion>[];
  final seenUnions = <String>{};
  for (final (n, r) in rows.skip(1).indexed) {
    final first = get(r, 'first_name');
    if (first == null) continue;
    final key = get(r, 'id') ?? 'row${n + 2}';
    final f = <String, dynamic>{'first_name': first};
    for (final k in ['title', 'middle_name', 'last_name', 'nickname', 'birth_place', 'death_place', 'burial_place', 'branch']) {
      final v = get(r, k);
      if (v != null) f[k] = v;
    }
    final sex = get(r, 'sex')?.toLowerCase();
    f['sex'] = switch (sex) {
      'm' || 'male' || 'man' || 'namiji' => 'male',
      'f' || 'female' || 'woman' || 'mace' => 'female',
      _ => 'unknown',
    };
    _putDate(f, 'birth', get(r, 'birth_date'));
    _putDate(f, 'death', get(r, 'death_date'));
    final living = get(r, 'living')?.toLowerCase();
    f['is_living'] = living == null ? f['death_date'] == null : !{'no', 'n', 'false', '0', 'a\'a', 'deceased'}.contains(living);
    if (f['is_living'] == true) {
      f.remove('death_date');
      f.remove('death_date_approx');
    }
    people.add(ImportPerson(key: key, fields: f));

    for (final k in ['father_id', 'mother_id']) {
      final parent = get(r, k);
      if (parent != null) parents.add(ImportLink(parent, key));
    }
    for (final s in (get(r, 'spouse_ids') ?? '').split(RegExp(r'[|;]'))) {
      final other = s.trim();
      if (other.isEmpty || other == key) continue;
      final pair = ([key, other]..sort()).join('|');
      if (seenUnions.add(pair)) unions.add(ImportUnion(key, other));
    }
  }
  if (people.isEmpty) throw const FileFormatException('No people found in the file.');
  return ImportFile(people: people, parents: parents, unions: unions);
}

// -----------------------------------------------------------------------------
// GEDCOM 5.5.1
// -----------------------------------------------------------------------------

const _months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

String _gedDate(DateTime d, bool approx) =>
    approx ? 'ABT ${d.year}' : '${d.day} ${_months[d.month - 1]} ${d.year}';

class _GedLine {
  _GedLine(this.level, this.xref, this.tag, this.value);

  final int level;
  final String? xref;
  final String tag;
  final String value;
  final children = <_GedLine>[];

  _GedLine? child(String tag) => children.firstWhereOrNull((c) => c.tag == tag);
  String? val(String tag) {
    final v = child(tag)?.value.trim();
    return v == null || v.isEmpty ? null : v;
  }
}

/// Reads INDI and FAM records from a GEDCOM file.
ImportFile parseGedcom(String text) {
  final lineRe = RegExp(r'^\s*(\d+)\s+(?:(@[^@]+@)\s+)?(\S+)(?:\s(.*))?$');
  final roots = <_GedLine>[];
  final stack = <_GedLine>[];
  for (final raw in text.replaceFirst('﻿', '').split(RegExp(r'\r\n|\r|\n'))) {
    final m = lineRe.firstMatch(raw);
    if (m == null) continue;
    final line = _GedLine(int.parse(m[1]!), m[2], m[3]!.toUpperCase(), m[4] ?? '');
    while (stack.isNotEmpty && stack.last.level >= line.level) {
      stack.removeLast();
    }
    if (line.tag == 'CONT' || line.tag == 'CONC') {
      if (stack.isNotEmpty) {
        final parent = stack.last;
        final joined = parent.value + (line.tag == 'CONT' ? '\n' : '') + line.value;
        final replacement = _GedLine(parent.level, parent.xref, parent.tag, joined)..children.addAll(parent.children);
        stack[stack.length - 1] = replacement;
        final owner = stack.length > 1 ? stack[stack.length - 2].children : roots;
        owner[owner.indexOf(parent)] = replacement;
      }
      continue;
    }
    (stack.isEmpty ? roots : stack.last.children).add(line);
    stack.add(line);
  }
  if (!roots.any((r) => r.tag == 'HEAD')) throw const FileFormatException('This is not a GEDCOM file.');

  final people = <ImportPerson>[];
  for (final r in roots.where((r) => r.tag == 'INDI' && r.xref != null)) {
    final name = r.child('NAME');
    var given = name?.val('GIVN');
    var surname = name?.val('SURN');
    final nm = RegExp(r'^([^/]*)(?:/([^/]*)/)?').firstMatch(name?.value ?? '');
    given ??= nm?[1]?.trim();
    surname ??= nm?[2]?.trim();
    final givenParts = (given ?? '').split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final f = <String, dynamic>{
      'first_name': givenParts.isEmpty ? (surname ?? '?') : givenParts.first,
      if (givenParts.length > 1) 'middle_name': givenParts.skip(1).join(' '),
      if (givenParts.isNotEmpty && (surname?.isNotEmpty ?? false)) 'last_name': surname,
      'title': ?name?.val('NPFX'),
      'nickname': ?name?.val('NICK'),
      'sex': switch (r.val('SEX')?.toUpperCase()) { 'M' => 'male', 'F' => 'female', _ => 'unknown' },
    };
    final birt = r.child('BIRT');
    final deat = r.child('DEAT');
    _putGedDate(f, 'birth', birt?.val('DATE'));
    if (birt?.val('PLAC') != null) f['birth_place'] = birt!.val('PLAC');
    f['is_living'] = deat == null;
    if (deat != null) {
      _putGedDate(f, 'death', deat.val('DATE'));
      if (deat.val('PLAC') != null) f['death_place'] = deat.val('PLAC');
    }
    final buri = r.child('BURI')?.val('PLAC');
    if (buri != null) f['burial_place'] = buri;
    final note = r.children.where((c) => c.tag == 'NOTE' && !c.value.startsWith('@')).map((c) => c.value).join('\n\n');
    if (note.trim().isNotEmpty) f['biography'] = note.trim();
    people.add(ImportPerson(key: r.xref!, fields: f));
  }

  // Non-biological parents are marked under the child's FAMC.
  final pedigree = <String, ParentKind>{};
  for (final r in roots.where((r) => r.tag == 'INDI' && r.xref != null)) {
    for (final famc in r.children.where((c) => c.tag == 'FAMC')) {
      final kind = switch (famc.val('PEDI')?.toLowerCase()) {
        'adopted' => ParentKind.adopted,
        'foster' => ParentKind.foster,
        _ => null,
      };
      if (kind != null) pedigree['${famc.value.trim()}|${r.xref}'] = kind;
    }
  }

  final parents = <ImportLink>[];
  final unions = <ImportUnion>[];
  for (final fam in roots.where((r) => r.tag == 'FAM' && r.xref != null)) {
    final husb = fam.val('HUSB');
    final wife = fam.val('WIFE');
    if (husb != null && wife != null) {
      unions.add(ImportUnion(husb, wife, fam.child('DIV') != null ? UnionStatus.divorced : UnionStatus.married));
    }
    for (final chil in fam.children.where((c) => c.tag == 'CHIL')) {
      final child = chil.value.trim();
      final kind = pedigree['${fam.xref}|$child'] ?? ParentKind.biological;
      for (final parent in [?husb, ?wife]) {
        parents.add(ImportLink(parent, child, kind));
      }
    }
  }
  if (people.isEmpty) throw const FileFormatException('No people found in the file.');
  return ImportFile(people: people, parents: parents, unions: unions);
}

void _putGedDate(Map<String, dynamic> f, String prefix, String? raw) {
  if (raw == null) return;
  final s = raw.toUpperCase().trim();
  final exact = RegExp(r'^(\d{1,2}) ([A-Z]{3}) (\d{4})$').firstMatch(s);
  final month = exact == null ? -1 : _months.indexOf(exact[2]!);
  if (exact != null && month >= 0) {
    f['${prefix}_date'] = _iso(DateTime(int.parse(exact[3]!), month + 1, int.parse(exact[1]!)));
    return;
  }
  final year = RegExp(r'(\d{4})').firstMatch(s);
  if (year != null) {
    f['${prefix}_date'] = '${year[1]}-01-01';
    f['${prefix}_date_approx'] = true;
  }
}

String exportGedcom(FamilyGraph g, {ExportDetails? details, String familyName = 'Bua', DateTime? now}) {
  final out = StringBuffer();
  void line(int level, String text) {
    // GEDCOM lines are limited; long text continues with CONC/CONT.
    final parts = text.split('\n');
    for (final (i, part) in parts.indexed) {
      var rest = part;
      var first = true;
      do {
        final chunk = rest.length > 200 ? rest.substring(0, 200) : rest;
        rest = rest.substring(chunk.length);
        if (i == 0 && first) {
          out.write('$level $chunk\r\n');
        } else {
          out.write('${level + 1} ${first ? 'CONT' : 'CONC'} $chunk\r\n');
        }
        first = false;
      } while (rest.isNotEmpty);
    }
  }

  final today = now ?? DateTime.now();
  line(0, 'HEAD');
  line(1, 'SOUR BUA_FAMILY');
  line(2, 'NAME $familyName Family');
  line(1, 'DATE ${_gedDate(today, false)}');
  line(1, 'GEDC');
  line(2, 'VERS 5.5.1');
  line(2, 'FORM LINEAGE-LINKED');
  line(1, 'CHAR UTF-8');

  final people = g.persons.values.sortedBy((p) => p.birthDate ?? DateTime(9999)).toList();
  final xref = {for (final (i, p) in people.indexed) p.id: '@I${i + 1}@'};

  // Families: every couple, plus parents of children with no recorded couple.
  final fams = <String, ({String? husb, String? wife, FamilyUnion? union, List<(String, ParentKind)> kids})>{};
  String famKey(Iterable<String> parentIds) => (parentIds.toList()..sort()).join('|');
  ({String? husb, String? wife}) roles(List<String> ids) {
    final ps = ids.map((id) => g[id]!).toList();
    if (ps.length == 1) return ps.first.sex == Sex.female ? (husb: null, wife: ps.first.id) : (husb: ps.first.id, wife: null);
    final a = ps[0], b = ps[1];
    return a.sex == Sex.female || b.sex == Sex.male ? (husb: b.id, wife: a.id) : (husb: a.id, wife: b.id);
  }

  for (final u in g.unions) {
    if (g[u.partner1Id] == null || g[u.partner2Id] == null) continue;
    final r = roles([u.partner1Id, u.partner2Id]);
    fams[famKey([u.partner1Id, u.partner2Id])] = (husb: r.husb, wife: r.wife, union: u, kids: []);
  }
  for (final p in people) {
    final links = g.parentLinksOf(p.id).where((l) => g[l.parentId] != null).toList();
    final bio = links.where((l) => l.kind == ParentKind.biological).map((l) => l.parentId).take(2).toList();
    final groups = <(List<String>, ParentKind)>[
      if (bio.isNotEmpty) (bio, ParentKind.biological),
      for (final l in links.where((l) => l.kind != ParentKind.biological)) ([l.parentId], l.kind),
    ];
    for (final (ids, kind) in groups) {
      final k = famKey(ids);
      final r = roles(ids);
      fams.putIfAbsent(k, () => (husb: r.husb, wife: r.wife, union: null, kids: [])).kids.add((p.id, kind));
    }
  }
  final famList = fams.values.toList();
  final famXref = {for (final (i, _) in famList.indexed) i: '@F${i + 1}@'};

  for (final p in people) {
    line(0, '${xref[p.id]} INDI');
    final given = [p.firstName, p.middleName].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
    line(1, 'NAME $given /${p.lastName ?? ''}/');
    if (given.isNotEmpty) line(2, 'GIVN $given');
    if (p.lastName?.isNotEmpty ?? false) line(2, 'SURN ${p.lastName}');
    if (p.title?.isNotEmpty ?? false) line(2, 'NPFX ${p.title}');
    if (p.nickname?.isNotEmpty ?? false) line(2, 'NICK ${p.nickname}');
    line(1, 'SEX ${switch (p.sex) { Sex.male => 'M', Sex.female => 'F', Sex.unknown => 'U' }}');
    if (p.birthDate != null || p.birthPlace != null) {
      line(1, 'BIRT');
      if (p.birthDate != null) line(2, 'DATE ${_gedDate(p.birthDate!, p.birthDateApprox)}');
      if (p.birthPlace?.isNotEmpty ?? false) line(2, 'PLAC ${p.birthPlace}');
    }
    if (!p.isLiving) {
      if (p.deathDate == null && p.deathPlace == null) {
        line(1, 'DEAT Y');
      } else {
        line(1, 'DEAT');
        if (p.deathDate != null) line(2, 'DATE ${_gedDate(p.deathDate!, p.deathDateApprox)}');
        if (p.deathPlace?.isNotEmpty ?? false) line(2, 'PLAC ${p.deathPlace}');
      }
      if (p.burialPlace?.isNotEmpty ?? false) {
        line(1, 'BURI');
        line(2, 'PLAC ${p.burialPlace}');
      }
    }
    final c = details?.contacts[p.id];
    if (c != null && ['phone', 'email', 'address', 'city', 'country'].any((k) => (c[k] as String?)?.isNotEmpty ?? false)) {
      line(1, 'RESI');
      if ((c['address'] as String?)?.isNotEmpty ?? false) line(2, 'ADDR ${c['address']}');
      if ((c['city'] as String?)?.isNotEmpty ?? false) line(3, 'CITY ${c['city']}');
      if ((c['country'] as String?)?.isNotEmpty ?? false) line(3, 'CTRY ${c['country']}');
      if ((c['phone'] as String?)?.isNotEmpty ?? false) line(2, 'PHON ${c['phone']}');
      if ((c['email'] as String?)?.isNotEmpty ?? false) line(2, 'EMAIL ${c['email']}');
    }
    final h = details?.health[p.id];
    final health = [
      if ((h?['blood_group'] as String?)?.isNotEmpty ?? false) 'Blood group: ${h!['blood_group']}',
      if ((h?['genotype'] as String?)?.isNotEmpty ?? false) 'Genotype: ${h!['genotype']}',
    ];
    if (p.biography?.trim().isNotEmpty ?? false) line(1, 'NOTE ${p.biography!.trim()}');
    if (health.isNotEmpty) line(1, 'NOTE ${health.join('; ')}');
    for (final (i, f) in famList.indexed) {
      for (final (kid, kind) in f.kids) {
        if (kid != p.id) continue;
        line(1, 'FAMC ${famXref[i]}');
        if (kind != ParentKind.biological) line(2, 'PEDI ${kind == ParentKind.adopted ? 'adopted' : 'foster'}');
      }
      if (f.husb == p.id || f.wife == p.id) line(1, 'FAMS ${famXref[i]}');
    }
  }
  for (final (i, f) in famList.indexed) {
    line(0, '${famXref[i]} FAM');
    if (f.husb != null) line(1, 'HUSB ${xref[f.husb]}');
    if (f.wife != null) line(1, 'WIFE ${xref[f.wife]}');
    final u = f.union;
    if (u != null) {
      line(1, 'MARR');
      if (u.startDate != null) line(2, 'DATE ${_gedDate(u.startDate!, false)}');
      if (u.status == UnionStatus.divorced) line(1, 'DIV Y');
    }
    for (final (kid, _) in f.kids) {
      line(1, 'CHIL ${xref[kid]}');
    }
  }
  line(0, 'TRLR');
  return out.toString();
}
