import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';

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
  bool _signUp = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.account_tree, size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(l.appTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(l.welcomeTagline, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 32),
                    if (_signUp) ...[
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(labelText: l.displayName),
                        validator: (v) => (v ?? '').trim().isEmpty ? l.required : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: l.email),
                      validator: (v) => (v ?? '').contains('@') ? null : l.invalidEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(labelText: l.password),
                      validator: (v) => (v ?? '').length < 8 ? l.passwordTooShort : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_signUp ? l.signUp : l.signIn),
                    ),
                    if (!_signUp)
                      TextButton(onPressed: _busy ? null : _forgot, child: Text(l.forgotPassword)),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _signUp = !_signUp),
                      child: Text(_signUp ? l.haveAccount : l.noAccount),
                    ),
                    const SizedBox(height: 16),
                    const Center(child: LanguageToggle()),
                  ],
                ),
              ),
            ),
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
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'en', label: Text(l.english)),
        ButtonSegment(value: 'ha', label: Text(l.hausa)),
      ],
      selected: {l.localeName},
      onSelectionChanged: (s) => ref.read(localeProvider.notifier).set(Locale(s.first)),
    );
  }
}
