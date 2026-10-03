import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/community.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';

/// Family polls: open ones to vote on, then the decisions.
class PollsScreen extends ConsumerWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final polls = ref.watch(pollsProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        titleSpacing: 0,
        title: Text(l.pollsTitle, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => context.push('/polls/new'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.newPoll),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pollsProvider.future),
        child: AsyncBody(
          value: polls,
          onRetry: () => ref.invalidate(pollsProvider),
          builder: (all) {
            final open = all.where((p) => p.isOpen(now)).toList();
            final decided = all.where((p) => !p.isOpen(now)).toList()
              ..sort((a, b) => b.decidedAt(now).compareTo(a.decidedAt(now)));
            return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
              if (all.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(l.noPollsYet, textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkSubtle)),
                ),
              for (final p in open) ...[_OpenPoll(poll: p, key: ValueKey(p.id)), const SizedBox(height: 12)],
              if (all.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(l.secretBallot, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                ),
              if (decided.isNotEmpty) ...[
                const SizedBox(height: 4),
                GroupHeading(l.decided),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    for (final (i, p) in decided.indexed) ...[
                      if (i > 0) const InsetDivider(indent: 16),
                      _DecidedPoll(poll: p, now: now),
                    ],
                  ]),
                ),
              ],
            ]);
          },
        ),
      ),
    );
  }
}

class _PollMenu extends ConsumerWidget {
  const _PollMenu({required this.poll});

  final Poll poll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(profileProvider);
    if (me == null || (poll.createdBy != me.id && !me.isAdmin)) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Bua.inkSubtle),
      onSelected: (v) async {
        final repo = ref.read(repositoryProvider);
        final ok = await guarded(context, () => v == 'close' ? repo.closePoll(poll.id) : repo.deletePoll(poll.id));
        if (ok) ref.invalidate(pollsProvider);
      },
      itemBuilder: (_) => [
        if (poll.isOpen(DateTime.now())) PopupMenuItem(value: 'close', child: Text(l.closePoll)),
        PopupMenuItem(value: 'delete', child: Text(l.deletePoll)),
      ],
    );
  }
}

class _OpenPoll extends ConsumerStatefulWidget {
  const _OpenPoll({super.key, required this.poll});

  final Poll poll;

  @override
  ConsumerState<_OpenPoll> createState() => _OpenPollState();
}

class _OpenPollState extends ConsumerState<_OpenPoll> {
  late String? _choice = widget.poll.myOptionId;
  // Show the ballot even after voting, when changing a vote.
  bool _changing = false;
  bool _saving = false;

  Future<void> _vote() async {
    final c = _choice;
    if (c == null) return;
    setState(() => _saving = true);
    final ok = await guarded(context, () => ref.read(repositoryProvider).vote(widget.poll.id, c));
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _changing = false;
    });
    if (ok) ref.invalidate(pollsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.poll;
    final voted = p.myOptionId != null;
    final showResults = voted && p.resultsVisible && !_changing;

    final meta = [
      if (p.context?.isNotEmpty ?? false) p.context!,
      if (p.closesAt != null) l.closesDate(l.dayMonth(p.closesAt!)),
      voted ? l.youVoted : l.notVotedYet,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 14),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(meta,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: voted ? Bua.green : Bua.inkSubtle)),
                const SizedBox(height: 4),
                Text(p.question, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3)),
              ]),
            ),
          ),
          _PollMenu(poll: p),
        ]),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: showResults
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (final o in p.options) _ResultBar(option: o, percent: p.percent(o), mine: o.id == p.myOptionId),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(
                      child: Text(l.votedOf(p.total, p.eligible),
                          style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                    ),
                    TextButton(onPressed: () => setState(() => _changing = true), child: Text(l.changeVote)),
                  ]),
                ])
              : RadioGroup<String>(
                  groupValue: _choice,
                  onChanged: (v) => setState(() => _choice = v),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (final o in p.options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: _choice == o.id ? Bua.greenTint : Bua.ground,
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: RadioListTile<String>(
                            value: o.id,
                            dense: true,
                            title: Text(o.label, style: const TextStyle(fontSize: 15)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    FilledButton(
                      onPressed: _choice == null || _saving ? null : _vote,
                      child: Text(voted ? l.changeVote : l.vote),
                    ),
                  ]),
                ),
        ),
      ]),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.option, required this.percent, required this.mine});

  final PollOption option;
  final int percent;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(children: [
          Positioned.fill(child: Container(color: Bua.ground)),
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent / 100,
              child: Container(color: mine ? Bua.green.withValues(alpha: 0.22) : Bua.greenTint),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              if (mine) ...[const Icon(Icons.check_circle, size: 16, color: Bua.green), const SizedBox(width: 6)],
              Expanded(
                child: Text(option.label,
                    style: TextStyle(fontSize: 15, fontWeight: mine ? FontWeight.w600 : FontWeight.w400)),
              ),
              Text('$percent%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DecidedPoll extends StatelessWidget {
  const _DecidedPoll({required this.poll, required this.now});

  final Poll poll;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lead = poll.leader;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: Bua.greenTint, shape: BoxShape.circle),
          child: const Icon(Icons.how_to_vote_outlined, size: 18, color: Bua.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lead == null ? poll.question : '${poll.question}: ${lead.label}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text(
              lead == null
                  ? l.votedOf(poll.total, poll.eligible)
                  : l.decidedLine(poll.percent(lead), l.dayMonth(poll.decidedAt(now))),
              style: const TextStyle(fontSize: 12, color: Bua.inkSubtle),
            ),
          ]),
        ),
        _PollMenu(poll: poll),
      ]),
    );
  }
}

/// Ask the family a question.
class NewPollScreen extends ConsumerStatefulWidget {
  const NewPollScreen({super.key});

  @override
  ConsumerState<NewPollScreen> createState() => _NewPollScreenState();
}

class _NewPollScreenState extends ConsumerState<NewPollScreen> {
  final _question = TextEditingController();
  final _context = TextEditingController();
  final _choices = [TextEditingController(), TextEditingController()];
  DateTime _closes = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_question, _context, ..._choices]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final options = _choices.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (_question.text.trim().isEmpty || options.length < 2) return showSnack(context, l.needTwoChoices);
    setState(() => _saving = true);
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).createPoll(
            question: _question.text.trim(),
            context: _context.text.trim().isEmpty ? null : _context.text.trim(),
            // Voting stays open through the chosen day.
            closesAt: _closes.add(const Duration(days: 1)),
            options: options,
          ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    ref.invalidate(pollsProvider);
    context.canPop() ? context.pop() : context.go('/polls');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.close,
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/polls'),
        ),
        title: Text(l.newPoll, style: Theme.of(context).textTheme.titleMedium),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        SectionCard(padding: const EdgeInsets.all(16), children: [
          LabeledField(
            label: l.question,
            child: TextField(
              controller: _question,
              autofocus: true,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: l.pollContext,
            child: TextField(controller: _context, decoration: InputDecoration(hintText: l.pollContextHint)),
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(padding: const EdgeInsets.all(16), children: [
          Text(l.choices, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Bua.inkBody)),
          const SizedBox(height: 8),
          for (final (i, c) in _choices.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: c,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l.choiceN(i + 1),
                  suffixIcon: _choices.length <= 2
                      ? null
                      : IconButton(
                          tooltip: l.delete,
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _choices.removeAt(i).dispose()),
                        ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _choices.length >= 10 ? null : () => setState(() => _choices.add(TextEditingController())),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.addChoice),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(padding: const EdgeInsets.all(16), children: [
          LabeledField(
            label: l.closesOnPoll,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _closes,
                  firstDate: DateUtils.dateOnly(now),
                  lastDate: DateTime(now.year + 1, now.month, now.day),
                );
                if (d != null) setState(() => _closes = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: Bua.inkSubtle),
                ),
                child: Text(l.weekdayDate(_closes), style: const TextStyle(fontSize: 15)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(l.secretBallot, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
        ]),
        const SizedBox(height: 20),
        FilledButton(onPressed: _saving ? null : _submit, child: Text(l.post)),
      ]),
    );
  }
}
