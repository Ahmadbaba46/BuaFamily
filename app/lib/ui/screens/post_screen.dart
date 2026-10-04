import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';

/// One moment with its comments. Opened from notifications, so it always
/// loads fresh.
class PostScreen extends ConsumerWidget {
  const PostScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final post = ref.watch(postProvider(postId));
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
        title: Text(l.post, style: Theme.of(context).textTheme.titleMedium),
      ),
      body: AsyncBody(
        value: post,
        onRetry: () => ref.invalidate(postProvider(postId)),
        builder: (p) {
          if (p == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.postGone, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkSubtle)),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(commentsProvider(Target.post(postId)));
              ref.invalidate(postProvider(postId));
              await ref.read(postProvider(postId).future);
            },
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
              PostCard(post: p),
              const SizedBox(height: 16),
              GroupHeading(l.comments),
              const SizedBox(height: 8),
              CommentThread(target: Target.post(postId)),
            ]),
          );
        },
      ),
    );
  }
}
