import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/kinship.dart';
import '../../l10n/l10n.dart';
import '../../models/details.dart';
import '../../models/help.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/social.dart';

/// Open blood requests, compatible donors, and the viewer's own donor status.
class BloodDonorsScreen extends ConsumerStatefulWidget {
  const BloodDonorsScreen({super.key});

  @override
  ConsumerState<BloodDonorsScreen> createState() => _BloodDonorsScreenState();
}

class _BloodDonorsScreenState extends ConsumerState<BloodDonorsScreen> {
  String? _group;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final donors = ref.watch(bloodDonorsProvider);
    final requests = ref.watch(bloodRequestsProvider).value ?? const <BloodRequest>[];
    final graph = ref.watch(graphProvider).value;
    final myPersonId = ref.watch(profileProvider)?.personId;
    final myHealth = myPersonId == null ? null : ref.watch(detailsProvider(myPersonId)).value?.health;
    final open = requests.where((r) => r.open).toList();
    final group = _group ?? (open.isNotEmpty ? open.first.bloodGroup : myHealth?.bloodGroup) ?? 'O+';

    Future<void> refresh() {
      ref.invalidate(bloodRequestsProvider);
      return ref.refresh(bloodDonorsProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        titleSpacing: 0,
        title: Text(l.bloodDonors, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: () => context.push('/blood/request'),
              style: FilledButton.styleFrom(
                backgroundColor: Bua.danger,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Text(l.requestBlood),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: AsyncBody(
          value: donors,
          onRetry: () => ref.invalidate(bloodDonorsProvider),
          builder: (list) {
            final matches = list
                .where((d) => d.personId != myPersonId && canDonate(d.bloodGroup, group))
                .where((d) => graph?[d.personId] != null)
                .toList()
              ..sort((a, b) => graph![a.personId]!.displayName.compareTo(graph[b.personId]!.displayName));
            return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
              for (final r in open) ...[_RequestCard(request: r, myGroup: myHealth?.bloodGroup), const SizedBox(height: 12)],
              const SizedBox(height: 4),
              LabeledField(
                label: l.matchesFor,
                child: DropdownButtonFormField<String>(
                  initialValue: group,
                  isExpanded: true,
                  items: [
                    for (final g in Health.bloodGroups)
                      DropdownMenuItem(
                        value: g,
                        child: Text(
                          g == 'AB+' ? g : l.canReceiveFrom(g, donorGroupsFor(g).join(', ')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (g) => setState(() => _group = g),
                ),
              ),
              const SizedBox(height: 12),
              if (matches.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                  child: Text(l.noDonors, textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkSubtle)),
                )
              else
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    for (final (i, d) in matches.indexed) ...[
                      if (i > 0) const InsetDivider(indent: 70),
                      _DonorRow(donor: d, myPersonId: myPersonId),
                    ],
                  ]),
                ),
              const SizedBox(height: 14),
              if (myPersonId != null) _MyDonorStatus(personId: myPersonId, health: myHealth),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.shield_outlined, size: 16, color: Bua.inkSubtle),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.donorPrivacy, style: const TextStyle(fontSize: 12, height: 1.45, color: Bua.inkSubtle)),
                ),
              ]),
            ]);
          },
        ),
      ),
    );
  }
}

class _BloodBadge extends StatelessWidget {
  const _BloodBadge(this.group, {this.size = 44, this.light = false});

  final String group;
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: light ? Bua.dangerTint : Bua.danger,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Text(
          group.replaceAll('-', '−'),
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: light ? Bua.dangerInk : Colors.white,
          ),
        ),
      );
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request, this.myGroup});

  final BloodRequest request;
  final String? myGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = request;
    final me = ref.watch(profileProvider);
    final graph = ref.watch(graphProvider).value;
    final asker = authorOf(ref, r.requestedBy);
    final patient = r.patientPersonId == null ? r.patientName ?? '' : graph?[r.patientPersonId!]?.displayName ?? '';
    final mine = r.requestedBy == me?.id;
    final offered = r.offers.contains(me?.id);
    final compatible = myGroup == null || canDonate(myGroup!, r.bloodGroup);
    final askerFirst = asker.person?.firstName ?? asker.name.split(' ').first;

    Future<void> act(Future<void> Function() f) async {
      if (await guarded(context, f)) ref.invalidate(bloodRequestsProvider);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Bua.dangerTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1C4BF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _BloodBadge(r.bloodGroup),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                [if (r.urgent) l.urgent, l.ago(r.createdAt)].join(' · ').toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bua.dangerInk),
              ),
              Text(l.pintsFor(r.units, patient), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text([r.hospital, l.askedBy(asker.name)].join(' · '),
                  style: const TextStyle(fontSize: 13, color: Bua.inkMuted)),
              if (r.note?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(r.note!, style: const TextStyle(fontSize: 13, height: 1.4)),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          if (!mine)
            Expanded(
              child: offered
                  ? OutlinedButton.icon(
                      onPressed: () => act(() => ref.read(repositoryProvider).setBloodOffer(r.id, false)),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(l.youOffered),
                    )
                  : FilledButton(
                      onPressed:
                          compatible ? () => act(() => ref.read(repositoryProvider).setBloodOffer(r.id, true)) : null,
                      style: FilledButton.styleFrom(backgroundColor: Bua.danger),
                      child: Text(l.iCanDonate),
                    ),
            ),
          if (!mine && r.contactPhone != null) const SizedBox(width: 8),
          if (r.contactPhone != null && !mine)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri(scheme: 'tel', path: '+${r.contactPhone}')),
                icon: const Icon(Icons.call_outlined, size: 18),
                label: Text(l.callPerson(askerFirst), overflow: TextOverflow.ellipsis),
              ),
            ),
          if (mine || (me?.isAdmin ?? false)) ...[
            if (!mine) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => act(() => ref.read(repositoryProvider).closeBloodRequest(r.id)),
                child: Text(l.closeRequest),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 8),
        Text(
          !compatible && !mine ? l.notCompatible(myGroup!) : l.offersSoFar(r.offers.length),
          style: const TextStyle(fontSize: 12, color: Bua.dangerInk),
        ),
      ]),
    );
  }
}

class _DonorRow extends ConsumerWidget {
  const _DonorRow({required this.donor, this.myPersonId});

  final BloodDonor donor;
  final String? myPersonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final graph = ref.watch(graphProvider).value!;
    final p = graph[donor.personId]!;
    final k = myPersonId == null ? null : kinshipOf(graph, myPersonId!, p.id);
    final sub = [
      ?donor.town,
      if (k != null && k.type != KinType.none) l.kinshipToYou(k),
    ].join(' · ');
    return InkWell(
      onTap: () => context.push('/person/${p.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [
          PersonAvatar(person: p),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle)),
            ]),
          ),
          _BloodBadge(donor.bloodGroup, size: 38, light: true),
        ]),
      ),
    );
  }
}

class _MyDonorStatus extends StatelessWidget {
  const _MyDonorStatus({required this.personId, this.health});

  final String personId;
  final Health? health;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final listed = health?.bloodDonor ?? false;
    return Material(
      color: listed ? Bua.greenTint : Bua.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: listed ? Bua.greenIndicator : Bua.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/person/$personId'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            if (listed && health?.bloodGroup != null)
              _BloodBadge(health!.bloodGroup!, size: 40)
            else
              const IconTile(Icons.bloodtype_outlined, background: Bua.dangerTint, color: Bua.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(listed ? l.onDonorList : l.joinDonorList,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(listed ? l.changeInHealth : l.joinDonorListSub,
                    style: const TextStyle(fontSize: 12, color: Bua.inkSubtle)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Bua.inkSubtle),
          ]),
        ),
      ),
    );
  }
}

/// Form to ask the family for blood.
class NewBloodRequestScreen extends ConsumerStatefulWidget {
  const NewBloodRequestScreen({super.key});

  @override
  ConsumerState<NewBloodRequestScreen> createState() => _NewBloodRequestScreenState();
}

class _NewBloodRequestScreenState extends ConsumerState<NewBloodRequestScreen> {
  String? _group;
  int _units = 1;
  String? _patientId;
  final _patientName = TextEditingController();
  final _hospital = TextEditingController();
  late final _phone = TextEditingController(text: ref.read(profileProvider)?.phone ?? '');
  final _note = TextEditingController();
  bool _urgent = true;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_patientName, _hospital, _phone, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (_group == null) return showSnack(context, '${l.bloodGroupNeeded}: ${l.required}');
    if (_patientId == null && _patientName.text.trim().isEmpty) {
      return showSnack(context, '${l.patient} ${l.required}');
    }
    if (_hospital.text.trim().isEmpty) return showSnack(context, '${l.hospital}: ${l.required}');
    final phoneText = _phone.text.trim();
    final phone = phoneText.isEmpty ? null : phoneText.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() => _saving = true);
    final ok = await guarded(
      context,
      () => ref.read(repositoryProvider).createBloodRequest({
        'blood_group': _group,
        'units': _units,
        'patient_person_id': _patientId,
        'patient_name': _patientId == null ? _patientName.text.trim() : null,
        'hospital': _hospital.text.trim(),
        'contact_phone': phone,
        'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
        'urgent': _urgent,
      }),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ref.invalidate(bloodRequestsProvider);
      showSnack(context, l.bloodRequestSent);
      context.canPop() ? context.pop() : context.go('/blood');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final graph = ref.watch(graphProvider).value;
    final patient = _patientId == null ? null : graph?[_patientId!];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.close,
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/blood'),
        ),
        title: Text(l.requestBlood, style: Theme.of(context).textTheme.titleMedium),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        SectionCard(padding: const EdgeInsets.all(16), children: [
          Text(l.bloodGroupNeeded, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Bua.inkMuted)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final g in Health.bloodGroups)
              ChoiceChip(
                label: Text(g.replaceAll('-', '−'), style: const TextStyle(fontWeight: FontWeight.w700)),
                selected: _group == g,
                onSelected: (_) => setState(() => _group = g),
              ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Text(l.units, style: const TextStyle(fontSize: 15))),
            IconButton.outlined(
              tooltip: l.oneFewer,
              onPressed: _units <= 1 ? null : () => setState(() => _units--),
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 36,
              child: Text('$_units',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            IconButton.outlined(
              tooltip: l.oneMore,
              onPressed: _units >= 20 ? null : () => setState(() => _units++),
              icon: const Icon(Icons.add),
            ),
          ]),
          const SizedBox(height: 16),
          LabeledField(
            label: l.patient,
            child: patient != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: PersonChip(person: patient, onRemove: () => setState(() => _patientId = null)),
                  )
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    TextField(controller: _patientName, decoration: InputDecoration(hintText: l.patientHint)),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AddChip(
                        icon: Icons.account_tree_outlined,
                        label: l.pickFromFamily,
                        onTap: () async {
                          if (graph == null) return;
                          final p = await pickPerson(context, graph);
                          if (p != null) setState(() => _patientId = p.id);
                        },
                      ),
                    ),
                  ]),
          ),
          const SizedBox(height: 14),
          LabeledField(label: l.hospital, child: TextField(controller: _hospital)),
          const SizedBox(height: 14),
          LabeledField(
            label: l.contactPhone,
            child: TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(hintText: l.phoneHint, prefixIcon: const Icon(Icons.phone_outlined)),
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: l.noteOptional,
            child: TextField(controller: _note, minLines: 2, maxLines: 5, textCapitalization: TextCapitalization.sentences),
          ),
          const SizedBox(height: 6),
          ToggleRow(title: l.urgent, value: _urgent, onChanged: (v) => setState(() => _urgent = v)),
        ]),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: Bua.danger, minimumSize: const Size.fromHeight(52)),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l.requestBlood),
        ),
      ]),
    );
  }
}
