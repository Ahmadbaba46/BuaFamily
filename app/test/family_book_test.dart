import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bua_family/domain/family_book.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/family_graph.dart';
import 'package:bua_family/models/person.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/widgets.dart' as pw;

import 'domain_test.dart' show buildFamily;

void main() {
  test('register numbers: the founder is 1, children add a number in birth order', () {
    final n = registerNumbers(buildFamily(), 'ahmadu');
    expect(n['ahmadu'], '1');
    expect(n['musa'], '1.1');
    expect(n['sani'], '1.2');
    expect(n['bello'], '1.1.1', reason: 'born before his sister Aisha');
    expect(n['aisha'], '1.1.2');
    expect(n['fatima'], '1.1.2.1');
    expect(n['kabir'], '1.2.1.1');
    expect(n.containsKey('hauwa'), isFalse, reason: 'wives who married in appear with their husband');
    expect(n.containsKey('stranger'), isFalse);
    expect(compareRegister('1.10', '1.9'), greaterThan(0));
    expect(compareRegister('1.2', '1.2.1'), lessThan(0));
  });

  test('the family book is a PDF with a cover, the generations and an index', () async {
    await initializeDateFormatting('en');
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final font = pw.Font.ttf(File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync().buffer.asByteData());
    final strong = pw.Font.ttf(File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync().buffer.asByteData());
    final g = buildFamily();
    // A long life story must flow on to the next page rather than fail.
    final long = FamilyGraph(
      persons: [
        for (final p in g.persons.values)
          p.id == 'musa'
              ? Person(id: p.id, firstName: p.firstName, sex: p.sex, birthDate: p.birthDate,
                  biography: List.filled(400, 'Musa farmed in Kano and taught the Quran to the children of the town.').join(' '))
              : p,
      ],
      unions: g.unions,
      links: g.links,
    );
    // A 1×1 PNG portrait, and a photo the PDF can't read (left out, not a failure).
    final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');
    final bytes = await familyBookPdf(long, 'ahmadu', l,
        regular: font,
        bold: strong,
        familyName: 'Bua',
        generatedAt: DateTime(2026, 10, 4),
        photos: {'ahmadu': png, 'musa': Uint8List.fromList(List.filled(64, 7))});
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(5000));
    final out = Platform.environment['BOOK_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
