import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/kinship.dart';
import '../../l10n/l10n.dart';
import '../../models/family_graph.dart';
import '../../models/person.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/common.dart';

enum _Filter { all, living, deceased }

enum _Sort { name, oldest, youngest, family }

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;
  _Sort _sort = _Sort.name;

  /// Admins: people picked to delete together (selecting when non-null).
  Set<String>? _selected;

  void _toggle(String id) => setState(() {
        final s = _selected ??= {};
        if (!s.remove(id)) s.add(id);
        if (s.isEmpty) _selected = null;
      });

  Future<void> _deleteOne(Person p) async {
    final l = context.l10n;
    if (!await confirm(context, l.confirmDeletePerson(p.displayName)) || !mounted) return;
    if (await guarded(context, () => ref.read(repositoryProvider).deletePerson(p.id))) ref.invalidate(graphProvider);
  }

  Future<void> _deleteSelected(FamilyGraph graph) async {
    final l = context.l10n;
    final ids = _selected?.toList() ?? const <String>[];
    if (ids.isEmpty) return;
    final names = [for (final id in ids.take(5)) graph[id]?.displayName ?? '?'];
    final more = ids.length - names.length;
    if (!await confirm(context, l.confirmDeletePeople(ids.length, [...names, if (more > 0) l.andMore(more)].join(', '))) ||
        !mounted) {
      return;
    }
    final repo = ref.read(repositoryProvider);
    var done = 0;
    Object? error;
    for (final id in ids) {
      try {
        await repo.deletePerson(id);
        done++;
      } catch (e) {
        error ??= e;
      }
    }
    if (!mounted) return;
    ref.invalidate(graphProvider);
    setState(() => _selected = null);
    if (error != null) {
      showError(context, error);
    } else {
      showSnack(context, l.peopleDeleted(done));
    }
  }

  Widget? _adminTrailing(Person p, {required bool isMe}) {
    final l = context.l10n;
    if (_selected != null) {
      return isMe
          ? null
          : Checkbox(value: _selected!.contains(p.id), onChanged: (_) => _toggle(p.id));
    }
    return PopupMenuButton<String>(
      tooltip: l.personOptions,
      icon: Icon(Icons.more_vert, color: Bua.inkSubtle),
      onSelected: (v) => switch (v) {
        'edit' => context.push('/person/${p.id}/edit'),
        'select' => _toggle(p.id),
        _ => _deleteOne(p),
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'edit', child: Text(l.editPerson)),
        if (!isMe) PopupMenuItem(value: 'select', child: Text(l.selectSeveral)),
        if (!isMe) PopupMenuItem(value: 'delete', child: Text(l.deletePerson)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final graphAsync = ref.watch(graphProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final myId = ref.watch(profileProvider)?.personId;

    return Scaffold(
      floatingActionButton: isAdmin && _selected == null
          ? FloatingActionButton(
              tooltip: l.newPerson,
              onPressed: () => context.push('/new-person'),
              child: const Icon(Icons.person_add_alt_1),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: AsyncBody(
          value: graphAsync,
          onRetry: () => ref.invalidate(graphProvider),
          builder: (graph) {
            final matches = graph.search(_query).map((p) => p.id).toSet();
            final ordered = switch (_sort) {
              _Sort.name => graph.search(_query),
              _Sort.family => graph.familyOrder(),
              _Sort.oldest || _Sort.youngest => graph.search(_query)
                ..sort((a, b) {
                  // Unknown birth dates last either way.
                  if (a.birthDate == null || b.birthDate == null) {
                    return (a.birthDate == null ? 1 : 0) - (b.birthDate == null ? 1 : 0);
                  }
                  final c = a.birthDate!.compareTo(b.birthDate!);
                  return _sort == _Sort.oldest ? c : -c;
                }),
            };
            final people = ordered.where((p) => matches.contains(p.id)).where((p) => switch (_filter) {
                  _Filter.all => true,
                  _Filter.living => p.isLiving,
                  _Filter.deceased => !p.isLiving,
                }).toList();
            final me = myId == null ? null : graph[myId];
            final showMe = me != null && people.any((p) => p.id == me.id);
            final others = people.where((p) => p.id != me?.id).toList();

            final header = Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (_selected != null)
                      Row(children: [
                        Transform.translate(
                          offset: const Offset(-12, 0),
                          child: IconButton(
                            tooltip: l.cancel,
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _selected = null),
                          ),
                        ),
                        Expanded(
                          child: Text(l.selectedCount(_selected!.length),
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selected = {
                                for (final p in others) p.id,
                              }),
                          child: Text(l.groupSelectAll),
                        ),
                        IconButton.filled(
                          tooltip: l.delete,
                          style: IconButton.styleFrom(backgroundColor: Bua.danger),
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteSelected(graph),
                        ),
                      ])
                    else
                      Row(children: [
                        // Lines the ☰ icon up with the search box below.
                        Transform.translate(offset: const Offset(-12, 0), child: const SidebarButton()),
                        Expanded(child: Text(l.navMembers, style: Theme.of(context).textTheme.titleLarge)),
                      ]),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: Bua.inkMuted),
                        hintText: l.searchHint,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Bua.lineStrong),
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                      for (final f in _Filter.values) ...[
                        ChoiceChip(
                          label: Text(switch (f) {
                            _Filter.all => l.filterAll,
                            _Filter.living => l.filterLiving,
                            _Filter.deceased => l.filterDeceased,
                          }),
                          selected: _filter == f,
                          labelStyle: TextStyle(
                            color: _filter == f ? Colors.white : Bua.ink,
                            fontWeight: _filter == f ? FontWeight.w600 : FontWeight.w500,
                          ),
                          side: _filter == f ? BorderSide.none : BorderSide(color: Bua.lineStrong),
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                        const SizedBox(width: 8),
                      ],
                          ]),
                        ),
                      ),
                      Text(l.peopleCount(people.length), style: TextStyle(fontSize: 13, color: Bua.inkSubtle)),
                      PopupMenuButton<_Sort>(
                        tooltip: l.sortBy,
                        icon: Icon(Icons.sort, color: Bua.inkMuted),
                        initialValue: _sort,
                        onSelected: (s) => setState(() => _sort = s),
                        itemBuilder: (_) => [
                          for (final s in _Sort.values)
                            CheckedPopupMenuItem(
                              value: s,
                              checked: _sort == s,
                              child: Text(switch (s) {
                                _Sort.name => l.sortName,
                                _Sort.oldest => l.sortOldest,
                                _Sort.youngest => l.sortYoungest,
                                _Sort.family => l.sortFamily,
                              }),
                            ),
                        ],
                      ),
                    ]),
                  ]),
                );

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              header,
              Expanded(
                child: CustomScrollView(slivers: [
              if (people.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: Center(child: Text(l.noResults)))
              else ...[
                if (showMe)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Material(
                        color: Bua.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: Bua.green, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: PersonTile(
                          person: me,
                          viewPhoto: true,
                          subtitle: [l.relSelf, if (me.branch?.isNotEmpty ?? false) me.branch!].join(' · '),
                          subtitleColor: Bua.green,
                          trailing: isAdmin
                              ? _adminTrailing(me, isMe: true)
                              : Icon(Icons.chevron_right, color: Bua.inkSubtle),
                          onTap: () => context.push('/person/${me.id}'),
                        ),
                      ),
                    ),
                  ),
                if (others.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(18)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          for (final (i, p) in others.indexed) ...[
                            if (_sort == _Sort.name && (i == 0 || _letter(others[i - 1]) != _letter(p)))
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                                child: Text(
                                  _letter(p),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bua.green),
                                ),
                              ),
                            PersonTile(
                              person: p,
                              viewPhoto: true,
                              subtitle: _subtitle(context, graph, myId, p),
                              trailing: isAdmin ? _adminTrailing(p, isMe: false) : null,
                              onTap: _selected != null ? () => _toggle(p.id) : () => context.push('/person/${p.id}'),
                              onLongPress: isAdmin ? () => _toggle(p.id) : null,
                            ),
                          ],
                        ]),
                      ),
                    ),
                  ),
              ],
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }

  static String _letter(Person p) => p.fullName.isEmpty ? '#' : p.fullName[0].toUpperCase();

  /// "Your brother · 1978 · Kano": relationship to the viewer, then the usual details.
  static String _subtitle(BuildContext context, FamilyGraph g, String? myId, Person p) {
    final l = context.l10n;
    final base = personSubtitle(context, p);
    if (myId == null || g[myId] == null) return base;
    final k = kinshipOf(g, myId, p.id);
    if (k.type == KinType.none) return base;
    return [l.kinshipToYou(k), if (base.isNotEmpty) base].join(' · ');
  }
}
