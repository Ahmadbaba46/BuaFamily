import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../models/family_graph.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/hijri.dart';
import '../widgets/hero_page.dart';
import '../widgets/share_sheet.dart';
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

    void back() => context.canPop() ? context.pop() : context.go('/events');
    final actions = <Widget>[
      IconButton(
        tooltip: l.shareLabel,
        icon: const Icon(Icons.share_outlined, color: Colors.white),
        onPressed: () => showShareSheet(
          context,
          link: shareLink('event', event.id, lang: Localizations.localeOf(context).languageCode),
          text: '${event.title} · ${l.weekdayDate(event.startsAt)}',
        ),
      ),
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
    ];

    // The band grows with the text size, so the title always fits.
    final band = 210 + (MediaQuery.textScalerOf(context).scale(24) - 24) * 3;
    return Scaffold(
      body: HeroPage(
        title: event.title,
        color: Bua.green,
        bandHeight: band,
        onBack: back,
        actions: actions,
        child: ListView(padding: EdgeInsets.zero, children: [
        PatternBand(
          height: band,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  BackButton(color: Colors.white, onPressed: back),
                  const Spacer(),
                  ...actions,
                ]),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.eventCategory(event.category.name).toUpperCase(),
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Bua.goldOnDark)),
                    const SizedBox(height: 4),
                    Text(event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                    if (host.name.isNotEmpty)
                      Text(l.hostedBy(host.name), style: TextStyle(fontSize: 13, color: Bua.greenOnDark)),
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
                subtitle: [timeRange, ?hijriFor(ref, l, event.startsAt)].join('\n'),
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
            // From the day itself: who came, and the photos.
            if (!DateTime.now().isBefore(event.startsAt.subtract(const Duration(hours: 6)))) ...[
              const SizedBox(height: 14),
              _WhoCame(event: event),
              const SizedBox(height: 14),
              _EventPhotos(event: event),
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
      ),
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
            if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 13, color: Bua.inkSubtle)),
          ]),
        ),
        if (action != null)
          Flexible(child: TextButton(onPressed: onAction, child: Text(action!, textAlign: TextAlign.center))),
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
                  decoration: BoxDecoration(color: Bua.surface, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(2),
                  child: AuthorAvatar(authorOf(ref, r.userId), radius: 18),
                ),
              if (people.length > max)
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Bua.surfaceMuted,
                  child: Text('+${people.length - max}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bua.inkMuted)),
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

/// Who came, by person in the tree. Members mark themselves; the host and
/// admins mark anyone (children and elders without the app too).
class _WhoCame extends ConsumerWidget {
  const _WhoCame({required this.event});

  final FamilyEvent event;

  Future<void> _set(BuildContext context, WidgetRef ref, {Set<String> add = const {}, Set<String> remove = const {}}) async {
    final ok = await guarded(
        context, () => ref.read(repositoryProvider).setAttendance(event.id, add: add, remove: remove));
    if (ok) ref.invalidate(eventAttendanceProvider(event.id));
  }

  Future<void> _markMany(BuildContext context, WidgetRef ref, List<String> current) async {
    final graph = ref.read(graphProvider).value;
    if (graph == null) return;
    final chosen = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PeoplePicker(graph: graph, initial: current.toSet()),
    );
    if (chosen == null || !context.mounted) return;
    await _set(context, ref, add: chosen.difference(current.toSet()), remove: current.toSet().difference(chosen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider);
    final me = profile?.personId;
    final graph = ref.watch(graphProvider).value;
    final came = ref.watch(eventAttendanceProvider(event.id));
    final ids = came.value ?? const <String>[];
    final people = [for (final id in ids) ?graph?[id]]..sort((a, b) => a.displayName.compareTo(b.displayName));
    final canMarkOthers = event.createdBy == profile?.id || (profile?.isAdmin ?? false);
    final iCame = me != null && ids.contains(me);

    return SectionCard(
      title: ids.isEmpty ? l.whoCame : l.whoCameCount(ids.length),
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (came.isLoading && !came.hasValue)
          const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator(minHeight: 2))
        else if (people.isEmpty)
          Text(l.noOneMarkedYet, style: TextStyle(fontSize: 14, color: Bua.inkSubtle))
        else
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final p in people)
              Tooltip(
                message: p.displayName,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.push('/person/${p.id}'),
                  child: PersonAvatar(person: p, radius: 18),
                ),
              ),
          ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (me != null && !iCame)
            FilledButton.icon(
              onPressed: () => _set(context, ref, add: {me}),
              icon: const Icon(Icons.how_to_reg_outlined, size: 18),
              label: Text(l.imHere),
            ),
          if (iCame) ...[
            Text(l.youCame, style: TextStyle(fontSize: 14, color: Bua.greenDark)),
            TextButton(onPressed: () => _set(context, ref, remove: {me}), child: Text(l.undoLabel)),
          ],
          if (canMarkOthers)
            OutlinedButton.icon(
              onPressed: () => _markMany(context, ref, ids),
              icon: const Icon(Icons.checklist, size: 18),
              label: Text(l.markWhoCame),
            ),
        ]),
      ]),
        ),
      ],
    );
  }
}

/// Tick everyone who came; returns the chosen ids, or null if closed.
class _PeoplePicker extends StatefulWidget {
  const _PeoplePicker({required this.graph, required this.initial});

  final FamilyGraph graph;
  final Set<String> initial;

  @override
  State<_PeoplePicker> createState() => _PeoplePickerState();
}

class _PeoplePickerState extends State<_PeoplePicker> {
  late final Set<String> _chosen = {...widget.initial};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final people = widget.graph.familyOrder().where((p) => p.isLiving && p.matches(_query)).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      builder: (context, scroll) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(l.markWhoCame, style: Theme.of(context).textTheme.titleLarge)),
              FilledButton(onPressed: () => Navigator.pop(context, _chosen), child: Text(l.save)),
            ]),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchByName),
              onChanged: (v) => setState(() => _query = v),
            ),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            controller: scroll,
            itemCount: people.length,
            itemBuilder: (_, i) {
              final p = people[i];
              return CheckboxListTile(
                value: _chosen.contains(p.id),
                onChanged: (v) => setState(() => v == true ? _chosen.add(p.id) : _chosen.remove(p.id)),
                secondary: PersonAvatar(person: p, radius: 18),
                title: Text(p.displayName),
                subtitle: p.branch == null ? null : Text(p.branch!),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// The event's own album: a strip of photos and a way to add more.
class _EventPhotos extends ConsumerWidget {
  const _EventPhotos({required this.event});

  final FamilyEvent event;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    String? albumId;
    final ok = await guarded(context, () async => albumId = await ref.read(repositoryProvider).eventAlbum(event.id));
    if (!ok || albumId == null || !context.mounted) return;
    ref.invalidate(albumsProvider);
    context.push('/new-moment?album=$albumId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final album = ref.watch(albumsProvider).value?.where((a) => a.eventId == event.id).firstOrNull;
    final photos = album == null ? const <Photo>[] : ref.watch(albumPhotosProvider(album.id)).value ?? const <Photo>[];
    return SectionCard(
      title: l.eventPhotosTitle,
      trailing: album == null || photos.isEmpty
          ? null
          : TextButton(onPressed: () => context.push('/albums/${album.id}'), child: Text(l.seeAll)),
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (photos.isEmpty)
          Text(l.eventPhotosHint, style: TextStyle(fontSize: 14, color: Bua.inkSubtle))
        else
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 96,
                  child: GestureDetector(
                    onTap: () => context.push('/photo/${photos[i].id}?album=${album!.id}'),
                    child: StoragePhoto(photos[i].storagePath, placeholder: const Color(0xFFE8DDC8)),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () => _add(context, ref),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text(l.addPhotos),
          ),
        ),
      ]),
        ),
      ],
    );
  }
}
