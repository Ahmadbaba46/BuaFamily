import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import '../widgets/request_card.dart';
import 'sign_in_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider);
    final graph = ref.watch(graphProvider).value;
    final me = profile?.personId == null ? null : graph?[profile!.personId!];
    final isAdmin = ref.watch(isAdminProvider);
    // Admins review everything on the Admin tab; here everyone sees their own.
    final myRequests = ref
        .watch(requestsProvider(null))
        .value
        ?.where((r) => r.requestedBy == profile?.id)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.navMore)),
      body: ListView(children: [
        if (me != null)
          PersonTile(
            person: me,
            subtitle: l.myProfile,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/person/${me.id}'),
          )
        else
          ListTile(
            leading: const Icon(Icons.person_search),
            title: Text(profile?.displayName ?? ''),
            subtitle: Text(l.notLinked),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.translate),
          title: Text(l.language),
          trailing: const LanguageToggle(),
        ),
        SectionHeader(l.myRequests),
        if (myRequests == null)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
        else if (myRequests.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l.noRequests))
        else if (graph != null)
          for (final r in myRequests.take(30))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: RequestCard(
                request: r,
                graph: graph,
                actions: [
                  if (r.status == RequestStatus.pending && !isAdmin)
                    TextButton(
                      onPressed: () async {
                        final ok = await guarded(context, () => ref.read(repositoryProvider).withdrawRequest(r.id));
                        if (ok) ref.invalidate(requestsProvider);
                      },
                      child: Text(l.withdraw),
                    ),
                ],
              ),
            ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l.signOut),
          onTap: () => ref.read(authProvider).signOut(),
        ),
      ]),
    );
  }
}
