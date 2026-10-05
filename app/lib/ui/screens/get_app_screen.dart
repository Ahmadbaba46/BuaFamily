import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../services/app_update.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';

/// Opens the APK download in the browser (Android then offers to install it).
/// The Google Play build opens its Play page instead.
Future<void> downloadAndroidApp(WidgetRef ref, AndroidRelease release) async {
  if (isPlayBuild) return openPlayStore(ref);
  await launchUrl(Uri.parse(ref.read(repositoryProvider).releaseUrl(release.pathForThisPhone)),
      mode: LaunchMode.externalApplication);
}

Future<void> openPlayStore(WidgetRef ref) async {
  Map<String, dynamic>? info;
  try {
    info = await ref.read(publicInfoProvider.future);
  } catch (_) {}
  await launchUrl(Uri.parse(playStoreUrlOf(info)), mode: LaunchMode.externalApplication);
}

/// The Android app: download link, version and how to install it. Open to
/// everyone (also before signing in), so the link can be shared on WhatsApp.
class GetAppScreen extends ConsumerWidget {
  const GetAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final release = ref.watch(androidReleaseProvider);
    final installed = ref.watch(installedBuildProvider).value;
    final onPlay = isPlayBuild || ref.watch(publicInfoProvider).value?['play_store_url'] != null;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
      ),
      body: AsyncBody(
        value: release,
        onRetry: () => ref.invalidate(androidReleaseProvider),
        builder: (r) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 32), shrinkWrap: true, children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/brand/app_icon.png', width: 96, height: 96),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.getAppTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(l.getAppSub, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Bua.inkMuted)),
              const SizedBox(height: 24),
              if (onPlay) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  onPressed: () => openPlayStore(ref),
                  icon: const Icon(Icons.shop),
                  label: Text(l.getOnPlay),
                ),
                if (!isPlayBuild && r != null)
                  TextButton(onPressed: () => downloadAndroidApp(ref, r), child: Text(l.downloadApkInstead)),
                const SizedBox(height: 12),
              ],
              if (r == null && !onPlay)
                InfoBanner(icon: Icons.hourglass_empty, text: l.getAppNone)
              else if (r != null && !onPlay) ...[
                Text(
                  l.getAppVersion(r.version, r.publishedAt == null ? '' : l.formatDate(r.publishedAt!)),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Bua.inkSubtle),
                ),
                const SizedBox(height: 12),
                if (installed != null && installed >= r.build)
                  InfoBanner(icon: Icons.check_circle_outline, text: l.getAppLatest)
                else
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                    onPressed: () => downloadAndroidApp(ref, r),
                    icon: const Icon(Icons.download),
                    label: Text(l.download),
                  ),
                // On the website the phone type isn't known: the main file suits
                // most phones; older 32-bit phones take this one.
                if (!isAndroidApp && r.arm32Path != null)
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(ref.read(repositoryProvider).releaseUrl(r.arm32Path!)),
                        mode: LaunchMode.externalApplication),
                    child: Text(l.forOlderPhones),
                  ),
                if (r.notes != null) ...[
                  const SizedBox(height: 20),
                  Text(l.whatsNew, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Bua.inkMuted)),
                  const SizedBox(height: 4),
                  Text(r.notes!, style: const TextStyle(fontSize: 15, height: 1.45)),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(18)),
                  child: Text(l.getAppSteps, style: const TextStyle(fontSize: 14, height: 1.6)),
                ),
              ],
              const SizedBox(height: 14),
              Text(l.getAppIphone, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Bua.inkSubtle)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// On Home in the Android app: a newer version is published.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final update = ref.watch(updateAvailableProvider);
    if (update == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        decoration: BoxDecoration(
          color: Bua.greenTint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Bua.greenIndicator),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.system_update, color: Bua.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.updateAvailableTitle,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Bua.greenDark)),
                Text(l.updateAvailableBody(update.version),
                    style: TextStyle(fontSize: 13, height: 1.4, color: Bua.greenDark)),
              ]),
            ),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => context.push('/get-app'), child: Text(l.whatsNew)),
            FilledButton.icon(
              onPressed: () => downloadAndroidApp(ref, update),
              icon: Icon(isPlayBuild ? Icons.shop : Icons.download, size: 18),
              label: Text(isPlayBuild ? l.updateOnPlay : l.download),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Admin → Settings: publish a new Android build.
class AndroidReleaseCard extends ConsumerStatefulWidget {
  const AndroidReleaseCard({super.key, required this.pickApks});

  /// Lets the admin choose the APKs: (file name, bytes) each; empty if cancelled.
  final Future<List<(String, Uint8List)>> Function() pickApks;

  @override
  ConsumerState<AndroidReleaseCard> createState() => _AndroidReleaseCardState();
}

class _AndroidReleaseCardState extends ConsumerState<AndroidReleaseCard> {
  bool _busy = false;

  Future<void> _publish(AndroidRelease? current) async {
    final l = context.l10n;
    final files = await widget.pickApks();
    if (files.isEmpty || !mounted) return;
    for (final f in files) {
      if (f.$2.length > maxUploadBytes) {
        showSnack(context, l.apkTooBig(f.$1, (f.$2.length / (1024 * 1024)).toStringAsFixed(1)));
        return;
      }
    }
    final main = files.where((f) => !isArm32Apk(f.$1)).firstOrNull;
    final arm32 = files.where((f) => isArm32Apk(f.$1)).firstOrNull;
    if (main == null) {
      showSnack(context, l.apkNeedMain);
      return;
    }
    final file = main;
    final guess = versionFromFileName(file.$1);
    final nextBuild = guess?.$1 ?? ((current?.build ?? 0) + 1);
    final build = TextEditingController(text: '$nextBuild');
    final version = TextEditingController(text: guess?.$2 ?? '1.0.$nextBuild');
    final notes = TextEditingController();
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.publishVersion),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final f in [main, ?arm32]) Text(f.$1, style: TextStyle(fontSize: 13, color: Bua.inkSubtle)),
            const SizedBox(height: 12),
            TextField(controller: version, decoration: InputDecoration(labelText: l.versionLabel)),
            const SizedBox(height: 8),
            TextField(
              controller: build,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l.buildNumber),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.whatsNewOptional),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.publishVersion)),
        ],
      ),
    );
    final buildNo = int.tryParse(build.text.trim());
    final versionText = version.text.trim();
    final notesText = notes.text.trim();
    build.dispose();
    version.dispose();
    notes.dispose();
    if (go != true || buildNo == null || !mounted) return;

    setState(() => _busy = true);
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).publishAndroid(
            bytes: file.$2,
            arm32Bytes: arm32?.$2,
            build: buildNo,
            version: versionText.isEmpty ? '1.0.$buildNo' : versionText,
            notes: notesText.isEmpty ? null : notesText,
            previousPaths: [?current?.path, ?current?.arm32Path],
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ref.invalidate(androidReleaseProvider);
      showSnack(context, l.appPublished);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final current = ref.watch(androidReleaseProvider).value;
    final link = '$siteUrl/#/get-app';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IconTile(Icons.android, background: Bua.greenTint),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.androidAppAdmin, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(
                current == null
                    ? l.androidNotPublished
                    : l.androidPublished(
                        current.version, current.publishedAt == null ? '' : l.formatDate(current.publishedAt!)),
                style: TextStyle(fontSize: 12, height: 1.4, color: Bua.inkSubtle),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : () => _publish(current),
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.upload_file),
          label: Text(_busy ? l.uploading : l.publishVersion),
        ),
        const SizedBox(height: 6),
        Text(l.apkFilesHint, style: TextStyle(fontSize: 12, height: 1.4, color: Bua.inkSubtle)),
        const SizedBox(height: 12),
        _PlayStoreLink(url: ref.watch(settingsProvider).value?.playStoreUrl),
        if (current != null) ...[
          const SizedBox(height: 12),
          Text(l.shareAppLink, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
          Row(children: [
            Expanded(child: SelectableText(link, style: TextStyle(fontSize: 14, color: Bua.green))),
            IconButton(
              tooltip: l.copied,
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) showSnack(context, l.copied);
              },
            ),
          ]),
        ],
      ]),
    );
  }
}

/// Admin: the app's Google Play link, once it's there.
class _PlayStoreLink extends ConsumerWidget {
  const _PlayStoreLink({required this.url});

  final String? url;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final r = await showFormDialog(context, title: l.playStoreLink, note: l.playStoreLinkHelp, fields: [
      TextSpec('url', l.playStoreLink,
          initial: url, hint: 'https://play.google.com/store/apps/details?id=$androidPackage'),
    ]);
    if (r == null || !context.mounted) return;
    final value = (r['url'] as String?) ?? '';
    if (value.isNotEmpty && !value.startsWith('https://play.google.com/')) {
      showSnack(context, l.playStoreLinkInvalid);
      return;
    }
    final ok = await guarded(
        context, () => ref.read(repositoryProvider).updateSettings({'play_store_url': value.isEmpty ? null : value}));
    if (ok) {
      ref.invalidate(settingsProvider);
      ref.invalidate(publicInfoProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _edit(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(Icons.shop, size: 20, color: Bua.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.playStoreLink, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(url ?? l.notSet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
            ]),
          ),
          Icon(Icons.edit_outlined, size: 18, color: Bua.inkSubtle),
        ]),
      ),
    );
  }
}
