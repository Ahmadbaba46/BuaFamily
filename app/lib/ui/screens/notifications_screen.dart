import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/fund.dart';
import '../../models/hijri.dart';
import '../../models/notification.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/hijri.dart';
import '../widgets/push_widgets.dart';
import '../widgets/social.dart';

/// The main line of a notification, in the reader's language.
String notificationText(AppLocalizations l, AppNotification n) => switch (n.kind) {
      NotificationKind.event => l.notifEvent(n.str('title') ?? ''),
      NotificationKind.announcement => n.str('body') ?? l.announcement,
      NotificationKind.birthday => l.notifBirthday(n.str('name') ?? '', (n.data['age'] as num?)?.toInt() ?? 0),
      NotificationKind.eventReminder => l.notifEventReminder(n.str('title') ?? ''),
      NotificationKind.tagged => n.data.containsKey('photo_id') ? l.notifTaggedPhoto : l.notifTaggedPost,
      NotificationKind.comment => (n.str('name') ?? '').isEmpty
          ? l.notifComment(n.str('body') ?? '')
          : n.data['also'] == true
              ? l.notifCommentAlso(n.str('name')!, n.str('body') ?? '')
              : l.notifCommentBy(n.str('name')!, n.str('body') ?? ''),
      NotificationKind.bloodRequest =>
        l.notifBloodRequest(n.str('blood_group') ?? '', n.str('patient') ?? '', n.str('hospital') ?? ''),
      NotificationKind.bloodOffer => l.notifBloodOffer(n.str('blood_group') ?? ''),
      NotificationKind.remembrance =>
        l.notifRemembrance((n.data['years'] as num?)?.toInt() ?? 0, n.str('name') ?? ''),
      NotificationKind.memory => l.notifMemory(n.str('name') ?? '', n.str('body') ?? ''),
      NotificationKind.fundContribution => l.notifFundContribution(naira((n.data['amount'] as num?) ?? 0)),
      NotificationKind.fundConfirmed => l.notifFundConfirmed(naira((n.data['amount'] as num?) ?? 0)),
      NotificationKind.fundRequest => l.notifFundRequest(n.str('title') ?? ''),
      NotificationKind.mentorRequest => (n.str('name') ?? '').isEmpty
          ? l.notifMentorRequest(n.str('body') ?? '')
          : l.notifMentorRequestFrom(n.str('name')!, n.str('body') ?? ''),
      NotificationKind.mentorReply => l.notifMentorReply(n.str('name') ?? '', n.str('body') ?? ''),
      NotificationKind.occasion => _occasionText(l, n),
      NotificationKind.claimReviewed => n.data['approved'] == true
          ? l.notifClaimApproved(n.str('person') ?? '')
          : (n.str('reason') ?? '').isEmpty
              ? l.notifClaimDeclined(n.str('person') ?? '')
              : l.notifClaimDeclinedWhy(n.str('person') ?? '', n.str('reason')!),
      NotificationKind.duesReminder =>
        l.notifDuesReminder(n.str('title') ?? '', naira((n.data['owed'] as num?) ?? 0)),
      NotificationKind.weeklySummary => _weeklyText(l, n),
      NotificationKind.directMessage => l.notifDirectMessage(n.str('name') ?? '', n.str('body') ?? ''),
      NotificationKind.adminAlert => switch (n.str('alert')) {
          'blood_no_offer' => l.notifAlertBlood(
              n.str('blood_group') ?? '', n.str('patient') ?? '', (n.data['hours'] as num?)?.toInt() ?? 2),
          'fund_low' => l.notifAlertFundLow(
              naira((n.data['balance'] as num?) ?? 0), naira((n.data['threshold'] as num?) ?? 0)),
          _ => l.notifAlertWaiting(
              (n.data['suggestions'] as num?)?.toInt() ?? 0, (n.data['accounts'] as num?)?.toInt() ?? 0),
        },
      NotificationKind.opportunity => l.notifOpportunity(n.str('title') ?? ''),
      NotificationKind.poll => l.notifPoll(n.str('question') ?? ''),
      NotificationKind.story => l.notifStory(n.str('speaker') ?? '', n.str('title') ?? ''),
      NotificationKind.test => l.notifTest,
      NotificationKind.accountRequest => n.str('person') != null
          ? l.notifAccountClaim(n.str('name') ?? '', n.str('person')!)
          : n.str('note') != null
              ? l.notifAccountNote(n.str('name') ?? '', n.str('note')!)
              : l.notifAccountRequest(n.str('name') ?? ''),
      NotificationKind.changeRequest => n.str('request_kind') == 'create_person'
          ? l.notifChangeAdd(n.str('name') ?? '', n.str('person') ?? l.notifSomeone)
          : l.notifChangeEdit(n.str('name') ?? '', n.str('person') ?? l.notifTheTree),
      NotificationKind.accountApproved => l.notifAccountApproved,
      NotificationKind.appUpdate => l.notifAppUpdate(n.str('version') ?? ''),
      NotificationKind.requestReviewed => n.data['approved'] == true
          ? l.notifRequestApproved(n.str('person') ?? l.notifTheTree)
          : l.notifRequestDeclined(n.str('person') ?? l.notifTheTree),
    };

String _weeklyText(AppLocalizations l, AppNotification n) {
  int count(String k) => (n.data[k] as num?)?.toInt() ?? 0;
  final text = l.notifWeeklySummary(
      count('active'), count('moments'), count('photos'), naira((n.data['money_in'] as num?) ?? 0));
  final waiting = count('waiting_suggestions') + count('waiting_accounts');
  return waiting > 0 ? '$text ${l.notifWeeklyWaiting(waiting)}' : text;
}

String _occasionText(AppLocalizations l, AppNotification n) {
  final o = switch (n.str('occasion')) {
    'ramadan' => Occasion.ramadan,
    'eid_al_fitr' => Occasion.eidAlFitr,
    'eid_al_adha' => Occasion.eidAlAdha,
    _ => Occasion.islamicNewYear,
  };
  final year = (n.data['hijri_year'] as num?)?.toInt() ?? 0;
  return (n.data['eve'] == true ? l.occasionEve(o) : l.occasionGreeting(o, year)) ?? l.occasionName(o);
}

IconData _icon(NotificationKind k) => switch (k) {
      NotificationKind.event => Icons.event,
      NotificationKind.announcement => Icons.campaign_outlined,
      NotificationKind.birthday => Icons.card_giftcard,
      NotificationKind.eventReminder => Icons.alarm,
      NotificationKind.tagged => Icons.person_pin_outlined,
      NotificationKind.comment => Icons.chat_bubble_outline,
      NotificationKind.bloodRequest || NotificationKind.bloodOffer => Icons.bloodtype_outlined,
      NotificationKind.remembrance || NotificationKind.memory => Icons.dark_mode_outlined,
      NotificationKind.fundContribution || NotificationKind.fundConfirmed || NotificationKind.fundRequest =>
        Icons.volunteer_activism_outlined,
      NotificationKind.mentorRequest || NotificationKind.opportunity => Icons.school_outlined,
      NotificationKind.mentorReply => Icons.forum_outlined,
      NotificationKind.occasion => Icons.nightlight_round,
      NotificationKind.claimReviewed => Icons.how_to_reg_outlined,
      NotificationKind.duesReminder => Icons.event_repeat,
      NotificationKind.weeklySummary => Icons.insights_outlined,
      NotificationKind.directMessage => Icons.forum_outlined,
      NotificationKind.adminAlert => Icons.warning_amber_rounded,
      NotificationKind.poll => Icons.how_to_vote_outlined,
      NotificationKind.story => Icons.mic_none,
      NotificationKind.test => Icons.notifications_active_outlined,
      NotificationKind.accountRequest => Icons.person_add_alt_outlined,
      NotificationKind.changeRequest => Icons.edit_note,
      NotificationKind.accountApproved => Icons.celebration_outlined,
      NotificationKind.requestReviewed => Icons.fact_check_outlined,
      NotificationKind.appUpdate => Icons.system_update,
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
            return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
              const PushPrompt(),
              const SizedBox(height: 80),
              Icon(Icons.notifications_none, size: 48, color: Bua.inkSubtle),
              const SizedBox(height: 12),
              Text(l.noNotifications, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkSubtle)),
            ]);
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
            const PushPrompt(),
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
        color: n.isRead ? null : (Bua.dark ? Bua.greenTint : const Color(0xFFF2F8F4)),
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
              Text(meta, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
            ]),
          ),
          if (!n.isRead)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: Bua.green, shape: BoxShape.circle),
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
        shape: CircleBorder(side: BorderSide(color: Bua.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push('/notifications'),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(alignment: Alignment.center, children: [
              Icon(Icons.notifications_none, size: 22, color: Bua.ink),
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
