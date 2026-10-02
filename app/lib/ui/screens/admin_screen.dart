import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';
import '../widgets/request_card.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.navAdmin),
          bottom: TabBar(tabs: [
            Tab(text: l.requestsTitle),
            Tab(text: l.accountsTitle),
            Tab(text: l.settingsTitle),
          ]),
        ),
        body: const TabBarView(children: [_RequestsTab(), _AccountsTab(), _SettingsTab()]),
      ),
    );
  }
}

// ------------------------------------------------------------------ requests

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final requests = ref.watch(requestsProvider(RequestStatus.pending));
    final graph = ref.watch(graphProvider).value;
    final names = {for (final p in ref.watch(profilesProvider).value ?? <Profile>[]) p.id: p.displayName};

    Future<void> review(ChangeRequest r, bool approve) async {
      String? note;
      if (!approve) {
        final v = await showFormDialog(context, title: l.reject, fields: [TextSpec('note', l.rejectReason)]);
        if (v == null) return;
        note = v['note'] as String?;
      }
      if (!context.mounted) return;
      final ok = await guarded(
        context,
        () => ref.read(repositoryProvider).reviewRequest(r.id, approve: approve, note: note),
      );
      if (ok) {
        ref.invalidate(requestsProvider);
        if (approve) ref.invalidate(graphProvider);
      }
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(requestsProvider(RequestStatus.pending).future),
      child: AsyncBody(
        value: requests,
        onRetry: () => ref.invalidate(requestsProvider),
        builder: (list) => list.isEmpty || graph == null
            ? ListView(children: [const SizedBox(height: 80), Center(child: Text(l.noRequests))])
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => RequestCard(
                  request: list[i],
                  graph: graph,
                  requesterName: names[list[i].requestedBy],
                  actions: [
                    TextButton(onPressed: () => review(list[i], false), child: Text(l.reject)),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () => review(list[i], true), child: Text(l.approve)),
                  ],
                ),
              ),
      ),
    );
  }
}

// ------------------------------------------------------------------ accounts

class _AccountsTab extends ConsumerWidget {
  const _AccountsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profiles = ref.watch(profilesProvider);
    final graph = ref.watch(graphProvider).value;
    final me = ref.watch(profileProvider);

    Future<void> update(Profile p, {AccountStatus? status, AppRole? role, String? personId}) async {
      final ok = await guarded(
        context,
        () => ref.read(repositoryProvider).adminUpdateAccount(p.id, status: status, role: role, personId: personId),
      );
      if (ok) ref.invalidate(profilesProvider);
    }

    Future<void> link(Profile p) async {
      if (graph == null) return;
      final person = await pickPerson(context, graph);
      if (person != null) await update(p, personId: person.id);
    }

    Widget card(Profile p) {
      final linked = p.personId == null ? null : graph?[p.personId!];
      final wants = p.requestedPersonId == null ? null : graph?[p.requestedPersonId!];
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(p.displayName.isEmpty ? (p.email ?? '?') : p.displayName,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              if (p.role == AppRole.admin) Chip(label: Text(l.roleAdmin), visualDensity: VisualDensity.compact),
            ]),
            if (p.email != null) Text(p.email!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(linked == null ? l.notLinked : l.linkedTo(linked.displayName)),
            if (p.claimNote?.isNotEmpty ?? false) Text('“${p.claimNote}”', style: const TextStyle(fontStyle: FontStyle.italic)),
            if (wants != null && linked == null) Text(l.wantsToBe(wants.displayName)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, alignment: WrapAlignment.end, children: [
              if (wants != null && linked == null)
                FilledButton.tonal(
                  onPressed: () => update(p, personId: wants.id, status: AccountStatus.active),
                  child: Text('${l.activate}: ${wants.firstName}'),
                ),
              OutlinedButton(onPressed: () => link(p), child: Text(l.linkToPerson)),
              if (p.status != AccountStatus.active)
                FilledButton(onPressed: () => update(p, status: AccountStatus.active), child: Text(l.activate)),
              if (p.status == AccountStatus.active && p.id != me?.id)
                TextButton(onPressed: () => update(p, status: AccountStatus.suspended), child: Text(l.suspend)),
              if (p.status == AccountStatus.active && p.id != me?.id)
                TextButton(
                  onPressed: () => update(p, role: p.role == AppRole.admin ? AppRole.member : AppRole.admin),
                  child: Text(p.role == AppRole.admin ? l.makeMember : l.makeAdmin),
                ),
            ]),
          ]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(profilesProvider.future),
      child: AsyncBody(
        value: profiles,
        onRetry: () => ref.invalidate(profilesProvider),
        builder: (list) {
          final groups = [
            (l.pendingAccounts, list.where((p) => p.status == AccountStatus.pending).toList()),
            (l.activeAccounts, list.where((p) => p.status == AccountStatus.active).toList()),
            (l.suspendedAccounts, list.where((p) => p.status == AccountStatus.suspended).toList()),
          ];
          return ListView(padding: const EdgeInsets.all(12), children: [
            for (final (title, members) in groups)
              if (members.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Text('$title (${members.length})', style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final p in members) Padding(padding: const EdgeInsets.only(bottom: 8), child: card(p)),
              ],
          ]);
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ settings

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final graph = ref.watch(graphProvider).value;

    Future<void> save(Map<String, dynamic> changes) async {
      final ok = await guarded(context, () => ref.read(repositoryProvider).updateSettings(changes));
      if (ok) ref.invalidate(settingsProvider);
    }

    return AsyncBody(
      value: settings,
      onRetry: () => ref.invalidate(settingsProvider),
      builder: (s) {
        final root = s.rootPersonId == null ? null : graph?[s.rootPersonId!];
        return ListView(children: [
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: Text(l.familyName),
            subtitle: Text(s.familyName),
            onTap: () async {
              final v = await showFormDialog(context, title: l.familyName, fields: [
                TextSpec('name', l.familyName, initial: s.familyName, required: true),
              ]);
              if (v != null) await save({'family_name': v['name']});
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.group_add_outlined),
            title: Text(l.memberContributions),
            subtitle: Text(l.memberContributionsHelp),
            value: s.memberContributionsEnabled,
            onChanged: (v) => save({'member_contributions_enabled': v}),
          ),
          ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: Text(l.treeRoot),
            subtitle: Text(root?.displayName ?? l.treeRootAuto),
            trailing: root == null
                ? null
                : IconButton(
                    tooltip: l.clear,
                    icon: const Icon(Icons.clear),
                    onPressed: () => save({'root_person_id': null}),
                  ),
            onTap: graph == null
                ? null
                : () async {
                    final p = await pickPerson(context, graph);
                    if (p != null) await save({'root_person_id': p.id});
                  },
          ),
        ]);
      },
    );
  }
}
