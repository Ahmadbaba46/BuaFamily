import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../models/fund.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';
import '../widgets/social.dart';

String contributionStatusLabel(AppLocalizations l, ContributionStatus s) => switch (s) {
      ContributionStatus.pending => l.contribPending,
      ContributionStatus.confirmed => l.contribConfirmed,
      ContributionStatus.rejected => l.contribRejected,
    };

String payMethodLabel(AppLocalizations l, PayMethod m) => switch (m) {
      PayMethod.transfer => l.payTransfer,
      PayMethod.cash => l.payCash,
      PayMethod.mobile => l.payMobile,
    };

/// Balance, open causes, the viewer's contributions and, for the committee,
/// what needs confirming.
class WelfareFundScreen extends ConsumerWidget {
  const WelfareFundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final overview = ref.watch(fundOverviewProvider);
    final causes = ref.watch(fundCausesProvider).value ?? const <FundCause>[];
    final contributions = ref.watch(contributionsProvider).value ?? const <Contribution>[];
    final me = ref.watch(profileProvider);
    final committee = me?.isCommittee ?? false;

    final open = causes.where((c) => c.status == CauseStatus.open).toList()
      ..sort((a, b) => a.urgent == b.urgent ? 0 : (a.urgent ? -1 : 1));
    final proposals = causes.where((c) => c.status == CauseStatus.proposed).toList();
    final closed = causes.where((c) => c.status == CauseStatus.closed).toList();
    final mine = contributions.where((c) => c.userId == me?.id).toList();
    final toConfirm = committee ? contributions.where((c) => c.status == ContributionStatus.pending).toList() : const [];
    final causeTitles = {for (final c in causes) c.id: c.title};

    Future<void> refresh() async {
      refreshFund(ref);
      await ref.read(fundOverviewProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        title: Text(l.welfareFund, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          if (committee)
            PopupMenuButton<String>(
              onSelected: (v) => switch (v) {
                'cause' => context.push('/fund/new'),
                'payout' => _recordPayout(context, ref, open),
                _ => _editAccount(context, ref, overview.value),
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'cause', child: Text(l.newCause)),
                PopupMenuItem(value: 'payout', child: Text(l.recordPayout)),
                PopupMenuItem(value: 'account', child: Text(l.editAccount)),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: AsyncBody(
          value: overview,
          onRetry: () => refreshFund(ref),
          builder: (o) => ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Bua.green, borderRadius: BorderRadius.circular(22)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.fundBalance, style: const TextStyle(fontSize: 13, color: Bua.greenOnDark)),
                Text(naira(o.balance),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                if (o.treasurers.isNotEmpty)
                  Text(
                    l.treasurerLine(o.treasurers.join(', '), o.updatedAt == null ? '—' : l.ago(o.updatedAt!).toLowerCase()),
                    style: const TextStyle(fontSize: 12, color: Bua.greenOnDark),
                  ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Bua.greenDark),
                      onPressed: () => context.push('/fund/give'),
                      child: Text(l.contribute),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x80FFFFFF)),
                      ),
                      onPressed: () => context.push('/fund/new?ask=1'),
                      child: Text(l.askForSupport, textAlign: TextAlign.center),
                    ),
                  ),
                ]),
              ]),
            ),
            if (toConfirm.isNotEmpty) ...[
              const SizedBox(height: 16),
              GroupHeading(l.toConfirm(toConfirm.length)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  for (final (i, c) in toConfirm.indexed) ...[
                    if (i > 0) const InsetDivider(indent: 16),
                    _ConfirmRow(contribution: c, causeTitle: causeTitles[c.causeId]),
                  ],
                ]),
              ),
            ],
            if (committee && proposals.isNotEmpty) ...[
              const SizedBox(height: 16),
              GroupHeading(l.supportRequests),
              const SizedBox(height: 8),
              for (final c in proposals) ...[_ProposalCard(cause: c), const SizedBox(height: 10)],
            ],
            const SizedBox(height: 16),
            GroupHeading(l.openCauses),
            const SizedBox(height: 8),
            for (final c in open) ...[_CauseCard(cause: c), const SizedBox(height: 10)],
            if (open.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l.nothingYet, style: const TextStyle(color: Bua.inkSubtle)),
              ),
            if (mine.isNotEmpty) ...[
              const SizedBox(height: 8),
              GroupHeading(l.myContributions),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  for (final (i, c) in mine.indexed) ...[
                    if (i > 0) const InsetDivider(indent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(naira(c.amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(
                          [causeTitles[c.causeId] ?? l.generalFund, payMethodLabel(l, c.method), l.formatDate(c.createdAt)]
                              .join(' · '),
                          style: const TextStyle(fontSize: 13, color: Bua.inkSubtle),
                        ),
                        const SizedBox(height: 6),
                        _StatusPill(c.status),
                      ]),
                    ),
                  ],
                ]),
              ),
            ],
            if (closed.isNotEmpty) ...[
              const SizedBox(height: 16),
              GroupHeading(l.closed),
              const SizedBox(height: 8),
              for (final c in closed) ...[_CauseCard(cause: c), const SizedBox(height: 10)],
            ],
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.shield_outlined, size: 16, color: Bua.inkSubtle),
              const SizedBox(width: 8),
              Expanded(child: Text(l.fundNote, style: const TextStyle(fontSize: 12, height: 1.45, color: Bua.inkSubtle))),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _recordPayout(BuildContext context, WidgetRef ref, List<FundCause> open) async {
    final l = context.l10n;
    final v = await showFormDialog(context, title: l.recordPayout, fields: [
      TextSpec('amount', l.amountNaira, number: true, required: true),
      ChoiceSpec<String?>('cause', l.forCause, options: {null: l.generalFund, for (final c in open) c.id: c.title}),
      TextSpec('note', l.notes, multiline: true),
    ]);
    if (v == null || !context.mounted) return;
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).recordPayout(
            causeId: v['cause'] as String?,
            amount: (v['amount'] as int).toDouble(),
            note: v['note'] as String?,
          ),
    );
    if (ok) refreshFund(ref);
  }

  Future<void> _editAccount(BuildContext context, WidgetRef ref, FundOverview? o) async {
    final l = context.l10n;
    final v = await showFormDialog(context, title: l.editAccount, fields: [
      TextSpec('bank', l.bank, initial: o?.bankName),
      TextSpec('number', l.accountNumber, initial: o?.accountNumber),
      TextSpec('name', l.accountName, initial: o?.accountName),
      TextSpec('opening', l.openingBalance, initial: o?.openingBalance.round(), number: true),
    ]);
    if (v == null || !context.mounted) return;
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).updateFundSettings({
        'bank_name': v['bank'],
        'account_number': v['number'],
        'account_name': v['name'],
        'opening_balance': v['opening'] ?? 0,
      }),
    );
    if (ok) refreshFund(ref);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final ContributionStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (status) {
      ContributionStatus.confirmed => Pill(l.contribConfirmed, icon: Icons.check),
      ContributionStatus.pending => Pill(l.contribPending, background: Bua.goldTint, color: Bua.goldInk),
      ContributionStatus.rejected => Pill(l.contribRejected, background: Bua.dangerTint, color: Bua.dangerInk),
    };
  }
}

class _CauseCard extends StatelessWidget {
  const _CauseCard({required this.cause});

  final FundCause cause;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = cause;
    return Material(
      color: Bua.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/fund/cause/${c.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
              if (c.urgent && c.status == CauseStatus.open)
                Pill(l.urgent.toUpperCase(), background: Bua.dangerTint, color: Bua.dangerInk),
            ]),
            if (c.target != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: c.progress,
                  minHeight: 10,
                  backgroundColor: Bua.track,
                  color: Bua.green,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: naira(c.raised), style: const TextStyle(fontWeight: FontWeight.w700, color: Bua.ink)),
                if (c.target != null) TextSpan(text: ' ${l.raisedOf('', naira(c.target!)).trim()}'),
                TextSpan(text: ' · ${l.contributorsCount(c.contributors)}'),
              ]),
              style: const TextStyle(fontSize: 13, color: Bua.inkMuted),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ProposalCard extends ConsumerWidget {
  const _ProposalCard({required this.cause});

  final FundCause cause;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = cause;
    final asker = c.createdBy == null ? null : authorOf(ref, c.createdBy!);
    Future<void> set(CauseStatus s) async {
      if (await guarded(context, () => ref.read(repositoryProvider).updateCause(c.id, {'status': s.name}))) {
        refreshFund(ref);
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Bua.goldTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Bua.goldLine),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text(
          [if (c.target != null) naira(c.target!), if (asker != null) asker.name, l.ago(c.createdAt)].join(' · '),
          style: const TextStyle(fontSize: 12, color: Bua.goldInkDark),
        ),
        if (c.description?.isNotEmpty ?? false) ...[
          const SizedBox(height: 6),
          Text(c.description!, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => set(CauseStatus.declined), child: Text(l.decline))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(onPressed: () => set(CauseStatus.open), child: Text(l.openCause))),
        ]),
      ]),
    );
  }
}

class _ConfirmRow extends ConsumerWidget {
  const _ConfirmRow({required this.contribution, this.causeTitle});

  final Contribution contribution;
  final String? causeTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = contribution;
    final who = authorOf(ref, c.userId);
    Future<void> review(ContributionStatus s) async {
      if (await guarded(context, () => ref.read(repositoryProvider).reviewContribution(c.id, s))) refreshFund(ref);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          AuthorAvatar(who, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${who.name} · ${naira(c.amount)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text([causeTitle ?? l.generalFund, payMethodLabel(l, c.method), l.ago(c.createdAt)].join(' · '),
                  style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
            ]),
          ),
          if (c.receiptPath != null)
            TextButton.icon(
              onPressed: () async {
                final url = await ref.read(receiptUrlProvider(c.receiptPath!).future);
                await launchUrl(Uri.parse(url));
              },
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: Text(l.viewReceipt),
            ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => review(ContributionStatus.rejected), child: Text(l.notReceived))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(onPressed: () => review(ContributionStatus.confirmed), child: Text(l.confirmAction))),
        ]),
      ]),
    );
  }
}
