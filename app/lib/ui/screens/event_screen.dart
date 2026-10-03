import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';

String _utc(DateTime d) {
  final u = d.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year}${two(u.month)}${two(u.day)}T${two(u.hour)}${two(u.minute)}00Z';
}

/// Google Calendar "add event" link; works on phones and computers.
Uri calendarLink(FamilyEvent e) => Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': e.title,
      'dates': '${_utc(e.startsAt)}/${_utc(e.endsAt ?? e.startsAt.add(const Duration(hours: 2)))}',
      if (e.details != null) 'details': e.details!,
      if (e.place != null || e.address != null) 'location': [?e.place, ?e.address].join(', '),
    });

Uri mapsLink(FamilyEvent e) =>
    Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': [?e.place, ?e.address].join(', ')});

class EventScreen extends ConsumerWidget {
  const EventScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final events = ref.watch(eventsProvider);
    final event = events.value?.where((e) => e.id == eventId).firstOrNull;
    final profile = ref.watch(profileProvider);

    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: events.isLoading ? const Center(child: CircularProgressIndicator()) : Center(child: Text(l.noResults)),
      );
    }

    final host = authorOf(ref, event.createdBy);
    final isAdmin = profile?.isAdmin ?? false;
    final canDelete = event.createdBy == profile?.id || isAdmin;
    final upcoming = event.isUpcoming(DateTime.now());
    final timeRange = [
      l.clock(event.startsAt),
      if (event.endsAt != null) l.clock(event.endsAt!),
    ].join(' – ');

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        PatternBand(
          height: 210,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  BackButton(
                    color: Colors.white,
                    onPressed: () => context.canPop() ? context.pop() : context.go('/events'),
                  ),
                  const Spacer(),
                  if (canDelete || isAdmin)
                    PopupMenuButton<String>(
                      iconColor: Colors.white,
                      onSelected: (v) async {
                        final repo = ref.read(repositoryProvider);
                        if (v == 'pin') {
                          if (await guarded(context, () => repo.setPinned(eventId: event.id, pinned: !event.pinned))) {
                            ref.invalidate(eventsProvider);
                          }
                        } else if (v == 'delete') {
                          if (!await confirm(context, l.confirmDeleteEvent) || !context.mounted) return;
                          if (await guarded(context, () => repo.deleteEvent(event.id))) {
                            ref.invalidate(eventsProvider);
                            if (context.mounted) context.canPop() ? context.pop() : context.go('/events');
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        if (isAdmin) PopupMenuItem(value: 'pin', child: Text(event.pinned ? l.unpin : l.pinToHome)),
                        if (canDelete) PopupMenuItem(value: 'delete', child: Text(l.deleteEvent)),
                      ],
                    ),
                ]),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.eventCategory(event.category.name).toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Bua.goldOnDark)),
                    const SizedBox(height: 4),
                    Text(event.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                    if (host.name.isNotEmpty)
                      Text(l.hostedBy(host.name), style: const TextStyle(fontSize: 13, color: Bua.greenOnDark)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SectionCard(children: [
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                title: l.weekdayDate(event.startsAt),
                subtitle: timeRange,
                action: upcoming ? l.addToCalendar : null,
                onAction: () => launchUrl(calendarLink(event)),
              ),
              if (event.place != null || event.address != null) ...[
                const InsetDivider(indent: 66),
                _InfoRow(
                  icon: Icons.place_outlined,
                  title: event.place ?? event.address!,
                  subtitle: event.place == null ? null : event.address,
                  action: l.directions,
                  onAction: () => launchUrl(mapsLink(event)),
                ),
              ],
            ]),
            if (event.details?.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(event.details!, style: const TextStyle(fontSize: 15, height: 1.5)),
              ),
            ],
            if (event.rsvpEnabled && upcoming) ...[
              const SizedBox(height: 14),
              _RsvpCard(event: event),
            ],
            if (event.rsvpEnabled) ...[
              const SizedBox(height: 14),
              _Attendees(event: event),
            ],
            const SizedBox(height: 14),
            SectionCard(
              title: l.wishes,
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CommentThread(target: Target.event(event.id), hint: l.writeWish),
                ),
              ],
            ),
          ]),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, this.subtitle, this.action, this.onAction});

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(children: [
        IconTile(icon, background: Bua.greenTint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
          ]),
        ),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ]),
    );
  }
}

class _RsvpCard extends ConsumerStatefulWidget {
  const _RsvpCard({required this.event});

  final FamilyEvent event;

  @override
  ConsumerState<_RsvpCard> createState() => _RsvpCardState();
}

class _RsvpCardState extends ConsumerState<_RsvpCard> {
  RsvpResponse? _response;
  int? _guests;

  Future<void> _save(RsvpResponse response, int guests) async {
    setState(() {
      _response = response;
      _guests = guests;
    });
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).setRsvp(widget.event.id, response, guests: guests),
    );
    if (ok) ref.invalidate(eventsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final mine = widget.event.rsvpOf(ref.watch(profileProvider)?.id);
    final response = _response ?? mine?.response;
    final guests = _guests ?? mine?.guests ?? 0;

    Widget option(RsvpResponse r, String label) {
      final selected = response == r;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          child: Material(
            color: selected ? Bua.green : Bua.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _save(r, r == RsvpResponse.no ? 0 : guests),
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (selected) ...[const Icon(Icons.check, size: 18, color: Colors.white), const SizedBox(width: 6)],
                    Flexible(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : Bua.inkBody)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SectionCard(
      title: l.areYouComing,
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            option(RsvpResponse.going, l.rsvpGoing),
            const SizedBox(width: 8),
            option(RsvpResponse.maybe, l.rsvpMaybe),
            const SizedBox(width: 8),
            option(RsvpResponse.no, l.rsvpNo),
          ]),
        ),
        if (response == RsvpResponse.going || response == RsvpResponse.maybe)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(children: [
              Expanded(child: Text(l.bringingOthers, style: const TextStyle(fontSize: 14))),
              IconButton.outlined(
                tooltip: l.oneFewer,
                onPressed: guests == 0 ? null : () => _save(response!, guests - 1),
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 36,
                child: Text('$guests',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              IconButton.outlined(
                tooltip: l.oneMore,
                onPressed: guests >= 20 ? null : () => _save(response!, guests + 1),
                icon: const Icon(Icons.add),
              ),
            ]),
          ),
      ],
    );
  }
}

class _Attendees extends ConsumerWidget {
  const _Attendees({required this.event});

  final FamilyEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final going = event.rsvps.where((r) => r.response == RsvpResponse.going).toList();
    final maybe = event.rsvps.where((r) => r.response == RsvpResponse.maybe).toList();
    final title = [
      l.goingCount(event.headcount(RsvpResponse.going)),
      if (maybe.isNotEmpty) l.maybeCount(event.headcount(RsvpResponse.maybe)),
    ].join(' · ');
    final people = [...going, ...maybe];
    const max = 8;

    return SectionCard(
      title: title,
      trailing: people.isEmpty
          ? null
          : TextButton(onPressed: () => _showAll(context, ref, people), child: Text(l.seeAll)),
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
      children: [
        if (people.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Wrap(spacing: 2, runSpacing: 4, children: [
              for (final r in people.take(max))
                Container(
                  decoration: const BoxDecoration(color: Bua.surface, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(2),
                  child: AuthorAvatar(authorOf(ref, r.userId), radius: 18),
                ),
              if (people.length > max)
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Bua.surfaceMuted,
                  child: Text('+${people.length - max}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bua.inkMuted)),
                ),
            ]),
          ),
      ],
    );
  }

  void _showAll(BuildContext context, WidgetRef ref, List<Rsvp> people) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(children: [
        for (final r in people)
          Builder(builder: (context) {
            final a = authorOf(ref, r.userId);
            return ListTile(
              leading: AuthorAvatar(a),
              title: Text(a.name),
              subtitle: Text([
                r.response == RsvpResponse.going ? l.rsvpGoing : l.rsvpMaybe,
                if (r.guests > 0) '+${r.guests}',
              ].join(' · ')),
              onTap: a.person == null ? null : () => context.push('/person/${a.person!.id}'),
            );
          }),
      ]),
    );
  }
}
