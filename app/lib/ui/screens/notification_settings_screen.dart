import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/push_widgets.dart';

/// "0803 123 4567" → "2348031234567"; null when it can't be a phone number.
/// Mirrors private.normalize_phone in the database.
String? normalizePhone(String input) {
  final d = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (RegExp(r'^0[789][01][0-9]{8}$').hasMatch(d)) return '234${d.substring(1)}';
  if (RegExp(r'^[789][01][0-9]{8}$').hasMatch(d)) return '234$d';
  if (RegExp(r'^[0-9]{10,15}$').hasMatch(d)) return d;
  return null;
}

/// "2348031234567" → "+234 803 123 4567".
String formatPhone(String phone) {
  if (phone.length == 13 && phone.startsWith('234')) {
    return '+234 ${phone.substring(3, 6)} ${phone.substring(6, 9)} ${phone.substring(9)}';
  }
  return '+$phone';
}

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  late final _phone = TextEditingController(
    text: ref.read(profileProvider)?.phone == null ? '' : formatPhone(ref.read(profileProvider)!.phone!),
  );
  String? _phoneError;
  bool _saving = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save({bool? optIn, bool? birthdays, bool? events}) async {
    final l = context.l10n;
    final repo = ref.read(repositoryProvider);
    final text = _phone.text.trim();
    final phone = text.isEmpty ? null : normalizePhone(text);
    if (text.isNotEmpty && phone == null) {
      setState(() => _phoneError = l.phoneInvalid);
      return;
    }
    if ((optIn ?? false) && phone == null) {
      setState(() => _phoneError = l.phoneInvalid);
      return;
    }
    setState(() {
      _phoneError = null;
      _saving = true;
    });
    final ok = await guarded(context, () async {
      if (phone == null) {
        await repo.clearPhone();
      } else {
        await repo.updateSmsPreferences(phone: phone, optIn: optIn, birthdays: birthdays, events: events);
      }
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      await ref.read(authProvider).refresh();
      if (mounted && phone != null) _phone.text = formatPhone(phone);
      if (mounted) showSnack(context, l.saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider);
    final smsOn = ref.watch(settingsProvider).value?.smsEnabled ?? false;
    final optIn = profile?.smsOptIn ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        title: Text(l.notificationsSms, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        InfoBanner(icon: Icons.notifications_none, text: l.inAppNote, tone: BannerTone.green),
        const SizedBox(height: 12),
        SectionCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), children: const [
          PushDeviceToggle(),
        ]),
        const SizedBox(height: 12),
        if (!smsOn) ...[
          InfoBanner(icon: Icons.sms_outlined, text: l.smsOffNote),
          const SizedBox(height: 12),
        ],
        SectionCard(title: 'SMS', padding: const EdgeInsets.fromLTRB(0, 6, 0, 8), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: LabeledField(
              label: l.phoneNumber,
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: InputDecoration(
                  hintText: l.phoneHint,
                  errorText: _phoneError,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  suffixIcon: TextButton(onPressed: _saving ? null : () => _save(), child: Text(l.save)),
                ),
                onSubmitted: (_) => _save(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ToggleRow(
              title: l.smsOptIn,
              subtitle: l.smsOptInSub,
              value: optIn,
              onChanged: _saving ? null : (v) => _save(optIn: v),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ToggleRow(
              title: l.smsBirthdays,
              subtitle: l.smsBirthdaysSub,
              value: profile?.smsBirthdays ?? true,
              onChanged: !optIn || _saving ? null : (v) => _save(birthdays: v),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ToggleRow(
              title: l.smsEvents,
              subtitle: l.smsEventsSub,
              value: profile?.smsEvents ?? true,
              onChanged: !optIn || _saving ? null : (v) => _save(events: v),
            ),
          ),
        ]),
      ]),
    );
  }
}
