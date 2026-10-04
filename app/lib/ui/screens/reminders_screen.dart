import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/kinship.dart';
import '../../l10n/l10n.dart';
import '../../models/family_graph.dart';
import '../../models/hijri.dart';
import '../../models/person.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/hijri.dart';

enum _Kind { birthday, remembrance, wedding, event }

class _Item {
  _Item({
    required this.date,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.person,
    this.action,
    this.onAction,
  });

  final DateTime date;
  final _Kind kind;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Person? person;
  final String? action;
  final VoidCallback? onAction;
}

/// Birthdays, death anniversaries, wedding anniversaries and events over the
/// next month.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key, this.now});

  /// For tests.
  final DateTime? now;

  static DateTime _next(DateTime from, DateTime d) {
    final thisYear = DateTime(from.year, d.month, d.day);
    return thisYear.isBefore(from) ? DateTime(from.year + 1, d.month, d.day) : thisYear;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final end = today.add(const Duration(days: 31));
    final graph = ref.watch(graphProvider).value;
    final events = ref.watch(eventsProvider).value ?? const <FamilyEvent>[];
    final me = ref.watch(profileProvider);
    final myId = me?.personId;

    String rel(String kind, Person p) {
      if (graph == null || myId == null || p.id == myId) return kind;
      final k = kinshipOf(graph, myId, p.id);
      return k.type == KinType.none ? kind : '$kind · ${l.kinshipToYou(k)}';
    }

    final items = <_Item>[];
    if (graph != null) {
      for (final p in graph.persons.values) {
        if (p.isLiving && p.birthDate != null && !p.birthDateApprox) {
          final d = _next(today, p.birthDate!);
          if (d.isBefore(end) && d.year > p.birthDate!.year) {
            items.add(_Item(
              date: d,
              kind: _Kind.birthday,
              person: p,
              title: l.turnsAge(p.displayName, d.year - p.birthDate!.year),
              subtitle: rel(l.kindBirthday, p),
              onTap: () => context.push('/person/${p.id}'),
              action: d == today ? l.greet : null,
              onAction: () => context.push('/new-moment?tag=${p.id}'),
            ));
          }
        }
        if (!p.isLiving && p.deathDate != null && !p.deathDateApprox) {
          final d = _next(today, p.deathDate!);
          if (d.isBefore(end) && d.year > p.deathDate!.year) {
            items.add(_Item(
              date: d,
              kind: _Kind.remembrance,
              person: p,
              title: l.yearsSincePassed(d.year - p.deathDate!.year, p.displayName),
              subtitle: rel(l.remembrance, p),
              onTap: () => context.push('/person/${p.id}/memorial'),
              action: d == today ? l.pray : null,
              onAction: () => context.push('/person/${p.id}/memorial'),
            ));
          }
        }
      }
      for (final u in graph.unions) {
        final a = graph[u.partner1Id];
        final b = graph[u.partner2Id];
        if (u.status != UnionStatus.married || u.startDate == null || a == null || b == null) continue;
        if (!a.isLiving || !b.isLiving) continue;
        final d = _next(today, u.startDate!);
        if (!d.isBefore(end) || d.year <= u.startDate!.year) continue;
        items.add(_Item(
          date: d,
          kind: _Kind.wedding,
          title: l.yearsMarried('${a.firstName} & ${b.firstName}', d.year - u.startDate!.year),
          subtitle: l.kindWedding,
          onTap: () => context.push('/person/${a.id}'),
        ));
      }
    }
    for (final e in events) {
      final d = DateTime(e.startsAt.year, e.startsAt.month, e.startsAt.day);
      if (d.isBefore(today) || !d.isBefore(end)) continue;
      final going = e.rsvpOf(me?.id)?.response == RsvpResponse.going;
      items.add(_Item(
        date: d,
        kind: _Kind.event,
        title: e.title,
        subtitle: '${l.event} · ${going ? l.youreGoing.toLowerCase() : [l.clock(e.startsAt), ?e.place].join(' · ')}',
        onTap: () => context.push('/events/${e.id}'),
      ));
    }
    items.sort((a, b) => a.date.compareTo(b.date));

    final todays = items.where((i) => i.date == today).toList();
    final week = items.where((i) => i.date.isAfter(today) && i.date.difference(today).inDays <= 7).toList();
    final later = items.where((i) => i.date.difference(today).inDays > 7).toList();

    Widget group(String title, List<_Item> rows, {bool showDate = true}) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupHeading(title),
            const SizedBox(height: 8),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                for (final (i, item) in rows.indexed) ...[
                  if (i > 0) const InsetDivider(indent: 72),
                  _ItemRow(item: item, showDate: showDate, near: title == l.thisWeek),
                ],
              ]),
            ),
            const SizedBox(height: 16),
          ],
        );

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
        titleSpacing: 0,
        title: Text(l.remindersTitle, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            tooltip: l.settingsScreen,
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        if (todays.isNotEmpty) group(l.todayDate(l.weekdayDate(today)), todays, showDate: false),
        if (week.isNotEmpty) group(l.thisWeek, week),
        if (later.isNotEmpty) group(l.comingUp, later),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(l.nothingComingUp, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkSubtle)),
          ),
        _IslamicOccasions(today: today),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(l.remindersNote, style: TextStyle(fontSize: 12, height: 1.45, color: Bua.inkSubtle)),
        ),
      ]),
    );
  }
}

/// The coming Islamic occasions, with both dates and a countdown.
class _IslamicOccasions extends ConsumerWidget {
  const _IslamicOccasions({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final offset = ref.watch(hijriOffsetProvider);
    final list = Occasion.upcoming(today, offset: offset);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GroupHeading(l.islamicOccasions),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(l.hijriDate(HijriDate.fromDate(today, offset: offset)),
            style: TextStyle(fontSize: 13, color: Bua.inkMuted)),
      ),
      const SizedBox(height: 8),
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          for (final (i, (o, date)) in list.indexed) ...[
            if (i > 0) const InsetDivider(indent: 66),
            ListTile(
              leading: IconTile(
                o.greet ? Icons.nightlight_round : Icons.brightness_3_outlined,
                background: o.greet ? Bua.greenTint : Bua.ground,
              ),
              title: Text(l.occasionName(o), style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${l.weekdayDate(date)} · ${l.hijriDate(HijriDate.fromDate(date, offset: offset))}',
              ),
              trailing: Text(
                l.inDaysCount(date.difference(today).inDays),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: date.difference(today).inDays <= 7 ? Bua.green : Bua.inkSubtle,
                ),
              ),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(l.moonNote, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
      ),
      const SizedBox(height: 16),
    ]);
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.showDate, required this.near});

  final _Item item;
  final bool showDate;
  final bool near;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (bg, fg) = switch (item.kind) {
      _Kind.birthday => (Bua.greenTint, Bua.greenDark),
      _Kind.remembrance => (Bua.track, Bua.memorial),
      _Kind.wedding => (Bua.goldTint, Bua.goldInk),
      _Kind.event => (Bua.surfaceMuted, Bua.inkMuted),
    };
    final Widget lead = !showDate && item.person != null
        ? PersonAvatar(person: item.person!, radius: 22)
        : Container(
            width: 46,
            height: 48,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(near ? l.weekdayShort(item.date) : l.monthShort(item.date),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
              Text('${item.date.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg)),
            ]),
          );
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(children: [
          lead,
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(item.subtitle, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
            ]),
          ),
          if (item.action != null)
            item.kind == _Kind.birthday
                ? FilledButton(
                    onPressed: item.onAction,
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                    child: Text(item.action!),
                  )
                : TextButton(onPressed: item.onAction, child: Text(item.action!)),
        ]),
      ),
    );
  }
}

