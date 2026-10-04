import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../models/social.dart' show Member;
import '../../services/app_update.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/home_shell.dart';
import 'sign_in_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider);
    final graph = ref.watch(graphProvider).value;
    final me = profile?.personId == null ? null : graph?[profile!.personId!];
    final wanted = profile?.requestedPersonId == null ? null : graph?[profile!.requestedPersonId!];
    final isAdmin = ref.watch(isAdminProvider);
    final attention = ref.watch(adminAttentionProvider);
    final openBlood = ref.watch(bloodRequestsProvider).value?.where((r) => r.open).length ?? 0;
    final myPending = ref
            .watch(requestsProvider(null))
            .value
            ?.where((r) => r.requestedBy == profile?.id && r.status == RequestStatus.pending)
            .length ??
        0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: EdgeInsets.fromLTRB(sidebarAlwaysOpen(context) ? 20 : 8, 10, 16, 8),
            child: Row(children: [
              const SidebarButton(),
              Expanded(child: Text(l.navMore, style: Theme.of(context).textTheme.titleLarge)),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
          Material(
            color: Bua.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: me == null ? () => findMeInTree(context, ref) : () => context.push('/person/${me.id}'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  if (me != null)
                    PersonAvatar(person: me, radius: 28)
                  else
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Bua.track,
                      child: Icon(Icons.person_search, color: Bua.unknownFg),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(me?.displayName ?? profile?.displayName ?? '',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text(
                        [
                          isAdmin ? l.roleAdmin : l.roleMember,
                          me != null
                              ? l.viewMyProfile
                              : wanted != null
                                  ? l.linkWaiting(wanted.displayName)
                                  : l.findMeInTree,
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 13,
                          color: me == null && wanted == null ? Bua.green : Bua.inkSubtle,
                          fontWeight: me == null && wanted == null ? FontWeight.w600 : null,
                        ),
                      ),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, color: Bua.inkSubtle),
                ]),
              ),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            Material(
              color: Bua.green,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/admin'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    const Icon(Icons.shield_outlined, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l.adminRequestsAccounts,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    if (attention > 0)
                      Container(
                        constraints: const BoxConstraints(minWidth: 24),
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Text('$attention',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bua.greenDark)),
                      )
                    else
                      const Icon(Icons.chevron_right, color: Colors.white),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                NavRow(
                  icon: Icons.insights_outlined,
                  title: l.metricsTitle,
                  onTap: () => context.push('/admin/metrics'),
                ),
                const InsetDivider(),
                NavRow(
                  icon: Icons.import_export,
                  title: l.dataTitle,
                  onTap: () => context.push('/admin/data'),
                ),
                const InsetDivider(),
                NavRow(
                  icon: Icons.rule,
                  title: l.checkTree,
                  onTap: () => context.push('/admin/tree-check'),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(l.family.toUpperCase(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Bua.inkMuted)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              NavRow(
                icon: Icons.photo_library_outlined,
                title: l.albums,
                onTap: () => context.push('/albums'),
              ),
              const InsetDivider(),
              NavRow(
                icon: Icons.cake_outlined,
                title: l.remindersTitle,
                onTap: () => context.push('/reminders'),
              ),
              const InsetDivider(),
              NavRow(
                icon: Icons.link,
                title: l.howRelated,
                onTap: () => context.push('/related'),
              ),
              const InsetDivider(),
              NavRow(
                icon: Icons.handshake_outlined,
                title: l.whoCanHelp,
                onTap: () => context.push('/help'),
              ),
              const InsetDivider(),
              NavRow(
                icon: Icons.volunteer_activism_outlined,
                title: l.welfareFund,
                onTap: () => context.push('/fund'),
              ),
              const InsetDivider(),
              NavRow(
                icon: Icons.bloodtype_outlined,
                iconColor: Bua.danger,
                title: l.bloodDonors,
                value: openBlood > 0 ? '$openBlood ${l.urgent.toLowerCase()}' : null,
                onTap: () => context.push('/blood'),
              ),
              const InsetDivider(),
              NavRow(
                icon: Icons.school_outlined,
                title: l.mentorsTitle,
                onTap: () => context.push('/mentors'),
              ),
              const InsetDivider(),
              NavRow(
                icon: Icons.how_to_vote_outlined,
                title: l.pollsTitle,
                onTap: () => context.push('/polls'),
              ),
              const InsetDivider(),
              NavRow(
                icon: Icons.mic_none,
                title: l.storiesTitle,
                onTap: () => context.push('/stories'),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(l.account.toUpperCase(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Bua.inkMuted)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              NavRow(
                icon: Icons.settings_outlined,
                title: l.settingsScreen,
                onTap: () => context.push('/settings'),
              ),
              const InsetDivider(),
              NavRow(
                icon: Icons.android,
                title: l.getTheApp,
                value: ref.watch(updateAvailableProvider) != null ? l.updateAvailableTitle : null,
                onTap: () => context.push('/get-app'),
              ),
              const InsetDivider(),
              if (me != null) ...[
                NavRow(
                  icon: Icons.edit_outlined,
                  title: l.editMyDetails,
                  onTap: () => context.push('/me/edit'),
                ),
                const InsetDivider(),
              ],
              NavRow(
                icon: Icons.notifications_none,
                title: l.notificationsSms,
                value: profile?.smsOptIn ?? false ? 'SMS ✓' : null,
                onTap: () => context.push('/settings/notifications'),
              ),
              const InsetDivider(),
              NavRow(
                icon: Icons.fact_check_outlined,
                title: l.myRequests,
                value: myPending > 0 ? l.pendingCount(myPending) : null,
                onTap: () => context.push('/my-requests'),
              ),
              const InsetDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  const Icon(Icons.translate, size: 20, color: Bua.green),
                  const SizedBox(width: 14),
                  Expanded(child: Text(l.language, style: const TextStyle(fontSize: 15))),
                  const LanguageToggle(),
                ]),
              ),
              const InsetDivider(),
              NavRow(
                icon: Icons.logout,
                title: l.signOut,
                color: Bua.danger,
                iconColor: Bua.danger,
                onTap: () => ref.read(authProvider).signOut(),
              ),
            ]),
          ),
          ]),
          ),
        ]),
      ),
    );
  }
}

/// Links the signed-in account to a person in the tree: admins link
/// themselves at once; members send it to the admins to confirm.
Future<void> findMeInTree(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final graph = ref.read(graphProvider).value;
  final profile = ref.read(profileProvider);
  if (graph == null || profile == null) return;
  final taken = {for (final m in ref.read(membersProvider).value?.values ?? const <Member>[]) ?m.personId};
  final person = await pickPerson(context, graph, exclude: taken);
  if (person == null || !context.mounted) return;
  final repo = ref.read(repositoryProvider);
  final ok = await guarded(
    context,
    () => profile.isAdmin
        ? repo.adminUpdateAccount(profile.id, personId: person.id)
        : repo.updateMyProfile(requestedPersonId: person.id),
  );
  if (!ok || !context.mounted) return;
  await ref.read(authProvider).refresh();
  if (context.mounted) showSnack(context, profile.isAdmin ? l.linkedNow : l.thisIsMeSent);
}
