import 'package:bua_family/domain/family_files.dart';
import 'package:bua_family/domain/tree_pdf.dart';
import 'package:bua_family/models/family_graph.dart';
import 'package:bua_family/models/person.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'domain_test.dart' show buildFamily;

void main() {
  test('CSV cells with commas, quotes and new lines survive', () {
    final rows = parseCsvRows('a,b,c\r\n"Kano, Nigeria","He said ""hi""","two\nlines"\r\n');
    expect(rows, [
      ['a', 'b', 'c'],
      ['Kano, Nigeria', 'He said "hi"', 'two\nlines'],
    ]);
    // Spreadsheets saved with semicolons (common in some locales).
    expect(parseCsvRows('first_name;last_name\nMusa;Bua'), [
      ['first_name', 'last_name'],
      ['Musa', 'Bua'],
    ]);
  });

  test('the template reads back into people, parents and a couple', () {
    final f = parseFamilyCsv(familyCsvTemplate());
    expect(f.people.map((p) => p.firstName), ['Ahmadu', 'Hauwa', 'Musa']);
    final ahmadu = f.people.first.fields;
    expect(ahmadu['birth_date'], '1920-01-01');
    expect(ahmadu['birth_date_approx'], true);
    expect(ahmadu['is_living'], false);
    expect(f.people[2].fields['birth_date'], '1950-03-04');
    expect(f.parents.map((l) => '${l.parent}>${l.child}'), ['1>3', '2>3']);
    expect(f.unions.length, 1);
  });

  test('friendly headers and values are understood', () {
    final f = parseFamilyCsv('First name,Last name,Sex,Birth date,Living\nAisha,Bua,F,4/3/1984,\nMusa,Bua,namiji,1950,no\n');
    expect(f.people[0].fields['sex'], 'female');
    expect(f.people[0].fields['birth_date'], '1984-03-04');
    expect(f.people[0].fields['is_living'], true);
    expect(f.people[1].fields['sex'], 'male');
    expect(f.people[1].fields['is_living'], false);
    expect(() => parseFamilyCsv('name\nX'), throwsA(isA<FileFormatException>()));
  });

  test('CSV export round-trips and matches everyone by id', () {
    final g = buildFamily();
    final csv = exportFamilyCsv(g);
    final f = parseFamilyCsv(csv);
    expect(f.people.length, g.persons.length);
    final plan = planImport(f, g);
    expect(plan.matchCount, g.persons.length);
    expect(plan.newCount, 0);
  });

  test('GEDCOM export round-trips people, couples and parents', () {
    final g = buildFamily();
    final ged = exportGedcom(g, now: DateTime(2026, 10, 3));
    expect(ged, startsWith('0 HEAD'));
    expect(ged, contains('1 DATE 3 OCT 2026'));
    expect(ged.trim(), endsWith('0 TRLR'));

    final f = parseGedcom(ged);
    expect(f.people.length, g.persons.length);
    expect(f.unions.length, g.unions.length);
    final kids = f.parents.map((l) => l.child).toSet();
    expect(kids.length, g.links.map((l) => l.childId).toSet().length);
    // Approximate birth years come back as approximate.
    final ahmadu = f.people.firstWhere((p) => p.firstName == 'ahmadu');
    expect(ahmadu.fields['birth_date'], '1920-01-01');
    expect(ahmadu.fields['birth_date_approx'], isNull);
  });

  test('GEDCOM names, dates, places and long notes', () {
    final f = parseGedcom('''
0 HEAD
1 GEDC
2 VERS 5.5.1
0 @I1@ INDI
1 NAME Musa Ibrahim /Bua/
2 NPFX Alhaji
1 SEX M
1 BIRT
2 DATE ABT 1950
2 PLAC Kano
1 DEAT
2 DATE 12 MAR 2001
1 NOTE First line
2 CONT second line
0 @I2@ INDI
1 NAME Aisha /Bua/
1 SEX F
1 FAMC @F1@
2 PEDI adopted
0 @F1@ FAM
1 HUSB @I1@
1 CHIL @I2@
0 TRLR
''');
    final musa = f.people.first.fields;
    expect(musa['first_name'], 'Musa');
    expect(musa['middle_name'], 'Ibrahim');
    expect(musa['last_name'], 'Bua');
    expect(musa['title'], 'Alhaji');
    expect(musa['birth_date_approx'], true);
    expect(musa['birth_place'], 'Kano');
    expect(musa['death_date'], '2001-03-12');
    expect(musa['is_living'], false);
    expect(musa['biography'], 'First line\nsecond line');
    expect(f.parents.single.kind, ParentKind.adopted);
    expect(() => parseGedcom('hello'), throwsA(isA<FileFormatException>()));
  });

  test('matching by name and birth year; the rest are new', () {
    final g = FamilyGraph(persons: const [
      Person(id: 'a', firstName: 'Musa', lastName: 'Bua'),
      Person(id: 'b', firstName: 'Sani', lastName: 'Bua'),
    ], unions: const [], links: const []);
    final f = parseFamilyCsv('id,first_name,last_name,birth_date,father_id\n1,Musa,Bua,1950,\n2,Bashir,Bua,1985,1\n');
    final plan = planImport(f, g);
    expect(plan.rows.first.match?.id, 'a');
    expect(plan.rows.last.isNew, isTrue);
    expect(plan.newCount, 1);
    expect(plan.linkCount, 1);

    final json = plan.toJson();
    expect((json['people'] as List).first, {'key': '1', 'id': 'a'});
    expect(((json['people'] as List).last as Map)['first_name'], 'Bashir');

    // Leaving Bashir out drops his link too.
    plan.rows.last.include = false;
    expect(plan.newCount, 0);
    expect(plan.linkCount, 0);
    expect((plan.toJson()['people'] as List).length, 1);
  });

  test('the printable tree is a PDF', () async {
    final bytes = await printableTreePdf(buildFamily(), 'ahmadu',
        regular: pw.Font.helvetica(), bold: pw.Font.helveticaBold(), title: 'The Bua Family', subtitle: 'October 2026');
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}
