import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../../models/person.dart';
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';

const _recentKey = 'recent_searches';

const searchKinds = ['post', 'event', 'album', 'photo', 'story', 'cause', 'poll', 'opportunity', 'memory', 'skill', 'work'];

String searchKindLabel(AppLocalizations l, String kind) => switch (kind) {
      'people' => l.kindPeople,
      'post' => l.kindPost,
      'event' => l.kindEvent,
      'album' => l.kindAlbum,
      'photo' => l.kindPhoto,
      'story' => l.kindStory,
      'cause' => l.kindCause,
      'poll' => l.kindPoll,
      'opportunity' => l.kindOpportunity,
      'memory' => l.kindMemory,
      'skill' => l.kindSkill,
      'work' => l.kindWork,
      _ => kind,
    };

IconData searchKindIcon(String kind) => switch (kind) {
      'post' => Icons.chat_bubble_outline,
      'event' => Icons.event_outlined,
      'album' => Icons.photo_library_outlined,
      'photo' => Icons.image_outlined,
      'story' => Icons.mic_none,
      'cause' => Icons.volunteer_activism_outlined,
      'poll' => Icons.how_to_vote_outlined,
      'opportunity' => Icons.school_outlined,
      'memory' => Icons.local_florist_outlined,
      'skill' => Icons.handyman_outlined,
      'work' => Icons.work_outline,
      _ => Icons.search,
    };

/// [text] with the part matching [query] in bold (Hausa letters match plain ones).
TextSpan highlight(String text, String query, TextStyle base) {
  final q = searchFold(query.trim());
  if (q.isEmpty) return TextSpan(text: text, style: base);
  final folded = searchFold(text);
  // Folding drops apostrophes, so positions can drift; only bold when they line up.
  final at = folded.length == text.length ? folded.indexOf(q) : -1;
  if (at < 0) return TextSpan(text: text, style: base);
  return TextSpan(style: base, children: [
    TextSpan(text: text.substring(0, at)),
    TextSpan(text: text.substring(at, at + q.length), style: const TextStyle(fontWeight: FontWeight.w700, color: Bua.ink)),
    TextSpan(text: text.substring(at + q.length)),
  ]);
}

/// One box for everything: people from the tree, and moments, events,
/// photos, stories, causes, polls, opportunities, memories, skills and work
/// the member may see.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _box = TextEditingController(text: widget.initialQuery);
  late String _query = widget.initialQuery;
  String? _kind;
  Timer? _debounce;
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _recent = p.getStringList(_recentKey) ?? const []);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _box.dispose();
    super.dispose();
  }

  void _changed(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  Future<void> _remember() async {
    final q = _query.trim();
    if (q.length < 2) return;
    final next = [q, ..._recent.where((r) => r.toLowerCase() != q.toLowerCase())].take(8).toList();
    setState(() => _recent = next);
    try {
      await (await SharedPreferences.getInstance()).setStringList(_recentKey, next);
    } catch (_) {}
  }

  Future<void> _clearRecent() async {
    setState(() => _recent = const []);
    try {
      await (await SharedPreferences.getInstance()).remove(_recentKey);
    } catch (_) {}
  }

  void _open(String link) {
    _remember();
    context.push(link);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final graph = ref.watch(graphProvider).value;
    final q = _query;
    final people = q.length < 2 || graph == null ? const <Person>[] : graph.search(q);
    final hits = ref.watch(searchProvider(q));
    final found = hits.value ?? const <SearchHit>[];
    final byKind = <String, List<SearchHit>>{};
    for (final h in found) {
      byKind.putIfAbsent(h.kind, () => []).add(h);
    }
    final kinds = [if (people.isNotEmpty) 'people', for (final k in searchKinds) if (byKind.containsKey(k)) k];
    final showKinds = _kind == null ? kinds : kinds.where((k) => k == _kind).toList();
    const subtle = TextStyle(fontSize: 13, color: Bua.inkSubtle, height: 1.35);

    Widget section(String kind, List<Widget> rows, int total) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
            child: Row(children: [
              Expanded(child: GroupHeading(searchKindLabel(l, kind))),
              if (_kind == null && total > rows.length)
                TextButton(onPressed: () => setState(() => _kind = kind), child: Text(l.showAllCount(total))),
            ]),
          ),
          Material(
            color: Bua.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (final (i, r) in rows.indexed) ...[if (i > 0) const InsetDivider(indent: 66), r],
            ]),
          ),
        ]);

    Widget hitRow(SearchHit h) {
      final person = (h.kind == 'skill' || h.kind == 'work') && graph != null ? graph[h.id] : null;
      final title = person != null ? person.displayName : (h.title ?? h.snippet ?? '');
      final sub = [
        if (person != null && h.title != null) h.title!,
        if (h.title != null && h.snippet != null && h.snippet!.isNotEmpty) h.snippet!,
        if (h.at != null) l.formatDate(h.at!),
      ].join(' · ');
      return ListTile(
        leading: person != null ? PersonAvatar(person: person) : IconTile(searchKindIcon(h.kind), background: Bua.greenTint),
        title: Text.rich(highlight(title, q, const TextStyle(fontSize: 15, color: Bua.ink)),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: sub.isEmpty ? null : Text.rich(highlight(sub, q, subtle), maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () => _open(h.link),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
        titleSpacing: 0,
        title: TextField(
          controller: _box,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _changed,
          onSubmitted: (v) {
            setState(() => _query = v.trim());
            _remember();
          },
          decoration: InputDecoration(
            hintText: l.searchEverything,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            suffixIcon: _box.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l.clear,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _box.clear();
                      _query = '';
                      _kind = null;
                    }),
                  ),
          ),
        ),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
        if (q.length < 2) ...[
          if (_recent.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Row(children: [
                Expanded(child: GroupHeading(l.recentSearches)),
                TextButton(onPressed: _clearRecent, child: Text(l.clearRecent)),
              ]),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final r in _recent)
                ActionChip(
                  avatar: const Icon(Icons.history, size: 18),
                  label: Text(r),
                  onPressed: () => setState(() {
                    _box.text = r;
                    _query = r;
                  }),
                ),
            ]),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 32, 8, 0),
            child: Column(children: [
              const Icon(Icons.manage_search, size: 48, color: Bua.inkSubtle),
              const SizedBox(height: 10),
              Text(_box.text.trim().length == 1 ? l.searchTypeMore : l.searchTips,
                  textAlign: TextAlign.center, style: const TextStyle(color: Bua.inkMuted, height: 1.45)),
            ]),
          ),
        ] else ...[
          if (kinds.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                for (final k in [null, ...kinds])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(k == null
                          ? '${l.searchAll} ${people.length + found.length}'
                          : '${searchKindLabel(l, k)} ${k == 'people' ? people.length : byKind[k]!.length}'),
                      selected: _kind == k,
                      labelStyle: TextStyle(color: _kind == k ? Colors.white : Bua.ink),
                      onSelected: (_) => setState(() => _kind = k),
                    ),
                  ),
              ]),
            ),
          if (hits.isLoading) const LinearProgressIndicator(minHeight: 2),
          for (final k in showKinds)
            if (k == 'people')
              section(
                k,
                [
                  for (final p in (_kind == null ? people.take(5) : people))
                    PersonTile(person: p, viewPhoto: true, onTap: () => _open('/person/${p.id}')),
                ],
                people.length,
              )
            else
              section(
                k,
                [for (final h in (_kind == null ? byKind[k]!.take(3) : byKind[k]!)) hitRow(h)],
                byKind[k]!.length,
              ),
          if (!hits.isLoading && kinds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Text(
                hits.hasError ? errorText(hits.error!) : l.searchNothing(q),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Bua.inkMuted),
              ),
            ),
        ],
      ]),
    );
  }
}
