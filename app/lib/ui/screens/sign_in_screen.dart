import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;

import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import 'notification_settings_screen.dart' show formatPhone, normalizePhone;

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _signUp = false;
  bool _busy = false;

  /// Sign in with a phone number and a code by SMS instead of email.
  bool _usePhone = false;

  /// The number the code went to (international, without +).
  String? _codeSentTo;
  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    _code.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final l = context.l10n;
    final phone = normalizePhone(_phone.text);
    if (phone == null) {
      showSnack(context, l.invalidPhone);
      return;
    }
    setState(() => _busy = true);
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).auth.signInWithOtp(
        phone: '+$phone',
        data: {
          if (_name.text.trim().isNotEmpty) 'display_name': _name.text.trim(),
          'locale': l.localeName,
        },
      ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _codeSentTo = phone;
        _code.clear();
        _startResendTimer();
      }
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendIn = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _verifyCode() async {
    final code = _code.text.trim();
    if (_codeSentTo == null || code.length < 6) return;
    setState(() => _busy = true);
    await guarded(
      context,
      () => ref.read(repositoryProvider).auth.verifyOTP(type: OtpType.sms, phone: '+$_codeSentTo', token: code),
    );
    if (mounted) setState(() => _busy = false);
  }

  List<Widget> _phoneFields(AppLocalizations l) {
    if (_codeSentTo == null) {
      return [
        LabeledField(
          label: l.yourNameNew,
          child: TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
          ),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: l.phoneNumber,
          child: TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: InputDecoration(hintText: l.phoneHint, prefixIcon: const Icon(Icons.phone_outlined)),
            onSubmitted: (_) => _sendCode(),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _busy ? null : _sendCode,
          child: Text(l.sendCode),
        ),
        const SizedBox(height: 8),
      ];
    }
    return [
      Text(l.codeSent(formatPhone(_codeSentTo!)), style: const TextStyle(fontSize: 14, color: Bua.inkMuted)),
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
          onChanged: (v) {
            if (v.trim().length == 6) _verifyCode();
          },
        ),
      ),
      const SizedBox(height: 18),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: _busy ? null : _verifyCode,
        child: _busy
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(l.signIn),
      ),
      Wrap(alignment: WrapAlignment.spaceBetween, children: [
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: _busy ? null : () => setState(() => _codeSentTo = null),
          child: Text(l.changeNumber),
        ),
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: _busy || _resendIn > 0 ? null : _sendCode,
          child: Text(_resendIn > 0 ? l.resendIn(_resendIn) : l.resendCode),
        ),
      ]),
    ];
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = ref.read(repositoryProvider).auth;
    final l = context.l10n;
    await guarded(context, () async {
      if (_signUp) {
        final res = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'display_name': _name.text.trim(), 'locale': l.localeName},
        );
        if (res.session == null && mounted) {
          showSnack(context, l.checkEmailToConfirm);
          setState(() => _signUp = false);
        }
      } else {
        await auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      }
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      showSnack(context, context.l10n.invalidEmail);
      return;
    }
    final l = context.l10n;
    final ok = await guarded(context, () => ref.read(repositoryProvider).auth.resetPasswordForEmail(email));
    if (ok && mounted) showSnack(context, l.resetPasswordSent);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PatternBand(
                height: 340,
                child: SafeArea(
                  bottom: false,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        boxShadow: [BoxShadow(color: Color(0x2E000000), blurRadius: 24, offset: Offset(0, 8))],
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      child: Image.asset('assets/brand/app_icon.png', semanticLabel: l.appTitle),
                    ),
                    const SizedBox(height: 14),
                    Text(l.appTitle,
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(l.welcomeTagline, style: const TextStyle(fontSize: 15, color: Bua.greenTint)),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Color(0x1A17231B), blurRadius: 24, offset: Offset(0, 6))],
                  ),
                  child: Form(
                    key: _form,
                    child: AutofillGroup(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(_signUp && !_usePhone ? l.createYourAccount : l.welcomeBack,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        PillSegmented<bool>(
                          values: const [false, true],
                          labelOf: (phone) => phone ? l.phoneTab : l.emailTab,
                          selected: _usePhone,
                          height: 38,
                          expand: true,
                          onChanged: (v) => setState(() => _usePhone = v),
                        ),
                        const SizedBox(height: 14),
                        if (_usePhone) ..._phoneFields(l),
                        if (!_usePhone && _signUp) ...[
                          LabeledField(
                            label: l.displayName,
                            child: TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.name],
                              validator: (v) => (v ?? '').trim().isEmpty ? l.required : null,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (!_usePhone) ...[
                        LabeledField(
                          label: l.email,
                          child: TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: (v) => (v ?? '').contains('@') ? null : l.invalidEmail,
                          ),
                        ),
                        const SizedBox(height: 14),
                        LabeledField(
                          label: l.password,
                          child: TextFormField(
                            controller: _password,
                            obscureText: true,
                            autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
                            validator: (v) => (v ?? '').length < 8 ? l.passwordTooShort : null,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox.square(
                                  dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(_signUp ? l.signUp : l.signIn),
                        ),
                        const SizedBox(height: 4),
                        Wrap(alignment: WrapAlignment.spaceBetween, children: [
                          if (!_signUp)
                            TextButton(
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              onPressed: _busy ? null : _forgot,
                              child: Text(l.forgotPassword, style: const TextStyle(fontWeight: FontWeight.w500)),
                            ),
                          TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            onPressed: _busy ? null : () => setState(() => _signUp = !_signUp),
                            child: Text(_signUp ? l.signIn : l.signUp),
                          ),
                        ]),
                        ],
                      ]),
                    ),
                  ),
                ),
              ),
              if (kIsWeb)
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/get-app'),
                    icon: const Icon(Icons.android),
                    label: Text(l.getTheApp),
                  ),
                ),
              const Center(child: LanguageToggle()),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  l.privateSpaceNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Bua.inkSubtle),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return PillSegmented<String>(
      values: const ['en', 'ha'],
      labelOf: (v) => v == 'en' ? l.english : l.hausa,
      selected: l.localeName,
      onChanged: (v) => ref.read(localeProvider.notifier).set(Locale(v)),
    );
  }
}
