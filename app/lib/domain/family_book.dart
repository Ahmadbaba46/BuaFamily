import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/l10n.dart';
import '../models/family_graph.dart';
import '../models/person.dart';

const _green = PdfColor.fromInt(0xFF1D6B40);
const _greenDark = PdfColor.fromInt(0xFF134A2C);
const _greenTint = PdfColor.fromInt(0xFFE3F0E7);
const _gold = PdfColor.fromInt(0xFFC99A3B);
const _ink = PdfColor.fromInt(0xFF17231B);
const _subtle = PdfColor.fromInt(0xFF5B6960);
const _line = PdfColor.fromInt(0xFFDDE3DE);

/// Register numbers for everyone in the line of [rootId]: the founder is 1,
/// their children 1.1, 1.2 … (in birth order), grandchildren 1.2.1 and so on.
/// A child reached through two parents keeps the first number found.
Map<String, String> registerNumbers(FamilyGraph g, String rootId) {
  final numbers = <String, String>{rootId: '1'};
  final queue = [rootId];
  for (var i = 0; i < queue.length; i++) {
    final id = queue[i];
    var n = 0;
    for (final c in g.childrenOf(id)) {
      n++;
      if (numbers.containsKey(c.id)) continue;
      numbers[c.id] = '${numbers[id]}.$n';
      queue.add(c.id);
    }
  }
  return numbers;
}

/// Compare register numbers part by part (1.10 after 1.9).
int compareRegister(String a, String b) {
  final x = a.split('.').map(int.parse).toList();
  final y = b.split('.').map(int.parse).toList();
  for (var i = 0; i < x.length && i < y.length; i++) {
    if (x[i] != y[i]) return x[i].compareTo(y[i]);
  }
  return x.length.compareTo(y.length);
}

/// The family book: a cover, then everyone in the line of [rootId] generation
/// by generation (photo, dates, places, parents, spouses, children, life
/// story), everyone else in the tree, and an index of names. Contact and
/// health details are never included. [photos] are portraits by person id.
Future<Uint8List> familyBookPdf(
  FamilyGraph g,
  String rootId,
  AppLocalizations l, {
  required pw.Font regular,
  required pw.Font bold,
  required String familyName,
  required DateTime generatedAt,
  Map<String, Uint8List> photos = const {},
}) async {
  final numbers = registerNumbers(g, rootId);
  final ordered = numbers.keys.toList()..sort((a, b) => compareRegister(numbers[a]!, numbers[b]!));
  final generations = <int, List<String>>{};
  for (final id in ordered) {
    generations.putIfAbsent(numbers[id]!.split('.').length, () => []).add(id);
  }
  // Spouses who married in appear with their partner, not on their own.
  final inLine = numbers.keys.toSet();
  final spousesOfLine = {
    for (final id in inLine)
      for (final s in g.spousesOf(id))
        if (!inLine.contains(s.id)) s.id,
  };
  final others = g.persons.values.where((p) => !inLine.contains(p.id) && !spousesOfLine.contains(p.id)).toList()
    ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

  final founder = g[rootId]!;
  final title = l.treePosterTitle(familyName);
  final images = <String, pw.ImageProvider>{};
  bool readable(Uint8List b) =>
      b.length > 8 && ((b[0] == 0xFF && b[1] == 0xD8) || (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47));
  for (final e in photos.entries) {
    if (!readable(e.value)) continue; // JPEG and PNG only
    try {
      images[e.key] = pw.MemoryImage(e.value);
    } catch (_) {
      // A photo that won't decode is left out.
    }
  }

  pw.TextStyle style(double size, {bool strong = false, PdfColor color = _ink, double? height}) =>
      pw.TextStyle(font: strong ? bold : regular, fontSize: size, color: color, lineSpacing: height);

  String lifeLine(Person p) => [
        if (!p.isLiving) l.late(p),
        if (p.lifespan(approxPrefix: l.approxPrefix()).isNotEmpty) p.lifespan(approxPrefix: l.approxPrefix()),
        if (p.branch?.trim().isNotEmpty ?? false) p.branch!.trim(),
      ].join(' · ');

  String named(Person p) {
    final n = numbers[p.id];
    return n == null ? p.displayName : '${p.displayName} ($n)';
  }

  pw.Widget portrait(Person p, double size) {
    final image = images[p.id];
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: p.isLiving ? _greenTint : const PdfColor.fromInt(0xFFEDEBE6),
        image: image == null ? null : pw.DecorationImage(image: image, fit: pw.BoxFit.cover),
      ),
      alignment: pw.Alignment.center,
      child: image != null
          ? null
          : pw.Text(p.initials, style: style(size * 0.34, strong: true, color: p.isLiving ? _greenDark : _subtle)),
    );
  }

  List<pw.Widget> entry(String id) {
    final p = g[id]!;
    final parents = g.parentsOf(id);
    final spouses = g.spousesOf(id);
    final children = g.childrenOf(id);
    final bio = p.biography?.trim() ?? '';
    final lines = <String>[
      if (p.birthPlace?.trim().isNotEmpty ?? false) l.bookBornIn(p.birthPlace!.trim()),
      if (!p.isLiving && (p.burialPlace?.trim().isNotEmpty ?? false)) l.bookBuriedIn(p.burialPlace!.trim()),
      if (parents.isNotEmpty) l.parentsNames(parents.map(named).join(' & ')),
      if (spouses.isNotEmpty) l.bookMarriedTo(spouses.map((s) {
        final life = s.lifespan(approxPrefix: l.approxPrefix());
        return [named(s), if (!s.isLiving) l.late(s).toLowerCase(), if (life.isNotEmpty) life].join(', ');
      }).join('; ')),
      if (children.isNotEmpty) l.bookChildren(children.map(named).join(', ')),
    ];
    return [
      pw.Container(
      margin: pw.EdgeInsets.only(bottom: bio.isEmpty ? 10 : 4),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        portrait(p, 46),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: const pw.BoxDecoration(
                    color: _greenTint, borderRadius: pw.BorderRadius.all(pw.Radius.circular(3))),
                child: pw.Text(numbers[id]!, style: style(8.5, strong: true, color: _greenDark)),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(child: pw.Text(p.displayName, style: style(12, strong: true))),
            ]),
            if (lifeLine(p).isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(lifeLine(p), style: style(9, color: _subtle)),
              ),
            for (final t in lines)
              pw.Padding(padding: const pw.EdgeInsets.only(top: 3), child: pw.Text(t, style: style(9.5))),
          ]),
        ),
      ]),
      ),
      // The life story flows on to the next page when it's long.
      if (bio.isNotEmpty)
        pw.Paragraph(
          text: bio,
          style: style(9.5, height: 1.5),
          margin: const pw.EdgeInsets.only(left: 66, right: 10, bottom: 12),
        ),
    ];
  }

  pw.Widget heading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6, bottom: 8),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(text, style: style(16, strong: true, color: _green)),
          pw.SizedBox(height: 3),
          pw.Container(height: 1.5, width: 60, color: _gold),
        ]),
      );

  // The index: everyone in the book, by name, with their number (or "& n",
  // the number of the person they married).
  final indexed = [...inLine, ...spousesOfLine].map((id) => g[id]!).toList()
    ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  pw.Widget indexRow(Person p) => pw.Row(children: [
        pw.Expanded(child: pw.Text(p.displayName, style: style(9.5))),
        pw.Text(
            numbers[p.id] ??
                g.spousesOf(p.id).map((s) => numbers[s.id]).whereType<String>().map((n) => '& $n').join(', '),
            style: style(9, color: _subtle)),
      ]);

  final doc = pw.Document(title: '$title · ${l.familyBookSubtitle}', creator: 'Bua Family');
  final page = PdfPageFormat.a4.copyWith(marginLeft: 40, marginRight: 40, marginTop: 40, marginBottom: 40);

  // Cover.
  doc.addPage(pw.Page(
    pageFormat: page,
    build: (_) => pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
      portrait(founder, 120),
      pw.SizedBox(height: 28),
      pw.Text(title, textAlign: pw.TextAlign.center, style: style(34, strong: true, color: _green)),
      pw.SizedBox(height: 6),
      pw.Text(l.familyBookSubtitle, style: style(16, color: _subtle)),
      pw.SizedBox(height: 18),
      pw.Container(height: 2, width: 80, color: _gold),
      pw.SizedBox(height: 18),
      pw.Text(l.familyBookCover(founder.displayName, inLine.length + spousesOfLine.length, generations.length),
          textAlign: pw.TextAlign.center, style: style(12)),
      pw.SizedBox(height: 60),
      pw.Text(l.bookMadeOn(l.formatDate(generatedAt)), style: style(9, color: _subtle)),
    ]),
  ));

  doc.addPage(pw.MultiPage(
    pageFormat: page,
    footer: (c) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(title, style: style(8, color: _subtle)),
      pw.Text('${c.pageNumber} / ${c.pagesCount}', style: style(8, color: _subtle)),
    ]),
    build: (_) => [
      pw.Text(l.bookHowToRead(founder.displayName), style: style(10, color: _subtle, height: 1.5)),
      pw.SizedBox(height: 12),
      for (final MapEntry(key: n, value: ids) in generations.entries) ...[
        heading(l.generationHeading(n)),
        for (final id in ids) ...entry(id),
      ],
      if (others.isNotEmpty) ...[
        pw.NewPage(),
        heading(l.bookAlsoInTree),
        for (final p in others)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(children: [
              pw.Expanded(child: pw.Text(p.displayName, style: style(10))),
              pw.Text(lifeLine(p), style: style(9, color: _subtle)),
            ]),
          ),
      ],
      pw.NewPage(),
      heading(l.bookIndex),
      for (var i = 0; i < indexed.length; i += 2)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(child: indexRow(indexed[i])),
            pw.SizedBox(width: 16),
            pw.Expanded(child: i + 1 < indexed.length ? indexRow(indexed[i + 1]) : pw.SizedBox()),
          ]),
        ),
    ],
  ));
  return doc.save();
}
