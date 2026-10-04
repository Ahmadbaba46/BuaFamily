import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../models/social.dart' show Member;
import '../../services/invites.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import 'sign_in_screen.dart' show LanguageToggle;

final _inviteProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
  (ref, code) => ref.watch(repositoryProvider).inviteInfo(code),
);

/// Opened from an invite link: who invited you, then sign up (or accept).
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  bool _busy = false;

  Future<void> _go() async {
    final auth = ref.read(authProvider);
    if (!auth.signedIn) {
      await rememberInvite(widget.code);
      if (mounted) context.go('/sign-in');
      return;
    }
    setState(() => _busy = true);
    final l = context.l10n;
    final ok = await guarded(context, () => ref.read(repositoryProvider).redeemInvite(widget.code));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      await auth.refresh();
      if (mounted) {
        showSnack(context, l.inviteAccepted);
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final info = ref.watch(_inviteProvider(widget.code));
    return Scaffold(
      body: SafeArea(
        child: AsyncBody(
          value: info,
          onRetry: () => ref.invalidate(_inviteProvider(widget.code)),
          builder: (i) {
            final valid = i?['valid'] == true;
            final family = (i?['family'] as String?) ?? 'Bua';
            final inviter = i?['invited_by'] as String?;
            final person = i?['person'] as String?;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ListView(padding: const EdgeInsets.all(28), shrinkWrap: true, children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset('assets/brand/app_icon.png', width: 96, height: 96),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(l.inviteTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  if (!valid)
                    InfoBanner(icon: Icons.link_off, text: l.inviteInvalid)
                  else ...[
                    Text(
                      inviter == null ? l.inviteBodyGeneric(family) : l.inviteBody(inviter, family),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.45, color: Bua.inkMuted),
                    ),
                    if (person != null) ...[
                      const SizedBox(height: 6),
                      Text(l.inviteFor(person),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Bua.greenDark)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                      onPressed: _busy ? null : _go,
                      child: Text(ref.watch(authProvider).signedIn ? l.acceptInvite : l.joinWithInvite),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Center(child: LanguageToggle()),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Admin: make an invite link and share it.
Future<void> showInviteSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Bua.ground,
      builder: (_) => const _InviteSheet(),
    );

class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet();

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  String? _personId;
  String? _link;
  bool _busy = false;

  Future<void> _pick() async {
    final graph = ref.read(graphProvider).value;
    if (graph == null) return;
    final taken = {for (final m in ref.read(membersProvider).value?.values ?? const <Member>[]) ?m.personId};
    final p = await pickPerson(context, graph, exclude: taken);
    if (p != null) setState(() => _personId = p.id);
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    String? code;
    final ok = await guarded(context, () async {
      code = await ref.read(repositoryProvider).createInvite(personId: _personId);
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok && code != null) _link = inviteLink(code!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final person = _personId == null ? null : ref.watch(graphProvider).value?[_personId!];
    final family = ref.watch(settingsProvider).value?.familyName ?? 'Bua';
    final message = _link == null
        ? ''
        : person == null
            ? l.inviteMessage(family, _link!)
            : l.inviteMessageFor(person.firstName, family, _link!);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.inviteSomeone, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l.inviteSomeoneHint, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
          const SizedBox(height: 16),
          if (_link == null) ...[
            Material(
              color: Bua.surface,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                leading: person == null
                    ? const Icon(Icons.person_search, color: Bua.green)
                    : PersonAvatar(person: person, radius: 18),
                title: Text(person?.displayName ?? l.invitePerson),
                trailing: person == null
                    ? const Icon(Icons.chevron_right)
                    : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _personId = null)),
                onTap: _pick,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _busy ? null : _create,
              icon: const Icon(Icons.link),
              label: Text(l.createInvite),
            ),
          ] else ...[
            InfoBanner(icon: Icons.check_circle_outline, text: l.inviteReady),
            const SizedBox(height: 12),
            SelectableText(message, style: const TextStyle(fontSize: 14, height: 1.45)),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: const Color(0xFF1FA855)),
              onPressed: () => launchUrl(
                Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.chat),
              label: Text(l.shareWhatsApp),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: message));
                if (context.mounted) showSnack(context, l.copied);
              },
              icon: const Icon(Icons.copy),
              label: Text(l.copyLink),
            ),
          ],
        ]),
      ),
    );
  }
}
