import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../models/calendar.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';

/// The family's events, birthdays and remembrance days in the calendar app
/// on the phone (Google Calendar, iPhone, Outlook), through a private link.
class CalendarFeedScreen extends ConsumerWidget {
  const CalendarFeedScreen({super.key});

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    if (await guarded(context, action)) ref.invalidate(calendarFeedProvider);
  }

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok && context.mounted) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) showSnack(context, context.l10n.calendarCopied);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final repo = ref.read(repositoryProvider);
    final feed = ref.watch(calendarFeedProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.calendarTitle)),
      body: AsyncBody(
        value: feed,
        onRetry: () => ref.invalidate(calendarFeedProvider),
        builder: (CalendarFeed? f) {
          final on = f != null && f.enabled;
          final links = on ? repo.calendarLinks(f.token) : null;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
            Row(children: [
              IconTile(Icons.calendar_month_outlined, background: Bua.greenTint, color: Bua.green, size: 48),
              const SizedBox(width: 14),
              Expanded(child: Text(l.calendarIntro, style: const TextStyle(fontSize: 15, height: 1.4))),
            ]),
            const SizedBox(height: 16),
            if (!on)
              FilledButton.icon(
                onPressed: () => _run(context, ref, () => repo.calendarLink()),
                icon: const Icon(Icons.link),
                label: Text(l.calendarGetLink),
              )
            else ...[
              FilledButton.icon(
                onPressed: () => _open(context, links!.google),
                icon: const Icon(Icons.event_available),
                label: Text(l.calendarAddGoogle),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _open(context, links!.webcal),
                icon: const Icon(Icons.phone_iphone),
                label: Text(l.calendarAddApple),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: links!.https));
                  if (context.mounted) showSnack(context, l.calendarCopied);
                },
                icon: const Icon(Icons.copy),
                label: Text(l.calendarCopy),
              ),
              const SizedBox(height: 12),
              Text(
                f.lastFetchedAt == null ? l.calendarNeverFetched : l.calendarLastFetched(l.ago(f.lastFetchedAt!)),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Bua.inkSubtle),
              ),
              const SizedBox(height: 16),
              SectionCard(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(l.calendarEventsNote, style: TextStyle(fontSize: 13, color: Bua.inkMuted)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ToggleRow(
                    title: l.calendarBirthdays,
                    subtitle: l.calendarBirthdaysHint,
                    value: f.includeBirthdays,
                    onChanged: (v) => _run(context, ref, () => repo.calendarSettings(birthdays: v)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ToggleRow(
                    title: l.calendarRemembrance,
                    subtitle: l.calendarRemembranceHint,
                    value: f.includeRemembrance,
                    onChanged: (v) => _run(context, ref, () => repo.calendarSettings(remembrance: v)),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              InfoBanner(icon: Icons.lock_outline, text: l.calendarPrivate),
              const SizedBox(height: 8),
              Text(l.calendarRefreshNote, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () async {
                  if (!await confirm(context, l.calendarConfirmNewLink) || !context.mounted) return;
                  await _run(context, ref, () => repo.calendarLink(reset: true));
                },
                icon: const Icon(Icons.autorenew),
                label: Text(l.calendarNewLink),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Bua.danger),
                onPressed: () async {
                  await _run(context, ref, () => repo.calendarSettings(enabled: false));
                  if (context.mounted) showSnack(context, l.calendarTurnedOff);
                },
                icon: const Icon(Icons.link_off),
                label: Text(l.calendarTurnOff),
              ),
            ],
          ]);
        },
      ),
    );
  }
}
