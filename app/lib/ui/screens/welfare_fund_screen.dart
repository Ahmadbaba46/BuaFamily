import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

import '../../domain/fund_pdf.dart';
import '../../l10n/l10n.dart';
import '../../models/contributions.dart' show EventPayoutDue;
import '../../models/fund.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';
import '../widgets/social.dart';
import 'dues_screen.dart' show standingText;
import 'import_export_screen.dart' show saveBytes;

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
    final duesTitles = {for (final p in ref.watch(duesPlansProvider).value ?? const <DuesPlan>[]) p.id: p.title};

    Future<void> refresh() async {
      refreshFund(ref);
      await ref.read(fundOverviewProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        title: Text(l.welfareFund, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            tooltip: l.fundReports,
            icon: const Icon(Icons.assessment_outlined),
            onPressed: () => context.push('/fund/reports'),
          ),
          if (committee)
            PopupMenuButton<String>(
              onSelected: (v) => switch (v) {
                'cause' => context.push('/fund/new'),
                'payout' => _recordPayout(context, ref, open),
                'dues' => context.push('/fund/dues'),
                'record' => _recordFor(context, ref, open),
                _ => _editAccount(context, ref, overview.value),
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'dues', child: Text(l.duesTitle)),
                PopupMenuItem(value: 'record', child: Text(l.recordForMember)),
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
                Text(l.fundBalance, style: TextStyle(fontSize: 13, color: Bua.greenOnDark)),
                Text(naira(o.balance),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                if (o.treasurers.isNotEmpty)
                  Text(
                    l.treasurerLine(o.treasurers.join(', '), o.updatedAt == null ? '—' : l.ago(o.updatedAt!).toLowerCase()),
                    style: TextStyle(fontSize: 12, color: Bua.greenOnDark),
                  ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Bua.onWhite),
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
            const _MyDues(),
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
            if (committee) const _EventPayouts(),
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
                child: Text(l.nothingYet, style: TextStyle(color: Bua.inkSubtle)),
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
                          [causeTitles[c.causeId] ?? duesTitles[c.duesPlanId] ?? l.generalFund, c.online ? l.paidOnline : payMethodLabel(l, c.method), l.formatDate(c.createdAt)]
                              .join(' · '),
                          style: TextStyle(fontSize: 13, color: Bua.inkSubtle),
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
              Icon(Icons.shield_outlined, size: 16, color: Bua.inkSubtle),
              const SizedBox(width: 8),
              Expanded(child: Text(l.fundNote, style: TextStyle(fontSize: 12, height: 1.45, color: Bua.inkSubtle))),
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

  /// Committee: money collected for someone (cash at a meeting, a transfer seen).
  Future<void> _recordFor(BuildContext context, WidgetRef ref, List<FundCause> open) async {
    final l = context.l10n;
    final members = (await ref.read(membersProvider.future)).values.toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    final plans = (await ref.read(duesPlansProvider.future)).where((p) => p.active).toList();
    if (!context.mounted) return;
    final v = await showFormDialog(context, title: l.recordForMember, fields: [
      ChoiceSpec<String>('who', l.chooseMember, options: {for (final m in members) m.userId: m.displayName}),
      TextSpec('amount', l.amountNaira, number: true, required: true),
      ChoiceSpec<String?>('for', l.forWhat, initial: plans.isEmpty ? null : 'dues:${plans.first.id}', options: {
        null: l.generalFund,
        for (final p in plans) 'dues:${p.id}': p.title,
        for (final c in open) 'cause:${c.id}': c.title,
      }),
      ChoiceSpec<PayMethod>('method', l.paymentMethod, initial: PayMethod.cash, options: {
        for (final m in PayMethod.values) m: payMethodLabel(l, m),
      }),
    ]);
    if (v == null || v['who'] == null || !context.mounted) return;
    final target = v['for'] as String?;
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).recordFor(
            userId: v['who'] as String,
            amount: (v['amount'] as int).toDouble(),
            method: v['method'] as PayMethod? ?? PayMethod.cash,
            causeId: target != null && target.startsWith('cause:') ? target.substring(6) : null,
            duesPlanId: target != null && target.startsWith('dues:') ? target.substring(5) : null,
          ),
    );
    if (ok) {
      refreshFund(ref);
      if (context.mounted) showSnack(context, l.paymentRecorded);
    }
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

/// The member's own dues: what's owed or paid up to, a button to pay, and a
/// PDF statement of everything they've given.
class _MyDues extends ConsumerWidget {
  const _MyDues();

  Future<void> _statement(BuildContext context, WidgetRef ref, List<(DuesPlan, DuesStanding)> dues) async {
    final l = context.l10n;
    try {
      final me = ref.read(profileProvider);
      final mine = (await ref.read(contributionsProvider.future)).where((c) => c.userId == me?.id).toList();
      final causes = await ref.read(fundCausesProvider.future);
      final plans = await ref.read(duesPlansProvider.future);
      final bytes = await memberStatementPdf(
        l: l,
        family: ref.read(settingsProvider).value?.familyName ?? 'Bua',
        name: me?.displayName ?? '',
        dues: dues,
        contributions: mine,
        titles: {for (final c in causes) c.id: c.title, for (final p in plans) p.id: p.title},
        regular: pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf')),
        bold: pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf')),
        generatedAt: DateTime.now(),
      );
      if (context.mounted) await saveBytes(context, 'bua-fund-statement.pdf', bytes, 'application/pdf');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final plans = {for (final p in ref.watch(duesPlansProvider).value ?? const <DuesPlan>[]) p.id: p};
    final standings = ref.watch(myDuesProvider).value ?? const <DuesStanding>[];
    final dues = [
      for (final s in standings)
        if (plans[s.planId] case final plan?) (plan, s),
    ];
    if (dues.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GroupHeading(l.myDues),
        const SizedBox(height: 8),
        for (final (plan, s) in dues) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: Bua.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: s.owed > 0 ? Bua.dangerTint : Bua.line),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Icon(
                  s.exempt ? Icons.remove_circle_outline : (s.owed > 0 ? Icons.error_outline : Icons.check_circle),
                  color: s.exempt ? Bua.inkSubtle : (s.owed > 0 ? Bua.danger : Bua.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(plan.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(l.duesEvery(naira(plan.amount), duesPer(l, plan.period)),
                        style: TextStyle(fontSize: 12.5, color: Bua.inkSubtle)),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              Text(standingText(l, s),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: s.owed > 0 ? Bua.danger : Bua.ink)),
              if (s.pending > 0)
                Text(l.waitingConfirmation(naira(s.pending)), style: TextStyle(fontSize: 13, color: Bua.inkSubtle)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (!s.exempt)
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () => context.push(
                        '/fund/give?dues=${plan.id}&amount=${(s.owed > 0 ? s.owed : plan.amount).round()}'),
                    child: Text(l.payDues),
                  ),
                TextButton.icon(
                  onPressed: () => _statement(context, ref, dues),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(l.myStatement),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 10),
        ],
      ]),
    );
  }
}

/// Committee: wedding and naming gifts paid in the app, to pass on to hosts.
class _EventPayouts extends ConsumerWidget {
  const _EventPayouts();

  Future<void> _done(BuildContext context, WidgetRef ref, EventPayoutDue p) async {
    final l = context.l10n;
    final name = authorOf(ref, p.receiverId).name;
    if (!await confirm(context, l.eventPayoutConfirm(naira(p.amount), name)) || !context.mounted) return;
    if (await guarded(context, () => ref.read(repositoryProvider).eventPayoutDone(p.eventId))) {
      ref.invalidate(eventPayoutsDueProvider);
      ref.invalidate(eventGiftsProvider(p.eventId));
      if (context.mounted) showSnack(context, l.eventPayoutDone(name));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final due = ref.watch(eventPayoutsDueProvider).value ?? const <EventPayoutDue>[];
    if (due.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GroupHeading(l.eventPayoutsTitle),
        const SizedBox(height: 4),
        Text(l.eventPayoutsHint, style: TextStyle(fontSize: 12, height: 1.4, color: Bua.inkMuted)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            for (final (i, p) in due.indexed) ...[
              if (i > 0) const InsetDivider(indent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/events/${p.eventId}'),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(l.eventPayoutLine(authorOf(ref, p.receiverId).name, p.payments),
                            style: TextStyle(fontSize: 13, color: Bua.inkMuted)),
                        Text(naira(p.amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                  FilledButton(onPressed: () => _done(context, ref, p), child: Text(l.eventPayoutSent)),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
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
                TextSpan(text: naira(c.raised), style: TextStyle(fontWeight: FontWeight.w700, color: Bua.ink)),
                if (c.target != null) TextSpan(text: ' ${l.raisedOf('', naira(c.target!)).trim()}'),
                TextSpan(text: ' · ${l.contributorsCount(c.contributors)}'),
              ]),
              style: TextStyle(fontSize: 13, color: Bua.inkMuted),
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
          style: TextStyle(fontSize: 12, color: Bua.goldInkDark),
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
              Text([causeTitle ?? l.generalFund, c.online ? l.paidOnline : payMethodLabel(l, c.method), l.ago(c.createdAt)].join(' · '),
                  style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
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
