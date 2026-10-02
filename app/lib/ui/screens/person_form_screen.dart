import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../models/family_graph.dart';
import '../../models/person.dart';
import '../../state/providers.dart';
import '../widgets/common.dart';

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
      return;
    }
    _sex = sexFromString(widget.presetSex);
    final rel = widget.relationTo == null ? null : g[widget.relationTo!];
    if (rel != null) {
      // Sensible defaults from the relative.
      _t('branch').text = rel.branch ?? '';
      if (widget.relationType == 'child') {
        if (rel.sex == Sex.male) _t('last_name').text = rel.lastName ?? '';
        final spouses = g.spousesOf(rel.id);
        if (spouses.length == 1) _otherParentId = spouses.first.id;
      }
      if (widget.relationType == 'parent' && _sex == Sex.male) {
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
                'type': widget.relationType,
                'person_id': widget.relationTo,
                if (widget.relationType != 'spouse') 'kind': _kind.name,
                if (widget.relationType == 'child' && _otherParentId != null) 'other_parent_id': _otherParentId,
                if (widget.relationType == 'spouse') 'status': _unionStatus.name,
              };
        if (isAdmin) {
          openId = await repo.createPerson(values, relation: relation);
        } else {
          await repo.submitRequest(RequestKind.createPerson, {'person': values, 'relation': ?relation});
          message = l.sentForApproval;
        }
        return;
      }

      // Edit: only send what changed.
      final before = original.toJson();
      final changes = {
        for (final e in values.entries)
          if (before[e.key] != e.value) e.key: e.value,
      };
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

    final relative = widget.relationTo == null ? null : graph[widget.relationTo!];
    final title = _original != null
        ? (isAdmin || editingSelf ? l.editPerson : l.suggestEdit)
        : relative == null
            ? l.newPerson
            : '${l.newPersonTitle(_relationLabel(l))} ${l.ofPerson(relative.firstName)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(onPressed: _busy ? null : () => _save(graph), child: Text(l.save)),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isAdmin && !editingSelf)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l.sentForApproval)),
                  ]),
                ),
              ),
            if (relative != null) ..._relationFields(l, graph, relative),
            _field('title', l.title),
            _field('first_name', l.firstName, required: true),
            _field('middle_name', l.middleName),
            _field('last_name', l.lastName),
            _field('nickname', l.nickname),
            const SizedBox(height: 4),
            Text(l.sex, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            SegmentedButton<Sex>(
              segments: [
                ButtonSegment(value: Sex.male, label: Text(l.male)),
                ButtonSegment(value: Sex.female, label: Text(l.female)),
                ButtonSegment(value: Sex.unknown, label: Text(l.unknown)),
              ],
              selected: {_sex},
              onSelectionChanged: (s) => setState(() => _sex = s.first),
            ),
            const SizedBox(height: 16),
            _DateField(
              label: l.birthDate,
              value: _birth,
              approx: _birthApprox,
              onChanged: (d) => setState(() => _birth = d),
              onApproxChanged: (v) => setState(() => _birthApprox = v),
            ),
            _field('birth_place', l.birthPlace),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.isLiving),
              value: _living,
              onChanged: (v) => setState(() => _living = v),
            ),
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
            _field('branch', l.branch),
            _field('biography', l.biography, lines: 5),
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy ? null : () => _save(graph), child: Text(l.save)),
          ],
        ),
      ),
    );
  }

  String _relationLabel(AppLocalizations l) {
    final sex = switch (_sex) {
      Sex.male => 'male',
      Sex.female => 'female',
      Sex.unknown => 'other',
    };
    return switch (widget.relationType) {
      'parent' => l.relParent(sex),
      'child' => l.relChild(sex),
      _ => l.relSpouse(sex),
    }.toLowerCase();
  }

  List<Widget> _relationFields(AppLocalizations l, FamilyGraph g, Person relative) {
    switch (widget.relationType) {
      case 'child':
        final spouses = g.spousesOf(relative.id);
        return [
          if (spouses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String?>(
                initialValue: _otherParentId,
                decoration: InputDecoration(labelText: l.otherParent),
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
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<UnionStatus>(
              initialValue: _unionStatus,
              decoration: InputDecoration(labelText: l.unionStatus),
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

  Widget _kindField(AppLocalizations l) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<ParentKind>(
          initialValue: _kind,
          decoration: InputDecoration(labelText: l.relationKind),
          items: [
            for (final k in ParentKind.values) DropdownMenuItem(value: k, child: Text(l.parentKindLabel(k))),
          ],
          onChanged: (v) => setState(() => _kind = v ?? ParentKind.biological),
        ),
      );

  Widget _field(String key, String label, {bool required = false, int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _t(key),
          maxLines: lines,
          textCapitalization: lines > 1 ? TextCapitalization.sentences : TextCapitalization.words,
          decoration: InputDecoration(labelText: label),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: v == null
                ? null
                : IconButton(tooltip: l.clear, icon: const Icon(Icons.clear), onPressed: () => onChanged(null)),
          ),
          child: InkWell(
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
            child: Text(v == null ? l.pickDate : l.formatDate(v, approx: approx)),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l.dateApprox),
          value: approx,
          onChanged: (b) => onApproxChanged(b ?? false),
        ),
      ]),
    );
  }
}
