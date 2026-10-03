import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../models/family_graph.dart';
import '../theme.dart';
import 'bua.dart';
import 'social.dart' show StoragePhoto;

/// Human-readable summary of a change request.
class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.graph,
    this.requesterName,
    this.actions = const [],
    this.showStatus = false,
  });

  final ChangeRequest request;
  final FamilyGraph graph;
  final String? requesterName;
  final List<Widget> actions;
  final bool showStatus;

  String _name(String? id) => id == null ? '?' : graph[id]?.displayName ?? '?';

  String _personName(Map<String, dynamic>? p) =>
      [p?['first_name'], p?['middle_name'], p?['last_name']].whereType<String>().join(' ');

  String _title(AppLocalizations l) {
    final p = request.payload;
    switch (request.kind) {
      case RequestKind.createPerson:
        final person = p['person'] as Map<String, dynamic>?;
        final rel = p['relation'] as Map<String, dynamic>?;
        final base = l.reqCreatePerson(_personName(person));
        if (rel == null) return base;
        final sex = switch (person?['sex']) {
          'male' => 'male',
          'female' => 'female',
          _ => 'other',
        };
        final relLabel = switch (rel['type']) {
          'parent' => l.relParent(sex),
          'child' => l.relChild(sex),
          _ => l.relSpouse(sex),
        };
        return '$base ${l.reqRelation(relLabel.toLowerCase(), _name(rel['person_id'] as String?))}';
      case RequestKind.updatePerson:
        return l.reqUpdatePerson(_name(request.targetPersonId));
      case RequestKind.addParentChild:
        return l.reqAddParentChild(_name(p['parent_id'] as String?), _name(p['child_id'] as String?));
      case RequestKind.addUnion:
        return l.reqAddUnion(_name(p['partner1_id'] as String?), _name(p['partner2_id'] as String?));
    }
  }

  /// Proposed values for person requests, with readable field names.
  List<(String, String)> _details(AppLocalizations l) {
    final person = request.payload['person'] as Map<String, dynamic>?;
    final rel = request.payload['relation'] as Map<String, dynamic>?;
    if (person == null) return const [];
    final labels = {
      'title': l.title,
      'first_name': l.firstName,
      'middle_name': l.middleName,
      'last_name': l.lastName,
      'nickname': l.nickname,
      'sex': l.sex,
      'birth_date': l.birthDate,
      'birth_place': l.birthPlace,
      'death_date': l.deathDate,
      'death_place': l.deathPlace,
      'burial_place': l.burialPlace,
      'branch': l.branch,
      'biography': l.biography,
    };
    String value(String key, Object v) => switch ((key, v)) {
          ('sex', 'male') => l.male,
          ('sex', 'female') => l.female,
          ('sex', _) => l.unknown,
          ('birth_date' || 'death_date', final String d) when DateTime.tryParse(d) != null =>
            l.formatDate(DateTime.parse(d), approx: person['${key}_approx'] == true),
          _ => '$v',
        };
    // A new person's name is already in the card title.
    final inTitle = request.kind == RequestKind.createPerson
        ? const {'first_name', 'middle_name', 'last_name'}
        : const <String>{};
    return [
      if (request.kind == RequestKind.createPerson && rel?['other_parent_id'] != null)
        (l.otherParent, _name(rel!['other_parent_id'] as String?)),
      for (final e in person.entries)
        if (labels.containsKey(e.key) && !inTitle.contains(e.key) && e.value != null && e.value != '')
          (labels[e.key]!, value(e.key, e.value as Object)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (icon, tileBg, tileFg) = switch (request.kind) {
      RequestKind.createPerson => (Icons.person_add_alt_1, Bua.greenTint, Bua.green),
      RequestKind.updatePerson => (Icons.edit_outlined, Bua.goldTint, Bua.goldInk),
      RequestKind.addParentChild || RequestKind.addUnion => (Icons.link, Bua.greenTint, Bua.green),
    };
    final details = _details(l);
    final meta = [if (requesterName != null) l.requestedBy(requesterName!), l.formatDate(request.createdAt)].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (showStatus) ...[
          Row(children: [_statusPill(l), const SizedBox(width: 8), Expanded(child: Text(meta, style: _meta))]),
          const SizedBox(height: 8),
          Text(_title(l), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.35)),
        ] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconTile(icon, background: tileBg, color: tileFg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_title(l), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.35)),
                const SizedBox(height: 2),
                Text(meta, style: _meta),
              ]),
            ),
          ]),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Bua.ground, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final (k, v) in details)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 110, child: Text(k, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle))),
                    Expanded(child: Text(v, style: const TextStyle(fontSize: 13))),
                  ]),
                ),
            ]),
          ),
        ],
        if ((request.payload['person'] as Map<String, dynamic>?)?['photo_path'] case final String path) ...[
          const SizedBox(height: 10),
          Row(children: [
            SizedBox(width: 110, child: Text(l.photoLabel, style: const TextStyle(fontSize: 13, color: Bua.inkSubtle))),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 72, height: 72, child: StoragePhoto(path)),
            ),
          ]),
        ],
        if (request.reviewNote?.isNotEmpty ?? false) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Bua.ground, borderRadius: BorderRadius.circular(12)),
            child: Text('“${request.reviewNote}”',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Bua.inkBody)),
          ),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(width: 10), a],
          ]),
        ],
      ]),
    );
  }

  static const _meta = TextStyle(fontSize: 13, color: Bua.inkSubtle);

  Widget _statusPill(AppLocalizations l) => switch (request.status) {
        RequestStatus.pending => Pill(l.statusPending.toUpperCase(), background: Bua.goldTint, color: Bua.goldInk),
        RequestStatus.approved => Pill(l.statusApproved.toUpperCase(), icon: Icons.check),
        RequestStatus.rejected =>
          Pill(l.statusRejected.toUpperCase(), background: Bua.dangerTint, color: Bua.dangerInk),
      };
}
