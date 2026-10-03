import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/details.dart';
import '../../models/person.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';

/// A member edits their own details and decides who sees them. Name, sex and
/// dates still go through an admin (link at the top).
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final personId = ref.watch(profileProvider)?.personId;
    final person = personId == null ? null : ref.watch(graphProvider).value?[personId];
    final details = personId == null ? null : ref.watch(detailsProvider(personId));

    if (person == null || details == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.editMyDetails, style: Theme.of(context).textTheme.titleMedium)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: personId == null ? InfoBanner(icon: Icons.link_off, text: l.notLinkedEdit) : const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return AsyncBody(
      value: details,
      onRetry: () => ref.invalidate(detailsProvider(personId!)),
      builder: (d) => _EditForm(person: person, details: d),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.person, required this.details});

  final Person person;
  final PersonDetails details;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final _nickname = TextEditingController(text: widget.person.nickname);
  late final _bio = TextEditingController(text: widget.person.biography);
  late final _phone = TextEditingController(text: widget.details.contact?.phone);
  late final _city = TextEditingController(text: widget.details.contact?.city);
  late Audience _contactVis = widget.details.contact?.visibility ?? Audience.family;
  late String? _blood = widget.details.health?.bloodGroup;
  late String? _genotype = widget.details.health?.genotype;
  late Audience _healthVis = widget.details.health?.visibility ?? Audience.private;
  late bool _donor = widget.details.health?.bloodDonor ?? false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_nickname, _bio, _phone, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    final repo = ref.read(repositoryProvider);
    final p = widget.person;
    final c = widget.details.contact;
    final h = widget.details.health;
    setState(() => _saving = true);
    final ok = await guarded(context, () async {
      await repo.updatePerson(p.id, {'nickname': _opt(_nickname), 'biography': _opt(_bio)});
      await repo.saveContact(Contact(
        personId: p.id,
        phone: _opt(_phone),
        city: _opt(_city),
        email: c?.email,
        address: c?.address,
        country: c?.country,
        visibility: _contactVis,
      ));
      if (_blood != null || _genotype != null || h != null) {
        await repo.saveHealth(Health(
          personId: p.id,
          bloodGroup: _blood,
          genotype: _genotype,
          conditions: h?.conditions,
          visibility: _healthVis,
          bloodDonor: _donor,
        ));
      }
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ref.invalidate(graphProvider);
      ref.invalidate(detailsProvider(p.id));
      ref.invalidate(bloodDonorsProvider);
      ref.invalidate(helpDirectoryProvider);
      showSnack(context, context.l10n.saved);
      context.canPop() ? context.pop() : context.go('/person/${p.id}');
    }
  }

  Future<void> _addSkill() async {
    final l = context.l10n;
    final text = TextEditingController();
    final skill = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.addSkill),
        content: TextField(
          controller: text,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.skill),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, text.text), child: Text(l.add)),
        ],
      ),
    );
    text.dispose();
    if (skill == null || skill.trim().isEmpty || !mounted) return;
    if (await guarded(context, () => ref.read(repositoryProvider).addSkill(widget.person.id, skill))) {
      ref.invalidate(detailsProvider(widget.person.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.person;
    final skills = ref.watch(detailsProvider(p.id)).value?.skills ?? widget.details.skills;

    Widget audience(Audience value, ValueChanged<Audience> onChanged) => PillSegmented<Audience>(
          values: Audience.values,
          labelOf: (a) => a == Audience.family ? l.wholeFamily : l.onlyMeAdmins,
          selected: value,
          height: 36,
          expand: true,
          onChanged: onChanged,
        );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.close,
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/person/${p.id}'),
        ),
        title: Text(l.editMyDetails, style: Theme.of(context).textTheme.titleMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size(72, 40)),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.save),
            ),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        Row(children: [
          PersonAvatar(person: p, radius: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.displayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text('${l.nameDatesNote} ', style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
                InkWell(
                  onTap: () => context.push('/person/${p.id}/edit'),
                  child: Text(l.askAnAdmin,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Bua.green)),
                ),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(title: l.aboutMe, padding: const EdgeInsets.fromLTRB(0, 6, 0, 16), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              LabeledField(label: l.nickname, child: TextField(controller: _nickname)),
              const SizedBox(height: 14),
              LabeledField(
                label: l.myStory,
                child: TextField(
                  controller: _bio,
                  minLines: 3,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        SectionCard(title: l.contact, padding: const EdgeInsets.fromLTRB(0, 6, 0, 16), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              LabeledField(
                label: l.phone,
                child: TextField(controller: _phone, keyboardType: TextInputType.phone),
              ),
              const SizedBox(height: 14),
              LabeledField(label: l.city, child: TextField(controller: _city)),
              const SizedBox(height: 14),
              Text(l.whoSeesContact, style: const TextStyle(fontSize: 13, color: Bua.inkMuted)),
              const SizedBox(height: 6),
              audience(_contactVis, (a) => setState(() => _contactVis = a)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        SectionCard(title: l.health, padding: const EdgeInsets.fromLTRB(0, 6, 0, 8), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(
                  child: LabeledField(
                    label: l.bloodGroup,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _blood,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        for (final b in Health.bloodGroups) DropdownMenuItem(value: b, child: Text(b)),
                      ],
                      onChanged: (v) => setState(() {
                        _blood = v;
                        if (v == null) _donor = false;
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LabeledField(
                    label: l.genotype,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _genotype,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        for (final g in Health.genotypes) DropdownMenuItem(value: g, child: Text(g)),
                      ],
                      onChanged: (v) => setState(() => _genotype = v),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              Text(l.whoSeesHealth, style: const TextStyle(fontSize: 13, color: Bua.inkMuted)),
              const SizedBox(height: 6),
              audience(_healthVis, (a) => setState(() => _healthVis = a)),
              const SizedBox(height: 6),
              ToggleRow(
                title: l.bloodDonorOptIn,
                subtitle: l.bloodDonorOptInSub,
                value: _donor,
                onChanged: _blood == null ? null : (v) => setState(() => _donor = v),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        SectionCard(title: l.skills, padding: const EdgeInsets.fromLTRB(0, 6, 0, 16), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in skills)
                InputChip(
                  label: Text(s.skill),
                  onDeleted: () async {
                    if (await guarded(context, () => ref.read(repositoryProvider).deleteDetail('person_skills', s.id!))) {
                      ref.invalidate(detailsProvider(p.id));
                    }
                  },
                ),
              ActionChip(avatar: const Icon(Icons.add, size: 18), label: Text(l.addSkill), onPressed: _addSkill),
            ]),
          ),
        ]),
      ]),
    );
  }
}
