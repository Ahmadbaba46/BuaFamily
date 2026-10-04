import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/fund_pdf.dart' show duesPer;
import '../../l10n/l10n.dart';
import '../../models/fund.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';
import 'welfare_fund_screen.dart' show payMethodLabel;

enum _Filter { all, owing, paidUp, exempt }

/// What a member's standing says, in a few words.
String standingText(AppLocalizations l, DuesStanding s) {
  if (s.exempt) return l.duesExempt;
  if (s.owed > 0) return '${l.youOwe(naira(s.owed))} · ${l.unpaidPeriods(s.owedPeriods)}';
  if (s.paidThrough != null) return l.paidUpTo(l.monthYear(s.paidThrough!));
  return l.paidUpNothingYet;
}

/// Committee: dues plans and where every member stands; remind those who
/// owe, record cash collected, exempt someone or change when they start.
class DuesScreen extends ConsumerStatefulWidget {
  const DuesScreen({super.key});

  @override
  ConsumerState<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends ConsumerState<DuesScreen> {
  String? _planId;
  _Filter _filter = _Filter.all;
  String _query = '';

  List<DateTime> _months() {
    final now = DateTime.now();
    return [for (var i = -12; i <= 3; i++) DateTime(now.year, now.month + i)];
  }

  Future<void> _editPlan(DuesPlan? plan) async {
    final l = context.l10n;
    final months = _months();
    final start = plan == null ? DateTime(DateTime.now().year, DateTime.now().month) : DateTime(plan.startsOn.year, plan.startsOn.month);
    final v = await showFormDialog(context, title: plan == null ? l.newDuesPlan : l.editDuesPlan, fields: [
      TextSpec('title', l.planTitleLabel, initial: plan?.title ?? l.duesTitle, required: true),
      TextSpec('amount', l.amountNaira, initial: plan?.amount.round(), number: true, required: true),
      ChoiceSpec<DuesPeriod>('period', l.planPeriod, initial: plan?.period ?? DuesPeriod.monthly, options: {
        DuesPeriod.monthly: l.periodMonthly,
        DuesPeriod.quarterly: l.periodQuarterly,
        DuesPeriod.yearly: l.periodYearly,
      }),
      ChoiceSpec<DateTime>('starts', l.planStarts, initial: start, options: {
        for (final m in {...months, start}.toList()..sort()) m: l.monthYear(m),
      }),
      SwitchSpec('remind', l.planAutoRemind, initial: plan?.autoRemind ?? true),
      if (plan != null) SwitchSpec('active', l.planActive, initial: plan.active),
    ]);
    if (v == null || !mounted) return;
    final starts = v['starts'] as DateTime? ?? start;
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).saveDuesPlan({
        'title': (v['title'] as String).trim(),
        'amount': v['amount'],
        'period': (v['period'] as DuesPeriod? ?? DuesPeriod.monthly).name,
        'starts_on': '${starts.year}-${starts.month.toString().padLeft(2, '0')}-01',
        'auto_remind': v['remind'] as bool? ?? true,
        if (plan != null) 'active': v['active'] as bool? ?? true,
      }, id: plan?.id),
    );
    if (ok) refreshFund(ref);
  }

  Future<void> _remind(DuesPlan plan) async {
    final l = context.l10n;
    int n = 0;
    final ok = await guarded(context, () async => n = await ref.read(repositoryProvider).remindDues(plan.id));
    if (ok && mounted) showSnack(context, l.remindedCount(n));
  }

  Future<void> _member(DuesPlan plan, DuesStanding s) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(child: _MemberSheet(plan: plan, standing: s)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final plans = ref.watch(duesPlansProvider);
    final all = ref.watch(allDuesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/fund')),
        titleSpacing: 0,
        title: Text(l.duesTitle, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(tooltip: l.newDuesPlan, icon: const Icon(Icons.add), onPressed: () => _editPlan(null)),
        ],
      ),
      body: AsyncBody(
        value: plans,
        onRetry: () => refreshFund(ref),
        builder: (list) {
          if (list.isEmpty) {
            return ListView(padding: const EdgeInsets.all(24), children: [
              Icon(Icons.event_repeat, size: 44, color: Bua.inkSubtle),
              const SizedBox(height: 12),
              Text(l.noDuesPlans, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted, height: 1.45)),
              const SizedBox(height: 16),
              Center(child: FilledButton.icon(onPressed: () => _editPlan(null), icon: const Icon(Icons.add), label: Text(l.newDuesPlan))),
            ]);
          }
          final plan = list.where((p) => p.id == _planId).firstOrNull ?? list.firstWhere((p) => p.active, orElse: () => list.first);
          final rows = (all.value ?? const <DuesStanding>[]).where((s) => s.planId == plan.id).toList();
          final owing = rows.where((s) => s.owed > 0).toList();
          final counted = rows.where((s) => !s.exempt).length;
          final q = _query.trim().toLowerCase();
          final shown = rows.where((s) {
            final ok = switch (_filter) {
              _Filter.all => true,
              _Filter.owing => s.owed > 0,
              _Filter.paidUp => s.paidUp,
              _Filter.exempt => s.exempt,
            };
            return ok && (q.isEmpty || s.name.toLowerCase().contains(q));
          }).toList()
            ..sort((a, b) => b.owed.compareTo(a.owed));
          final totalOwed = owing.fold<double>(0, (a, s) => a + s.owed);

          return RefreshIndicator(
            onRefresh: () async => refreshFund(ref),
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
              if (list.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final p in list)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p.title),
                          selected: p.id == plan.id,
                          labelStyle: TextStyle(color: p.id == plan.id ? Colors.white : Bua.ink),
                          onSelected: (_) => setState(() => _planId = p.id),
                        ),
                      ),
                  ]),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(plan.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        Text(
                          [
                            l.duesEvery(naira(plan.amount), duesPer(l, plan.period)),
                            l.monthYear(plan.startsOn),
                            if (!plan.active) l.closed,
                          ].join(' · '),
                          style: TextStyle(fontSize: 13, color: Bua.inkSubtle),
                        ),
                      ]),
                    ),
                    IconButton(tooltip: l.editDuesPlan, icon: const Icon(Icons.edit_outlined), onPressed: () => _editPlan(plan)),
                  ]),
                  const SizedBox(height: 8),
                  Text(l.duesSummaryLine(owing.length, counted, naira(totalOwed)),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: owing.isEmpty || !plan.active ? null : () => _remind(plan),
                    icon: const Icon(Icons.notifications_active_outlined, size: 18),
                    label: Text(l.remindOwing),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l.searchByName,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final f in _Filter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(switch (f) {
                          _Filter.all => '${l.duesFilterAll} ${rows.length}',
                          _Filter.owing => '${l.duesFilterOwing} ${owing.length}',
                          _Filter.paidUp => '${l.duesFilterPaidUp} ${rows.where((s) => s.paidUp).length}',
                          _Filter.exempt => '${l.duesFilterExempt} ${rows.where((s) => s.exempt).length}',
                        }),
                        selected: _filter == f,
                        labelStyle: TextStyle(color: _filter == f ? Colors.white : Bua.ink),
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              if (all.isLoading && rows.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              Material(
                color: Bua.surface,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (final (i, s) in shown.indexed) ...[
                    if (i > 0) const InsetDivider(indent: 16),
                    ListTile(
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        [standingText(l, s), if (s.pending > 0) l.waitingConfirmation(naira(s.pending))].join('\n'),
                        style: TextStyle(color: s.owed > 0 ? Bua.danger : Bua.inkMuted, fontSize: 13),
                      ),
                      trailing: Icon(
                        s.exempt ? Icons.remove_circle_outline : (s.owed > 0 ? Icons.error_outline : Icons.check_circle),
                        color: s.exempt ? Bua.inkSubtle : (s.owed > 0 ? Bua.danger : Bua.green),
                      ),
                      onTap: () => _member(plan, s),
                    ),
                  ],
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}

/// One member on one plan: record a payment, exempt them, or change when they start.
class _MemberSheet extends ConsumerStatefulWidget {
  const _MemberSheet({required this.plan, required this.standing});

  final DuesPlan plan;
  final DuesStanding standing;

  @override
  ConsumerState<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends ConsumerState<_MemberSheet> {
  late final _amount = TextEditingController(
    text: (widget.standing.owed > 0 ? widget.standing.owed : widget.plan.amount).round().toString(),
  );
  PayMethod _method = PayMethod.cash;
  late bool _exempt = widget.standing.exempt;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _record() async {
    final l = context.l10n;
    final amount = double.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (amount == null || amount <= 0) return showSnack(context, l.amountInvalid);
    setState(() => _busy = true);
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).recordFor(
            userId: widget.standing.userId,
            amount: amount,
            method: _method,
            duesPlanId: widget.plan.id,
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      refreshFund(ref);
      Navigator.pop(context);
      showSnack(context, l.paymentRecorded);
    }
  }

  Future<void> _save({bool? exempt, DateTime? startsOn}) async {
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).setDuesMember(
            widget.plan.id,
            widget.standing.userId,
            exempt: exempt ?? _exempt,
            startsOn: startsOn ?? widget.standing.startsOn,
          ),
    );
    if (ok) refreshFund(ref);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = widget.standing;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        Text(standingText(l, s), style: TextStyle(color: s.owed > 0 ? Bua.danger : Bua.inkMuted)),
        if (s.lastPaidAt != null)
          Text('${naira(s.paid)} · ${l.ago(s.lastPaidAt!)}', style: TextStyle(fontSize: 13, color: Bua.inkSubtle)),
        Divider(height: 24, color: Bua.line),
        Text(l.recordPaymentFrom(s.name), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: const InputDecoration(prefixText: '₦ '),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final m in PayMethod.values)
            ChoiceChip(label: Text(payMethodLabel(l, m)), selected: _method == m, onSelected: (_) => setState(() => _method = m)),
        ]),
        const SizedBox(height: 10),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _busy ? null : _record,
          child: Text(l.recordContributionButton),
        ),
        Divider(height: 24, color: Bua.line),
        ToggleRow(
          title: l.exemptToggle,
          value: _exempt,
          onChanged: (v) {
            setState(() => _exempt = v);
            _save(exempt: v);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.duesStartLabel),
          subtitle: Text(s.startsOn == null ? '—' : l.monthYear(s.startsOn!)),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: widget.plan.startsOn,
              lastDate: DateTime(DateTime.now().year + 1, 12, 31),
              initialDate: s.startsOn ?? widget.plan.startsOn,
            );
            if (picked != null) {
              await _save(startsOn: DateTime(picked.year, picked.month));
              if (context.mounted) Navigator.pop(context);
            }
          },
        ),
      ]),
    );
  }
}
