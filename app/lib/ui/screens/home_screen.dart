import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/person.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';
import 'notifications_screen.dart';

/// Family feed: today's birthdays and remembrances, pinned notices, moments.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.now});

  /// For tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final today = now ?? DateTime.now();
    final profile = ref.watch(profileProvider);
    final graph = ref.watch(graphProvider).value;
    final me = profile?.personId == null ? null : graph?[profile!.personId!];
    final feed = ref.watch(feedProvider);
    final events = ref.watch(eventsProvider).value ?? const <FamilyEvent>[];

    final name = me?.firstName ?? profile?.displayName.split(' ').first ?? '';
    final birthdays = <Person>[];
    final remembrances = <Person>[];
    for (final p in graph?.persons.values ?? const <Person>[]) {
      bool onToday(DateTime? d, bool approx) =>
          d != null && !approx && d.month == today.month && d.day == today.day && d.year < today.year;
      if (p.isLiving && onToday(p.birthDate, p.birthDateApprox)) birthdays.add(p);
      if (!p.isLiving && onToday(p.deathDate, p.deathDateApprox)) remembrances.add(p);
    }
    final pinnedEvents = events.where((e) => e.pinned && e.isUpcoming(today)).toList();

    Future<void> refresh() {
      ref.invalidate(myLikesProvider);
      ref.invalidate(eventsProvider);
      ref.invalidate(membersProvider);
      return ref.refresh(feedProvider.future);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: refresh,
          child: AsyncBody(
            value: feed,
            onRetry: () => ref.invalidate(feedProvider),
            builder: (posts) {
              final pinned = posts.where((p) => p.pinned).toList();
              final rest = posts.where((p) => !p.pinned).toList();
              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.weekdayDate(today), style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
                          Text(l.greeting(name), style: Theme.of(context).textTheme.titleLarge),
                        ]),
                      ),
                      const NotificationBell(),
                    ]),
                  ),
                  if (birthdays.isNotEmpty || remembrances.isNotEmpty) ...[
                    SizedBox(
                      height: 132,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final p in birthdays)
                            _TodayCard(
                              dark: true,
                              icon: Icons.card_giftcard,
                              label: l.birthdayToday,
                              title: l.turnsAge(p.displayName, today.year - p.birthDate!.year),
                              action: l.sendGreeting,
                              onTap: () => context.push('/new-moment?tag=${p.id}'),
                            ),
                          for (final p in remembrances)
                            _TodayCard(
                              icon: Icons.dark_mode_outlined,
                              label: l.remembrance,
                              title: l.yearsSincePassed(today.year - p.deathDate!.year, p.displayName),
                              action: l.addPrayer,
                              onTap: () => context.push('/person/${p.id}/memorial'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  for (final e in pinnedEvents) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: PinnedCard(
                        icon: Icons.event,
                        label: '${l.eventCategory(e.category.name)} · ${l.pinned}',
                        title: e.title,
                        meta: [l.weekdayDate(e.startsAt), l.clock(e.startsAt), ?e.place].join(' · '),
                        onTap: () => context.push('/events/${e.id}'),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  for (final p in pinned) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: p.kind == PostKind.announcement && p.photos.isEmpty
                          ? _PinnedAnnouncement(post: p)
                          : PostCard(post: p),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _Composer(onTap: () => context.push('/new-moment')),
                  ),
                  const SizedBox(height: 14),
                  if (rest.isEmpty && pinned.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
                      child: Text(l.feedEmpty,
                          textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkSubtle, height: 1.5)),
                    ),
                  for (final p in rest) ...[
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: PostCard(post: p)),
                    const SizedBox(height: 14),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PinnedAnnouncement extends ConsumerWidget {
  const _PinnedAnnouncement({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final author = authorOf(ref, post.authorId);
    final admin = author.member?.isAdmin ?? false;
    return PinnedCard(
      icon: Icons.campaign_outlined,
      label: '${l.announcement} · ${l.pinned}',
      title: post.body,
      meta: l.fromAuthor(admin ? '${author.name} (${l.roleAdmin.toLowerCase()})' : author.name, l.ago(post.createdAt)),
      onTap: () => showComments(context, Target.post(post.id)),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.icon,
    required this.label,
    required this.title,
    required this.action,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final String title;
  final String action;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : Bua.ink;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: dark ? Bua.green : Bua.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: dark ? BorderSide.none : const BorderSide(color: Bua.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, size: 16, color: dark ? Bua.greenOnDark : Bua.inkMuted),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: dark ? Bua.greenOnDark : Bua.inkMuted)),
                ),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3, color: fg)),
              ),
              if (dark)
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Text(action,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Bua.greenDark)),
                )
              else
                Text(action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Bua.green)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Composer extends ConsumerWidget {
  const _Composer({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final author = authorOf(ref, profile?.id ?? '');
    final me = profile?.personId == null ? null : ref.watch(graphProvider).value?[profile!.personId!];
    return Material(
      color: Bua.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Bua.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(children: [
            const SizedBox(width: 10),
            if (me != null) PersonAvatar(person: me, radius: 19) else AuthorAvatar(author, radius: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Text(context.l10n.shareMomentPrompt,
                  style: const TextStyle(fontSize: 15, color: Bua.inkSubtle), overflow: TextOverflow.ellipsis),
            ),
            const IconTile(Icons.photo_outlined, background: Bua.greenTint),
            const SizedBox(width: 8),
          ]),
        ),
      ),
    );
  }
}
