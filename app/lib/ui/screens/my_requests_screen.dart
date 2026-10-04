import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/request_card.dart';

/// Everything the signed-in user has proposed, with its review status.
class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider);
    final graph = ref.watch(graphProvider).value;
    final requests = ref.watch(requestsProvider(null));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        title: Text(l.myRequests, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(requestsProvider(null).future),
        child: AsyncBody(
          value: requests,
          onRetry: () => ref.invalidate(requestsProvider),
          builder: (all) {
            final mine = all.where((r) => r.requestedBy == profile?.id).toList();
            return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(l.myRequestsHelp, style: TextStyle(fontSize: 13, height: 1.45, color: Bua.inkMuted)),
              ),
              if (mine.isEmpty || graph == null)
                Padding(padding: const EdgeInsets.only(top: 60), child: Center(child: Text(l.noRequests)))
              else
                for (final r in mine) ...[
                  RequestCard(
                    request: r,
                    graph: graph,
                    showStatus: true,
                    actions: [
                      if (r.status == RequestStatus.pending)
                        OutlinedButton(
                          onPressed: () async {
                            final ok = await guarded(context, () => ref.read(repositoryProvider).withdrawRequest(r.id));
                            if (ok) ref.invalidate(requestsProvider);
                          },
                          child: Text(l.withdraw),
                        ),
                      if (r.status == RequestStatus.approved && r.resultPersonId != null)
                        TextButton(
                          onPressed: () => context.go('/tree?focus=${r.resultPersonId}'),
                          child: Text(l.seeInTree),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
            ]);
          },
        ),
      ),
    );
  }
}
