import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repository.dart';
import '../../domain/kinship.dart';
import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../models/details.dart';
import '../../models/family_graph.dart';
import '../../models/person.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';

class PersonScreen extends ConsumerWidget {
  const PersonScreen({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graphAsync = ref.watch(graphProvider);
    return Scaffold(
      body: AsyncBody(
        value: graphAsync,
        onRetry: () => ref.invalidate(graphProvider),
        builder: (graph) {
          final person = graph[personId];
          if (person == null) {
            return Scaffold(appBar: AppBar(), body: Center(child: Text(context.l10n.noResults)));
          }
          return _PersonView(graph: graph, person: person);
        },
      ),
    );
  }
}

class _PersonView extends ConsumerWidget {
  const _PersonView({required this.graph, required this.person});

  final FamilyGraph graph;
  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final canContribute = ref.watch(canContributeProvider);
    final isMe = profile?.personId == person.id;
    final canEditDetails = isAdmin || isMe;

    final myId = profile?.personId;
    final kinship = myId != null && !isMe && graph[myId] != null ? kinshipOf(graph, myId, person.id) : null;
    final band = person.isLiving ? Bua.green : Bua.memorial;

    final facts = [
      if (person.nickname?.isNotEmpty ?? false) '“${person.nickname}”',
      if (person.isLiving && person.birthDate != null)
        '${l.born} ${person.birthDateApprox ? l.approxPrefix() : ''}${person.birthDate!.year}',
      if (!person.isLiving && person.lifespan(approxPrefix: l.approxPrefix()).isNotEmpty)
        person.lifespan(approxPrefix: l.approxPrefix()),
      if (person.isLiving && (person.birthPlace?.isNotEmpty ?? false)) person.birthPlace!,
      if (!person.isLiving && (person.branch?.isNotEmpty ?? false)) person.branch!,
    ];

    // Band, top bar and the avatar overlapping the band's lower edge, all in
    // one Stack so the avatar paints above the band.
    final header = Stack(clipBehavior: Clip.none, children: [
      Column(children: [PatternBand(height: 150, color: band), const SizedBox(height: 62)]),
      SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            BackButton(color: Colors.white, onPressed: () => context.canPop() ? context.pop() : context.go('/tree')),
            const Spacer(),
            if (canEditDetails || canContribute)
              IconButton(
                tooltip: canEditDetails ? l.editPerson : l.suggestEdit,
                icon: Icon(canEditDetails ? Icons.edit_outlined : Icons.edit_note, color: Colors.white),
                onPressed: () => context.push('/person/${person.id}/edit'),
              ),
            PopupMenuButton<String>(
              iconColor: Colors.white,
              onSelected: (v) => _onMenu(context, ref, v),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'tree', child: Text(l.viewInTree)),
                if (profile?.personId == null && profile?.requestedPersonId != person.id)
                  PopupMenuItem(value: 'me', child: Text(l.thisIsMe)),
                if (isAdmin) PopupMenuItem(value: 'delete', child: Text(l.deletePerson)),
              ],
            ),
          ]),
        ),
      ),
      Positioned(
        top: 150 - 56,
        left: 0,
        right: 0,
        child: Center(
          child: Semantics(
            button: canEditDetails,
            label: canEditDetails ? l.changePhoto : null,
            child: GestureDetector(
              onTap: canEditDetails ? () => _changePhoto(context, ref) : null,
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  decoration: const BoxDecoration(color: Bua.ground, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(4),
                  child: PersonAvatar(person: person, radius: 50, gapColor: Bua.ground),
                ),
                if (canEditDetails)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Bua.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Bua.ground, width: 3),
                      ),
                      child: const Icon(Icons.photo_camera, size: 16, color: Colors.white),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    ]);

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            header,
            if (!person.isLiving) ...[
              const SizedBox(height: 10),
              Center(child: Pill(l.late(person), background: Bua.track, color: Bua.unknownFg)),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(person.displayName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            ),
            if (facts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(facts.join(' · '),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Bua.inkMuted)),
              ),
            const SizedBox(height: 10),
            if (isMe || kinship != null)
              Center(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 34),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: Bua.greenTint, borderRadius: BorderRadius.circular(17)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isMe ? Icons.person : Icons.link, size: 16, color: Bua.greenDark),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isMe ? l.thisIsYou : l.kinshipToYou(kinship!),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Bua.greenDark),
                      ),
                    ),
                  ]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(backgroundColor: Bua.surface, side: const BorderSide(color: Bua.line)),
                    onPressed: () => context.go('/tree?focus=${person.id}'),
                    icon: const Icon(Icons.account_tree_outlined, size: 18),
                    label: Text(l.viewInTree),
                  ),
                ),
                if (canContribute) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _FamilySection.addRelative(context, ref, graph, person),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: Text(l.addRelative),
                    ),
                  ),
                ],
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _AboutSection(person: person),
                _FamilySection(graph: graph, person: person),
                _DetailsSections(person: person, canEdit: canEditDetails),
              ]),
            ),
        ]),
      ),
    ]);
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, String action) async {
    final l = context.l10n;
    final repo = ref.read(repositoryProvider);
    switch (action) {
      case 'tree':
        context.go('/tree?focus=${person.id}');
      case 'me':
        final ok = await guarded(context, () => repo.updateMyProfile(requestedPersonId: person.id));
        if (ok && context.mounted) {
          showSnack(context, l.thisIsMeSent);
          ref.read(authProvider).refresh();
        }
      case 'delete':
        if (!await confirm(context, l.confirmDeletePerson(person.displayName))) return;
        if (!context.mounted) return;
        final ok = await guarded(context, () => repo.deletePerson(person.id));
        if (ok && context.mounted) {
          ref.invalidate(graphProvider);
          context.pop();
        }
    }
  }

  Future<void> _changePhoto(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (file == null || !context.mounted) return;
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final ok = await guarded(context, () async {
      await ref.read(repositoryProvider).uploadPhoto(person.id, await file.readAsBytes(), ext);
    });
    if (ok) ref.invalidate(graphProvider);
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget tile(String label, DateTime? d, bool approx, String? place) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: Bua.ground, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
              Text(d == null ? '—' : l.formatDate(d, approx: approx),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              if (place?.isNotEmpty ?? false) Text(place!, style: const TextStyle(fontSize: 13, color: Bua.inkMuted)),
            ]),
          ),
        );

    final showBirth = person.birthDate != null || (person.birthPlace?.isNotEmpty ?? false);
    final showDeath = !person.isLiving && (person.deathDate != null || (person.deathPlace?.isNotEmpty ?? false));
    final bio = person.biography;
    final rows = <(IconData, String, String)>[
      if (person.burialPlace?.isNotEmpty ?? false) (Icons.place_outlined, l.buried, person.burialPlace!),
      if (person.branch?.isNotEmpty ?? false) (Icons.account_tree_outlined, l.branch, person.branch!),
    ];
    if (!showBirth && !showDeath && rows.isEmpty && (bio == null || bio.isEmpty)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(title: l.sectionAbout, children: [
        if (showBirth || showDeath)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              if (showBirth) tile(l.born, person.birthDate, person.birthDateApprox, person.birthPlace),
              if (showBirth && showDeath) const SizedBox(width: 10),
              if (showDeath) tile(l.died, person.deathDate, person.deathDateApprox, person.deathPlace),
            ]),
          ),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Icon(r.$1, size: 20, color: Bua.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.$2, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                  Text(r.$3, style: const TextStyle(fontSize: 15)),
                ]),
              ),
            ]),
          ),
        if (bio != null && bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Text(bio, style: Theme.of(context).textTheme.bodyLarge),
          ),
      ]),
    );
  }
}

class _FamilySection extends ConsumerWidget {
  const _FamilySection({required this.graph, required this.person});

  final FamilyGraph graph;
  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final id = person.id;
    final parents = graph.parentsOf(id);
    final unions = graph.unionsOf(id);
    final childGroups = graph.childrenByOtherParent(id);
    final siblings = graph.siblingsOf(id);
    final multipleSpouses = childGroups.keys.where((k) => k != null).length > 1;

    String sexKey(Person p) => switch (p.sex) {
          Sex.male => 'male',
          Sex.female => 'female',
          Sex.unknown => 'other',
        };

    Widget tile(Person p, String? relation) {
      final base = personSubtitle(context, p);
      final sub = [?relation, if (base.isNotEmpty) base].join(' · ');
      return PersonTile(person: p, subtitle: sub, onTap: () => context.push('/person/${p.id}'));
    }

    String parentLabel(Person parent) {
      final link = graph.parentLinksOf(id).where((x) => x.parentId == parent.id).firstOrNull;
      final rel = l.relParent(sexKey(parent));
      return link == null || link.kind == ParentKind.biological ? rel : '$rel (${l.parentKindLabel(link.kind)})';
    }

    if (parents.isEmpty && unions.isEmpty && childGroups.isEmpty && siblings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SectionCard(title: l.sectionFamily, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Text(l.nothingYet, style: Theme.of(context).textTheme.bodySmall),
          ),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(title: l.sectionFamily, children: [
        if (parents.isNotEmpty) ...[
          SubLabel(l.parents),
          for (final p in parents) tile(p, parentLabel(p)),
        ],
        if (unions.isNotEmpty) ...[
          SubLabel(l.spouses),
          for (final u in unions)
            if (graph[u.partnerOf(id)!] case final s?)
              tile(s, u.status == UnionStatus.married ? l.relSpouse(sexKey(s)) : l.unionStatusLabel(u.status)),
        ],
        if (childGroups.values.any((c) => c.isNotEmpty)) ...[
          SubLabel(l.children),
          for (final entry in childGroups.entries)
            for (final c in entry.value)
              tile(c, [
                l.relChild(sexKey(c)),
                if (multipleSpouses && entry.key != null) graph[entry.key!]?.firstName,
              ].whereType<String>().join(', ')),
        ],
        if (siblings.isNotEmpty) ...[
          SubLabel(l.siblings),
          for (final s in siblings) tile(s, l.kinship(kinshipOf(graph, id, s.id))),
        ],
      ]),
    );
  }

  static Future<void> addRelative(BuildContext context, WidgetRef ref, FamilyGraph graph, Person person) =>
      _FamilySection(graph: graph, person: person)._addRelative(context, ref);

  Future<void> _addRelative(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.man), title: Text(l.addFather), onTap: () => Navigator.pop(c, 'father')),
          ListTile(leading: const Icon(Icons.woman), title: Text(l.addMother), onTap: () => Navigator.pop(c, 'mother')),
          ListTile(leading: const Icon(Icons.favorite_outline), title: Text(l.addSpouse), onTap: () => Navigator.pop(c, 'spouse')),
          ListTile(leading: const Icon(Icons.boy), title: Text(l.addSon), onTap: () => Navigator.pop(c, 'son')),
          ListTile(leading: const Icon(Icons.girl), title: Text(l.addDaughter), onTap: () => Navigator.pop(c, 'daughter')),
          const Divider(),
          ListTile(leading: const Icon(Icons.link), title: Text(l.linkExisting), onTap: () => Navigator.pop(c, 'link')),
        ]),
      ),
    );
    if (choice == null || !context.mounted) return;
    final id = person.id;
    final spouseSex = person.sex == Sex.male ? 'female' : person.sex == Sex.female ? 'male' : '';
    switch (choice) {
      case 'father':
        context.push('/new-person?type=parent&of=$id&sex=male');
      case 'mother':
        context.push('/new-person?type=parent&of=$id&sex=female');
      case 'spouse':
        context.push('/new-person?type=spouse&of=$id&sex=$spouseSex');
      case 'son':
        context.push('/new-person?type=child&of=$id&sex=male');
      case 'daughter':
        context.push('/new-person?type=child&of=$id&sex=female');
      case 'link':
        await _linkExisting(context, ref);
    }
  }

  Future<void> _linkExisting(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final other = await pickPerson(context, graph, exclude: {person.id});
    if (other == null || !context.mounted) return;
    final values = await showFormDialog(context, title: l.linkExisting, fields: [
      ChoiceSpec<String>('relation', l.relationIs(other.displayName), initial: 'parent', options: {
        'parent': l.relationParentOf,
        'child': l.relationChildOf,
        'spouse': l.relationSpouseOf,
      }),
      ChoiceSpec<ParentKind>('kind', l.relationKind, initial: ParentKind.biological, options: {
        for (final k in ParentKind.values) k: l.parentKindLabel(k),
      }),
    ]);
    if (values == null || !context.mounted) return;

    final relation = values['relation'] as String;
    final kind = values['kind'] as ParentKind;
    final repo = ref.read(repositoryProvider);
    final isAdmin = ref.read(isAdminProvider);
    final ok = await guarded(context, () async {
      if (relation == 'spouse') {
        if (isAdmin) {
          await repo.addUnion(other.id, person.id, UnionStatus.married);
        } else {
          await repo.submitRequest(RequestKind.addUnion, {'partner1_id': other.id, 'partner2_id': person.id});
        }
      } else {
        final parent = relation == 'parent' ? other.id : person.id;
        final child = relation == 'parent' ? person.id : other.id;
        if (isAdmin) {
          await repo.addParentChild(parent, child, kind);
        } else {
          await repo.submitRequest(
            RequestKind.addParentChild,
            {'parent_id': parent, 'child_id': child, 'kind': kind.name},
          );
        }
      }
    });
    if (!ok || !context.mounted) return;
    if (isAdmin) {
      ref.invalidate(graphProvider);
    } else {
      showSnack(context, l.sentForApproval);
      ref.invalidate(requestsProvider);
    }
  }
}

class _DetailsSections extends ConsumerWidget {
  const _DetailsSections({required this.person, required this.canEdit});

  final Person person;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(detailsProvider(person.id));
    final d = async.value;
    if (d == null) {
      return async.hasError
          ? Padding(padding: const EdgeInsets.all(16), child: Text(l.errorGeneric(errorText(async.error!))))
          : const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
    }
    FamilyRepository repo() => ref.read(repositoryProvider);
    Future<void> run(Future<void> Function() action) async {
      if (await guarded(context, action)) ref.invalidate(detailsProvider(person.id));
    }

    Widget? itemMenu({required VoidCallback onEdit, required VoidCallback onDelete}) => canEdit
        ? PopupMenuButton<bool>(
            onSelected: (edit) => edit ? onEdit() : onDelete(),
            itemBuilder: (_) => [
              PopupMenuItem(value: true, child: Text(l.edit)),
              PopupMenuItem(value: false, child: Text(l.delete)),
            ],
          )
        : null;

    String years(int? a, int? b) => [if (a != null) '$a', if (b != null) '$b'].join(' – ');

    final empty = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Text(l.nothingYet, style: Theme.of(context).textTheme.bodySmall),
    );

    Widget detailRow(IconData icon, String title, String subtitle, Widget? trailing) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconTile(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
              ]),
            ),
            ?trailing,
          ]),
        );

    final contact = d.contact;
    final health = d.health;
    final hasWork = d.education.isNotEmpty || d.occupations.isNotEmpty || d.skills.isNotEmpty;

    Widget addMenu() => PopupMenuButton<String>(
          tooltip: l.add,
          icon: const Icon(Icons.add, color: Bua.green),
          onSelected: (v) => switch (v) {
            'edu' => run(() => _editEducation(context, repo().saveEducation)),
            'work' => run(() => _editOccupation(context, repo().saveOccupation)),
            _ => run(() async {
                final v = await showFormDialog(context, title: l.skill, fields: [TextSpec('skill', l.skill, required: true)]);
                if (v != null) await repo().addSkill(person.id, v['skill'] as String);
              }),
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edu', child: Text(l.addEducation)),
            PopupMenuItem(value: 'work', child: Text(l.addWork)),
            PopupMenuItem(value: 'skill', child: Text(l.addSkill)),
          ],
        );

    Widget editButton(VoidCallback onPressed) =>
        IconButton(tooltip: l.edit, icon: const Icon(Icons.edit_outlined, size: 20, color: Bua.green), onPressed: onPressed);

    final healthShared = health?.visibility == Audience.family;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Education, work and skills
      if (hasWork || canEdit)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SectionCard(title: l.educationWork, trailing: canEdit ? addMenu() : null, children: [
            if (!hasWork) empty,
            for (final e in d.education)
              detailRow(
                Icons.school_outlined,
                e.institution,
                [e.qualification, e.field, years(e.startYear, e.endYear)].where((s) => s != null && s.isNotEmpty).join(' · '),
                itemMenu(
                  onEdit: () => run(() => _editEducation(context, repo().saveEducation, e)),
                  onDelete: () => run(() => repo().deleteDetail('person_education', e.id!)),
                ),
              ),
            for (final o in d.occupations)
              detailRow(
                Icons.work_outline,
                [o.title, o.organization].where((s) => s != null && s.isNotEmpty).join(', '),
                [o.location, if (o.isCurrent) l.currentJob else years(o.startYear, o.endYear)]
                    .where((s) => s != null && s.isNotEmpty)
                    .join(' · '),
                itemMenu(
                  onEdit: () => run(() => _editOccupation(context, repo().saveOccupation, o)),
                  onDelete: () => run(() => repo().deleteDetail('person_occupations', o.id!)),
                ),
              ),
            if (d.skills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in d.skills)
                    InputChip(
                      label: Text(s.skill),
                      onDeleted: canEdit ? () => run(() => repo().deleteDetail('person_skills', s.id!)) : null,
                    ),
                ]),
              ),
          ]),
        ),

      // Health (private unless shared)
      if (canEdit || (health != null && !health.isEmpty))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SectionCard(
            title: l.health,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (health != null && !health.isEmpty)
                healthShared
                    ? Pill(l.sharedWithFamily, icon: Icons.people_outline)
                    : Pill(l.privateLabel, icon: Icons.lock_outline, background: Bua.track, color: Bua.unknownFg),
              if (canEdit) editButton(() => run(() => _editHealth(context, repo(), health))),
            ]),
            children: [
              if (health == null || health.isEmpty)
                empty
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Row(children: [
                    for (final (label, value) in [(l.bloodGroup, health.bloodGroup), (l.genotype, health.genotype)]) ...[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: Bua.ground, borderRadius: BorderRadius.circular(14)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(label, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                            Text(value ?? '—', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                      if (label == l.bloodGroup) const SizedBox(width: 10),
                    ],
                  ]),
                ),
                if (health.conditions?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Text(health.conditions!, style: const TextStyle(fontSize: 14)),
                  ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(children: [
                  const Icon(Icons.lock_outline, size: 14, color: Bua.inkSubtle),
                  const SizedBox(width: 6),
                  Expanded(child: Text(l.healthPrivacyNote, style: const TextStyle(fontSize: 12, color: Bua.inkSubtle))),
                ]),
              ),
            ],
          ),
        ),

      // Contact (only living people)
      if (person.isLiving && (canEdit || (contact != null && !contact.isEmpty)))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SectionCard(
            title: l.contact,
            trailing: canEdit ? editButton(() => run(() => _editContact(context, repo(), contact))) : null,
            children: [
              if (contact == null || contact.isEmpty) empty,
              if (contact != null) ...[
                if (contact.phone?.isNotEmpty ?? false) _contactRow(Icons.phone_outlined, contact.phone!),
                if (contact.email?.isNotEmpty ?? false) _contactRow(Icons.email_outlined, contact.email!),
                if ([contact.address, contact.city, contact.country].any((s) => s?.isNotEmpty ?? false))
                  _contactRow(
                    Icons.place_outlined,
                    [contact.address, contact.city, contact.country].where((s) => s?.isNotEmpty ?? false).join(', '),
                  ),
              ],
            ],
          ),
        ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _contactRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Icon(icon, size: 20, color: Bua.green),
          const SizedBox(width: 12),
          Expanded(child: SelectableText(text, style: const TextStyle(fontSize: 15))),
        ]),
      );

  Future<void> _editEducation(BuildContext context, Future<void> Function(Education) save, [Education? e]) async {
    final l = context.l10n;
    final v = await showFormDialog(context, title: l.education, fields: [
      TextSpec('institution', l.institution, initial: e?.institution, required: true),
      TextSpec('qualification', l.qualification, initial: e?.qualification),
      TextSpec('field', l.field, initial: e?.field),
      TextSpec('start', l.startYear, initial: e?.startYear, number: true),
      TextSpec('end', l.endYear, initial: e?.endYear, number: true),
    ]);
    if (v == null) return;
    await save(Education(
      id: e?.id,
      personId: person.id,
      institution: v['institution'] as String,
      qualification: v['qualification'] as String?,
      field: v['field'] as String?,
      startYear: v['start'] as int?,
      endYear: v['end'] as int?,
    ));
  }

  Future<void> _editOccupation(BuildContext context, Future<void> Function(Occupation) save, [Occupation? o]) async {
    final l = context.l10n;
    final v = await showFormDialog(context, title: l.work, fields: [
      TextSpec('title', l.jobTitle, initial: o?.title, required: true),
      TextSpec('organization', l.organization, initial: o?.organization),
      TextSpec('industry', l.industry, initial: o?.industry),
      TextSpec('location', l.location, initial: o?.location),
      TextSpec('start', l.startYear, initial: o?.startYear, number: true),
      TextSpec('end', l.endYear, initial: o?.endYear, number: true),
      SwitchSpec('current', l.currentJob, initial: o?.isCurrent ?? false),
    ]);
    if (v == null) return;
    await save(Occupation(
      id: o?.id,
      personId: person.id,
      title: v['title'] as String,
      organization: v['organization'] as String?,
      industry: v['industry'] as String?,
      location: v['location'] as String?,
      startYear: v['start'] as int?,
      endYear: v['end'] as int?,
      isCurrent: v['current'] as bool,
    ));
  }

  Map<Audience, String> _audiences(AppLocalizations l) =>
      {Audience.family: l.visibleFamily, Audience.private: l.visiblePrivate};

  Future<void> _editContact(BuildContext context, FamilyRepository repo, Contact? c) async {
    final l = context.l10n;
    final v = await showFormDialog(context, title: l.contact, fields: [
      TextSpec('phone', l.phone, initial: c?.phone),
      TextSpec('email', l.email, initial: c?.email),
      TextSpec('address', l.address, initial: c?.address),
      TextSpec('city', l.city, initial: c?.city),
      TextSpec('country', l.country, initial: c?.country),
      ChoiceSpec<Audience>('vis', l.visibleTo, options: _audiences(l), initial: c?.visibility ?? Audience.family),
    ]);
    if (v == null) return;
    await repo.saveContact(Contact(
      personId: person.id,
      phone: v['phone'] as String?,
      email: v['email'] as String?,
      address: v['address'] as String?,
      city: v['city'] as String?,
      country: v['country'] as String?,
      visibility: v['vis'] as Audience,
    ));
  }

  Future<void> _editHealth(BuildContext context, FamilyRepository repo, Health? h) async {
    final l = context.l10n;
    final v = await showFormDialog(context, title: l.health, note: l.healthPrivacyNote, fields: [
      ChoiceSpec<String?>('blood', l.bloodGroup,
          initial: h?.bloodGroup, options: {null: '—', for (final b in Health.bloodGroups) b: b}),
      ChoiceSpec<String?>('genotype', l.genotype,
          initial: h?.genotype, options: {null: '—', for (final g in Health.genotypes) g: g}),
      TextSpec('conditions', l.conditions, initial: h?.conditions, multiline: true),
      ChoiceSpec<Audience>('vis', l.visibleTo, options: _audiences(l), initial: h?.visibility ?? Audience.private),
    ]);
    if (v == null) return;
    await repo.saveHealth(Health(
      personId: person.id,
      bloodGroup: v['blood'] as String?,
      genotype: v['genotype'] as String?,
      conditions: v['conditions'] as String?,
      visibility: v['vis'] as Audience,
    ));
  }
}
