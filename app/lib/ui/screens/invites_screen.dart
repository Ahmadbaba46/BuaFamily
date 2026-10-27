import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../services/invites.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/share_sheet.dart';
import '../widgets/social.dart';
import 'join_screen.dart' show showInviteSheet;

/// Admins: the invite links made, who used them, and cancelling one that
/// should no longer work.
class InvitesScreen extends ConsumerWidget {
  const InvitesScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, Invite i) async {
    final l = context.l10n;
    if (!i.used && (!await confirm(context, l.confirmCancelInvite) || !context.mounted)) return;
    if (await guarded(context, () => ref.read(repositoryProvider).deleteInvite(i.code))) {
      ref.invalidate(invitesProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final invites = ref.watch(invitesProvider);
    final graph = ref.watch(graphProvider).value;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/admin')),
        title: Text(l.invitesTitle, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            tooltip: l.inviteSomeone,
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () async {
              await showInviteSheet(context);
              ref.invalidate(invitesProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(invitesProvider.future),
        child: AsyncBody(
          value: invites,
          onRetry: () => ref.invalidate(invitesProvider),
          builder: (list) => ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.noInvitesYet, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
              )
            else
              SectionCard(children: [
                for (final (n, i) in list.indexed) ...[
                  if (n > 0) const Divider(height: 1),
                  ListTile(
                    leading: IconTile(
                      i.used ? Icons.how_to_reg_outlined : Icons.mail_outline,
                      background: i.used ? Bua.greenTint : (i.expired(now) ? Bua.ground : Bua.goldTint),
                      color: i.used ? Bua.green : (i.expired(now) ? Bua.inkSubtle : Bua.goldInk),
                    ),
                    title: Text(
                      i.personId == null ? l.inviteAnyone : graph?[i.personId!]?.displayName ?? l.inviteAnyone,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      [
                        if (i.used)
                          l.inviteUsedBy(i.usedBy == null ? '?' : authorOf(ref, i.usedBy!).name, l.ago(i.usedAt!))
                        else if (i.expired(now))
                          l.inviteExpired
                        else
                          l.inviteWaiting,
                        if (i.createdBy != null) l.inviteMadeBy(authorOf(ref, i.createdBy!).name, l.ago(i.createdAt)),
                      ].join(' · '),
                      style: TextStyle(fontSize: 13, color: Bua.inkMuted),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => v == 'share'
                          ? showShareSheet(context,
                              link: inviteLink(i.code, lang: Localizations.localeOf(context).languageCode))
                          : _delete(context, ref, i),
                      itemBuilder: (_) => [
                        if (!i.used && !i.expired(now)) PopupMenuItem(value: 'share', child: Text(l.shareLabel)),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(!i.used && !i.expired(now) ? l.cancelInvite : l.removeFromList),
                        ),
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
