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
          Text(l.whoCanHelpSub, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Bua.inkSubtle)),
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
              _CategoryGrid(
                selected: _category,
                onChanged: (c) => setState(() => _category = _category == c ? null : c),
              ),
              const SizedBox(height: 16),
              GroupHeading(heading),
              const SizedBox(height: 8),
              if (people.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                  child: Text(l.helpEmptyNote,
                      textAlign: TextAlign.center, style: TextStyle(color: Bua.inkSubtle, height: 1.5)),
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
                child: Text(l.contactNote, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(children: [
          PersonAvatar(person: p),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              if (headline.isNotEmpty)
                Text(headline, style: TextStyle(fontSize: 13, color: Bua.inkBody)),
              if (relation != null)
                Text(relation!, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
            ]),
          ),
          if (profile.phone?.isNotEmpty ?? false)
            IconButton.filledTonal(
              tooltip: l.callPerson(p.firstName),
              onPressed: () => launchUrl(Uri(scheme: 'tel', path: profile.phone!.replaceAll(' ', ''))),
              icon: const Icon(Icons.call_outlined),
            )
          else
            OutlinedButton(
              onPressed: () => context.push('/person/${p.id}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Bua.ink,
                side: BorderSide(color: Bua.lineStrong),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Text(l.profile),
            ),
        ]),
      ),
    );
  }
}

IconData helpCategoryIcon(HelpCategory c) => switch (c) {
      HelpCategory.health => Icons.favorite_border,
      HelpCategory.law => Icons.balance,
      HelpCategory.trades => Icons.build_outlined,
      HelpCategory.teaching => Icons.school_outlined,
      HelpCategory.business => Icons.work_outline,
      HelpCategory.engineering => Icons.engineering_outlined,
      HelpCategory.tech => Icons.computer_outlined,
      HelpCategory.islamic => Icons.menu_book_outlined,
    };

/// The eight fields as tappable tiles, four to a row.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onChanged});

  final HelpCategory? selected;
  final ValueChanged<HelpCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LayoutBuilder(builder: (context, c) {
      const gap = 8.0;
      final width = (c.maxWidth - gap * 3) / 4;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final cat in HelpCategory.values)
          SizedBox(
            width: width,
            height: 72,
            child: _CategoryTile(
              icon: helpCategoryIcon(cat),
              label: l.helpCategory(cat.name),
              selected: selected == cat,
              onTap: () => onChanged(cat),
            ),
          ),
      ]);
    });
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : Bua.ink;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? Bua.green : Bua.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? Bua.green : Bua.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 20, color: selected ? Colors.white : Bua.green),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.2, fontWeight: FontWeight.w600, color: fg),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
