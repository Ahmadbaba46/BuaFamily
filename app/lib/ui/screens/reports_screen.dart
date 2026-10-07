import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../models/report.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/report_sheet.dart';
import '../widgets/social.dart';

/// Admins: what members reported, and what was done about it.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final reports = ref.watch(reportsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/admin')),
        title: Text(l.reportsTitle),
      ),
      body: AsyncBody(
        value: reports,
        onRetry: () => ref.invalidate(reportsProvider),
        builder: (all) {
          final open = all.where((r) => r.isOpen).toList()
            // Child safety first, then newest.
            ..sort((a, b) {
              final c = (b.reason == ReportReason.childSafety ? 1 : 0) - (a.reason == ReportReason.childSafety ? 1 : 0);
              return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
            });
          final done = all.where((r) => !r.isOpen).toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(reportsProvider.future),
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
              Text(l.reportsIntro, style: TextStyle(fontSize: 13, height: 1.45, color: Bua.inkMuted)),
              const SizedBox(height: 12),
              if (open.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(children: [
                    Icon(Icons.verified_user_outlined, size: 44, color: Bua.green),
                    const SizedBox(height: 8),
                    Text(l.noOpenReports, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
                  ]),
                ),
              for (final r in open) ...[_ReportCard(report: r), const SizedBox(height: 10)],
              if (done.isNotEmpty) ...[
                Padding(padding: const EdgeInsets.fromLTRB(4, 16, 4, 8), child: GroupHeading(l.reportsDone)),
                for (final r in done) ...[_ReportCard(report: r), const SizedBox(height: 10)],
              ],
            ]),
          );
        },
      ),
    );
  }
}

String reportKindLabel(AppLocalizations l, ReportKind k) => switch (k) {
      ReportKind.post => l.reportKindPost,
      ReportKind.photo => l.reportKindPhoto,
      ReportKind.comment => l.reportKindComment,
      ReportKind.profile => l.reportKindProfile,
      ReportKind.member => l.reportKindMember,
      ReportKind.message => l.reportKindMessage,
    };

String reportStatusLabel(AppLocalizations l, ReportStatus s) => switch (s) {
      ReportStatus.open => l.reportStatusOpen,
      ReportStatus.removed => l.reportStatusRemoved,
      ReportStatus.actioned => l.reportStatusActioned,
      ReportStatus.dismissed => l.reportStatusDismissed,
    };

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.report});

  final Report report;

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    if (await guarded(context, action)) {
      ref.invalidate(reportsProvider);
      ref.invalidate(feedProvider);
      ref.invalidate(profilesProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = report;
    final repo = ref.read(repositoryProvider);
    final urgent = r.reason == ReportReason.childSafety;
    final reporter = r.reporterId == null ? null : authorOf(ref, r.reporterId!);
    final removable = r.kind == ReportKind.post || r.kind == ReportKind.photo || r.kind == ReportKind.comment;
    final target = r.targetUser == null ? null : ref.watch(profilesProvider).value?.where((p) => p.id == r.targetUser).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Bua.surface,
        borderRadius: BorderRadius.circular(20),
        border: urgent && r.isOpen ? Border.all(color: Bua.danger, width: 2) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text(reportKindLabel(l, r.kind), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Pill(
              reportReasonLabel(l, r.reason),
              icon: urgent ? Icons.warning_amber_rounded : null,
              background: urgent ? Bua.dangerTint : Bua.goldTint,
              color: urgent ? Bua.danger : Bua.goldInk,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          [
            if (r.author != null) l.reportedAuthor(r.author!),
            if (reporter != null) l.reportedBy(reporter.name),
            l.ago(r.createdAt),
          ].join(' · '),
          style: TextStyle(fontSize: 12, color: Bua.inkSubtle),
        ),
        if (r.text?.isNotEmpty ?? false) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Bua.ground, borderRadius: BorderRadius.circular(12)),
            child: Text('“${r.text}”', style: TextStyle(fontSize: 14, height: 1.45, color: Bua.inkBody)),
          ),
        ],
        if (r.note?.isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          Text(l.reportNoteFrom(r.note!), style: TextStyle(fontSize: 13, height: 1.45, color: Bua.inkMuted)),
        ],
        const SizedBox(height: 10),
        if (!r.isOpen)
          Row(children: [
            Expanded(
              child: Text(reportStatusLabel(l, r.status), style: TextStyle(fontSize: 13, color: Bua.inkMuted)),
            ),
            TextButton(
              onPressed: () => _run(context, ref, () => repo.resolveReport(r.id, ReportStatus.open)),
              child: Text(l.reopen),
            ),
          ])
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (r.link != null)
              OutlinedButton.icon(
                onPressed: () => context.push(r.link!),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l.openLabel),
              ),
            if (removable)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Bua.danger),
                onPressed: () async {
                  if (!await confirm(context, l.confirmRemoveReported) || !context.mounted) return;
                  await _run(context, ref, () => repo.removeReported(r));
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l.removeContent),
              ),
            if (target != null && target.status == AccountStatus.active && target.role != AppRole.admin)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Bua.danger),
                onPressed: () async {
                  if (!await confirm(context, l.confirmSuspendReported(r.author ?? '')) || !context.mounted) return;
                  await _run(context, ref, () async {
                    await repo.adminUpdateAccount(target.id, status: AccountStatus.suspended);
                    await repo.resolveReport(r.id, ReportStatus.actioned);
                  });
                },
                icon: const Icon(Icons.block, size: 18),
                label: Text(l.suspendAccount),
              ),
            TextButton(
              onPressed: () => _run(context, ref, () => repo.resolveReport(r.id, ReportStatus.actioned)),
              child: Text(l.markHandled),
            ),
            TextButton(
              onPressed: () => _run(context, ref, () => repo.resolveReport(r.id, ReportStatus.dismissed)),
              child: Text(l.dismissReport),
            ),
          ]),
      ]),
    );
  }
}
