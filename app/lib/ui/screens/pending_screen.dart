import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';
import 'sign_in_screen.dart';

/// Shown while an account waits for admin approval (or is suspended).
/// Pending users cannot see the tree, so they describe who they are instead.
class PendingScreen extends ConsumerStatefulWidget {
  const PendingScreen({super.key});

  @override
  ConsumerState<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends ConsumerState<PendingScreen> {
  late final _note = TextEditingController(text: ref.read(profileProvider)?.claimNote ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final l = context.l10n;
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).updateMyProfile(claimNote: _note.text.trim()),
    );
    if (ok && mounted) showSnack(context, l.saved);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final auth = ref.watch(authProvider);
    final suspended = auth.profile?.status == AccountStatus.suspended;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(actions: [
        TextButton(onPressed: auth.signOut, child: Text(l.signOut)),
      ]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(suspended ? Icons.block : Icons.hourglass_top, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(suspended ? l.suspendedTitle : l.pendingTitle,
                    textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(suspended ? l.suspendedBody : l.pendingBody, textAlign: TextAlign.center),
                if (!suspended) ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: _note,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: l.claimNoteLabel, hintText: l.claimNoteHint),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _busy ? null : _save, child: Text(l.save)),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: auth.refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(l.checkAgain),
                ),
                const SizedBox(height: 24),
                const Center(child: LanguageToggle()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
