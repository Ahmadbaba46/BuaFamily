import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../models/fund.dart' show naira;
import '../../models/hijri.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/claim_card.dart' show hasOpenClaim;
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';
import '../widgets/hijri.dart';
import '../widgets/request_card.dart';
import 'get_app_screen.dart';
import 'users_screen.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key, this.initialTab = 0, this.usersFilter = UserFilter.all});

  /// 0 requests, 1 accounts, 2 settings.
  final int initialTab;

  /// Which accounts to show first (e.g. claims from a notification).
  final UserFilter usersFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final requests = ref.watch(requestsProvider(RequestStatus.pending)).value?.length ?? 0;
    final accounts =
        ref.watch(profilesProvider).value?.where((p) => p.status == AccountStatus.pending || hasOpenClaim(p)).length ?? 0;

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
          actions: [
            IconButton(
              tooltip: l.activityTitle,
              icon: const Icon(Icons.sensors),
              onPressed: () => context.push('/admin/activity'),
            ),
            IconButton(
              tooltip: l.metricsTitle,
              icon: const Icon(Icons.insights_outlined),
              onPressed: () => context.push('/admin/metrics'),
            ),
          ],
          bottom: TabBar(tabs: [
            tab(l.requestsTitle, requests, true),
            tab(l.accountsTitle, accounts, true),
            Tab(text: l.settingsTitle),
          ]),
        ),
        body: TabBarView(children: [const _RequestsTab(), UsersView(initialFilter: usersFilter), const _SettingsTab()]),
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
            Icon(Icons.check, size: 16, color: Bua.green),
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
                IconTile(Icons.person_add_alt_1, background: Bua.greenTint),
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
                      style: TextStyle(fontSize: 13, height: 1.5, color: Bua.inkMuted)),
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
                        icon: Icon(Icons.clear, color: Bua.inkSubtle),
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
          _PushCard(settings: s, save: save),
          const SizedBox(height: 12),
          _HijriCard(settings: s, save: save),
          const SizedBox(height: 12),
          AdminUpdatesCard(settings: s, save: save),
          const SizedBox(height: 12),
          AndroidReleaseCard(pickApks: () async {
            final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['apk']);
            return [for (final f in files) (f.name, await f.readAsBytes())];
          }),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
            child: _SettingRow(
              icon: Icons.info_outline,
              title: l.aboutSettings,
              value: [s.developerName, s.developerCompany].whereType<String>().where((v) => v.trim().isNotEmpty).join(' · '),
              onTap: () async {
                final v = await showFormDialog(context, title: l.aboutSettings, fields: [
                  TextSpec('name', l.developerName, initial: s.developerName),
                  TextSpec('company', l.developerCompany, initial: s.developerCompany),
                  TextSpec('phone', l.phone, initial: s.developerPhone, hint: l.phoneHint),
                  TextSpec('email', l.email, initial: s.developerEmail),
                  TextSpec('website', l.developerWebsite, initial: s.developerWebsite),
                ]);
                if (v == null) return;
                String? text(String k) {
                  final t = (v[k] as String? ?? '').trim();
                  return t.isEmpty ? null : t;
                }
                final site = text('website');
                await save({
                  'developer_name': text('name'),
                  'developer_company': text('company'),
                  'developer_phone': text('phone'),
                  'developer_email': text('email'),
                  'developer_website': site == null || site.startsWith(RegExp('https?://')) ? site : 'https://$site',
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.lock_outline, size: 20, color: Bua.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${l.privacyTitle} ', style: TextStyle(fontWeight: FontWeight.w600, color: Bua.ink)),
                    TextSpan(text: l.privacyNote),
                  ]),
                  style: TextStyle(fontSize: 13, height: 1.5, color: Bua.inkMuted),
                ),
              ),
            ]),
          ),
        ]);
      },
    );
  }
}

/// The Islamic calendar: match the moon sighting, and the family greetings.
class _HijriCard extends StatelessWidget {
  const _HijriCard({required this.settings, required this.save});

  final AppSettings settings;
  final Future<void> Function(Map<String, dynamic>) save;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final offset = settings.hijriOffset;
    final today = HijriDate.fromDate(DateTime.now(), offset: offset);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IconTile(Icons.nightlight_round, background: Bua.greenTint),
          const SizedBox(width: 14),
          Expanded(child: Text(l.hijriSettingsTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 12),
        Text(l.hijriTodayIs(l.hijriDate(today)), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text(l.hijriAdjust, style: const TextStyle(fontSize: 14))),
          IconButton.outlined(
            tooltip: '−1',
            onPressed: offset <= -2 ? null : () => save({'hijri_offset': offset - 1}),
            icon: const Icon(Icons.remove, size: 18),
          ),
          SizedBox(
            width: 92,
            child: Text(
              offset == 0 ? l.hijriNoAdjust : l.hijriDaysSigned(offset > 0 ? '+' : '−', offset.abs()),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton.outlined(
            tooltip: '+1',
            onPressed: offset >= 2 ? null : () => save({'hijri_offset': offset + 1}),
            icon: const Icon(Icons.add, size: 18),
          ),
        ]),
        Text(l.hijriAdjustHint, style: TextStyle(fontSize: 12, height: 1.45, color: Bua.inkMuted)),
        Divider(height: 24, color: Bua.line),
        ToggleRow(
          title: l.islamicGreetingsToggle,
          value: settings.islamicGreetings,
          onChanged: (v) => save({'islamic_greetings': v}),
        ),
      ]),
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
              Text(value, style: TextStyle(fontSize: 13, color: Bua.inkSubtle)),
            ]),
          ),
          trailing ?? Icon(Icons.chevron_right, color: Bua.inkSubtle),
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
            IconTile(Icons.sms_outlined, background: Bua.greenTint),
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
              style: TextStyle(fontSize: 12, color: Bua.inkSubtle),
            ),
          ),
        if (status?.lastError != null && (status!.failed7d > 0 || status.queued > 0))
          Padding(
            padding: const EdgeInsets.fromLTRB(70, 0, 16, 8),
            child: Text(l.lastError(status.lastError!),
                maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Bua.danger)),
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

class _PushCard extends ConsumerWidget {
  const _PushCard({required this.settings, required this.save});

  final AppSettings settings;
  final Future<void> Function(Map<String, dynamic>) save;

  Future<void> _chooseKey(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
    if (f == null || !context.mounted) return;
    final text = utf8.decode(await f.readAsBytes(), allowMalformed: true);
    if (!context.mounted) return;
    final ok = await guarded(context, () => ref.read(repositoryProvider).setPush(serviceAccount: text));
    if (!ok) return;
    ref.invalidate(pushStatusProvider);
    ref.invalidate(settingsProvider);
    if (context.mounted) showSnack(context, l.saved);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(pushStatusProvider).value;
    final project = status?['project_id'] as String?;
    final devices = (status?['devices'] as num?)?.toInt() ?? 0;
    final members = (status?['members'] as num?)?.toInt() ?? 0;
    final sent = (status?['sent_7d'] as num?)?.toInt() ?? 0;
    final received = (status?['received_7d'] as num?)?.toInt() ?? 0;
    final lastError = status?['last_error'] as String?;
    final lastErrorAt = DateTime.tryParse(status?['last_error_at'] as String? ?? '');
    final recentError = lastError != null && lastErrorAt != null &&
        DateTime.now().difference(lastErrorAt) < const Duration(days: 2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            IconTile(Icons.notifications_active_outlined, background: Bua.greenTint),
            const SizedBox(width: 14),
            Expanded(
              child: ToggleRow(
                title: l.pushAdminTitle,
                subtitle: l.pushAdminSub,
                value: settings.pushEnabled,
                onChanged: project != null || settings.pushEnabled ? (v) => save({'push_enabled': v}) : null,
              ),
            ),
          ]),
        ),
        if (project == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: InfoBanner(icon: Icons.info_outline, text: l.pushSetupSteps),
          ),
        if (project != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(70, 0, 16, 4),
            child: Text(l.pushStats(members, devices, sent, received), style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
          ),
        if (recentError)
          Padding(
            padding: const EdgeInsets.fromLTRB(70, 0, 16, 8),
            child: Text(l.lastError(lastError),
                maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Bua.danger)),
          ),
        const InsetDivider(indent: 70),
        _SettingRow(
          icon: Icons.key_outlined,
          title: l.firebaseKey,
          value: project == null ? l.chooseKeyFile : l.firebaseKeySaved(project),
          onTap: () => _chooseKey(context, ref),
        ),
        if (project != null && settings.pushEnabled) ...[
          const InsetDivider(indent: 70),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await guarded(context, () => ref.read(repositoryProvider).sendTestPush());
                if (!context.mounted) return;
                ref.invalidate(pushStatusProvider);
                if (ok) showSnack(context, l.testPushSent);
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(l.sendTestPush),
            ),
          ),
        ],
      ]),
    );
  }
}

/// The Monday summary for admins, and the fund level that sets off an alert.
class AdminUpdatesCard extends StatelessWidget {
  const AdminUpdatesCard({super.key, required this.settings, required this.save});

  final AppSettings settings;
  final Future<void> Function(Map<String, dynamic>) save;

  Future<void> _editThreshold(BuildContext context) async {
    final l = context.l10n;
    final r = await showFormDialog(context, title: l.fundAlertBelow, note: l.fundAlertHint, fields: [
      TextSpec('amount', l.amountNaira, initial: settings.fundAlertBelow?.round(), number: true, hint: l.offLabel),
    ]);
    if (r == null) return;
    await save({'fund_alert_below': r['amount']});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final below = settings.fundAlertBelow;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IconTile(Icons.insights_outlined, background: Bua.greenTint),
          const SizedBox(width: 14),
          Expanded(child: Text(l.adminUpdatesTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 8),
        ToggleRow(
          title: l.weeklySummaryToggle,
          subtitle: l.weeklySummaryHint,
          value: settings.weeklySummary,
          onChanged: (v) => save({'weekly_summary': v}),
        ),
        Divider(height: 20, color: Bua.line),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _editThreshold(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(child: Text(l.fundAlertBelow, style: const TextStyle(fontSize: 15))),
              Text(below == null ? l.offLabel : naira(below),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Bua.green)),
              const SizedBox(width: 6),
              Icon(Icons.edit_outlined, size: 18, color: Bua.inkSubtle),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Text(l.alertsAlwaysOn, style: TextStyle(fontSize: 12, height: 1.45, color: Bua.inkMuted)),
      ]),
    );
  }
}
