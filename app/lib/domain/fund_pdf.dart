import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/l10n.dart';
import '../models/fund.dart';

const _green = PdfColor.fromInt(0xFF1D6B40);
const _greenTint = PdfColor.fromInt(0xFFE3F0E7);
const _ink = PdfColor.fromInt(0xFF17231B);
const _subtle = PdfColor.fromInt(0xFF5B6960);
const _line = PdfColor.fromInt(0xFFDDE3DE);

String duesPer(AppLocalizations l, DuesPeriod p) => switch (p) {
      DuesPeriod.monthly => l.perMonth,
      DuesPeriod.quarterly => l.perQuarter,
      DuesPeriod.yearly => l.perYear,
    };

String payMethodText(AppLocalizations l, PayMethod? m) => switch (m) {
      PayMethod.transfer => l.payTransfer,
      PayMethod.cash => l.payCash,
      PayMethod.mobile => l.payMobile,
      null => '',
    };

/// Where a report line's money came from or went: a cause, dues or the general fund.
String sourceTitle(AppLocalizations l, ReportSource s) => s.title ?? l.generalFund;

class _Doc {
  _Doc(this.regular, this.bold);

  final pw.Font regular;
  final pw.Font bold;

  pw.TextStyle get body => pw.TextStyle(font: regular, fontSize: 10, color: _ink);
  pw.TextStyle get strong => pw.TextStyle(font: bold, fontSize: 10, color: _ink);
  pw.TextStyle get muted => pw.TextStyle(font: regular, fontSize: 9, color: _subtle);

  pw.Widget heading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
        child: pw.Text(text, style: pw.TextStyle(font: bold, fontSize: 13, color: _green)),
      );

  pw.Widget table(List<String> headers, List<List<String>> rows, {Set<int> right = const {}}) => pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerStyle: pw.TextStyle(font: bold, fontSize: 9.5, color: _ink),
        headerDecoration: const pw.BoxDecoration(color: _greenTint),
        cellStyle: body,
        border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _line, width: 0.5)),
        cellAlignments: {for (final i in right) i: pw.Alignment.centerRight},
        headerAlignments: {for (final i in right) i: pw.Alignment.centerRight},
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      );

  pw.Widget header(String title, String subtitle) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 20, color: _green)),
        pw.SizedBox(height: 2),
        pw.Text(subtitle, style: pw.TextStyle(font: regular, fontSize: 11, color: _subtle)),
        pw.SizedBox(height: 8),
        pw.Container(height: 2, color: _green),
      ]);
}

/// The fund's statement for a period, for printing or sharing on WhatsApp.
Future<Uint8List> fundReportPdf(
  FundReport r,
  AppLocalizations l, {
  required pw.Font regular,
  required pw.Font bold,
  required DateTime generatedAt,
}) async {
  final d = _Doc(regular, bold);
  final title = '${r.family} Family · ${l.welfareFund}';
  final period = '${l.shortDate(r.from)} – ${l.shortDate(r.to)}';
  final doc = pw.Document(title: '$title · $period', creator: 'Bua Family');
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.copyWith(marginLeft: 36, marginRight: 36, marginTop: 36, marginBottom: 36),
    footer: (c) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(l.reportGenerated(l.shortDate(generatedAt)), style: d.muted),
      pw.Text('${c.pageNumber} / ${c.pagesCount}', style: d.muted),
    ]),
    build: (_) => [
      d.header(title, '${l.reportTitle} · $period'),
      pw.SizedBox(height: 12),
      pw.Row(children: [
        for (final (label, value) in [
          (l.openingLabel, r.opening),
          (l.moneyIn, r.moneyIn),
          (l.moneyOut, r.moneyOut),
          (l.closingLabel, r.closing),
        ])
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(right: 6),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: label == l.closingLabel ? _greenTint : null,
                border: pw.Border.all(color: _line),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(label, style: d.muted),
                pw.Text(naira(value), style: pw.TextStyle(font: bold, fontSize: 13, color: _ink)),
              ]),
            ),
          ),
      ]),
      pw.SizedBox(height: 6),
      pw.Text(l.paymentsFrom(r.payments, r.contributors), style: d.muted),
      if (r.sources.isNotEmpty) ...[
        d.heading(l.bySourceTitle),
        d.table(
          ['', l.inOut, l.outLabel],
          [for (final s in r.sources) [sourceTitle(l, s), naira(s.moneyIn), naira(s.moneyOut)]],
          right: {1, 2},
        ),
      ],
      if (r.months.length > 1) ...[
        d.heading(l.monthByMonth),
        d.table(
          ['', l.inOut, l.outLabel],
          [for (final m in r.months) [l.monthYear(m.month), naira(m.moneyIn), naira(m.moneyOut)]],
          right: {1, 2},
        ),
      ],
      if (r.dues != null && r.dues!.isNotEmpty) ...[
        d.heading(l.duesStandingTitle),
        d.table(
          ['', l.duesFilterOwing, l.closingLabel, l.moneyIn],
          [
            for (final s in r.dues!)
              [
                '${s.title} (${l.duesEvery(naira(s.amount), duesPer(l, s.period))})',
                '${s.owing} / ${s.members}',
                naira(s.owed),
                naira(s.collected),
              ],
          ],
          right: {1, 2, 3},
        ),
      ],
      if (r.transactions != null && r.transactions!.isNotEmpty) ...[
        d.heading(l.transactionsTitle),
        d.table(
          [l.date, '', '', l.forWhat, '', ''],
          [
            for (final t in r.transactions!)
              [
                l.shortDate(t.date),
                t.isIn ? l.inOut : l.outLabel,
                t.name ?? '',
                t.title ?? l.generalFund,
                payMethodText(l, t.method),
                '${t.isIn ? '+' : '−'}${naira(t.amount)}',
              ],
          ],
          right: {5},
        ),
      ],
      pw.SizedBox(height: 14),
      pw.Text(r.transactions == null ? l.reportCommitteeNote : l.fundNote, style: d.muted),
    ],
  ));
  return doc.save();
}

/// One member's dues and contributions, for their own records.
Future<Uint8List> memberStatementPdf({
  required AppLocalizations l,
  required String family,
  required String name,
  required List<(DuesPlan, DuesStanding)> dues,
  required List<Contribution> contributions,
  required Map<String, String> titles,
  required pw.Font regular,
  required pw.Font bold,
  required DateTime generatedAt,
}) async {
  final d = _Doc(regular, bold);
  final doc = pw.Document(title: l.statementFor(name), creator: 'Bua Family');
  String status(ContributionStatus s) => switch (s) {
        ContributionStatus.pending => l.statusPending,
        ContributionStatus.confirmed => l.statusConfirmedLabel,
        ContributionStatus.rejected => l.statusRejected,
      };
  final confirmed = contributions.where((c) => c.status == ContributionStatus.confirmed).fold<double>(0, (a, c) => a + c.amount);
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.copyWith(marginLeft: 36, marginRight: 36, marginTop: 36, marginBottom: 36),
    footer: (c) => pw.Text(l.reportGenerated(l.shortDate(generatedAt)), style: d.muted),
    build: (_) => [
      d.header('$family Family · ${l.welfareFund}', l.statementFor(name)),
      if (dues.isNotEmpty) ...[
        d.heading(l.myDues),
        d.table(
          ['', '', ''],
          [
            for (final (plan, s) in dues)
              [
                '${plan.title} (${l.duesEvery(naira(plan.amount), duesPer(l, plan.period))})',
                s.exempt
                    ? l.duesExempt
                    : s.owed > 0
                        ? l.youOwe(naira(s.owed))
                        : s.paidThrough == null
                            ? l.paidUpNothingYet
                            : l.paidUpTo(l.monthYear(s.paidThrough!)),
                naira(s.paid),
              ],
          ],
          right: {2},
        ),
      ],
      d.heading(l.contributionsLabel),
      if (contributions.isEmpty)
        pw.Text(l.nothingYet, style: d.muted)
      else
        d.table(
          [l.date, l.forWhat, '', '', ''],
          [
            for (final c in contributions)
              [
                l.shortDate(c.createdAt),
                titles[c.causeId ?? c.duesPlanId] ?? l.generalFund,
                payMethodText(l, c.method),
                status(c.status),
                naira(c.amount),
              ],
          ],
          right: {4},
        ),
      pw.SizedBox(height: 8),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('${l.statusConfirmedLabel}: ${naira(confirmed)}', style: d.strong),
      ),
    ],
  ));
  return doc.save();
}
