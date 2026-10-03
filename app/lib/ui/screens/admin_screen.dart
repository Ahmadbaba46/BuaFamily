import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';
import '../widgets/request_card.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key, this.initialTab = 0});

  /// 0 requests, 1 accounts, 2 settings.
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final requests = ref.watch(requestsProvider(RequestStatus.pending)).value?.length ?? 0;
    final accounts =
        ref.watch(profilesProvider).value?.where((p) => p.status == AccountStatus.pending).length ?? 0;

    Widget tab(String label, int count, bool emphasise) => Tab(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: emphasise ? Bua.green : Bua.track,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: emphasise ? Colors.white : Bua.ink)),
              ),
            ],
          ]),
        );

    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
          title: Text(l.navAdmin, style: Theme.of(context).textTheme.titleLarge),
          bottom: TabBar(tabs: [
            tab(l.requestsTitle, requests, true),
            tab(l.accountsTitle, accounts, true),
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
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => RequestCard(
                  request: list[i],
                  graph: graph,
                  requesterName: names[list[i].requestedBy],
                  actions: [
                    OutlinedButton(onPressed: () => review(list[i], false), child: Text(l.reject)),
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

    Future<void> link(Profile p, {bool approve = false}) async {
      if (graph == null) return;
      final person = await pickPerson(context, graph);
      if (person != null) await update(p, personId: person.id, status: approve ? AccountStatus.active : null);
    }

    String initials(Profile p) {
      final parts = (p.displayName.isEmpty ? (p.email ?? '?') : p.displayName).trim().split(RegExp(r'\s+'));
      return parts.take(2).map((s) => s.isEmpty ? '' : s[0].toUpperCase()).join();
    }

    Widget avatar(Profile p, double size) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Bua.track, shape: BoxShape.circle),
          child: Text(initials(p),
              style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w700, color: Bua.unknownFg)),
        );

    Widget pendingCard(Profile p) {
      final wants = p.requestedPersonId == null ? null : graph?[p.requestedPersonId!];
      final linked = p.personId == null ? null : graph?[p.personId!];
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            avatar(p, 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.displayName.isEmpty ? (p.email ?? '?') : p.displayName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (p.email != null) Text(p.email!, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
              ]),
            ),
          ]),
          if (p.claimNote?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Bua.ground, borderRadius: BorderRadius.circular(12)),
              child: Text('“${p.claimNote}”',
                  style: const TextStyle(fontSize: 14, height: 1.45, fontStyle: FontStyle.italic, color: Bua.inkBody)),
            ),
          ],
          if (wants != null || linked != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Bua.connector),
              ),
              child: Row(children: [
                const Icon(Icons.link, size: 18, color: Bua.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    linked != null ? l.linkedTo(linked.displayName) : l.wantsToBe(wants!.displayName),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => link(p),
                child: Text(wants != null || linked != null ? l.linkSomeoneElse : l.linkToPerson,
                    textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => wants != null && linked == null
                    ? update(p, personId: wants.id, status: AccountStatus.active)
                    : update(p, status: AccountStatus.active),
                child: Text(wants != null && linked == null ? l.approveAndLink : l.activate,
                    textAlign: TextAlign.center),
              ),
            ),
          ]),
        ]),
      );
    }

    Widget compactRow(Profile p) {
      final linked = p.personId == null ? null : graph?[p.personId!];
      final self = p.id == me?.id;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
        child: Row(children: [
          avatar(p, 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.displayName.isEmpty ? (p.email ?? '?') : p.displayName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(linked == null ? l.notLinked : l.linkedTo(linked.displayName),
                  style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
            ]),
          ),
          if (p.isTreasurer) ...[
            Pill(l.treasurer, background: Bua.goldTint, color: Bua.goldInk),
            const SizedBox(width: 6),
          ],
          p.role == AppRole.admin
              ? Pill(l.roleAdmin, background: Bua.green, color: Colors.white)
              : Pill(l.roleMember, background: Bua.track, color: Bua.ink),
          if (self)
            const SizedBox(width: 12)
          else
            PopupMenuButton<String>(
              onSelected: (v) => switch (v) {
                'link' => link(p),
                'role' => update(p, role: p.role == AppRole.admin ? AppRole.member : AppRole.admin),
                'suspend' => update(p, status: AccountStatus.suspended),
                'treasurer' => guarded(context, () => ref.read(repositoryProvider).setTreasurer(p.id, !p.isTreasurer))
                    .then((ok) => ok ? ref.invalidate(profilesProvider) : null),
                _ => update(p, status: AccountStatus.active),
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'link', child: Text(l.linkToPerson)),
                if (p.status == AccountStatus.active) ...[
                  PopupMenuItem(value: 'role', child: Text(p.role == AppRole.admin ? l.makeMember : l.makeAdmin)),
                  PopupMenuItem(value: 'treasurer', child: Text(p.isTreasurer ? l.removeTreasurer : l.makeTreasurer)),
                  PopupMenuItem(value: 'suspend', child: Text(l.suspend)),
                ] else
                  PopupMenuItem(value: 'activate', child: Text(l.activate)),
              ],
            ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(profilesProvider.future),
      child: AsyncBody(
        value: profiles,
        onRetry: () => ref.invalidate(profilesProvider),
        builder: (list) {
          final pending = list.where((p) => p.status == AccountStatus.pending).toList();
          final active = list.where((p) => p.status == AccountStatus.active).toList();
          final suspended = list.where((p) => p.status == AccountStatus.suspended).toList();
          Widget compactCard(List<Profile> items) => Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [for (final p in items) compactRow(p)]),
              );
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (pending.isNotEmpty) ...[
              GroupHeading('${l.pendingAccounts} · ${pending.length}'),
              const SizedBox(height: 10),
              for (final p in pending) ...[pendingCard(p), const SizedBox(height: 12)],
            ],
            if (active.isNotEmpty) ...[
              GroupHeading('${l.activeAccounts} · ${active.length}'),
              const SizedBox(height: 10),
              compactCard(active),
              const SizedBox(height: 12),
            ],
            if (suspended.isNotEmpty) ...[
              GroupHeading('${l.suspendedAccounts} · ${suspended.length}'),
              const SizedBox(height: 10),
              compactCard(suspended),
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

    Widget check(String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check, size: 16, color: Bua.green),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ]),
        );

    return AsyncBody(
      value: settings,
      onRetry: () => ref.invalidate(settingsProvider),
      builder: (s) {
        final root = s.rootPersonId == null ? null : graph?[s.rootPersonId!];
        return ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const IconTile(Icons.person_add_alt_1, background: Bua.greenTint),
                const SizedBox(width: 14),
                Expanded(
                  child: ToggleRow(
                    title: l.memberContributions,
                    value: s.memberContributionsEnabled,
                    onChanged: (v) => save({'member_contributions_enabled': v}),
                  ),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.only(left: 54),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(l.memberContributionsHelp,
                      style: const TextStyle(fontSize: 13, height: 1.5, color: Bua.inkMuted)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Bua.ground, borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [check(l.adminAlwaysOwn), check(l.adminAlwaysDirect)]),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              _SettingRow(
                icon: Icons.home_work_outlined,
                title: l.familyName,
                value: s.familyName,
                onTap: () async {
                  final v = await showFormDialog(context, title: l.familyName, fields: [
                    TextSpec('name', l.familyName, initial: s.familyName, required: true),
                  ]);
                  if (v != null) await save({'family_name': v['name']});
                },
              ),
              const InsetDivider(indent: 70),
              _SettingRow(
                icon: Icons.account_tree_outlined,
                title: l.treeRoot,
                value: root?.displayName ?? l.treeRootAuto,
                trailing: root == null
                    ? null
                    : IconButton(
                        tooltip: l.clear,
                        icon: const Icon(Icons.clear, color: Bua.inkSubtle),
                        onPressed: () => save({'root_person_id': null}),
                      ),
                onTap: graph == null
                    ? null
                    : () async {
                        final p = await pickPerson(context, graph);
                        if (p != null) await save({'root_person_id': p.id});
                      },
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _SmsCard(settings: s, save: save),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lock_outline, size: 20, color: Bua.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${l.privacyTitle} ', style: const TextStyle(fontWeight: FontWeight.w600, color: Bua.ink)),
                    TextSpan(text: l.privacyNote),
                  ]),
                  style: const TextStyle(fontSize: 13, height: 1.5, color: Bua.inkMuted),
                ),
              ),
            ]),
          ),
        ]);
      },
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.title, required this.value, this.onTap, this.trailing});

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          IconTile(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
            ]),
          ),
          trailing ?? const Icon(Icons.chevron_right, color: Bua.inkSubtle),
        ]),
      ),
    );
  }
}

/// Termii setup: key, sender ID, route, on/off, status and a test message.
class _SmsCard extends ConsumerWidget {
  const _SmsCard({required this.settings, required this.save});

  final AppSettings settings;
  final Future<void> Function(Map<String, dynamic>) save;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(smsStatusProvider).value;
    final keySaved = status?.keySaved ?? false;
    final ready = keySaved && settings.smsSenderId != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            const IconTile(Icons.sms_outlined, background: Bua.greenTint),
            const SizedBox(width: 14),
            Expanded(
              child: ToggleRow(
                title: l.smsEnable,
                subtitle: l.smsEnableSub,
                value: settings.smsEnabled,
                onChanged: ready || settings.smsEnabled ? (v) => save({'sms_enabled': v}) : null,
              ),
            ),
          ]),
        ),
        if (!ready)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: InfoBanner(icon: Icons.info_outline, text: l.smsSetupSteps),
          ),
        if (status != null && (status.subscribers > 0 || status.sent7d > 0 || status.failed7d > 0))
          Padding(
            padding: const EdgeInsets.fromLTRB(70, 0, 16, 4),
            child: Text(
              [
                l.smsStats(status.subscribers, status.sent7d, status.failed7d),
                if (status.queued > 0) l.smsQueued(status.queued),
              ].join(' · '),
              style: const TextStyle(fontSize: 12, color: Bua.inkSubtle),
            ),
          ),
        if (status?.lastError != null && (status!.failed7d > 0 || status.queued > 0))
          Padding(
            padding: const EdgeInsets.fromLTRB(70, 0, 16, 8),
            child: Text(l.lastError(status.lastError!),
                maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Bua.danger)),
          ),
        const InsetDivider(indent: 70),
        _SettingRow(
          icon: Icons.key_outlined,
          title: l.apiKey,
          value: keySaved ? l.apiKeySaved : l.apiKeyMissing,
          onTap: () async {
            final v = await showFormDialog(context, title: l.apiKey, note: l.apiKeyNote, fields: [
              TextSpec('key', l.apiKey, required: true, secret: true),
              TextSpec('url', l.baseUrl, initial: status?.baseUrl, hint: l.baseUrlHint),
            ]);
            if (v == null || !context.mounted) return;
            final ok = await guarded(
              context,
              () => ref.read(repositoryProvider).setSmsSecret(apiKey: v['key'] as String?, baseUrl: v['url'] as String?),
            );
            if (ok) ref.invalidate(smsStatusProvider);
          },
        ),
        const InsetDivider(indent: 70),
        _SettingRow(
          icon: Icons.badge_outlined,
          title: l.senderId,
          value: settings.smsSenderId ?? l.apiKeyMissing,
          onTap: () async {
            final v = await showFormDialog(context, title: l.senderId, note: l.senderIdHint, fields: [
              TextSpec('id', l.senderId, initial: settings.smsSenderId, required: true),
            ]);
            if (v != null) await save({'sms_sender_id': v['id']});
          },
        ),
        const InsetDivider(indent: 70),
        _SettingRow(
          icon: Icons.alt_route,
          title: l.smsRoute,
          value: settings.smsChannel == 'dnd' ? l.routeDnd : l.routeGeneric,
          onTap: () async {
            final v = await showFormDialog(context, title: l.smsRoute, fields: [
              ChoiceSpec<String>('route', l.smsRoute,
                  options: {'generic': l.routeGeneric, 'dnd': l.routeDnd}, initial: settings.smsChannel),
            ]);
            if (v != null && v['route'] != null) await save({'sms_channel': v['route']});
          },
        ),
        if (ready && settings.smsEnabled) ...[
          const InsetDivider(indent: 70),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await guarded(context, () => ref.read(repositoryProvider).sendTestSms());
                if (!context.mounted) return;
                ref.invalidate(smsStatusProvider);
                if (ok) showSnack(context, l.testSmsSent);
              },
              icon: const Icon(Icons.send_to_mobile_outlined),
              label: Text(l.sendTestSms),
            ),
          ),
        ],
      ]),
    );
  }
}
