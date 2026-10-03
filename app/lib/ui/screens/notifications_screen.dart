import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/notification.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';

/// The main line of a notification, in the reader's language.
String notificationText(AppLocalizations l, AppNotification n) => switch (n.kind) {
      NotificationKind.event => l.notifEvent(n.str('title') ?? ''),
      NotificationKind.announcement => n.str('body') ?? l.announcement,
      NotificationKind.birthday => l.notifBirthday(n.str('name') ?? '', (n.data['age'] as num?)?.toInt() ?? 0),
      NotificationKind.eventReminder => l.notifEventReminder(n.str('title') ?? ''),
      NotificationKind.tagged => n.data.containsKey('photo_id') ? l.notifTaggedPhoto : l.notifTaggedPost,
      NotificationKind.comment => l.notifComment(n.str('body') ?? ''),
      NotificationKind.bloodRequest =>
        l.notifBloodRequest(n.str('blood_group') ?? '', n.str('patient') ?? '', n.str('hospital') ?? ''),
      NotificationKind.bloodOffer => l.notifBloodOffer(n.str('blood_group') ?? ''),
      NotificationKind.remembrance =>
        l.notifRemembrance((n.data['years'] as num?)?.toInt() ?? 0, n.str('name') ?? ''),
      NotificationKind.memory => l.notifMemory(n.str('name') ?? '', n.str('body') ?? ''),
    };

IconData _icon(NotificationKind k) => switch (k) {
      NotificationKind.event => Icons.event,
      NotificationKind.announcement => Icons.campaign_outlined,
      NotificationKind.birthday => Icons.card_giftcard,
      NotificationKind.eventReminder => Icons.alarm,
      NotificationKind.tagged => Icons.person_pin_outlined,
      NotificationKind.comment => Icons.chat_bubble_outline,
      NotificationKind.bloodRequest || NotificationKind.bloodOffer => Icons.bloodtype_outlined,
      NotificationKind.remembrance || NotificationKind.memory => Icons.dark_mode_outlined,
    };

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, this.now});

  /// For tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);
    final today = now ?? DateTime.now();
    bool isToday(DateTime d) => d.year == today.year && d.month == today.month && d.day == today.day;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
        title: Text(l.notifications, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => guarded(context, () => ref.read(repositoryProvider).markAllRead()),
              child: Text(l.markAllRead),
            ),
          IconButton(
            tooltip: l.notificationsSms,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings/notifications'),
          ),
        ],
      ),
      body: AsyncBody(
        value: items,
        onRetry: () => ref.invalidate(notificationsProvider),
        builder: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.notifications_none, size: 48, color: Bua.inkSubtle),
                const SizedBox(height: 12),
                Text(l.noNotifications, style: const TextStyle(color: Bua.inkSubtle)),
              ]),
            );
          }
          final todays = list.where((n) => isToday(n.createdAt)).toList();
          final older = list.where((n) => !isToday(n.createdAt)).toList();
          Widget group(String title, List<AppNotification> rows) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GroupHeading(title),
                  const SizedBox(height: 8),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      for (final (i, n) in rows.indexed) ...[
                        if (i > 0) const InsetDivider(indent: 70),
                        _NotificationRow(notification: n),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
              );
          return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
            if (todays.isNotEmpty) group(l.today, todays),
            if (older.isNotEmpty) group(l.earlier, older),
          ]);
        },
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final n = notification;
    final actor = n.actorId == null ? null : authorOf(ref, n.actorId!);
    final gold = n.kind == NotificationKind.announcement || n.kind == NotificationKind.birthday;
    final blood = n.kind == NotificationKind.bloodRequest;
    final meta = [
      if (actor != null && actor.name.isNotEmpty) actor.name,
      l.ago(n.createdAt),
    ].join(' · ');

    return InkWell(
      onTap: () {
        if (!n.isRead) ref.read(repositoryProvider).markRead(n.id).ignore();
        if (n.link != null) context.push(n.link!);
      },
      child: Container(
        color: n.isRead ? null : const Color(0xFFF2F8F4),
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (actor?.person != null &&
              n.kind != NotificationKind.birthday &&
              n.kind != NotificationKind.remembrance &&
              !blood)
            AuthorAvatar(actor!)
          else
            IconTile(
              _icon(n.kind),
              background: blood ? Bua.dangerTint : (gold ? Bua.goldTint : Bua.greenTint),
              color: blood ? Bua.danger : (gold ? Bua.goldInk : Bua.green),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                notificationText(l, n),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, height: 1.35, fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(meta, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
            ]),
          ),
          if (!n.isRead)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Bua.green, shape: BoxShape.circle),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Bell with a red dot when something is unread.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Semantics(
      label: unread > 0 ? '${context.l10n.notifications}, $unread' : context.l10n.notifications,
      button: true,
      child: Material(
        color: Bua.surface,
        shape: const CircleBorder(side: BorderSide(color: Bua.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push('/notifications'),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.notifications_none, size: 22, color: Bua.ink),
              if (unread > 0)
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Bua.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Bua.surface, width: 2),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
