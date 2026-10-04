import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/activity.dart';
import '../../models/family_graph.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';

final adminOnlineProvider =
    FutureProvider.autoDispose<List<OnlineEntry>>((ref) => ref.watch(repositoryProvider).adminOnline());

/// A page's name as people say it: "Home", "Aisha Bua's page", "Welfare fund".
String pageLabel(AppLocalizations l, String path, FamilyGraph? graph) {
  final parts = path.split('/').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return l.pageHome;
  final id = parts.length > 1 ? parts[1] : null;
  return switch (parts.first) {
    'home' => l.pageHome,
    'tree' => l.navTree,
    'members' => l.navMembers,
    'person' => graph?[id ?? ''] == null ? l.pageAPerson : l.pagePerson(graph![id!]!.displayName),
    'events' => id == null || id == 'new' ? l.navEvents : l.pageAnEvent,
    'posts' || 'new-moment' => l.pageAMoment,
    'albums' => id == null ? l.albums : l.pageAnAlbum,
    'photo' => l.pageAPhoto,
    'fund' => l.welfareFund,
    'blood' => l.bloodDonors,
    'mentors' => id == null ? l.mentorsTitle : l.pageAConversation,
    'polls' => l.pollsTitle,
    'stories' => l.storiesTitle,
    'notifications' => l.notifications,
    'settings' => l.settingsScreen,
    'more' => l.navMore,
    'related' => l.howRelated,
    'help' => l.whoCanHelp,
    'reminders' => l.remindersTitle,
    'about' => l.aboutTitle,
    'get-app' => l.getTheApp,
    'me' => l.editMyDetails,
    'my-requests' => l.myRequests,
    'sign-in' => l.pageSignIn,
    'admin' => switch (id) {
        'metrics' => l.metricsTitle,
        'activity' => l.activityTitle,
        'tree-check' => l.checkTree,
        'data' || 'import' || 'restore' => l.dataTitle,
        _ => l.navAdmin,
      },
    _ => path,
  };
}

String _thing(AppLocalizations l, ActivityEntry e) => switch (e.entity) {
      'persons' => l.entPerson,
      'unions' || 'parent_child' => l.entRelationship,
      'change_requests' => l.entSuggestion,
      'albums' => l.entAlbum,
      'posts' => e.str('kind') == 'announcement' ? l.entAnnouncement : l.entPost,
      'photos' => l.entPhoto,
      'events' => l.entEvent,
      'comments' => l.entComment,
      'blood_requests' => l.entBloodRequest,
      'blood_offers' => l.entBloodOffer,
      'memories' => l.entMemory,
      'fund_causes' => l.entCause,
      'fund_contributions' => l.entContribution,
      'fund_payouts' => l.entPayout,
      'mentors' => l.entMentor,
      'mentee_requests' => l.entStudent,
      'opportunities' => l.entOpportunity,
      'polls' => l.entPoll,
      'stories' => l.entStory,
      'invites' => l.entInvite,
      _ => l.entOther,
    };

/// What someone did, after their name: "added a moment", "opened Home".
String describeActivity(AppLocalizations l, ActivityEntry e, FamilyGraph? graph) {
  if (e.entity == 'session') {
    return switch (e.action) { 'sign_in' => l.actSignedIn, 'sign_out' => l.actSignedOut, _ => l.actOpenedApp };
  }
  if (e.entity == 'page') return l.actViewed(pageLabel(l, e.target ?? '', graph));
  return switch ((e.entity, e.action)) {
    ('likes', 'delete') => l.actUnliked,
    ('likes', _) => l.actLiked,
    ('event_rsvps', 'delete') => l.actRemoved(l.entEvent),
    ('event_rsvps', _) => l.actRsvp,
    ('poll_votes', _) => l.actVoted,
    ('change_requests', 'update') => l.actReviewed,
    ('profiles', _) => l.actAccount,
    ('app_settings', _) => l.actSettings,
    ('mentor_asks', 'insert') => l.actMentorAsk,
    ('mentor_messages', 'insert') => l.actMentorMessage,
    ('fund_contributions', 'update') when e.str('status') == 'confirmed' => l.actConfirmed,
    (_, 'insert') => l.actAdded(_thing(l, e)),
    (_, 'delete') => l.actRemoved(_thing(l, e)),
    _ => l.actChanged(_thing(l, e)),
  };
}

/// Where tapping an entry goes, if anywhere.
String? activityLink(ActivityEntry e) {
  if (e.entity == 'page') return e.target;
  if (e.action == 'delete' && e.entity != 'likes') return null;
  final post = e.str('post_id');
  final event = e.str('event_id');
  final person = e.str('person_id');
  return switch (e.entity) {
    'persons' => '/person/${e.target}',
    'unions' || 'parent_child' || 'memories' || 'change_requests' => person == null ? null : '/person/$person',
    'posts' => '/posts/${e.target}',
    'comments' || 'likes' => post != null ? '/posts/$post' : (event != null ? '/events/$event' : null),
    'photos' => '/photo/${e.target}',
    'albums' => '/albums/${e.target}',
    'events' => '/events/${e.target}',
    'event_rsvps' => event == null ? null : '/events/$event',
    'polls' || 'poll_votes' => '/polls',
    'blood_requests' || 'blood_offers' => '/blood',
    'fund_causes' => '/fund/cause/${e.target}',
    'fund_contributions' || 'fund_payouts' => '/fund',
    'mentors' || 'mentee_requests' || 'opportunities' => '/mentors',
    'stories' => '/stories',
    _ => null,
  };
}

/// "12 min", "1 h 5 min".
String durationLabel(AppLocalizations l, Duration d) {
  final m = d.inMinutes;
  return m < 60 ? l.minutesShort(m < 1 ? 1 : m) : l.hoursShort(m ~/ 60, m % 60);
}

/// Admin: who has the app open, and what members did.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final online = ref.watch(adminOnlineProvider).value?.where((o) => o.online).length ?? 0;
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/admin')),
          titleSpacing: 0,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.activityTitle, style: Theme.of(context).textTheme.titleLarge),
            Text(l.activitySub, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Bua.inkSubtle)),
          ]),
          bottom: TabBar(tabs: [
            Tab(text: online > 0 ? '${l.tabOnline} · $online' : l.tabOnline),
            Tab(text: l.tabActivityLog),
          ]),
        ),
        body: const TabBarView(children: [OnlineView(), ActivityLogView()]),
      ),
    );
  }
}

/// Members with the app open now, then those seen earlier today.
class OnlineView extends ConsumerStatefulWidget {
  const OnlineView({super.key, this.now});

  /// For tests.
  final DateTime? now;

  @override
  ConsumerState<OnlineView> createState() => _OnlineViewState();
}

class _OnlineViewState extends ConsumerState<OnlineView> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(const Duration(seconds: 20), (_) => ref.invalidate(adminOnlineProvider));
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final graph = ref.watch(graphProvider).value;
    final list = ref.watch(adminOnlineProvider);
    final now = widget.now ?? DateTime.now();

    Widget row(OnlineEntry o) {
      final person = o.personId == null ? null : graph?[o.personId!];
      final where = [
        o.platform == 'android' ? l.platformAndroidShort : l.platformWebShort,
        if (o.page != null) l.onPage(pageLabel(l, o.page!, graph)),
        o.online ? l.onlineFor(durationLabel(l, now.difference(o.startedAt))) : l.seenAgo(l.ago(o.seenAt, now: now)),
      ].join(' · ');
      return ListTile(
        leading: Stack(clipBehavior: Clip.none, children: [
          person != null ? PersonAvatar(person: person, radius: 20) : CircleAvatar(radius: 20, child: Text(o.name.isEmpty ? '?' : o.name[0])),
          if (o.online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: Bua.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Bua.surface, width: 2),
                ),
              ),
            ),
        ]),
        title: Text(o.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(where),
        trailing: Icon(o.platform == 'android' ? Icons.phone_android : Icons.language, size: 18, color: Bua.inkSubtle),
        onTap: o.page == null || !o.online ? null : () => context.push(o.page!),
      );
    }

    Widget group(String title, List<OnlineEntry> rows) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GroupHeading(title),
          const SizedBox(height: 8),
          Material(
            color: Bua.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (final (i, o) in rows.indexed) ...[
                if (i > 0) const InsetDivider(indent: 70),
                row(o),
              ],
            ]),
          ),
          const SizedBox(height: 16),
        ]);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminOnlineProvider.future),
      child: AsyncBody(
        value: list,
        onRetry: () => ref.invalidate(adminOnlineProvider),
        builder: (all) {
          final now_ = all.where((o) => o.online).toList();
          final earlier = all.where((o) => !o.online).toList();
          return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
            if (now_.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(children: [
                  Icon(Icons.bedtime_outlined, size: 40, color: Bua.inkSubtle),
                  const SizedBox(height: 8),
                  Text(l.nobodyOnline, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkSubtle)),
                ]),
              )
            else
              group(l.onlineNow, now_),
            if (earlier.isNotEmpty) group(l.earlierToday, earlier),
          ]);
        },
      ),
    );
  }
}

/// Everything members did, newest first, with filters and search.
class ActivityLogView extends ConsumerStatefulWidget {
  const ActivityLogView({super.key, this.now});

  /// For tests.
  final DateTime? now;

  @override
  ConsumerState<ActivityLogView> createState() => _ActivityLogViewState();
}

enum _Since { today, d7, d30, any }

class _ActivityLogViewState extends ConsumerState<ActivityLogView> {
  final _search = TextEditingController();
  Timer? _debounce;
  ActivityQuery _query = const ActivityQuery();
  _Since _since = _Since.d7;
  final List<ActivityEntry> _rows = [];
  bool _loading = false;
  bool _more = true;
  Object? _error;
  int _generation = 0;

  static const _page = 50;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _query = _query.copyWith(from: () => _fromFor(_since));
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  DateTime? _fromFor(_Since s) {
    final today = DateTime(_now.year, _now.month, _now.day);
    return switch (s) {
      _Since.today => today,
      _Since.d7 => today.subtract(const Duration(days: 6)),
      _Since.d30 => today.subtract(const Duration(days: 29)),
      _Since.any => null,
    };
  }

  Future<void> _load({bool reset = false}) async {
    final gen = reset ? ++_generation : _generation;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _rows.clear();
        _more = true;
      }
    });
    try {
      final next = await ref
          .read(repositoryProvider)
          .adminActivity(_query, before: reset || _rows.isEmpty ? null : _rows.last.id, limit: _page);
      if (!mounted || gen != _generation) return;
      setState(() {
        _rows.addAll(next);
        _more = next.length == _page;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _set(ActivityQuery q) {
    if (q == _query) return;
    _query = q;
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final graph = ref.watch(graphProvider).value;
    final users = ref.watch(adminUsersProvider).value ?? const [];

    final who = users.where((u) => u.profile.id == _query.userId).firstOrNull;
    final byDay = <DateTime, List<ActivityEntry>>{};
    for (final e in _rows) {
      byDay.putIfAbsent(DateTime(e.at.year, e.at.month, e.at.day), () => []).add(e);
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
        TextField(
          controller: _search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l.logSearch,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
          ),
          onChanged: (v) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 400), () => _set(_query.copyWith(search: v)));
          },
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final t in ActivityType.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(switch (t) {
                    ActivityType.all => l.logAll,
                    ActivityType.changes => l.logChanges,
                    ActivityType.pages => l.logPages,
                    ActivityType.sessions => l.logSessions,
                  }),
                  selected: _query.type == t,
                  labelStyle: TextStyle(color: _query.type == t ? Colors.white : Bua.ink, fontWeight: FontWeight.w500),
                  onSelected: (_) => _set(_query.copyWith(type: t)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: PillSegmented<_Since>(
            values: _Since.values,
            labelOf: (s) => switch (s) {
              _Since.today => l.logToday,
              _Since.d7 => l.log7,
              _Since.d30 => l.log30,
              _Since.any => l.logAnyTime,
            },
            selected: _since,
            height: 34,
              onChanged: (s) {
                setState(() => _since = s);
                _set(_query.copyWith(from: () => _fromFor(s)));
              },
            ),
          ),
          PopupMenuButton<String?>(
            initialValue: _query.userId,
            onSelected: (id) => _set(_query.copyWith(userId: () => id)),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: null, checked: _query.userId == null, child: Text(l.logAnyone)),
              for (final u in [...users]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())))
                CheckedPopupMenuItem(value: u.profile.id, checked: _query.userId == u.profile.id, child: Text(u.name)),
            ],
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Bua.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: who == null ? Bua.lineStrong : Bua.green),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_outline, size: 16, color: who == null ? Bua.inkMuted : Bua.green),
                const SizedBox(width: 6),
                Text(who?.name ?? l.logAnyone, style: const TextStyle(fontSize: 13)),
                Icon(Icons.arrow_drop_down, size: 18, color: Bua.inkMuted),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(l.logPrivacyNote, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
        const SizedBox(height: 12),
        if (_error != null && _rows.isEmpty)
          Center(
            child: TextButton.icon(
              onPressed: () => _load(reset: true),
              icon: const Icon(Icons.refresh),
              label: Text(errorText(_error!)),
            ),
          )
        else if (_rows.isEmpty && !_loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(l.logEmpty, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkSubtle)),
          ),
        for (final day in byDay.entries) ...[
          GroupHeading(l.weekdayDate(day.key)),
          const SizedBox(height: 8),
          Material(
            color: Bua.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (final (i, e) in day.value.indexed) ...[
                if (i > 0) const InsetDivider(indent: 66),
                _LogRow(entry: e, graph: graph),
              ],
            ]),
          ),
          const SizedBox(height: 14),
        ],
        if (_loading)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
        else if (_more && _rows.isNotEmpty)
          Center(child: OutlinedButton(onPressed: _load, child: Text(l.loadMore))),
      ]),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry, required this.graph});

  final ActivityEntry entry;
  final FamilyGraph? graph;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = entry;
    final person = e.personId == null ? null : graph?[e.personId!];
    final link = activityLink(e);
    final label = e.label;
    return ListTile(
      leading: person != null
          ? PersonAvatar(person: person, radius: 18)
          : CircleAvatar(radius: 18, child: Text(e.name.isEmpty ? '?' : e.name[0])),
      title: Text.rich(TextSpan(children: [
        TextSpan(text: e.name.isEmpty ? '—' : e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        TextSpan(text: ' ${describeActivity(l, e, graph)}'),
      ])),
      subtitle: Text(
        [
          if (label != null && label.isNotEmpty) '“$label”',
          l.clock(e.at),
          if (e.platform != null) e.platform == 'android' ? l.platformAndroidShort : l.platformWebShort,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: link == null ? null : Icon(Icons.chevron_right, color: Bua.inkSubtle),
      onTap: link == null ? null : () => context.push(link),
    );
  }
}
