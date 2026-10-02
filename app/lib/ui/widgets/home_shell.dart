import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../state/providers.dart';

/// Bottom navigation (phones) or side rail (tablets / web). Branch indexes:
/// 0 tree, 1 members, 2 admin, 3 more. The admin tab is hidden for members.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final isAdmin = ref.watch(isAdminProvider);
    final pendingCount = isAdmin
        ? (ref.watch(requestsProvider(RequestStatus.pending)).value?.length ?? 0)
        : 0;

    final branches = [0, 1, if (isAdmin) 2, 3];
    final items = [
      (Icons.account_tree_outlined, Icons.account_tree, l.navTree),
      (Icons.people_outline, Icons.people, l.navMembers),
      if (isAdmin) (Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, l.navAdmin),
      (Icons.menu, Icons.menu, l.navMore),
    ];
    final selected = branches.indexOf(shell.currentIndex).clamp(0, branches.length - 1);
    void go(int i) => shell.goBranch(branches[i], initialLocation: branches[i] == shell.currentIndex);

    Widget icon(IconData data, int i) {
      final badge = branches[i] == 2 && pendingCount > 0;
      return badge ? Badge(label: Text('$pendingCount'), child: Icon(data)) : Icon(data);
    }

    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (wide) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: selected,
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
          const VerticalDivider(width: 1),
          Expanded(child: shell),
        ]),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
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
    );
  }
}
