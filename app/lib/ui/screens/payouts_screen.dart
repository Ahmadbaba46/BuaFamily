import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/fund.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';
import '../widgets/social.dart';

/// Committee: the payouts recorded, to correct or delete one entered by mistake.
class PayoutsScreen extends ConsumerWidget {
  const PayoutsScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, FundPayout p, Map<String, String> causes) async {
    final l = context.l10n;
    final v = await showFormDialog(context, title: l.editPayout, fields: [
      TextSpec('amount', l.amountNaira, number: true, required: true, initial: p.amount.round()),
      ChoiceSpec<String?>('cause', l.forCause,
          initial: p.causeId, options: {null: l.generalFund, ...causes}),
      TextSpec('note', l.notes, multiline: true, initial: p.note),
    ]);
    if (v == null || !context.mounted) return;
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).updatePayout(p.id,
          causeId: v['cause'] as String?, amount: (v['amount'] as int).toDouble(), note: v['note'] as String?),
    );
    if (ok) refreshFund(ref);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, FundPayout p) async {
    final l = context.l10n;
    if (!await confirm(context, l.confirmDeletePayout(naira(p.amount))) || !context.mounted) return;
    if (await guarded(context, () => ref.read(repositoryProvider).deletePayout(p.id))) refreshFund(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final payouts = ref.watch(payoutsProvider);
    final causes = {for (final c in ref.watch(fundCausesProvider).value ?? const <FundCause>[]) c.id: c.title};
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/fund')),
        title: Text(l.payoutsRecorded, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(payoutsProvider.future),
        child: AsyncBody(
          value: payouts,
          onRetry: () => ref.invalidate(payoutsProvider),
          builder: (list) => list.isEmpty
              ? ListView(children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(l.noPayoutsYet, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
                  ),
                ])
              : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
                  SectionCard(children: [
                    for (final (i, p) in list.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        title: Text(naira(p.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          [
                            l.weekdayDate(p.paidOn),
                            p.causeId == null ? l.generalFund : causes[p.causeId] ?? l.forCause,
                            if (p.note?.trim().isNotEmpty ?? false) p.note!.trim(),
                            if (p.recordedBy != null) l.recordedBy(authorOf(ref, p.recordedBy!).name),
                          ].join(' · '),
                          style: TextStyle(fontSize: 13, color: Bua.inkMuted),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) => v == 'edit' ? _edit(context, ref, p, causes) : _delete(context, ref, p),
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'edit', child: Text(l.edit)),
                            PopupMenuItem(value: 'delete', child: Text(l.delete)),
                          ],
                        ),
                      ),
                    ],
                  ]),
                ]),
        ),
      ),
    );
  }
}
