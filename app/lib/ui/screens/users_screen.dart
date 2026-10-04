import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/claim_card.dart';
import 'join_screen.dart' show showInviteSheet;

enum UserFilter { all, waiting, claims, active, suspended, admins, treasurers, notLinked, noPush, inactive }

enum UserPlatform { any, android, web }

enum UserSort { newest, name, lastActive, mostActive }

/// Who matches the search box: name, email, phone or the linked person.
bool userMatches(UserRow u, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  // Phones are stored as 234…; people type 0803….
  var digits = q.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = digits.substring(1);
  return [u.profile.displayName, u.profile.email, u.personName].any((s) => s?.toLowerCase().contains(q) ?? false) ||
      (digits.length >= 4 && (u.profile.phone ?? '').contains(digits));
}

bool userInFilter(UserRow u, UserFilter f, DateTime now) {
  final p = u.profile;
  return switch (f) {
    UserFilter.all => true,
    UserFilter.waiting => p.status == AccountStatus.pending,
    UserFilter.claims => hasOpenClaim(p),
    UserFilter.active => p.status == AccountStatus.active,
    UserFilter.suspended => p.status == AccountStatus.suspended,
    UserFilter.admins => p.role == AppRole.admin,
    UserFilter.treasurers => p.isTreasurer,
    UserFilter.notLinked => p.personId == null,
    UserFilter.noPush => !u.hasPush,
    UserFilter.inactive => p.lastSeenAt == null || now.difference(p.lastSeenAt!) > const Duration(days: 30),
  };
}

bool userOnPlatform(UserRow u, UserPlatform platform) => switch (platform) {
      UserPlatform.any => true,
      UserPlatform.android => u.profile.lastPlatform == 'android' || (u.devices['android'] ?? 0) > 0,
      UserPlatform.web => u.profile.lastPlatform == 'web' || (u.devices['web'] ?? 0) > 0,
    };

int compareUsers(UserRow a, UserRow b, UserSort sort) {
  final far = DateTime(1900);
  return switch (sort) {
    UserSort.newest => (b.profile.createdAt ?? far).compareTo(a.profile.createdAt ?? far),
    UserSort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    UserSort.lastActive => (b.profile.lastSeenAt ?? far).compareTo(a.profile.lastSeenAt ?? far),
    UserSort.mostActive => b.activeDays30.compareTo(a.activeDays30) != 0
        ? b.activeDays30.compareTo(a.activeDays30)
        : (b.profile.lastSeenAt ?? far).compareTo(a.profile.lastSeenAt ?? far),
  };
}

/// Admin → Accounts: every account, searchable, filterable and sortable,
/// with the actions in a sheet.
class UsersView extends ConsumerStatefulWidget {
  const UsersView({super.key, this.now, this.initialFilter = UserFilter.all});

  /// For tests.
  final DateTime? now;

  /// E.g. claims, when opened from a claim notification.
  final UserFilter initialFilter;

  @override
  ConsumerState<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends ConsumerState<UsersView> {
  final _search = TextEditingController();
  late UserFilter _filter = widget.initialFilter;
  UserPlatform _platform = UserPlatform.any;
  UserSort _sort = UserSort.newest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _filterLabel(AppLocalizations l, UserFilter f) => switch (f) {
        UserFilter.all => l.filterAll,
        UserFilter.waiting => l.filterWaiting,
        UserFilter.claims => l.filterClaims,
        UserFilter.active => l.filterActive,
        UserFilter.suspended => l.filterSuspended,
        UserFilter.admins => l.filterAdmins,
        UserFilter.treasurers => l.filterTreasurers,
        UserFilter.notLinked => l.filterNotLinked,
        UserFilter.noPush => l.filterNoPush,
        UserFilter.inactive => l.filterInactive,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final users = ref.watch(adminUsersProvider);
    final now = widget.now ?? DateTime.now();

    return AsyncBody(
      value: users,
      onRetry: () => ref.invalidate(adminUsersProvider),
      builder: (all) {
        final searched = all.where((u) => userMatches(u, _search.text) && userOnPlatform(u, _platform)).toList();
        int count(UserFilter f) => searched.where((u) => userInFilter(u, f, now)).length;
        final shown = searched.where((u) => userInFilter(u, _filter, now)).toList()
          ..sort((a, b) => compareUsers(a, b, _sort));
        // People waiting for approval come first: they need an answer.
        final waiting = shown.where((u) => u.profile.status == AccountStatus.pending).toList();
        // Then members who say "this is me" about someone in the tree.
        final graph = ref.watch(graphProvider).value;
        final claims = [
          for (final u in shown)
            if (hasOpenClaim(u.profile) && graph?[u.profile.requestedPersonId!] != null) (u, graph![u.profile.requestedPersonId!]!),
        ];
        final others = shown
            .where((u) => u.profile.status != AccountStatus.pending && !claims.any((c) => c.$1.profile.id == u.profile.id))
            .toList();

        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Bua.inkMuted),
                hintText: l.searchUsers,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l.clear,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            )),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: l.inviteSomeone,
                onPressed: () => showInviteSheet(context),
                icon: const Icon(Icons.person_add_alt_1),
              ),
            ]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                for (final f in UserFilter.values)
                  if (f == UserFilter.all || f == _filter || count(f) > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${_filterLabel(l, f)} ${count(f)}'),
                        selected: _filter == f,
                        labelStyle: TextStyle(
                          color: _filter == f ? Colors.white : Bua.ink,
                          fontWeight: _filter == f ? FontWeight.w600 : FontWeight.w500,
                        ),
                        side: _filter == f ? BorderSide.none : const BorderSide(color: Bua.lineStrong),
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
            child: Row(children: [
              Expanded(
                child: Text(l.usersCount(shown.length), style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
              ),
              PopupMenuButton<UserPlatform>(
                tooltip: l.platformFilter,
                initialValue: _platform,
                onSelected: (v) => setState(() => _platform = v),
                itemBuilder: (_) => [
                  for (final p in UserPlatform.values)
                    CheckedPopupMenuItem(
                      value: p,
                      checked: _platform == p,
                      child: Text(switch (p) {
                        UserPlatform.any => l.platformAny,
                        UserPlatform.android => l.platformAndroid,
                        UserPlatform.web => l.platformWeb,
                      }),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.devices, size: 18, color: _platform == UserPlatform.any ? Bua.inkMuted : Bua.green),
                    const SizedBox(width: 4),
                    Text(
                      switch (_platform) {
                        UserPlatform.any => l.platformAny,
                        UserPlatform.android => l.platformAndroid,
                        UserPlatform.web => l.platformWeb,
                      },
                      style: const TextStyle(fontSize: 13),
                    ),
                  ]),
                ),
              ),
              PopupMenuButton<UserSort>(
                tooltip: l.sortBy,
                initialValue: _sort,
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => [
                  for (final s in UserSort.values)
                    CheckedPopupMenuItem(
                      value: s,
                      checked: _sort == s,
                      child: Text(switch (s) {
                        UserSort.newest => l.sortNewest,
                        UserSort.name => l.sortName,
                        UserSort.lastActive => l.sortLastActive,
                        UserSort.mostActive => l.sortMostActive,
                      }),
                    ),
                ],
                child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.sort, color: Bua.inkMuted)),
              ),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(adminUsersProvider.future),
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(l.noResults, textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkSubtle)),
                  ),
                for (final u in waiting) ...[_PendingCard(user: u), const SizedBox(height: 12)],
                for (final (u, person) in claims) ...[
                  ClaimCard(account: u.profile, person: person),
                  const SizedBox(height: 12),
                ],
                if (others.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      for (final (i, u) in others.indexed) ...[
                        if (i > 0) const InsetDivider(indent: 64),
                        _UserRowTile(user: u, now: now),
                      ],
                    ]),
                  ),
              ]),
            ),
          ),
        ]);
      },
    );
  }
}

/// Initials or the linked person's photo.
class _UserAvatar extends ConsumerWidget {
  const _UserAvatar({required this.user, this.size = 40});

  final UserRow user;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personId = user.profile.personId;
    final person = personId == null ? null : ref.watch(graphProvider).value?[personId];
    if (person != null) return PersonAvatar(person: person, radius: size / 2);
    final parts = user.name.trim().split(RegExp(r'\s+'));
    final initials = parts.take(2).map((s) => s.isEmpty ? '' : s[0].toUpperCase()).join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Bua.track, shape: BoxShape.circle),
      child: Text(initials,
          style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w700, color: Bua.unknownFg)),
    );
  }
}

String _seen(AppLocalizations l, UserRow u, DateTime now) =>
    u.profile.lastSeenAt == null ? l.neverSeen : l.lastSeen(l.ago(u.profile.lastSeenAt!, now: now));

class _UserRowTile extends StatelessWidget {
  const _UserRowTile({required this.user, required this.now});

  final UserRow user;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = user.profile;
    final platformIcon = switch (p.lastPlatform) {
      'android' => Icons.android,
      'web' => Icons.language,
      _ => null,
    };
    return InkWell(
      onTap: () => showUserSheet(context, user),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(children: [
          _UserAvatar(user: user),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
              Text(
                [user.personName ?? l.notLinked, _seen(l, user, now)].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: p.personId == null ? Bua.goldInk : Bua.inkSubtle),
              ),
            ]),
          ),
          if (platformIcon != null) ...[
            Icon(platformIcon, size: 16, color: Bua.inkSubtle),
            const SizedBox(width: 6),
          ],
          if (!user.hasPush && p.isActive) ...[
            const Icon(Icons.notifications_off_outlined, size: 16, color: Bua.inkSubtle),
            const SizedBox(width: 6),
          ],
          if (p.status == AccountStatus.suspended)
            Pill(l.filterSuspended, background: Bua.dangerTint, color: Bua.danger)
          else if (p.role == AppRole.admin)
            Pill(l.roleAdmin, background: Bua.green, color: Colors.white)
          else if (p.isTreasurer)
            Pill(l.treasurer, background: Bua.goldTint, color: Bua.goldInk),
        ]),
      ),
    );
  }
}

/// Someone waiting for approval: who they say they are, and approve.
class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.user});

  final UserRow user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = user.profile;
    final graph = ref.watch(graphProvider).value;
    final wants = p.requestedPersonId == null ? null : graph?[p.requestedPersonId!];
    final linked = p.personId == null ? null : graph?[p.personId!];
    final actions = _UserActions(context, ref, user);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Bua.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Bua.goldTint, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          _UserAvatar(user: user, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              if (p.email != null) Text(p.email!, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
            ]),
          ),
          Pill(l.filterWaiting, background: Bua.goldTint, color: Bua.goldInk),
        ]),
        if (p.claimNote?.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Bua.ground, borderRadius: BorderRadius.circular(12)),
            child: Text('“${p.claimNote}”',
                style: const TextStyle(fontSize: 14, height: 1.45, fontStyle: FontStyle.italic, color: Bua.inkBody)),
          ),
        ],
        if (wants != null || linked != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.link, size: 18, color: Bua.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(linked != null ? l.linkedTo(linked.displayName) : l.wantsToBe(wants!.displayName),
                  style: const TextStyle(fontSize: 13)),
            ),
          ]),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: actions.link,
              child: Text(wants != null || linked != null ? l.linkSomeoneElse : l.linkToPerson,
                  textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: () => wants != null && linked == null
                  ? actions.update(personId: wants.id, status: AccountStatus.active)
                  : actions.update(status: AccountStatus.active),
              child: Text(wants != null && linked == null ? l.approveAndLink : l.activate, textAlign: TextAlign.center),
            ),
          ),
        ]),
      ]),
    );
  }
}

/// What an admin can do to an account.
class _UserActions {
  _UserActions(this.context, this.ref, this.user);

  final BuildContext context;
  final WidgetRef ref;
  final UserRow user;

  void _refresh() {
    ref.invalidate(adminUsersProvider);
    ref.invalidate(profilesProvider);
  }

  Future<bool> update({AccountStatus? status, AppRole? role, String? personId}) async {
    final ok = await guarded(
      context,
      () => ref
          .read(repositoryProvider)
          .adminUpdateAccount(user.profile.id, status: status, role: role, personId: personId),
    );
    if (ok) _refresh();
    return ok;
  }

  Future<bool> link() async {
    final graph = ref.read(graphProvider).value;
    if (graph == null) return false;
    final person = await pickPerson(context, graph);
    return person == null ? false : update(personId: person.id);
  }

  Future<bool> treasurer() async {
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).setTreasurer(user.profile.id, !user.profile.isTreasurer),
    );
    if (ok) _refresh();
    return ok;
  }
}

/// Everything about one account, and what an admin can do with it.
Future<void> showUserSheet(BuildContext context, UserRow user) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Bua.ground,
      builder: (_) => _UserSheet(user: user),
    );

class _UserSheet extends ConsumerWidget {
  const _UserSheet({required this.user});

  final UserRow user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = user.profile;
    final me = ref.watch(profileProvider)?.id == p.id;
    final actions = _UserActions(context, ref, user);

    Future<void> run(Future<bool> Function() action) async {
      if (await action() && context.mounted) Navigator.pop(context);
    }

    Widget fact(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Icon(icon, size: 18, color: Bua.green),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          ]),
        );

    final devices = [
      if ((user.devices['android'] ?? 0) > 0) l.platformAndroid,
      if ((user.devices['web'] ?? 0) > 0) l.platformWeb,
      if ((user.devices['ios'] ?? 0) > 0) 'iPhone',
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            _UserAvatar(user: user, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                if (p.email != null) SelectableText(p.email!, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          fact(Icons.account_tree_outlined, user.personName == null ? l.notLinked : l.linkedTo(user.personName!)),
          if (p.phone != null) fact(Icons.phone_outlined, '+${p.phone}'),
          fact(Icons.schedule, _seen(l, user, DateTime.now())),
          fact(Icons.insights_outlined, l.activeDays(user.activeDays30)),
          fact(Icons.forum_outlined, l.postsAndComments(user.posts, user.comments)),
          fact(Icons.notifications_none, devices.isEmpty ? l.noPushDevices : l.pushOn(devices.join(', '))),
          if (p.appBuild != null) fact(Icons.android, l.androidVersionOf('1.0.${p.appBuild}')),
          if (p.createdAt != null) fact(Icons.person_add_alt, l.joinedOn(l.formatDate(p.createdAt!.toLocal()))),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: () => run(actions.link),
              icon: const Icon(Icons.link, size: 18),
              label: Text(p.personId == null ? l.linkToPerson : l.linkSomeoneElse),
            ),
            if (!me && p.status != AccountStatus.active)
              FilledButton.icon(
                onPressed: () => run(() => actions.update(status: AccountStatus.active)),
                icon: const Icon(Icons.check, size: 18),
                label: Text(l.activate),
              ),
            if (!me && p.status == AccountStatus.active) ...[
              OutlinedButton(
                onPressed: () => run(() => actions.update(role: p.role == AppRole.admin ? AppRole.member : AppRole.admin)),
                child: Text(p.role == AppRole.admin ? l.makeMember : l.makeAdmin),
              ),
              OutlinedButton(
                onPressed: () => run(actions.treasurer),
                child: Text(p.isTreasurer ? l.removeTreasurer : l.makeTreasurer),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Bua.danger),
                onPressed: () => run(() => actions.update(status: AccountStatus.suspended)),
                child: Text(l.suspend),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}
