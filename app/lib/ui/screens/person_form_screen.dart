import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../models/family_graph.dart';
import '../../models/person.dart';
import '../../models/social.dart' show PickedImage;
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/social.dart' show StoragePhoto;

/// Add a new person (optionally as a relative of [relationTo]) or edit [editId].
///
/// Admins save directly. Members' additions and changes to other people become
/// change requests; on their own record, non-core fields save directly and
/// core fields (names, dates, life status) go to the admins.
class PersonFormScreen extends ConsumerStatefulWidget {
  const PersonFormScreen({super.key, this.editId, this.relationType, this.relationTo, this.presetSex});

  final String? editId;

  /// 'parent', 'child' or 'spouse': the new person's relation to [relationTo].
  final String? relationType;
  final String? relationTo;
  final String? presetSex;

  @override
  ConsumerState<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends ConsumerState<PersonFormScreen> {
  final _form = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{};
  Person? _original;
  bool _initialised = false;
  bool _busy = false;

  Sex _sex = Sex.unknown;
  DateTime? _birth;
  bool _birthApprox = false;
  bool _living = true;
  DateTime? _death;
  bool _deathApprox = false;
  PickedImage? _photo;
  int? _birthOrder;

  late String? _relType = widget.relationType;
  String? _otherParentId;
  ParentKind _kind = ParentKind.biological;
  UnionStatus _unionStatus = UnionStatus.married;

  static const _textFields = [
    'title', 'first_name', 'middle_name', 'last_name', 'nickname',
    'birth_place', 'death_place', 'burial_place', 'branch', 'biography',
  ];

  TextEditingController _t(String key) => _c.putIfAbsent(key, TextEditingController.new);

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _init(FamilyGraph g) {
    if (_initialised) return;
    _initialised = true;
    final p = widget.editId == null ? null : g[widget.editId!];
    _original = p;
    if (p != null) {
      final j = p.toJson();
      for (final k in _textFields) {
        _t(k).text = (j[k] as String?) ?? '';
      }
      _sex = p.sex;
      _birth = p.birthDate;
      _birthApprox = p.birthDateApprox;
      _living = p.isLiving;
      _death = p.deathDate;
      _deathApprox = p.deathDateApprox;
      _birthOrder = p.birthOrder;
      return;
    }
    _sex = sexFromString(widget.presetSex);
    final rel = widget.relationTo == null ? null : g[widget.relationTo!];
    if (rel != null) {
      // Sensible defaults from the relative.
      _t('branch').text = rel.branch ?? '';
      if (_relType == 'child') {
        if (rel.sex == Sex.male) _t('last_name').text = rel.lastName ?? '';
        final spouses = g.spousesOf(rel.id);
        if (spouses.length == 1) _otherParentId = spouses.first.id;
        // Usually the next one born.
        final kids = g.childrenOf(rel.id);
        final highest = kids.map((k) => k.birthOrder ?? 0).fold(kids.length, (a, b) => a > b ? a : b);
        _birthOrder = highest < 60 ? highest + 1 : null;
      }
      if (_relType == 'parent' && _sex == Sex.male) {
        _t('last_name').text = rel.lastName ?? '';
      }
    }
  }

  String _dateStr(DateTime? d) => d == null
      ? ''
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _values() {
    String? t(String k) {
      final v = _t(k).text.trim();
      return v.isEmpty ? null : v;
    }

    return {
      for (final k in _textFields) k: t(k),
      'sex': _sex.name,
      'birth_date': _birth == null ? null : _dateStr(_birth),
      'birth_date_approx': _birthApprox,
      'birth_order': _birthOrder,
      'is_living': _living,
      'death_date': _living || _death == null ? null : _dateStr(_death),
      'death_date_approx': !_living && _deathApprox,
      if (_living) 'death_place': null,
      if (_living) 'burial_place': null,
    };
  }

  Future<void> _save(FamilyGraph g) async {
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    final repo = ref.read(repositoryProvider);
    final isAdmin = ref.read(isAdminProvider);
    final myPersonId = ref.read(profileProvider)?.personId;
    final values = _values();
    final photo = _photo;
    setState(() => _busy = true);

    String? message;
    String? openId;
    final ok = await guarded(context, () async {
      final original = _original;
      if (original == null) {
        // New person
        final relation = widget.relationTo == null
            ? null
            : {
                'type': _relType,
                'person_id': widget.relationTo,
                if (_relType != 'spouse') 'kind': _kind.name,
                if (_relType == 'child' && _otherParentId != null) 'other_parent_id': _otherParentId,
                if (_relType == 'spouse') 'status': _unionStatus.name,
              };
        if (isAdmin) {
          openId = await repo.createPerson(values, relation: relation);
          if (photo != null) await repo.uploadPhoto(openId!, Uint8List.fromList(photo.bytes), photo.extension);
        } else {
          if (photo != null) values['photo_path'] = await repo.uploadPendingPhoto(photo);
          await repo.submitRequest(RequestKind.createPerson, {'person': values, 'relation': ?relation});
          message = l.sentForApproval;
        }
        return;
      }

      // A new photo goes straight on for admins and for your own record;
      // otherwise it travels with the suggestion.
      final direct = isAdmin || original.id == myPersonId;
      if (photo != null && direct) {
        await repo.uploadPhoto(original.id, Uint8List.fromList(photo.bytes), photo.extension);
      }

      // Edit: only send what changed.
      final before = original.toJson();
      final changes = <String, dynamic>{
        for (final e in values.entries)
          if (before[e.key] != e.value) e.key: e.value,
      };
      if (photo != null && !direct) changes['photo_path'] = await repo.uploadPendingPhoto(photo);
      if (changes.isEmpty) return;
      if (isAdmin) {
        await repo.updatePerson(original.id, changes);
      } else if (original.id == myPersonId) {
        final core = {for (final e in changes.entries) if (Person.coreFields.contains(e.key)) e.key: e.value};
        final rest = {for (final e in changes.entries) if (!Person.coreFields.contains(e.key)) e.key: e.value};
        await repo.updatePerson(original.id, rest);
        if (core.isNotEmpty) {
          await repo.submitRequest(RequestKind.updatePerson, {'person': core}, targetPersonId: original.id);
          message = l.coreChangesSent;
        }
      } else {
        await repo.submitRequest(RequestKind.updatePerson, {'person': changes}, targetPersonId: original.id);
        message = l.sentForApproval;
      }
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;

    ref.invalidate(graphProvider);
    ref.invalidate(requestsProvider);
    if (message != null) showSnack(context, message!);
    if (openId != null) {
      context.pushReplacement('/person/$openId');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final graphAsync = ref.watch(graphProvider);
    final graph = graphAsync.value;
    if (graph == null) {
      return Scaffold(appBar: AppBar(), body: AsyncBody(value: graphAsync, builder: (_) => const SizedBox()));
    }
    _init(graph);

    final isAdmin = ref.watch(isAdminProvider);
    final canContribute = ref.watch(canContributeProvider);
    final myPersonId = ref.watch(profileProvider)?.personId;
    final editingSelf = _original != null && _original!.id == myPersonId;
    if (!isAdmin && !editingSelf && !canContribute) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(l.contributionsOff)));
    }
    final needsApproval = !isAdmin && !editingSelf;

    final relative = widget.relationTo == null ? null : graph[widget.relationTo!];
    final title = _original != null
        ? (isAdmin || editingSelf ? l.editPerson : l.suggestEdit)
        : relative == null
            ? l.newPerson
            : l.addRelative;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.close,
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/tree'),
        ),
        title: Text(title),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            if (needsApproval) ...[
              InfoBanner(icon: Icons.shield_outlined, text: l.approvalBanner),
              const SizedBox(height: 14),
            ],
            if (relative != null) ...[
              _card([
                Text(l.addingTo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Bua.inkMuted)),
                Row(children: [
                  PersonAvatar(person: relative),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(relative.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      if (personSubtitle(context, relative).isNotEmpty)
                        Text(personSubtitle(context, relative), style: TextStyle(fontSize: 13, color: Bua.inkSubtle)),
                    ]),
                  ),
                ]),
                if (_original == null) ...[
                  Text(l.newPersonIs(relative.firstName),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Bua.inkMuted)),
                  _relationChips(l, relative),
                ],
                ..._relationFields(l, graph, relative),
              ]),
              const SizedBox(height: 14),
            ],
            _card([
              _PhotoField(
                picked: _photo,
                currentPath: _original?.photoPath,
                onPick: () async {
                  final f = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 80,
                  );
                  if (f == null) return;
                  final bytes = await f.readAsBytes();
                  setState(() => _photo = PickedImage(bytes, f.name.contains('.') ? f.name.split('.').last : 'jpg'));
                },
              ),
              Row(children: [
                Expanded(child: _field('first_name', l.firstName, required: true)),
                const SizedBox(width: 10),
                Expanded(child: _field('last_name', l.lastName)),
              ]),
              _field('middle_name', l.middleName),
              _field('title', l.title),
              _field('nickname', l.nickname),
              LabeledField(
                label: l.sex,
                child: PillSegmented<Sex>(
                  values: Sex.values,
                  expand: true,
                  labelOf: l.sexLabel,
                  selected: _sex,
                  onChanged: (v) => setState(() => _sex = v),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            _card([
              _DateField(
                label: l.birthDate,
                value: _birth,
                approx: _birthApprox,
                onChanged: (d) => setState(() => _birth = d),
                onApproxChanged: (v) => setState(() => _birthApprox = v),
              ),
              _field('birth_place', l.birthPlace),
              LabeledField(
                label: l.birthOrder,
                child: DropdownButtonFormField<int?>(
                  initialValue: _birthOrder,
                  isExpanded: true,
                  decoration: InputDecoration(helperText: l.birthOrderHint, helperMaxLines: 2),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l.birthOrderNone)),
                    for (var i = 1; i <= 60; i++) DropdownMenuItem(value: i, child: Text(l.ordinal(i))),
                  ],
                  onChanged: (v) => setState(() => _birthOrder = v),
                ),
              ),
              ToggleRow(title: l.isLiving, value: _living, onChanged: (v) => setState(() => _living = v)),
              if (!_living) ...[
                _DateField(
                  label: l.deathDate,
                  value: _death,
                  approx: _deathApprox,
                  onChanged: (d) => setState(() => _death = d),
                  onApproxChanged: (v) => setState(() => _deathApprox = v),
                ),
                _field('death_place', l.deathPlace),
                _field('burial_place', l.burialPlace),
              ],
            ]),
            const SizedBox(height: 14),
            _card([
              _field('branch', l.branch),
              _field('biography', l.biography, lines: 5),
            ]),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              onPressed: _busy ? null : () => _save(graph),
              icon: Icon(needsApproval ? Icons.send_outlined : Icons.check),
              label: Text(needsApproval ? l.sendForApproval : l.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: 12), c],
          ],
        ),
      );

  /// Father / Mother / Spouse / Son / Daughter chips for a new relative.
  Widget _relationChips(AppLocalizations l, Person relative) {
    final spouseSex = relative.sex == Sex.male
        ? Sex.female
        : relative.sex == Sex.female
            ? Sex.male
            : Sex.unknown;
    final options = <(String, Sex, String)>[
      ('parent', Sex.male, l.addFather),
      ('parent', Sex.female, l.addMother),
      ('spouse', spouseSex, l.addSpouse),
      ('child', Sex.male, l.addSon),
      ('child', Sex.female, l.addDaughter),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final (type, sex, label) in options)
        ChoiceChip(
          label: Text(label),
          selected: _relType == type && (type == 'spouse' || _sex == sex),
          avatar: _relType == type && (type == 'spouse' || _sex == sex)
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
          labelStyle: TextStyle(
            fontSize: 14,
            color: _relType == type && (type == 'spouse' || _sex == sex) ? Colors.white : Bua.ink,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => setState(() {
            _relType = type;
            _sex = sex;
            if (type == 'child' && _otherParentId == null) {
              final spouses = ref.read(graphProvider).value?.spousesOf(relative.id) ?? const [];
              if (spouses.length == 1) _otherParentId = spouses.first.id;
            }
          }),
        ),
    ]);
  }

  List<Widget> _relationFields(AppLocalizations l, FamilyGraph g, Person relative) {
    switch (_relType) {
      case 'child':
        final spouses = g.spousesOf(relative.id);
        return [
          if (spouses.isNotEmpty)
            LabeledField(
              label: l.otherParent,
              child: DropdownButtonFormField<String?>(
                initialValue: _otherParentId,
                items: [
                  for (final s in spouses) DropdownMenuItem(value: s.id, child: Text(s.displayName)),
                  DropdownMenuItem(value: null, child: Text(l.otherParentUnknown)),
                ],
                onChanged: (v) => setState(() => _otherParentId = v),
              ),
            ),
          _kindField(l),
        ];
      case 'parent':
        return [_kindField(l)];
      case 'spouse':
        return [
          LabeledField(
            label: l.unionStatus,
            child: DropdownButtonFormField<UnionStatus>(
              initialValue: _unionStatus,
              items: [
                for (final s in UnionStatus.values) DropdownMenuItem(value: s, child: Text(l.unionStatusLabel(s))),
              ],
              onChanged: (v) => setState(() => _unionStatus = v ?? UnionStatus.married),
            ),
          ),
        ];
    }
    return const [];
  }

  Widget _kindField(AppLocalizations l) => LabeledField(
        label: l.relationKind,
        child: DropdownButtonFormField<ParentKind>(
          initialValue: _kind,
          items: [
            for (final k in ParentKind.values) DropdownMenuItem(value: k, child: Text(l.parentKindLabel(k))),
          ],
          onChanged: (v) => setState(() => _kind = v ?? ParentKind.biological),
        ),
      );

  Widget _field(String key, String label, {bool required = false, int lines = 1}) => LabeledField(
        label: label,
        child: TextFormField(
          controller: _t(key),
          maxLines: lines,
          textCapitalization: lines > 1 ? TextCapitalization.sentences : TextCapitalization.words,
          validator: required ? (v) => (v ?? '').trim().isEmpty ? context.l10n.required : null : null,
        ),
      );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.approx,
    required this.onChanged,
    required this.onApproxChanged,
  });

  final String label;
  final DateTime? value;
  final bool approx;
  final ValueChanged<DateTime?> onChanged;
  final ValueChanged<bool> onApproxChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = value;
    return LabeledField(
      label: label,
      child: Row(children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: v ?? DateTime(1980),
                firstDate: DateTime(1700),
                lastDate: DateTime.now(),
                initialDatePickerMode: approx ? DatePickerMode.year : DatePickerMode.day,
              );
              if (picked != null) onChanged(approx ? DateTime(picked.year) : picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                suffixIcon: v == null
                    ? const Icon(Icons.calendar_today_outlined, size: 18)
                    : IconButton(tooltip: l.clear, icon: const Icon(Icons.clear), onPressed: () => onChanged(null)),
              ),
              child: Text(
                v == null ? l.pickDate : l.formatDate(v, approx: approx),
                style: TextStyle(fontSize: 15, color: v == null ? Bua.inkSubtle : Bua.ink),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => onApproxChanged(!approx),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, maxWidth: 140),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Checkbox(value: approx, onChanged: (b) => onApproxChanged(b ?? false)),
              Flexible(child: Text(l.dateApprox, style: const TextStyle(fontSize: 13))),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Round photo with an "Add photo" / "Change photo" button.
class _PhotoField extends StatelessWidget {
  const _PhotoField({required this.picked, required this.currentPath, required this.onPick});

  final PickedImage? picked;
  final String? currentPath;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final has = picked != null || currentPath != null;
    return Row(children: [
      Material(
        color: Bua.greenTint,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPick,
          child: SizedBox(
            width: 72,
            height: 72,
            child: picked != null
                ? Image.memory(Uint8List.fromList(picked!.bytes), fit: BoxFit.cover)
                : currentPath != null
                    ? StoragePhoto(currentPath!)
                    : Icon(Icons.add_a_photo_outlined, color: Bua.green, size: 28),
          ),
        ),
      ),
      const SizedBox(width: 14),
      OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.photo_camera_outlined, size: 18),
        label: Text(has ? l.changePhoto : l.addPhoto),
      ),
    ]);
  }
}
