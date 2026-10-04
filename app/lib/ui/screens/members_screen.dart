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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final graphAsync = ref.watch(graphProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final myId = ref.watch(profileProvider)?.personId;

    return Scaffold(
      floatingActionButton: isAdmin
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
                    Row(children: [
                      // Lines the ☰ icon up with the search box below.
                      Transform.translate(offset: const Offset(-12, 0), child: const SidebarButton()),
                      Expanded(child: Text(l.navMembers, style: Theme.of(context).textTheme.titleLarge)),
                    ]),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Bua.inkMuted),
                        hintText: l.searchHint,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Bua.lineStrong),
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
                          side: _filter == f ? BorderSide.none : const BorderSide(color: Bua.lineStrong),
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                        const SizedBox(width: 8),
                      ],
                          ]),
                        ),
                      ),
                      Text(l.peopleCount(people.length), style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
                      PopupMenuButton<_Sort>(
                        tooltip: l.sortBy,
                        icon: const Icon(Icons.sort, color: Bua.inkMuted),
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
                          side: const BorderSide(color: Bua.green, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: PersonTile(
                          person: me,
                          viewPhoto: true,
                          subtitle: [l.relSelf, if (me.branch?.isNotEmpty ?? false) me.branch!].join(' · '),
                          subtitleColor: Bua.green,
                          trailing: const Icon(Icons.chevron_right, color: Bua.inkSubtle),
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
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bua.green),
                                ),
                              ),
                            PersonTile(
                              person: p,
                              viewPhoto: true,
                              subtitle: _subtitle(context, graph, myId, p),
                              onTap: () => context.push('/person/${p.id}'),
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
