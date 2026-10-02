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
    final theme = Theme.of(context);

    final myId = profile?.personId;
    final kinship = myId != null && !isMe && graph[myId] != null ? kinshipOf(graph, myId, person.id) : null;

    return CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        title: Text(person.displayName),
        actions: [
          if (canEditDetails || canContribute)
            IconButton(
              tooltip: canEditDetails ? l.editPerson : l.suggestEdit,
              icon: Icon(canEditDetails ? Icons.edit : Icons.edit_note),
              onPressed: () => context.push('/person/${person.id}/edit'),
            ),
          PopupMenuButton<String>(
            onSelected: (v) => _onMenu(context, ref, v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'tree', child: Text(l.viewInTree)),
              if (profile?.personId == null && profile?.requestedPersonId != person.id)
                PopupMenuItem(value: 'me', child: Text(l.thisIsMe)),
              if (isAdmin) PopupMenuItem(value: 'delete', child: Text(l.deletePerson)),
            ],
          ),
        ],
      ),
      SliverToBoxAdapter(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: canEditDetails ? () => _changePhoto(context, ref) : null,
              child: Stack(children: [
                PersonAvatar(person: person, radius: 56),
                if (canEditDetails)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(Icons.photo_camera, size: 16, color: theme.colorScheme.onPrimary),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Text(person.displayName, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
          if (person.nickname?.isNotEmpty ?? false)
            Text('"${person.nickname}"', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          if (personSubtitle(context, person).isNotEmpty)
            Text(personSubtitle(context, person), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Center(
            child: Wrap(spacing: 8, children: [
              if (isMe) Chip(avatar: const Icon(Icons.person, size: 18), label: Text(l.thisIsYou)),
              if (kinship != null)
                Chip(
                  avatar: const Icon(Icons.link, size: 18),
                  label: Text('${l.relationshipToYou}: ${l.kinship(kinship)}'),
                ),
            ]),
          ),
          _AboutSection(person: person),
          _FamilySection(graph: graph, person: person, canContribute: canContribute),
          _DetailsSections(person: person, canEdit: canEditDetails),
          const SizedBox(height: 32),
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
    String? when(DateTime? d, bool approx, String? place) {
      final parts = [
        if (d != null) l.formatDate(d, approx: approx),
        if (place?.isNotEmpty ?? false) place!,
      ];
      return parts.isEmpty ? null : parts.join(' · ');
    }

    final rows = <(IconData, String, String)>[
      if (when(person.birthDate, person.birthDateApprox, person.birthPlace) case final v?)
        (Icons.cake_outlined, l.born, v),
      if (!person.isLiving)
        if (when(person.deathDate, person.deathDateApprox, person.deathPlace) case final v?)
          (Icons.local_florist_outlined, l.died, v),
      if (person.burialPlace?.isNotEmpty ?? false) (Icons.place_outlined, l.buried, person.burialPlace!),
      if (person.branch?.isNotEmpty ?? false) (Icons.account_tree_outlined, l.branch, person.branch!),
    ];
    final bio = person.biography;
    if (rows.isEmpty && (bio == null || bio.isEmpty)) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(l.sectionAbout),
      for (final r in rows)
        ListTile(dense: true, leading: Icon(r.$1), title: Text(r.$2), subtitle: Text(r.$3)),
      if (bio != null && bio.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(bio, style: Theme.of(context).textTheme.bodyLarge),
        ),
    ]);
  }
}

class _FamilySection extends ConsumerWidget {
  const _FamilySection({required this.graph, required this.person, required this.canContribute});

  final FamilyGraph graph;
  final Person person;
  final bool canContribute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final id = person.id;
    final parents = graph.parentsOf(id);
    final unions = graph.unionsOf(id);
    final childGroups = graph.childrenByOtherParent(id);
    final siblings = graph.siblingsOf(id);
    final multipleSpouses = childGroups.keys.where((k) => k != null).length > 1;

    Widget tile(Person p, {String? extra}) {
      final base = personSubtitle(context, p);
      final sub = [?extra, if (base.isNotEmpty) base].join(' · ');
      return PersonTile(person: p, subtitle: sub, onTap: () => context.push('/person/${p.id}'));
    }

    String? parentKind(Person parent) {
      final link = graph.parentLinksOf(id).where((x) => x.parentId == parent.id).firstOrNull;
      return link == null || link.kind == ParentKind.biological ? null : l.parentKindLabel(link.kind);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(
        l.sectionFamily,
        action: canContribute
            ? TextButton.icon(
                onPressed: () => _addRelative(context, ref),
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: Text(l.addRelative),
              )
            : null,
      ),
      if (parents.isNotEmpty) ...[
        _SubHeader(l.parents),
        for (final p in parents) tile(p, extra: parentKind(p)),
      ],
      if (unions.isNotEmpty) ...[
        _SubHeader(l.spouses),
        for (final u in unions)
          if (graph[u.partnerOf(id)!] case final s?)
            tile(s, extra: u.status == UnionStatus.married ? null : l.unionStatusLabel(u.status)),
      ],
      if (childGroups.values.any((c) => c.isNotEmpty)) ...[
        _SubHeader(l.children),
        for (final entry in childGroups.entries)
          for (final c in entry.value)
            tile(c, extra: multipleSpouses && entry.key != null ? graph[entry.key!]?.firstName : null),
      ],
      if (siblings.isNotEmpty) ...[
        _SubHeader(l.siblings),
        for (final s in siblings) tile(s, extra: l.kinship(kinshipOf(graph, id, s.id))),
      ],
      if (parents.isEmpty && unions.isEmpty && childGroups.isEmpty && siblings.isEmpty)
        Padding(padding: const EdgeInsets.all(16), child: Text(l.nothingYet)),
    ]);
  }

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

class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
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

    Widget addButton(VoidCallback onPressed) =>
        IconButton(tooltip: l.add, icon: const Icon(Icons.add), onPressed: onPressed);

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(l.nothingYet, style: Theme.of(context).textTheme.bodySmall),
    );

    final contact = d.contact;
    final health = d.health;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Education
      SectionHeader(l.education,
          action: canEdit ? addButton(() => run(() => _editEducation(context, repo().saveEducation))) : null),
      if (d.education.isEmpty) empty,
      for (final e in d.education)
        ListTile(
          leading: const Icon(Icons.school_outlined),
          title: Text(e.institution),
          subtitle: Text([e.qualification, e.field, years(e.startYear, e.endYear)]
              .where((s) => s != null && s.isNotEmpty)
              .join(' · ')),
          trailing: itemMenu(
            onEdit: () => run(() => _editEducation(context, repo().saveEducation, e)),
            onDelete: () => run(() => repo().deleteDetail('person_education', e.id!)),
          ),
        ),

      // Work
      SectionHeader(l.work,
          action: canEdit ? addButton(() => run(() => _editOccupation(context, repo().saveOccupation))) : null),
      if (d.occupations.isEmpty) empty,
      for (final o in d.occupations)
        ListTile(
          leading: const Icon(Icons.work_outline),
          title: Text(o.title),
          subtitle: Text([o.organization, o.location, if (o.isCurrent) l.currentJob else years(o.startYear, o.endYear)]
              .where((s) => s != null && s.isNotEmpty)
              .join(' · ')),
          trailing: itemMenu(
            onEdit: () => run(() => _editOccupation(context, repo().saveOccupation, o)),
            onDelete: () => run(() => repo().deleteDetail('person_occupations', o.id!)),
          ),
        ),

      // Skills
      SectionHeader(l.skills,
          action: canEdit
              ? addButton(() => run(() async {
                    final v = await showFormDialog(context,
                        title: l.skill, fields: [TextSpec('skill', l.skill, required: true)]);
                    if (v != null) await repo().addSkill(person.id, v['skill'] as String);
                  }))
              : null),
      if (d.skills.isEmpty)
        empty
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 4, children: [
            for (final s in d.skills)
              InputChip(
                label: Text(s.skill),
                onDeleted: canEdit ? () => run(() => repo().deleteDetail('person_skills', s.id!)) : null,
              ),
          ]),
        ),

      // Contact (only living people)
      if (person.isLiving && (canEdit || (contact != null && !contact.isEmpty))) ...[
        SectionHeader(l.contact,
            action: canEdit
                ? IconButton(
                    tooltip: l.edit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => run(() => _editContact(context, repo(), contact)),
                  )
                : null),
        if (contact == null || contact.isEmpty) empty,
        if (contact != null) ...[
          if (contact.phone?.isNotEmpty ?? false)
            ListTile(dense: true, leading: const Icon(Icons.phone_outlined), title: SelectableText(contact.phone!)),
          if (contact.email?.isNotEmpty ?? false)
            ListTile(dense: true, leading: const Icon(Icons.email_outlined), title: SelectableText(contact.email!)),
          if ([contact.address, contact.city, contact.country].any((s) => s?.isNotEmpty ?? false))
            ListTile(
              dense: true,
              leading: const Icon(Icons.home_outlined),
              title: Text([contact.address, contact.city, contact.country]
                  .where((s) => s?.isNotEmpty ?? false)
                  .join(', ')),
            ),
        ],
      ],

      // Health (private unless shared)
      if (canEdit || (health != null && !health.isEmpty)) ...[
        SectionHeader(l.health,
            action: canEdit
                ? IconButton(
                    tooltip: l.edit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => run(() => _editHealth(context, repo(), health)),
                  )
                : null),
        if (health == null || health.isEmpty) empty,
        if (health != null && !health.isEmpty)
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: Text([
              if (health.bloodGroup != null) '${l.bloodGroup}: ${health.bloodGroup}',
              if (health.genotype != null) '${l.genotype}: ${health.genotype}',
            ].join(' · ')),
            subtitle: Text([
              if (health.conditions?.isNotEmpty ?? false) health.conditions!,
              health.visibility == Audience.private ? l.visiblePrivate : l.visibleFamily,
            ].join('\n')),
          ),
      ],
    ]);
  }

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
