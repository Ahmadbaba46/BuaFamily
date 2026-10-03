import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/l10n.dart';
import '../../models/family_graph.dart';
import '../../models/person.dart';
import '../../state/providers.dart';
import '../theme.dart';

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

/// Round avatar: photo if available, otherwise initials on a tint (green for
/// men, gold for women). Deceased people get a grey ring; [highlight] draws a
/// coloured ring instead (e.g. "this is you").
class PersonAvatar extends ConsumerWidget {
  const PersonAvatar({
    super.key,
    required this.person,
    this.radius = 20,
    this.showPhoto = true,
    this.highlight,
    this.gapColor = Bua.surface,
  });

  final Person person;
  final double radius;

  /// When off, only a photo already fetched with everyone else's is shown
  /// (see [portraitUrlsProvider]); no single request is made for it.
  final bool showPhoto;
  final Color? highlight;

  /// Colour of the thin gap between avatar and ring (the background behind it).
  final Color gapColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (bg, fg) = switch (person.sex) {
      Sex.male => (Bua.maleBg, Bua.maleFg),
      Sex.female => (Bua.femaleBg, Bua.femaleFg),
      Sex.unknown => (Bua.unknownBg, Bua.unknownFg),
    };
    final path = person.photoPath;
    final batch = path == null ? null : ref.watch(portraitUrlsProvider).value?[path];
    final url = path == null
        ? null
        : batch ?? (showPhoto ? ref.watch(photoUrlProvider(path)).value : null);
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      foregroundImage: url == null ? null : NetworkImage(url),
      child: Text(
        person.initials,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: radius * 0.66),
      ),
    );
    final ring = highlight ?? (person.isLiving ? null : Bua.lateRing);
    if (ring == null) return avatar;
    final w = radius >= 40 ? 3.0 : 2.0;
    return Container(
      padding: EdgeInsets.all(w),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring, width: w)),
      child: Container(
        padding: EdgeInsets.all(w / 2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: gapColor),
        child: avatar,
      ),
    );
  }
}

/// One-line description under a name: "Late", lifespan, branch.
String personSubtitle(BuildContext context, Person p) {
  final l = context.l10n;
  final parts = <String>[
    if (!p.isLiving) l.late(p),
    if (p.lifespan(approxPrefix: l.approxPrefix()).isNotEmpty) p.lifespan(approxPrefix: l.approxPrefix()),
    if (p.branch?.isNotEmpty ?? false) p.branch!,
  ];
  return parts.join(' · ');
}

/// Avatar, name and a grey subtitle; the standard person row.
class PersonTile extends StatelessWidget {
  const PersonTile({
    super.key,
    required this.person,
    this.trailing,
    this.onTap,
    this.subtitle,
    this.subtitleColor,
    this.highlight,
  });

  final Person person;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? subtitle;
  final Color? subtitleColor;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle ?? personSubtitle(context, person);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            PersonAvatar(person: person, highlight: highlight),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(person.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor ?? Bua.inkSubtle,
                      fontWeight: subtitleColor == null ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
              ]),
            ),
            ?trailing,
          ]),
        ),
      ),
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

/// Uppercase green heading used above plain lists.
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
            title.toUpperCase(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Bua.green),
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
