import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/messages.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';

/// Family admins: every group chat, who is in it, and the power to remove
/// someone or delete a group. What was said stays private.
class AdminGroupsScreen extends ConsumerWidget {
  const AdminGroupsScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, AdminGroup g) async {
    final l = context.l10n;
    final me = ref.read(profileProvider)?.id;
    final who = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l.groupRemoveWho(g.name), style: Theme.of(c).textTheme.titleMedium),
          ),
          for (final m in g.members.where((m) => m.userId != me))
            ListTile(
              leading: AuthorAvatar(authorOf(ref, m.userId)),
              title: Text(authorOf(ref, m.userId).name),
              trailing: m.admin ? Pill(l.groupAdminBadge) : null,
              onTap: () => Navigator.pop(c, m.userId),
            ),
        ]),
      ),
    );
    if (who == null || !context.mounted) return;
    final name = authorOf(ref, who).name;
    if (!await confirm(context, l.groupConfirmRemove(name)) || !context.mounted) return;
    if (await guarded(context, () => ref.read(repositoryProvider).removeFromGroup(g.id, who))) {
      ref.invalidate(adminGroupsProvider);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, AdminGroup g) async {
    final l = context.l10n;
    if (!await confirm(context, l.groupConfirmDeleteNamed(g.name)) || !context.mounted) return;
    if (await guarded(context, () => ref.read(repositoryProvider).deleteGroup(g.id))) {
      ref.invalidate(adminGroupsProvider);
      ref.invalidate(groupsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final groups = ref.watch(adminGroupsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/admin')),
        title: Text(l.allGroups, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminGroupsProvider.future),
        child: AsyncBody(
          value: groups,
          onRetry: () => ref.invalidate(adminGroupsProvider),
          builder: (list) => ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
            Text(l.allGroupsNote, style: TextStyle(fontSize: 13, height: 1.45, color: Bua.inkMuted)),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.noGroupsYet, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
              ),
            for (final g in list) ...[
              SectionCard(children: [
                ListTile(
                  leading: const IconTile(Icons.groups_outlined),
                  title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    [
                      l.groupMembersCount(g.members.length),
                      if (g.createdBy != null) l.startedBy(authorOf(ref, g.createdBy!).name),
                      l.ago(g.lastMessageAt ?? g.createdAt),
                    ].join(' · '),
                    style: TextStyle(fontSize: 13, color: Bua.inkMuted),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => v == 'remove' ? _remove(context, ref, g) : _delete(context, ref, g),
                    itemBuilder: (_) => [
                      if (g.members.isNotEmpty) PopupMenuItem(value: 'remove', child: Text(l.groupRemoveSomeone)),
                      PopupMenuItem(value: 'delete', child: Text(l.groupDelete)),
                    ],
                  ),
                ),
                if (g.members.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      g.members.map((m) => authorOf(ref, m.userId).name).join(', '),
                      style: TextStyle(fontSize: 13, color: Bua.inkSubtle),
                    ),
                  ),
              ]),
              const SizedBox(height: 10),
            ],
          ]),
        ),
      ),
    );
  }
}
