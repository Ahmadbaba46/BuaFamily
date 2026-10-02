import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/account.dart';
import '../../models/family_graph.dart';

/// Human-readable summary of a change request.
class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.graph,
    this.requesterName,
    this.actions = const [],
  });

  final ChangeRequest request;
  final FamilyGraph graph;
  final String? requesterName;
  final List<Widget> actions;

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

  /// Field-by-field list of proposed values for person requests.
  List<String> _details() {
    final person = request.payload['person'] as Map<String, dynamic>?;
    if (person == null) return const [];
    return [
      for (final e in person.entries)
        if (e.value != null && e.value != '' && e.value != false) '${e.key.replaceAll('_', ' ')}: ${e.value}',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final (statusText, statusColor) = switch (request.status) {
      RequestStatus.pending => (l.statusPending, theme.colorScheme.tertiary),
      RequestStatus.approved => (l.statusApproved, theme.colorScheme.primary),
      RequestStatus.rejected => (l.statusRejected, theme.colorScheme.error),
    };
    final details = _details();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(_title(l), style: theme.textTheme.titleSmall)),
            Text(statusText, style: theme.textTheme.labelMedium?.copyWith(color: statusColor)),
          ]),
          const SizedBox(height: 4),
          Text(
            [if (requesterName != null) l.requestedBy(requesterName!), l.formatDate(request.createdAt)].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(details.join('\n'), style: theme.textTheme.bodySmall),
          ],
          if (request.reviewNote?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text('“${request.reviewNote}”', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
          ],
        ]),
      ),
    );
  }
}
