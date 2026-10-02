import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';

enum _Filter { all, living, deceased }

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final graphAsync = ref.watch(graphProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.navMembers)),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              tooltip: l.newPerson,
              onPressed: () => context.push('/new-person'),
              child: const Icon(Icons.person_add),
            )
          : null,
      body: AsyncBody(
        value: graphAsync,
        onRetry: () => ref.invalidate(graphProvider),
        builder: (graph) {
          final people = graph.search(_query).where((p) => switch (_filter) {
                _Filter.all => true,
                _Filter.living => p.isLiving,
                _Filter.deceased => !p.isLiving,
              }).toList();
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchHint),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Wrap(spacing: 8, children: [
                      for (final f in _Filter.values)
                        ChoiceChip(
                          label: Text(switch (f) {
                            _Filter.all => l.filterAll,
                            _Filter.living => l.filterLiving,
                            _Filter.deceased => l.filterDeceased,
                          }),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                Text(l.peopleCount(people.length), style: Theme.of(context).textTheme.labelMedium),
              ]),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(graphProvider.future),
                child: people.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 80),
                        Center(child: Text(l.noResults)),
                      ])
                    : ListView.builder(
                        itemCount: people.length,
                        itemBuilder: (_, i) => PersonTile(
                          person: people[i],
                          onTap: () => context.push('/person/${people[i].id}'),
                        ),
                      ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
