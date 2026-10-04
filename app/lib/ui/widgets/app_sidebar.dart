import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../models/fund.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'common.dart';
import 'home_shell.dart' show adminAttentionProvider;

/// Opens the sidebar (phones and tablets; on wide screens it is always shown).
final sidebarScaffoldKey = GlobalKey<ScaffoldState>();

/// Wide enough to keep the sidebar open next to every page.
bool sidebarAlwaysOpen(BuildContext context) => MediaQuery.sizeOf(context).width >= 1000;

/// The ☰ button at the top left of the main pages.
class SidebarButton extends StatelessWidget {
  const SidebarButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (sidebarAlwaysOpen(context)) return const SizedBox.shrink();
    return IconButton(
      tooltip: context.l10n.openMenu,
      icon: const Icon(Icons.menu),
      onPressed: () => sidebarScaffoldKey.currentState?.openDrawer(),
    );
  }
}

/// Every part of the app in one list, grouped, each with what is waiting
/// there (upcoming events, open requests, unread notifications...).
class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key, required this.router, this.onDone});

  final GoRouter router;

  /// Called after choosing a page (closes the drawer).
  final VoidCallback? onDone;

  static const _tabs = {'/home', '/tree', '/members', '/events', '/more'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final graph = ref.watch(graphProvider).value;
    final me = profile?.personId == null ? null : graph?[profile!.personId!];
    final now = DateTime.now();

    int? count(int? n) => n == null || n == 0 ? null : n;
    final people = count(graph?.persons.length);
    final upcoming = count(ref.watch(eventsProvider).value?.where((e) => e.isUpcoming(now)).length);
    final albums = count(ref.watch(albumsProvider).value?.length);
    final stories = count(ref.watch(storiesProvider).value?.length);
    final blood = count(ref.watch(bloodRequestsProvider).value?.where((r) => r.open).length);
    final causes = count(ref.watch(fundCausesProvider).value?.where((c) => c.status == CauseStatus.open).length);
    final polls =
        count(ref.watch(pollsProvider).value?.where((p) => p.isOpen(now) && p.myOptionId == null).length);
    final unread = count(ref.watch(unreadCountProvider));
    final myPending = count(ref
        .watch(requestsProvider(null))
        .value
        ?.where((r) => r.requestedBy == profile?.id && r.status == RequestStatus.pending)
        .length);
    final attention = count(ref.watch(adminAttentionProvider));

    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final here = router.routerDelegate.currentConfiguration.uri.path;

        void open(String path) {
          onDone?.call();
          _tabs.contains(path) ? router.go(path) : router.push(path);
        }

        Widget item(IconData icon, String label, String path, {int? badge, bool urgent = false}) {
          final selected = here == path || (path != '/home' && here.startsWith('$path/'));
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
            child: Material(
              color: selected ? Bua.greenTint : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => open(path),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    Icon(icon, size: 20, color: selected ? Bua.greenDark : Bua.inkMuted),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? Bua.greenDark : Bua.ink,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        constraints: const BoxConstraints(minWidth: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: urgent ? Bua.danger : (selected ? Bua.green : Bua.track),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badge',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: urgent || selected ? Colors.white : Bua.inkMuted,
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          );
        }

        Widget heading(String text) => Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 16, 6),
              child: Text(text.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Bua.inkSubtle)),
            );

        return Material(
          color: Bua.surface,
          child: SafeArea(
            right: false,
            child: ListView(padding: const EdgeInsets.only(bottom: 16), children: [
              // Who you are.
              InkWell(
                onTap: () => open(me == null ? '/more' : '/person/${me.id}'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                  child: Row(children: [
                    if (me != null)
                      PersonAvatar(person: me, radius: 22)
                    else
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Bua.track,
                        child: Icon(Icons.person_search, color: Bua.unknownFg),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(me?.displayName ?? profile?.displayName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                        Text(me == null ? l.findMeInTree : l.viewMyProfile,
                            style: const TextStyle(fontSize: 12.5, color: Bua.green, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                ),
              ),
              const Divider(height: 1, color: Bua.line),
              heading(l.family),
              item(Icons.home_outlined, l.navHome, '/home'),
              item(Icons.account_tree_outlined, l.navTree, '/tree'),
              item(Icons.people_outline, l.navMembers, '/members', badge: people),
              item(Icons.event_outlined, l.navEvents, '/events', badge: upcoming),
              item(Icons.photo_library_outlined, l.albums, '/albums', badge: albums),
              item(Icons.mic_none, l.storiesTitle, '/stories', badge: stories),
              item(Icons.alt_route, l.howRelated, '/related'),
              heading(l.helpEachOther),
              item(Icons.handshake_outlined, l.whoCanHelp, '/help'),
              item(Icons.bloodtype_outlined, l.bloodDonors, '/blood', badge: blood, urgent: true),
              item(Icons.volunteer_activism_outlined, l.welfareFund, '/fund', badge: causes),
              item(Icons.school_outlined, l.mentorsTitle, '/mentors'),
              item(Icons.how_to_vote_outlined, l.pollsTitle, '/polls', badge: polls),
              heading(l.account),
              item(Icons.notifications_none, l.notifications, '/notifications', badge: unread),
              item(Icons.cake_outlined, l.remindersTitle, '/reminders'),
              item(Icons.pending_actions_outlined, l.myRequests, '/my-requests', badge: myPending),
              item(Icons.settings_outlined, l.settingsScreen, '/settings'),
              if (isAdmin) ...[
                heading(l.navAdmin),
                item(Icons.admin_panel_settings_outlined, l.navAdmin, '/admin', badge: attention, urgent: true),
                item(Icons.insights_outlined, l.metricsTitle, '/admin/metrics'),
                item(Icons.rule, l.checkTree, '/admin/tree-check'),
                item(Icons.import_export, l.dataTitle, '/admin/data'),
              ],
            ]),
          ),
        );
      },
    );
  }
}
