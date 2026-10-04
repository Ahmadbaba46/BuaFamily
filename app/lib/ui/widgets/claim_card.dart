import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../models/person.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'bua.dart';
import 'common.dart';
import 'form_dialog.dart';

/// An approved member says "this is me" about [person]: who they are, what
/// they wrote, enough about the person to check it, and confirm or decline.
class ClaimCard extends ConsumerWidget {
  const ClaimCard({super.key, required this.account, required this.person, this.onDone, this.showPerson = true});

  final Profile account;
  final Person person;

  /// After a decision (e.g. refresh a list).
  final VoidCallback? onDone;

  /// Hide the person's details when already on their page.
  final bool showPerson;

  void _refresh(WidgetRef ref) {
    ref.invalidate(adminUsersProvider);
    ref.invalidate(profilesProvider);
    onDone?.call();
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref, String personId) async {
    final l = context.l10n;
    final ok = await guarded(context, () => ref.read(repositoryProvider).adminUpdateAccount(account.id, personId: personId));
    if (!ok || !context.mounted) return;
    _refresh(ref);
    showSnack(context, l.claimConfirmed);
  }

  Future<void> _other(BuildContext context, WidgetRef ref) async {
    final graph = ref.read(graphProvider).value;
    if (graph == null) return;
    final p = await pickPerson(context, graph);
    if (p != null && context.mounted) await _confirm(context, ref, p.id);
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final v = await showFormDialog(context, title: l.claimDeclineTitle, fields: [
      TextSpec('reason', l.claimDeclineReason, multiline: true),
    ]);
    if (v == null || !context.mounted) return;
    final ok = await guarded(context, () => ref.read(repositoryProvider).declineClaim(account.id, v['reason'] as String?));
    if (!ok || !context.mounted) return;
    _refresh(ref);
    showSnack(context, l.claimDeclined);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final graph = ref.watch(graphProvider).value;
    final takenBy = (ref.watch(profilesProvider).value ?? const <Profile>[])
        .where((p) => p.personId == person.id && p.id != account.id)
        .firstOrNull;
    final parents = graph?.parentsOf(person.id) ?? const <Person>[];
    final name = account.displayName.isNotEmpty ? account.displayName : (account.email ?? '?');
    final facts = [
      if (person.birthDate != null) '${person.birthDate!.year}',
      if (parents.isNotEmpty) l.childOf(parents.map((p) => p.displayName).join(' & ')),
      if (person.branch?.isNotEmpty ?? false) person.branch!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Bua.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Bua.greenIndicator, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IconTile(Icons.how_to_reg_outlined, background: Bua.greenTint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(l.claimTitle, style: TextStyle(fontSize: 13, color: Bua.inkSubtle)),
            ]),
          ),
          Pill(l.filterClaims, background: Bua.greenTint, color: Bua.green),
        ]),
        if (showPerson) ...[
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/person/${person.id}'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Bua.ground, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                PersonAvatar(person: person, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(person.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    if (facts.isNotEmpty) Text(facts, style: TextStyle(fontSize: 12.5, color: Bua.inkMuted)),
                  ]),
                ),
                Icon(Icons.chevron_right, color: Bua.inkSubtle),
              ]),
            ),
          ),
        ],
        if (account.claimNote?.isNotEmpty ?? false) ...[
          const SizedBox(height: 10),
          Text('“${account.claimNote}”',
              style: TextStyle(fontSize: 14, height: 1.45, fontStyle: FontStyle.italic, color: Bua.inkBody)),
        ],
        if (takenBy != null) ...[
          const SizedBox(height: 10),
          InfoBanner(
            icon: Icons.warning_amber_rounded,
            text: l.claimAlreadyLinked(takenBy.displayName),
            tone: BannerTone.danger,
          ),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Bua.danger),
            onPressed: () => _decline(context, ref),
            child: Text(l.claimDecline),
          ),
          OutlinedButton(onPressed: () => _other(context, ref), child: Text(l.linkSomeoneElse)),
          FilledButton.icon(
            onPressed: takenBy != null ? null : () => _confirm(context, ref, person.id),
            icon: const Icon(Icons.check, size: 18),
            label: Text(l.claimConfirm),
          ),
        ]),
      ]),
    );
  }
}

/// Approved members asking to be linked to someone in the tree.
bool hasOpenClaim(Profile p) =>
    p.status == AccountStatus.active && p.personId == null && p.requestedPersonId != null;
