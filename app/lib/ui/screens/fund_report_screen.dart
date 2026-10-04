import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/fund_pdf.dart';
import '../../l10n/l10n.dart';
import '../../models/fund.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'import_export_screen.dart' show saveBytes;

enum _Range { thisMonth, lastMonth, thisYear, lastYear, custom }

/// The fund's statement for any period: balances, where money came from and
/// went, month by month; the committee also sees every transaction and dues.
/// Exports to PDF (to print or share) and CSV.
class FundReportScreen extends ConsumerStatefulWidget {
  const FundReportScreen({super.key, this.today});

  /// For tests.
  final DateTime? today;

  @override
  ConsumerState<FundReportScreen> createState() => _FundReportScreenState();
}

class _FundReportScreenState extends ConsumerState<FundReportScreen> {
  _Range _range = _Range.thisYear;
  late (DateTime, DateTime) _period = _periodFor(_Range.thisYear);
  bool _busy = false;

  DateTime get _today {
    final t = widget.today ?? DateTime.now();
    return DateTime(t.year, t.month, t.day);
  }

  (DateTime, DateTime) _periodFor(_Range r) {
    final t = _today;
    return switch (r) {
      _Range.thisMonth => (DateTime(t.year, t.month), DateTime(t.year, t.month + 1, 0)),
      _Range.lastMonth => (DateTime(t.year, t.month - 1), DateTime(t.year, t.month, 0)),
      _Range.lastYear => (DateTime(t.year - 1), DateTime(t.year - 1, 12, 31)),
      _ => (DateTime(t.year), DateTime(t.year, 12, 31)),
    };
  }

  Future<void> _pick(_Range r) async {
    if (r != _Range.custom) {
      setState(() {
        _range = r;
        _period = _periodFor(r);
      });
      return;
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(_today.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: _period.$1, end: _period.$2),
    );
    if (picked == null) return;
    setState(() {
      _range = r;
      _period = (picked.start, picked.end);
    });
  }

  String _stamp() => '${DateFormat('yyyyMMdd').format(_period.$1)}-${DateFormat('yyyyMMdd').format(_period.$2)}';

  Future<void> _pdf(FundReport r) async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final bytes = await fundReportPdf(
        r,
        l,
        regular: pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf')),
        bold: pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf')),
        generatedAt: DateTime.now(),
      );
      if (mounted) await saveBytes(context, 'bua-fund-report-${_stamp()}.pdf', bytes, 'application/pdf');
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _csv(FundReport r) async {
    final l = context.l10n;
    String q(String? v) => '"${(v ?? '').replaceAll('"', '""')}"';
    final lines = <String>[];
    if (r.transactions != null) {
      lines.add('date,in_or_out,name,for,method,amount');
      for (final t in r.transactions!) {
        lines.add([
          DateFormat('yyyy-MM-dd').format(t.date),
          t.isIn ? 'in' : 'out',
          q(t.name),
          q(t.title ?? l.generalFund),
          t.method?.name ?? '',
          t.amount.toStringAsFixed(2),
        ].join(','));
      }
    } else {
      lines.add('month,in,out');
      for (final m in r.months) {
        lines.add([DateFormat('yyyy-MM').format(m.month), m.moneyIn.toStringAsFixed(2), m.moneyOut.toStringAsFixed(2)].join(','));
      }
    }
    await saveBytes(context, 'bua-fund-${_stamp()}.csv', utf8.encode('${lines.join('\n')}\n'), 'text/csv');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final report = ref.watch(fundReportProvider(_period));

    String rangeLabel(_Range r) => switch (r) {
          _Range.thisMonth => l.periodThisMonth,
          _Range.lastMonth => l.periodLastMonth,
          _Range.thisYear => l.periodThisYear,
          _Range.lastYear => l.periodLastYear,
          _Range.custom => _range == _Range.custom
              ? '${l.shortDate(_period.$1)} – ${l.shortDate(_period.$2)}'
              : l.periodCustom,
        };

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/fund')),
        titleSpacing: 0,
        title: Text(l.reportTitle, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            tooltip: l.exportCsv,
            icon: const Icon(Icons.table_view_outlined),
            onPressed: report.value == null ? null : () => _csv(report.value!),
          ),
          IconButton(
            tooltip: l.downloadPdf,
            icon: _busy
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
            onPressed: report.value == null || _busy ? null : () => _pdf(report.value!),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(fundReportProvider(_period).future),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final r in _Range.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(rangeLabel(r)),
                    selected: _range == r,
                    labelStyle: TextStyle(color: _range == r ? Colors.white : Bua.ink, fontWeight: FontWeight.w500),
                    onSelected: (_) => _pick(r),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          AsyncBody(
            value: report,
            onRetry: () => ref.invalidate(fundReportProvider(_period)),
            builder: (r) => _ReportBody(report: r),
          ),
        ]),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final FundReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = report;

    Widget tile(String label, double value, {bool strong = false}) => Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: strong ? Bua.green : Bua.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12.5, color: strong ? Bua.greenOnDark : Bua.inkMuted)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(naira(value),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: strong ? Colors.white : Bua.ink)),
            ),
          ]),
        );

    Widget card(String title, List<Widget> children) => Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...children,
          ]),
        );

    Widget moneyRow(String label, double moneyIn, double moneyOut, {String? sub}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 14)),
                if (sub != null) Text(sub, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
              ]),
            ),
            SizedBox(
              width: 96,
              child: Text(moneyIn == 0 ? '—' : '+${naira(moneyIn)}',
                  textAlign: TextAlign.right, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
            SizedBox(
              width: 96,
              child: Text(moneyOut == 0 ? '—' : '−${naira(moneyOut)}',
                  textAlign: TextAlign.right, style: const TextStyle(fontSize: 13.5, color: Bua.inkMuted)),
            ),
          ]),
        );

    final empty = r.moneyIn == 0 && r.moneyOut == 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('${l.shortDate(r.from)} – ${l.shortDate(r.to)}', style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
      const SizedBox(height: 8),
      for (final pair in [
        [tile(l.openingLabel, r.opening), tile(l.moneyIn, r.moneyIn)],
        [tile(l.moneyOut, r.moneyOut), tile(l.closingLabel, r.closing, strong: true)],
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: pair[0]),
              const SizedBox(width: 10),
              Expanded(child: pair[1]),
            ]),
          ),
        ),
      const SizedBox(height: 8),
      Text(l.paymentsFrom(r.payments, r.contributors), style: const TextStyle(fontSize: 13, color: Bua.inkMuted)),
      if (empty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(l.nothingInPeriod, textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkSubtle)),
        ),
      if (r.sources.isNotEmpty)
        card(l.bySourceTitle, [
          BreakdownBars(
            rows: [for (final s in r.sources.where((s) => s.moneyIn > 0)) (sourceTitle(l, s), s.moneyIn)],
            format: naira,
          ),
          const Divider(height: 20, color: Bua.line),
          for (final s in r.sources) moneyRow(sourceTitle(l, s), s.moneyIn, s.moneyOut),
        ]),
      if (r.months.length > 1 && !empty)
        card(l.monthByMonth, [
          for (final m in r.months.reversed) moneyRow(l.monthYear(m.month), m.moneyIn, m.moneyOut),
        ]),
      if (r.dues != null && r.dues!.isNotEmpty)
        card(l.duesStandingTitle, [
          for (final s in r.dues!)
            moneyRow(
              s.title,
              s.collected,
              0,
              sub: l.duesSummaryLine(s.owing, s.members, naira(s.owed)),
            ),
        ]),
      if (r.transactions != null && r.transactions!.isNotEmpty)
        card(l.transactionsTitle, [
          for (final t in r.transactions!.reversed)
            moneyRow(
              t.name?.isNotEmpty ?? false ? t.name! : (t.title ?? l.generalFund),
              t.isIn ? t.amount : 0,
              t.isIn ? 0 : t.amount,
              sub: [l.shortDate(t.date), t.title ?? l.generalFund, if (t.method != null) payMethodText(l, t.method)].join(' · '),
            ),
        ]),
      const SizedBox(height: 12),
      Text(r.transactions == null ? l.reportCommitteeNote : l.fundNote,
          style: const TextStyle(fontSize: 12, height: 1.45, color: Bua.inkSubtle)),
    ]);
  }
}
