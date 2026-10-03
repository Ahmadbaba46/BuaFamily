import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/l10n.dart';
import '../../models/fund.dart';
import '../../models/social.dart' show PickedImage;
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import 'welfare_fund_screen.dart' show payMethodLabel;

/// One cause (or the general fund when [causeId] is null): progress, how to
/// pay, and the form to record a contribution.
class FundCauseScreen extends ConsumerWidget {
  const FundCauseScreen({super.key, this.causeId});

  final String? causeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final overview = ref.watch(fundOverviewProvider).value;
    final causes = ref.watch(fundCausesProvider);
    final cause = causeId == null ? null : causes.value?.where((c) => c.id == causeId).firstOrNull;
    final committee = ref.watch(profileProvider)?.isCommittee ?? false;

    if (causeId != null && cause == null) {
      return Scaffold(
        appBar: AppBar(),
        body: causes.isLoading ? const Center(child: CircularProgressIndicator()) : Center(child: Text(l.noResults)),
      );
    }
    final open = cause == null || cause.status == CauseStatus.open;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/fund')),
        titleSpacing: 0,
        title: Text(cause?.title ?? l.contributeToFund,
            style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
        actions: [
          if (committee && cause != null && cause.status == CauseStatus.open)
            PopupMenuButton<String>(
              onSelected: (_) async {
                if (await guarded(context, () => ref.read(repositoryProvider).updateCause(cause.id, {'status': 'closed'}))) {
                  refreshFund(ref);
                }
              },
              itemBuilder: (_) => [PopupMenuItem(value: 'close', child: Text(l.closeCause))],
            ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
        if (cause != null) ...[
          SectionCard(padding: const EdgeInsets.all(16), children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: naira(cause.raised),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Bua.ink),
                ),
                if (cause.target != null) TextSpan(text: ' ${l.raisedOf('', naira(cause.target!)).trim()}'),
              ]),
              style: const TextStyle(fontSize: 15, color: Bua.inkMuted),
            ),
            if (cause.target != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: cause.progress, minHeight: 10, backgroundColor: Bua.track, color: Bua.green),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              [
                l.contributorsCount(cause.contributors),
                if (cause.closesOn != null) l.closesOn(l.formatDate(cause.closesOn!)),
                if (!open) l.closed,
              ].join(' · '),
              style: const TextStyle(fontSize: 13, color: Bua.inkSubtle),
            ),
            if (cause.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Text(cause.description!, style: const TextStyle(fontSize: 15, height: 1.5)),
            ],
            if (cause.names.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(cause.names.join(', '), style: const TextStyle(fontSize: 13, color: Bua.inkMuted, height: 1.4)),
            ],
          ]),
          const SizedBox(height: 12),
        ],
        if (open) ...[
          _HowToPay(overview: overview),
          const SizedBox(height: 12),
          _RecordForm(causeId: cause?.id),
        ],
      ]),
    );
  }
}

class _HowToPay extends StatelessWidget {
  const _HowToPay({this.overview});

  final FundOverview? overview;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final o = overview;
    Widget row(String label, String? value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle))),
            Expanded(child: Text(value ?? '—', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          ]),
        );
    return SectionCard(title: l.howToPay, padding: const EdgeInsets.fromLTRB(0, 6, 0, 12), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: o == null || !o.hasAccount
            ? Text(l.noAccountYet, style: const TextStyle(fontSize: 13, color: Bua.inkMuted))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                row(l.bank, o.bankName),
                row(l.accountNumber, o.accountNumber),
                row(l.accountName, o.accountName),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: o.accountNumber!));
                    if (context.mounted) showSnack(context, l.copied);
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l.copyAccountNumber),
                ),
              ]),
      ),
    ]);
  }
}

class _RecordForm extends ConsumerStatefulWidget {
  const _RecordForm({this.causeId});

  final String? causeId;

  @override
  ConsumerState<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends ConsumerState<_RecordForm> {
  final _amount = TextEditingController();
  PayMethod _method = PayMethod.transfer;
  PickedImage? _receipt;
  bool _showName = true;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() => _receipt = PickedImage(bytes, f.name.contains('.') ? f.name.split('.').last : 'jpg'));
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final amount = double.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (amount == null || amount <= 0) return showSnack(context, l.amountInvalid);
    setState(() => _saving = true);
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).recordContribution(
            causeId: widget.causeId,
            amount: amount,
            method: _method,
            showName: _showName,
            receipt: _receipt,
          ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      refreshFund(ref);
      showSnack(context, l.contributionRecorded);
      context.canPop() ? context.pop() : context.go('/fund');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SectionCard(title: l.recordContribution, padding: const EdgeInsets.fromLTRB(0, 6, 0, 16), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LabeledField(
            label: l.amountNaira,
            child: TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(prefixText: '₦ '),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in PayMethod.values)
              ChoiceChip(
                label: Text(payMethodLabel(l, m)),
                selected: _method == m,
                onSelected: (_) => setState(() => _method = m),
              ),
          ]),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickReceipt,
            icon: Icon(_receipt == null ? Icons.attach_file : Icons.check_circle_outline, size: 18),
            label: Text(_receipt == null ? l.attachReceipt : l.receiptAttached),
          ),
          const SizedBox(height: 4),
          ToggleRow(title: l.showMyName, value: _showName, onChanged: (v) => setState(() => _showName = v)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.recordContributionButton),
          ),
          const SizedBox(height: 10),
          Text(l.contributionNote, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle, height: 1.4)),
        ]),
      ),
    ]);
  }
}

/// New cause (committee) or a request for support (any member).
class NewCauseScreen extends ConsumerStatefulWidget {
  const NewCauseScreen({super.key, this.ask = false});

  /// A member asking for support: saved as a proposal for the committee.
  final bool ask;

  @override
  ConsumerState<NewCauseScreen> createState() => _NewCauseScreenState();
}

class _NewCauseScreenState extends ConsumerState<NewCauseScreen> {
  final _title = TextEditingController();
  final _details = TextEditingController();
  final _amount = TextEditingController();
  DateTime? _closes;
  bool _urgent = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _details, _amount]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (_title.text.trim().isEmpty) return showSnack(context, l.titleRequired);
    final amount = double.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    final committee = ref.read(profileProvider)?.isCommittee ?? false;
    setState(() => _saving = true);
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).createCause({
        'title': _title.text.trim(),
        'description': _details.text.trim().isEmpty ? null : _details.text.trim(),
        'target_amount': amount,
        'closes_on': _closes == null
            ? null
            : '${_closes!.year}-${_closes!.month.toString().padLeft(2, '0')}-${_closes!.day.toString().padLeft(2, '0')}',
        'urgent': _urgent,
        'status': widget.ask || !committee ? 'proposed' : 'open',
      }),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      refreshFund(ref);
      if (widget.ask || !committee) showSnack(context, l.requestSent);
      context.canPop() ? context.pop() : context.go('/fund');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.close,
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/fund'),
        ),
        title: Text(widget.ask ? l.askForSupport : l.newCause, style: Theme.of(context).textTheme.titleMedium),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        if (widget.ask) ...[
          InfoBanner(icon: Icons.lock_outline, text: l.askSupportNote),
          const SizedBox(height: 12),
        ],
        SectionCard(padding: const EdgeInsets.all(16), children: [
          LabeledField(
            label: l.causeTitle,
            child: TextField(controller: _title, textCapitalization: TextCapitalization.sentences),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: l.details,
            child: TextField(controller: _details, minLines: 3, maxLines: 8, textCapitalization: TextCapitalization.sentences),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: l.targetAmount,
            child: TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(prefixText: '₦ '),
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: l.closesOnLabel,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _closes ?? now.add(const Duration(days: 30)),
                  firstDate: now,
                  lastDate: DateTime(now.year + 3),
                );
                if (d != null) setState(() => _closes = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
                child: Text(_closes == null ? l.pickDate : l.formatDate(_closes!)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          ToggleRow(title: l.urgent, value: _urgent, onChanged: (v) => setState(() => _urgent = v)),
        ]),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.ask ? l.askForSupport : l.newCause),
        ),
      ]),
    );
  }
}
