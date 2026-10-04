import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import 'notification_settings_screen.dart' show formatPhone, normalizePhone;

/// Forgot the password: a code by SMS to the phone on the profile, then a
/// new password, then signed straight in.
class PasswordResetBySms extends ConsumerStatefulWidget {
  const PasswordResetBySms({super.key});

  @override
  ConsumerState<PasswordResetBySms> createState() => _PasswordResetBySmsState();
}

class _PasswordResetBySmsState extends ConsumerState<PasswordResetBySms> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  String? _sentTo;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  String _reason(AppLocalizations l, Object? reason) => switch (reason) {
        'sms_off' => l.resetSmsOff,
        'bad_phone' => l.invalidPhone,
        'too_many' => l.resetTooMany,
        'weak_password' => l.passwordTooShort,
        'wrong_code' => l.resetWrongCode,
        _ => l.resetExpired,
      };

  Future<void> _send() async {
    final l = context.l10n;
    final phone = normalizePhone(_phone.text);
    if (phone == null) {
      setState(() => _error = l.invalidPhone);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref.read(repositoryProvider).requestPasswordResetSms(phone);
      if (!mounted) return;
      setState(() {
        if (r['ok'] == true) {
          _sentTo = phone;
        } else {
          _error = _reason(l, r['reason']);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _reset() async {
    final l = context.l10n;
    if (_password.text.length < 8) {
      setState(() => _error = l.passwordTooShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(repositoryProvider);
      final r = await repo.resetPasswordWithSms(_sentTo!, _code.text.trim(), _password.text);
      if (!mounted) return;
      if (r['ok'] != true) {
        setState(() {
          _error = _reason(l, r['reason']);
          _busy = false;
        });
        return;
      }
      final email = r['email'] as String?;
      if (email != null) await repo.auth.signInWithPassword(email: email, password: _password.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnack(context, l.resetDone);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorText(e);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.resetHowTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        if (_sentTo == null) ...[
          LabeledField(
            label: l.phoneNumber,
            child: TextField(
              controller: _phone,
              autofocus: true,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: InputDecoration(hintText: l.phoneHint, prefixIcon: const Icon(Icons.phone_outlined)),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(height: 6),
          Text(l.resetByTextHint, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: _busy ? null : _send,
            child: Text(l.sendResetCode),
          ),
        ] else ...[
          Text(l.resetCodeSentTo(formatPhone(_sentTo!)), style: const TextStyle(fontSize: 14, color: Bua.inkMuted)),
          const SizedBox(height: 12),
          LabeledField(
            label: l.enterCode,
            child: TextField(
              controller: _code,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: l.newPasswordLabel,
            child: TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _reset(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: _busy ? null : _reset,
            child: Text(l.setNewPassword),
          ),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _sentTo = null),
            child: Text(l.changeNumber),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Bua.danger, fontSize: 13)),
        ],
      ]),
    );
  }
}
