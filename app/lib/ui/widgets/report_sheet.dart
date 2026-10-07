import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/report.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'common.dart';

String reportReasonLabel(AppLocalizations l, ReportReason r) => switch (r) {
      ReportReason.childSafety => l.reportReasonChildSafety,
      ReportReason.abuse => l.reportReasonAbuse,
      ReportReason.spam => l.reportReasonSpam,
      ReportReason.other => l.reportReasonOther,
    };

/// Asks why, then reports [targetId] to the family's admins.
Future<void> reportToAdmins(BuildContext context, WidgetRef ref, ReportKind kind, String targetId) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Bua.ground,
    builder: (_) => _ReportSheet(kind: kind, targetId: targetId),
  );
  if (sent == true && context.mounted) showSnack(context, context.l10n.reportSent);
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.kind, required this.targetId});

  final ReportKind kind;
  final String targetId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  ReportReason? _reason;
  final _note = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null) return;
    setState(() => _sending = true);
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).reportContent(widget.kind, widget.targetId, reason, note: _note.text.trim()),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.reportSheetTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(l.reportIntro, style: TextStyle(fontSize: 13, height: 1.45, color: Bua.inkMuted)),
          const SizedBox(height: 8),
          RadioGroup<ReportReason>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v),
            child: Column(children: [
              for (final r in ReportReason.values)
                RadioListTile<ReportReason>(
                  contentPadding: EdgeInsets.zero,
                  value: r,
                  title: Text(reportReasonLabel(l, r)),
                ),
            ]),
          ),
          if (_reason == ReportReason.childSafety)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Bua.dangerTint, borderRadius: BorderRadius.circular(12)),
              child: Text(l.reportChildSafetyNote, style: TextStyle(fontSize: 13, height: 1.45, color: Bua.ink)),
            ),
          TextField(
            controller: _note,
            maxLines: 3,
            maxLength: 2000,
            decoration: InputDecoration(hintText: l.reportNoteHint),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _reason == null || _sending ? null : _send,
            child: Text(l.reportSend),
          ),
        ]),
      ),
    );
  }
}
