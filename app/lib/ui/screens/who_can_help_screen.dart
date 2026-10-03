import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/kinship.dart';
import '../../l10n/l10n.dart';
import '../../models/help.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';

/// Skills directory: search the family's work, studies and skills.
class WhoCanHelpScreen extends ConsumerStatefulWidget {
  const WhoCanHelpScreen({super.key});

  @override
  ConsumerState<WhoCanHelpScreen> createState() => _WhoCanHelpScreenState();
}

class _WhoCanHelpScreenState extends ConsumerState<WhoCanHelpScreen> {
  final _search = TextEditingController();
  HelpCategory? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final directory = ref.watch(helpDirectoryProvider);
    final graph = ref.watch(graphProvider).value;
    final myId = ref.watch(profileProvider)?.personId;
    final query = _search.text.trim();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.whoCanHelp, style: Theme.of(context).textTheme.titleLarge),
          Text(l.whoCanHelpSub, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
        ]),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(helpDirectoryProvider.future),
        child: AsyncBody(
          value: directory,
          onRetry: () => ref.invalidate(helpDirectoryProvider),
          builder: (all) {
            final people = all
                .where((h) => h.person.id != myId)
                .where((h) => _category == null || h.inCategory(_category!))
                .where((h) => h.matches(query))
                .toList();
            final heading = query.isNotEmpty
                ? l.relativesMatching(people.length, query)
                : _category != null
                    ? l.relativesIn(people.length, l.helpCategory(_category!.name).toLowerCase())
                    : l.relativesWithSkills(people.length);

            return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l.searchSkills,
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l.clear,
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in HelpCategory.values)
                  ChoiceChip(
                    label: Text(l.helpCategory(c.name)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = _category == c ? null : c),
                  ),
              ]),
              const SizedBox(height: 16),
              GroupHeading(heading),
              const SizedBox(height: 8),
              if (people.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                  child: Text(l.helpEmptyNote,
                      textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkSubtle, height: 1.5)),
                )
              else
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    for (final (i, h) in people.indexed) ...[
                      if (i > 0) const InsetDivider(indent: 70),
                      _HelpRow(
                        profile: h,
                        relation: myId == null || graph == null ? null : _relation(l, kinshipOf(graph, myId, h.person.id)),
                      ),
                    ],
                  ]),
                ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(l.contactNote, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
              ),
            ]);
          },
        ),
      ),
    );
  }

  String? _relation(AppLocalizations l, Kinship k) => k.type == KinType.none ? null : l.kinshipToYou(k);
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.profile, this.relation});

  final HelpProfile profile;
  final String? relation;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = profile.person;
    final headline = profile.headline();
    return InkWell(
      onTap: () => context.push('/person/${p.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(children: [
          PersonAvatar(person: p),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              if (headline.isNotEmpty)
                Text(headline, style: const TextStyle(fontSize: 13, color: Bua.inkBody)),
              if (relation != null)
                Text(relation!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Bua.green)),
            ]),
          ),
          if (profile.phone?.isNotEmpty ?? false)
            IconButton.filledTonal(
              tooltip: l.callPerson(p.firstName),
              onPressed: () => launchUrl(Uri(scheme: 'tel', path: profile.phone!.replaceAll(' ', ''))),
              icon: const Icon(Icons.call_outlined),
            )
          else
            TextButton(onPressed: () => context.push('/person/${p.id}'), child: Text(l.profile)),
        ]),
      ),
    );
  }
}
