import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../../services/push.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'bua.dart';
import 'common.dart';

/// Turns notifications on for this device and says how it went.
Future<void> turnOnPush(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final result = await ref.read(pushControllerProvider.notifier).enable();
  if (!context.mounted) return;
  switch (result) {
    case PushResult.on:
      showSnack(context, l.pushTurnedOn);
    case PushResult.blocked:
      showSnack(context, l.pushBlocked);
    case PushResult.unavailable:
      showSnack(context, l.pushUnavailable);
    case PushResult.failed:
      showSnack(context, l.pushFailed);
    case PushResult.off:
      break;
  }
}

/// The on/off switch for notifications on this phone or browser.
class PushDeviceToggle extends ConsumerWidget {
  const PushDeviceToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final available = ref.watch(pushPlatformProvider).available;
    final serverOn = ref.watch(settingsProvider).value?.pushEnabled ?? false;
    final push = ref.watch(pushControllerProvider);

    final subtitle = !available
        ? l.pushUnavailable
        : !serverOn
            ? l.pushNotSetUp
            : push.permission == PushPermission.denied && !push.on
                ? l.pushBlocked
                : push.on
                    ? l.pushOnSub
                    : l.pushOffSub;

    return ToggleRow(
      title: kIsWeb ? l.pushInThisBrowser : l.pushOnThisPhone,
      subtitle: subtitle,
      value: push.on,
      onChanged: !available || !serverOn || push.busy
          ? null
          : (v) => v ? turnOnPush(context, ref) : ref.read(pushControllerProvider.notifier).disable(),
    );
  }
}

/// Invites members to turn on notifications, once, at the top of the inbox.
class PushPrompt extends ConsumerStatefulWidget {
  const PushPrompt({super.key});

  @override
  ConsumerState<PushPrompt> createState() => _PushPromptState();
}

class _PushPromptState extends ConsumerState<PushPrompt> {
  static const _key = 'push_prompt_dismissed';
  bool _dismissed = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance()
        .then((p) => p.getBool(_key) ?? false)
        .catchError((_) => false)
        .then((d) => mounted ? setState(() => _dismissed = d) : null);
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final push = ref.watch(pushControllerProvider);
    final show = !_dismissed &&
        ref.watch(pushPlatformProvider).available &&
        (ref.watch(settingsProvider).value?.pushEnabled ?? false) &&
        !push.on &&
        push.permission != PushPermission.denied;
    if (!show) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
        decoration: BoxDecoration(
          color: Bua.greenTint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Bua.greenIndicator),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.notifications_active_outlined, color: Bua.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.pushPromptTitle,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Bua.greenDark)),
                const SizedBox(height: 2),
                Text(l.pushPromptBody, style: TextStyle(fontSize: 13, height: 1.4, color: Bua.greenDark)),
              ]),
            ),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: _dismiss, child: Text(l.notNow)),
            FilledButton(onPressed: push.busy ? null : () => turnOnPush(context, ref), child: Text(l.turnOn)),
          ]),
        ]),
      ),
    );
  }
}
