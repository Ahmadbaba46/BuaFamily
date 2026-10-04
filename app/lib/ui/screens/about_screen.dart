import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../services/app_update.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import 'notification_settings_screen.dart' show formatPhone, normalizePhone;

/// This app's version, from the build ("1.0.250", "250").
final packageInfoProvider = FutureProvider<(String, String)?>((ref) async {
  try {
    final p = await PackageInfo.fromPlatform();
    return (p.version, p.buildNumber);
  } catch (_) {
    return null;
  }
});

/// What the app does, who made it, and which version this is.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final info = ref.watch(packageInfoProvider).value;
    final release = ref.watch(androidReleaseProvider).value;
    final update = ref.watch(updateAvailableProvider);

    final features = <(IconData, String, String)>[
      (Icons.account_tree_outlined, l.fTree, l.fTreeD),
      (Icons.people_outline, l.fMembers, l.fMembersD),
      (Icons.link, l.fRelated, l.fRelatedD),
      (Icons.photo_library_outlined, l.fSharing, l.fSharingD),
      (Icons.event_outlined, l.fEvents, l.fEventsD),
      (Icons.bloodtype_outlined, l.fBlood, l.fBloodD),
      (Icons.volunteer_activism_outlined, l.fFund, l.fFundD),
      (Icons.school_outlined, l.fMentors, l.fMentorsD),
      (Icons.mic_none, l.fStories, l.fStoriesD),
      (Icons.how_to_vote_outlined, l.fPolls, l.fPollsD),
      (Icons.local_florist_outlined, l.fMemorial, l.fMemorialD),
      (Icons.notifications_none, l.fReach, l.fReachD),
      (Icons.cloud_off_outlined, l.fOffline, l.fOfflineD),
      (Icons.translate, l.fLanguages, l.fLanguagesD),
      (Icons.lock_outline, l.fPrivate, l.fPrivateD),
    ];

    final company = (settings.developerCompany ?? '').trim();
    final name = (settings.developerName ?? '').trim();
    final phone = normalizePhone(settings.developerPhone ?? '');
    final email = (settings.developerEmail ?? '').trim();
    final website = (settings.developerWebsite ?? '').trim();

    Widget card(List<Widget> children) => Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        );

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        title: Text(l.aboutTitle, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        // The app, and this copy of it.
        card([
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/brand/app_icon.png', width: 64, height: 64),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${settings.familyName} Family', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(kIsWeb ? l.aboutOnWeb : l.aboutOnAndroid, style: const TextStyle(fontSize: 13, color: Bua.inkMuted)),
                if (info != null)
                  Text(l.aboutVersion(info.$1, info.$2), style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Text(l.aboutTagline, style: const TextStyle(fontSize: 14, height: 1.5)),
          if (release != null) ...[
            const Divider(height: 24, color: Bua.line),
            Row(children: [
              const Icon(Icons.android, size: 20, color: Bua.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAndroidApp && update == null ? l.aboutUpToDate : l.aboutLatestAndroid(release.version),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (!isAndroidApp || update != null)
                TextButton(onPressed: () => context.push('/get-app'), child: Text(l.getTheApp)),
            ]),
            if ((release.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l.whatsNew, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Bua.inkMuted)),
              const SizedBox(height: 2),
              Text(release.notes!.trim(), style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
          ],
        ]),
        const SizedBox(height: 18),
        GroupHeading(l.featuresTitle),
        const SizedBox(height: 8),
        card([
          for (final (i, f) in features.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconTile(f.$1, background: Bua.greenTint),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.$2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(f.$3, style: const TextStyle(fontSize: 13, height: 1.4, color: Bua.inkMuted)),
                ]),
              ),
            ]),
          ],
        ]),
        const SizedBox(height: 18),
        GroupHeading(l.developerTitle),
        const SizedBox(height: 8),
        card([
          Text(l.developedBy, style: const TextStyle(fontSize: 13, color: Bua.inkMuted)),
          const SizedBox(height: 4),
          if (name.isNotEmpty) Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          if (company.isNotEmpty)
            Text(company, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Bua.green)),
          if (phone != null || email.isNotEmpty || website.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (phone != null) ...[
                _Contact(Icons.call_outlined, l.contactCall, Uri(scheme: 'tel', path: '+$phone'), formatPhone(phone)),
                _Contact(Icons.chat_outlined, l.contactWhatsApp, Uri.parse('https://wa.me/$phone'), null),
              ],
              if (email.isNotEmpty) _Contact(Icons.mail_outline, l.contactEmail, Uri(scheme: 'mailto', path: email), email),
              if (website.isNotEmpty) _Contact(Icons.language, l.contactWebsite, Uri.parse(website), null),
            ]),
          ],
        ]),
        const SizedBox(height: 18),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.description_outlined, size: 18),
            label: Text(l.licensesLabel),
            onPressed: () => showLicensePage(
              context: context,
              applicationName: '${settings.familyName} Family',
              applicationVersion: info == null ? null : '${info.$1} (${info.$2})',
              applicationIcon: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset('assets/brand/app_icon.png', width: 48, height: 48),
              ),
            ),
          ),
        ),
        if (company.isNotEmpty)
          Text(
            l.copyrightLine('${DateTime.now().year}', company),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Bua.inkSubtle),
          ),
      ]),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact(this.icon, this.label, this.uri, this.tooltip);

  final IconData icon;
  final String label;
  final Uri uri;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = ActionChip(
      avatar: Icon(icon, size: 18, color: Bua.green),
      label: Text(label),
      onPressed: () => launchUrl(uri, mode: LaunchMode.externalApplication),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}
