import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';

enum _Tab { upcoming, announcements, past }

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key, this.now});

  /// For tests.
  final DateTime? now;

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  _Tab _tab = _Tab.upcoming;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = widget.now ?? DateTime.now();
    final events = ref.watch(eventsProvider);
    final announcements =
        ref.watch(feedProvider).value?.where((p) => p.kind == PostKind.announcement).toList() ?? const <Post>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: EdgeInsets.fromLTRB(sidebarAlwaysOpen(context) ? 20 : 8, 10, 12, 8),
            child: Row(children: [
              const SidebarButton(),
              Expanded(child: Text(l.navEvents, style: Theme.of(context).textTheme.titleLarge)),
              FilledButton.icon(
                onPressed: () => context.push(_tab == _Tab.announcements ? '/events/new?type=announcement' : '/events/new'),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.newLabel),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: PillSegmented<_Tab>(
                values: _Tab.values,
                height: 36,
                labelOf: (t) => switch (t) {
                  _Tab.upcoming => l.upcoming,
                  _Tab.announcements => l.announcements,
                  _Tab.past => l.past,
                },
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                ref.invalidate(feedProvider);
                return ref.refresh(eventsProvider.future);
              },
              child: AsyncBody(
                value: events,
                onRetry: () => ref.invalidate(eventsProvider),
                builder: (all) {
                  final upcoming = all.where((e) => e.isUpcoming(now)).toList();
                  final past = all.where((e) => !e.isUpcoming(now)).toList().reversed.toList();
                  Widget empty(String text) => Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(child: Text(text, style: const TextStyle(color: Bua.inkSubtle))),
                      );
                  return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: switch (_tab) {
                    _Tab.upcoming => [
                        if (upcoming.isEmpty) empty(l.noUpcomingEvents),
                        for (final e in upcoming) ...[EventCard(event: e), const SizedBox(height: 12)],
                        if (announcements.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          GroupHeading(l.latestAnnouncements),
                          const SizedBox(height: 8),
                          Container(
                            decoration:
                                BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
                            child: Column(children: [
                              for (final (i, a) in announcements.take(3).indexed) ...[
                                if (i > 0) const InsetDivider(indent: 66),
                                _AnnouncementRow(post: a),
                              ],
                            ]),
                          ),
                        ],
                      ],
                    _Tab.announcements => [
                        if (announcements.isEmpty) empty(l.noAnnouncements),
                        for (final a in announcements) ...[PostCard(post: a), const SizedBox(height: 12)],
                      ],
                    _Tab.past => [
                        if (past.isEmpty) empty(l.noPastEvents),
                        for (final e in past) ...[EventCard(event: e, past: true), const SizedBox(height: 12)],
                      ],
                  });
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AnnouncementRow extends ConsumerWidget {
  const _AnnouncementRow({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final author = authorOf(ref, post.authorId);
    return InkWell(
      onTap: () => showComments(context, Target.post(post.id), title: l.announcement),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const IconTile(Icons.campaign_outlined, background: Bua.goldTint, color: Bua.goldInk),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.35)),
              Text([author.name, l.ago(post.createdAt), if (post.pinned) l.pinned].join(' · '),
                  style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Date badge, title, time and place, and the viewer's reply.
class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.event, this.past = false});

  final FamilyEvent event;
  final bool past;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final mine = event.rsvpOf(ref.watch(profileProvider)?.id);
    final going = event.headcount(RsvpResponse.going);
    final maybe = event.headcount(RsvpResponse.maybe);
    final counts = [if (going > 0) l.goingCount(going), if (maybe > 0) l.maybeCount(maybe)].join(' · ');

    final Widget? status = past || !event.rsvpEnabled
        ? null
        : switch (mine?.response) {
            RsvpResponse.going => Pill(l.youreGoing, icon: Icons.check),
            RsvpResponse.maybe => Pill(l.youSaidMaybe, background: Bua.surfaceMuted, color: Bua.inkMuted),
            RsvpResponse.no => Pill(l.youCantGo, background: Bua.surfaceMuted, color: Bua.inkMuted),
            null => Pill(l.replyNeeded, background: Bua.goldTint, color: Bua.goldInk),
          };

    return Material(
      color: Bua.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/events/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 56,
              height: 60,
              decoration: BoxDecoration(
                color: past ? Bua.surfaceMuted : Bua.greenTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(l.monthShort(event.startsAt),
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: past ? Bua.inkMuted : Bua.green)),
                Text('${event.startsAt.day}',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: past ? Bua.inkMuted : Bua.greenDark)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text([l.dayClock(event.startsAt), ?event.place].join(' · '),
                    style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
                if (status != null || counts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    ?status,
                    if (counts.isNotEmpty)
                      Text(counts, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                  ]),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
