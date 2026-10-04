import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'app_sidebar.dart';
import 'claim_card.dart' show hasOpenClaim;

/// Number of things waiting for an admin (requests + new accounts); 0 for members.
final adminAttentionProvider = Provider<int>((ref) {
  if (!ref.watch(isAdminProvider)) return 0;
  final requests = ref.watch(requestsProvider(RequestStatus.pending)).value?.length ?? 0;
  final accounts =
      ref.watch(profilesProvider).value?.where((p) => p.status == AccountStatus.pending || hasOpenClaim(p)).length ?? 0;
  return requests + accounts;
});

/// Bottom navigation and a sidebar drawer (phones), a side rail (tablets), or
/// the full sidebar always open (wide screens; see the app frame).
/// Branches: 0 home, 1 tree, 2 members, 3 events, 4 more.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final attention = ref.watch(adminAttentionProvider);

    final items = [
      (Icons.home_outlined, Icons.home, l.navHome),
      (Icons.account_tree_outlined, Icons.account_tree, l.navTree),
      (Icons.people_outline, Icons.people, l.navMembers),
      (Icons.event_outlined, Icons.event, l.navEvents),
      (Icons.menu, Icons.menu, l.navMore),
    ];
    void go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

    Widget icon(IconData data, int i) => i == 4 && attention > 0
        ? Badge(label: Text('$attention'), child: Icon(data))
        : Icon(data);

    final drawer = Drawer(
      width: 300,
      child: AppSidebar(
        router: GoRouter.of(context),
        onDone: () => sidebarScaffoldKey.currentState?.closeDrawer(),
      ),
    );

    // The sidebar is already beside every page.
    if (sidebarAlwaysOpen(context)) return Scaffold(key: sidebarScaffoldKey, body: shell);

    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (wide) {
      return Scaffold(
        key: sidebarScaffoldKey,
        drawer: drawer,
        body: Row(children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: go,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (var i = 0; i < items.length; i++)
                NavigationRailDestination(
                  icon: icon(items[i].$1, i),
                  selectedIcon: icon(items[i].$2, i),
                  label: Text(items[i].$3),
                ),
            ],
          ),
          VerticalDivider(width: 1, color: Bua.line),
          Expanded(child: shell),
        ]),
      );
    }
    return Scaffold(
      key: sidebarScaffoldKey,
      drawer: drawer,
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Bua.line))),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: go,
          destinations: [
            for (var i = 0; i < items.length; i++)
              NavigationDestination(
                icon: icon(items[i].$1, i),
                selectedIcon: icon(items[i].$2, i),
                label: items[i].$3,
              ),
          ],
        ),
      ),
    );
  }
}
