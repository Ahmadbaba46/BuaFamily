import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../services/push.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/push_widgets.dart';
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
    final profile = auth.profile;
    final suspended = profile?.status == AccountStatus.suspended;
    final firstName = (profile?.displayName ?? '').split(' ').first;

    return Scaffold(
      appBar: AppBar(actions: [
        TextButton(onPressed: auth.signOut, child: Text(l.signOut)),
        const SizedBox(width: 8),
      ]),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: suspended ? Bua.dangerTint : Bua.greenTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(suspended ? Icons.block : Icons.hourglass_top_rounded,
                        size: 40, color: suspended ? Bua.danger : Bua.green),
                  ),
                ),
                const SizedBox(height: 14),
                Text(suspended ? l.suspendedTitle : l.pendingTitle,
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  suspended ? l.suspendedBody : l.pendingGreeting(firstName),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5, color: Bua.inkMuted),
                ),
                if (!suspended) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(l.claimNoteLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _note,
                        maxLines: 3,
                        decoration: InputDecoration(hintText: l.claimNoteHint),
                      ),
                      const SizedBox(height: 10),
                      Text(l.claimHelp, style: TextStyle(fontSize: 13, color: Bua.inkSubtle)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _busy ? null : _save, child: Text(l.save)),
                    ]),
                  ),
                  if (ref.watch(pushPlatformProvider).available &&
                      (ref.watch(settingsProvider).value?.pushEnabled ?? false)) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
                      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const PushDeviceToggle(),
                        const SizedBox(height: 4),
                        Text(l.pendingPushHint, style: TextStyle(fontSize: 13, color: Bua.inkSubtle)),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _Step(state: _StepState.done, label: l.stepCreated),
                  const _StepLine(),
                  _Step(state: _StepState.current, label: l.stepReview),
                  const _StepLine(),
                  _Step(state: _StepState.todo, label: l.stepExplore),
                ],
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Bua.green)),
                  onPressed: auth.refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(l.checkAgain),
                ),
                const SizedBox(height: 20),
                const Center(child: LanguageToggle()),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

enum _StepState { done, current, todo }

class _Step extends StatelessWidget {
  const _Step({required this.state, required this.label});

  final _StepState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dot = switch (state) {
      _StepState.done => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: Bua.green, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 16, color: Colors.white),
        ),
      _StepState.current => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Bua.green, width: 2)),
          child: Center(
            child: Container(
                width: 10, height: 10, decoration: BoxDecoration(color: Bua.green, shape: BoxShape.circle)),
          ),
        ),
      _StepState.todo => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Bua.lineStrong, width: 2)),
        ),
    };
    return Row(children: [
      dot,
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: state == _StepState.current ? FontWeight.w600 : FontWeight.w400,
            color: state == _StepState.todo ? Bua.inkSubtle : Bua.ink,
          ),
        ),
      ),
    ]);
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(width: 2, height: 14, margin: const EdgeInsets.only(left: 13), color: Bua.lineStrong),
      );
}
