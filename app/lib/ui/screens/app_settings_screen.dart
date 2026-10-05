import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../state/prefs.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import 'sign_in_screen.dart' show LanguageToggle;

/// In-app notification groups and the database kinds each one covers.
const notificationGroups = {
  'events': ['event', 'announcement', 'event_reminder'],
  'birthdays': ['birthday', 'remembrance', 'memory'],
  'tagged': ['tagged'],
  'comments': ['comment'],
  'occasions': ['occasion'],
  'weekly': ['weekly_summary'],
  'messages': ['direct_message'],
};

/// Language, data saver and which notifications to receive.
class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  List<String>? _muted;

  Future<void> _setGroup(String group, bool on) async {
    final current = [...(_muted ?? ref.read(profileProvider)?.mutedNotifications ?? const <String>[])];
    final kinds = notificationGroups[group]!;
    final next = on ? current.where((k) => !kinds.contains(k)).toList() : {...current, ...kinds}.toList();
    setState(() => _muted = next);
    final ok = await guarded(context, () => ref.read(repositoryProvider).setMutedNotifications(next));
    if (!mounted) return;
    if (ok) {
      await ref.read(authProvider).refresh();
    } else {
      setState(() => _muted = current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(devicePrefsProvider);
    final muted = _muted ?? ref.watch(profileProvider)?.mutedNotifications ?? const <String>[];
    bool on(String group) => !notificationGroups[group]!.any(muted.contains);

    Widget toggle(String title, String group) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ToggleRow(title: title, value: on(group), onChanged: (v) => _setGroup(group, v)),
        );
    const divider = Divider(height: 1, indent: 16, endIndent: 16);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        title: Text(l.settingsScreen, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        SectionCard(title: l.languageHarshe, padding: const EdgeInsets.fromLTRB(0, 6, 0, 16), children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(alignment: Alignment.centerLeft, child: LanguageToggle()),
          ),
        ]),
        const SizedBox(height: 12),
        SectionCard(title: l.appearanceTitle, padding: const EdgeInsets.fromLTRB(0, 6, 0, 16), children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          Text(l.themeLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Bua.inkMuted)),
          const SizedBox(height: 6),
          PillSegmented<Appearance>(
            values: Appearance.values,
            expand: true,
            height: 36,
            labelOf: (a) => switch (a) {
              Appearance.system => l.themeSystem,
              Appearance.light => l.themeLight,
              Appearance.dark => l.themeDark,
            },
            selected: prefs.appearance,
            onChanged: (a) => ref.read(devicePrefsProvider.notifier).set(appearance: a),
          ),
          const SizedBox(height: 14),
          Text(l.textSizeLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Bua.inkMuted)),
          const SizedBox(height: 6),
          PillSegmented<double>(
            values: textScales,
            expand: true,
            height: 36,
            labelOf: (v) => v == textScales[0] ? l.textNormal : (v == textScales[1] ? l.textLarge : l.textLarger),
            selected: prefs.textScale,
            onChanged: (v) => ref.read(devicePrefsProvider.notifier).set(textScale: v),
          ),
          const SizedBox(height: 10),
          Text(l.textSizeSample, style: const TextStyle(fontSize: 15)),
        ]),
        ),
      ]),
        const SizedBox(height: 12),
        SectionCard(title: l.dataSaver, padding: const EdgeInsets.fromLTRB(0, 6, 0, 6), children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ToggleRow(
              title: l.tapToLoadPhotos,
              subtitle: l.tapToLoadPhotosSub,
              value: prefs.tapToLoadPhotos,
              onChanged: (v) => ref.read(devicePrefsProvider.notifier).set(tapToLoadPhotos: v),
            ),
          ),
          divider,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ToggleRow(
              title: l.shrinkUploads,
              subtitle: l.shrinkUploadsSub,
              value: prefs.shrinkUploads,
              onChanged: (v) => ref.read(devicePrefsProvider.notifier).set(shrinkUploads: v),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        SectionCard(title: l.hijriSettingsTitle, padding: const EdgeInsets.fromLTRB(0, 6, 0, 6), children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ToggleRow(
              title: l.showHijriDates,
              subtitle: l.showHijriDatesHint,
              value: prefs.showHijri,
              onChanged: (v) => ref.read(devicePrefsProvider.notifier).set(showHijri: v),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        SectionCard(title: l.notifyMeAbout, padding: const EdgeInsets.fromLTRB(0, 6, 0, 6), children: [
          toggle(l.notifEventsAnnouncements, 'events'),
          divider,
          toggle(l.notifBirthdaysRemembrance, 'birthdays'),
          divider,
          toggle(l.notifTagged, 'tagged'),
          divider,
          toggle(l.notifCommentsMine, 'comments'),
          divider,
          if (ref.watch(messagesOnProvider)) ...[toggle(l.messagesTitle, 'messages'), divider],
          toggle(l.islamicOccasions, 'occasions'),
          divider,
          if (ref.watch(isAdminProvider)) ...[toggle(l.notifWeeklyForAdmins, 'weekly'), divider],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ToggleRow(title: l.urgentBlood, subtitle: l.alwaysOn, value: true, onChanged: null),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            NavRow(
              icon: Icons.sms_outlined,
              title: l.notificationsSms,
              onTap: () => context.push('/settings/notifications'),
            ),
            const InsetDivider(),
            NavRow(
              icon: Icons.lock_outline,
              title: l.privacyOfMyDetails,
              onTap: () => context.push('/me/edit'),
            ),
          ]),
        ),
      ]),
    );
  }
}
