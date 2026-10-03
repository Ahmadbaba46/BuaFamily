import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/family_graph.dart';
import '../models/person.dart';
import 'tree_layout.dart';

const _green = PdfColor.fromInt(0xFF1D6B40);
const _greenTint = PdfColor.fromInt(0xFFE3F0E7);
const _ink = PdfColor.fromInt(0xFF17231B);
const _subtle = PdfColor.fromInt(0xFF5B6960);
const _late = PdfColor.fromInt(0xFFF7F8F6);
const _lateRing = PdfColor.fromInt(0xFF8B958E);
const _connector = PdfColor.fromInt(0xFF9AA79E);
const _gold = PdfColor.fromInt(0xFFC99A3B);

/// A one-page poster of everyone descended from [rootId], for printing at
/// family gatherings. Fonts are passed in so Hausa letters print correctly.
Future<Uint8List> printableTreePdf(
  FamilyGraph graph,
  String rootId, {
  required pw.Font regular,
  required pw.Font bold,
  required String title,
  required String subtitle,
  String Function(Person p)? years,
}) async {
  final layout = layoutDescendants(graph, rootId);
  const header = 90.0;
  // PDF pages can be at most 200 inches (14,400 points) on a side.
  final scale = math.min(1.0, 14000 / math.max(layout.size.width, layout.size.height + header));
  final width = math.max(layout.size.width, 420.0);
  final height = layout.size.height + header;

  String lifespan(Person p) {
    if (years != null) return years(p);
    final b = p.birthDate?.year;
    final d = p.deathDate?.year;
    if (!p.isLiving) return '${b ?? '?'} – ${d ?? '?'}';
    return b == null ? '' : '$b';
  }

  final doc = pw.Document(title: title, creator: 'Bua Family');
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat(width * scale, height * scale, marginAll: 0),
    build: (_) => pw.Transform.scale(
      scale: scale,
      alignment: pw.Alignment.topLeft,
      child: pw.SizedBox(
        width: width,
        height: height,
        child: pw.Stack(children: [
          pw.Positioned(
            left: 40,
            top: 28,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 26, color: _green)),
              pw.SizedBox(height: 4),
              pw.Text(subtitle, style: pw.TextStyle(font: regular, fontSize: 11, color: _subtle)),
            ]),
          ),
          pw.Positioned(
            left: 0,
            top: header,
            child: pw.CustomPaint(
              size: PdfPoint(layout.size.width, layout.size.height),
              painter: (canvas, size) {
                for (final e in layout.edges) {
                  if (e.points.length < 2) continue;
                  canvas
                    ..setStrokeColor(e.isMarriage ? _gold : _connector)
                    ..setLineWidth(e.isMarriage ? 1.6 : 1.2)
                    ..moveTo(e.points.first.dx, size.y - e.points.first.dy);
                  for (final pt in e.points.skip(1)) {
                    canvas.lineTo(pt.dx, size.y - pt.dy);
                  }
                  canvas.strokePath();
                }
              },
            ),
          ),
          for (final n in layout.nodes)
            if (graph[n.personId] case final p?)
              pw.Positioned(
                left: n.offset.dx,
                top: header + n.offset.dy,
                child: pw.Container(
                  width: 150,
                  height: 68,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: p.isLiving ? (n.isSpouse ? PdfColors.white : _greenTint) : _late,
                    border: pw.Border.all(color: p.isLiving ? _green : _lateRing, width: n.isSpouse ? 0.8 : 1.2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        p.displayName,
                        maxLines: 2,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: bold, fontSize: 10.5, color: _ink),
                      ),
                      if (lifespan(p).isNotEmpty)
                        pw.Text(lifespan(p), style: pw.TextStyle(font: regular, fontSize: 9, color: _subtle)),
                    ],
                  ),
                ),
              ),
        ]),
      ),
    ),
  ));
  return doc.save();
}
