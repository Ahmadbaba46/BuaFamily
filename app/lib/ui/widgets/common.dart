import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/l10n.dart';
import '../../models/family_graph.dart';
import '../../models/person.dart';
import '../../state/providers.dart';

/// Readable message from a server or app error.
String errorText(Object e) => switch (e) {
      PostgrestException(:final message) => message,
      AuthException(:final message) => message,
      StorageException(:final message) => message,
      _ => e.toString(),
    };

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showError(BuildContext context, Object e) =>
    showSnack(context, context.l10n.errorGeneric(errorText(e)));

/// Runs [action], showing any error. Returns true on success.
Future<bool> guarded(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } catch (e) {
    if (context.mounted) showError(context, e);
    return false;
  }
}

/// Standard loading / error / data switch for async values.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.builder, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(context.l10n.errorGeneric(errorText(e)), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Round avatar: photo if available, otherwise initials. Deceased people are
/// shown with a muted ring.
class PersonAvatar extends ConsumerWidget {
  const PersonAvatar({super.key, required this.person, this.radius = 22, this.showPhoto = true});

  final Person person;
  final double radius;

  /// Off in the tree view, where hundreds of avatars would each fetch a photo URL.
  final bool showPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final bg = switch (person.sex) {
      Sex.male => scheme.primaryContainer,
      Sex.female => scheme.tertiaryContainer,
      Sex.unknown => scheme.surfaceContainerHighest,
    };
    final fg = switch (person.sex) {
      Sex.male => scheme.onPrimaryContainer,
      Sex.female => scheme.onTertiaryContainer,
      Sex.unknown => scheme.onSurfaceVariant,
    };
    final path = person.photoPath;
    final url = path == null || !showPhoto ? null : ref.watch(photoUrlProvider(path)).value;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      foregroundImage: url == null ? null : NetworkImage(url),
      child: Text(
        person.initials,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: radius * 0.7),
      ),
    );
    if (person.isLiving) return avatar;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.outline, width: 2)),
      child: avatar,
    );
  }
}

/// One-line description under a name: lifespan, "Late", branch.
String personSubtitle(BuildContext context, Person p) {
  final l = context.l10n;
  final parts = <String>[
    if (!p.isLiving) l.late(p),
    if (p.lifespan(approxPrefix: l.approxPrefix()).isNotEmpty) p.lifespan(approxPrefix: l.approxPrefix()),
    if (p.branch?.isNotEmpty ?? false) p.branch!,
  ];
  return parts.join(' · ');
}

class PersonTile extends StatelessWidget {
  const PersonTile({super.key, required this.person, this.trailing, this.onTap, this.subtitle});

  final Person person;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle ?? personSubtitle(context, person);
    return ListTile(
      leading: PersonAvatar(person: person),
      title: Text(person.displayName),
      subtitle: sub.isEmpty ? null : Text(sub),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Search dialog that returns a chosen person from the tree.
Future<Person?> pickPerson(BuildContext context, FamilyGraph graph, {Set<String> exclude = const {}}) {
  return showDialog<Person>(
    context: context,
    builder: (_) => _PersonPicker(graph: graph, exclude: exclude),
  );
}

class _PersonPicker extends StatefulWidget {
  const _PersonPicker({required this.graph, required this.exclude});

  final FamilyGraph graph;
  final Set<String> exclude;

  @override
  State<_PersonPicker> createState() => _PersonPickerState();
}

class _PersonPickerState extends State<_PersonPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = widget.graph.search(_query).where((p) => !widget.exclude.contains(p.id)).toList();
    return AlertDialog(
      title: Text(context.l10n.selectPerson),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: 420,
        height: 480,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.searchHint,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: results.isEmpty
                ? Center(child: Text(context.l10n.noResults))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (_, i) => PersonTile(
                      person: results[i],
                      onTap: () => Navigator.pop(context, results[i]),
                    ),
                  ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
      ],
    );
  }
}

/// Section header used on profile and settings pages.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
      child: Row(children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        ?action,
      ]),
    );
  }
}

Future<bool> confirm(BuildContext context, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.l10n.no)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(c.l10n.yes)),
      ],
    ),
  );
  return ok ?? false;
}
