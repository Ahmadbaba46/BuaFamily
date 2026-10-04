import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/kinship.dart';
import '../../l10n/l10n.dart';
import '../../models/community.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';
import '../widgets/social.dart';

enum _Tab { mentors, students, opportunities }

/// Mentors, students looking for help, and shared opportunities.
class MentorshipScreen extends ConsumerStatefulWidget {
  const MentorshipScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  ConsumerState<MentorshipScreen> createState() => _MentorshipScreenState();
}

class _MentorshipScreenState extends ConsumerState<MentorshipScreen> {
  late _Tab _tab = _Tab.values.where((t) => t.name == widget.initialTab).firstOrNull ?? _Tab.mentors;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = ref.watch(mentorshipProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/more')),
        titleSpacing: 0,
        title: Text(l.mentorsTitle, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: PillSegmented<_Tab>(
            values: _Tab.values,
            expand: true,
            height: 36,
            labelOf: (t) => switch (t) {
              _Tab.mentors => l.tabMentors,
              _Tab.students => l.tabStudents,
              _Tab.opportunities => l.tabOpportunities,
            },
            selected: _tab,
            onChanged: (t) => setState(() => _tab = t),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(mentorshipProvider.future),
            child: AsyncBody(
              value: data,
              onRetry: () => ref.invalidate(mentorshipProvider),
              builder: (m) => switch (_tab) {
                _Tab.mentors => _MentorsTab(data: m),
                _Tab.students => _StudentsTab(data: m),
                _Tab.opportunities => _OpportunitiesTab(data: m),
              },
            ),
          ),
        ),
      ]),
    );
  }
}

String? _relation(WidgetRef ref, AppLocalizations l, Author a) {
  final graph = ref.read(graphProvider).value;
  final me = ref.read(profileProvider)?.personId;
  if (graph == null || me == null || a.person == null || a.person!.id == me) return null;
  final k = kinshipOf(graph, me, a.person!.id);
  return k.type == KinType.none ? null : l.kinshipToYou(k);
}

class _MentorsTab extends ConsumerWidget {
  const _MentorsTab({required this.data});

  final Mentorship data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(profileProvider)?.id;
    final mine = data.mentors.where((m) => m.userId == me).firstOrNull;
    final toMe = data.asks.where((a) => a.mentorUserId == me).toList();
    final fromMe = data.asks.where((a) => a.fromUserId == me).toList();
    final latest = data.opportunities.firstOrNull;

    Future<void> offer() async {
      final v = await showFormDialog(context, title: l.offerToMentor, fields: [
        TextSpec('areas', l.mentorAreas, initial: mine?.areas, required: true, hint: l.mentorAreasHint),
        TextSpec('note', l.notes, initial: mine?.note, multiline: true),
      ]);
      if (v == null || !context.mounted) return;
      if (await guarded(context, () => ref.read(repositoryProvider).setMentor(areas: v['areas'] as String, note: v['note'] as String?))) {
        ref.invalidate(mentorshipProvider);
      }
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      if (latest != null) ...[
        PinnedCard(
          icon: Icons.school_outlined,
          label: l.newOpportunity,
          title: [latest.title, if (latest.deadline != null) l.deadlineOn(l.formatDate(latest.deadline!))].join(' · '),
          meta: l.sharedBy(authorOf(ref, latest.postedBy).name),
          onTap: latest.url == null ? null : () => launchUrl(Uri.parse(latest.url!)),
        ),
        const SizedBox(height: 16),
      ],
      for (final (title, asks) in [(l.asksToYou, toMe), (l.yourAsks, fromMe)])
        if (asks.isNotEmpty) ...[
          GroupHeading(title),
          const SizedBox(height: 8),
          Material(
            color: Bua.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (final (i, a) in asks.indexed) ...[
                if (i > 0) const InsetDivider(indent: 66),
                _ConversationRow(ask: a),
              ],
            ]),
          ),
          const SizedBox(height: 16),
        ],
      GroupHeading(l.offeringGuidance),
      const SizedBox(height: 8),
      if (data.mentors.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(l.noMentorsYet, style: TextStyle(color: Bua.inkSubtle)),
        )
      else
        Container(
          decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            for (final (i, m) in data.mentors.indexed) ...[
              if (i > 0) const InsetDivider(indent: 70),
              _MentorRow(mentor: m, isMe: m.userId == me),
            ],
          ]),
        ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: offer,
            icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
            label: Text(mine == null ? l.offerToMentor : l.editMentoring),
          ),
        ),
        if (mine != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              if (await guarded(context, ref.read(repositoryProvider).stopMentoring)) ref.invalidate(mentorshipProvider);
            },
            child: Text(l.stopMentoring),
          ),
        ],
      ]),
    ]);
  }
}

/// One mentorship conversation: who, the latest message, and whether it's new.
class _ConversationRow extends ConsumerWidget {
  const _ConversationRow({required this.ask});

  final MentorAsk ask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(profileProvider)?.id;
    final who = authorOf(ref, ask.otherThan(me));
    final unread = ask.unreadFor(me);
    final last = ask.lastMessage ?? ask.message;
    return ListTile(
      leading: AuthorAvatar(who),
      title: Text(who.name, style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w600)),
      subtitle: Text(
        '${ask.lastMessageBy == me || (ask.lastMessageBy == null && ask.fromUserId == me) ? l.youPrefix(last) : last} · ${l.ago(ask.activeAt)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: unread ? Bua.ink : Bua.inkMuted, fontWeight: unread ? FontWeight.w500 : FontWeight.w400),
      ),
      trailing: unread
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Bua.green, borderRadius: BorderRadius.circular(10)),
              child: Text(l.newMessages, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
            )
          : Icon(Icons.chevron_right, color: Bua.inkSubtle),
      onTap: () => context.push('/mentors/ask/${ask.id}'),
    );
  }
}

class _MentorRow extends ConsumerWidget {
  const _MentorRow({required this.mentor, required this.isMe});

  final Mentor mentor;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final who = authorOf(ref, mentor.userId);
    final rel = _relation(ref, l, who);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(children: [
        AuthorAvatar(who),
        const SizedBox(width: 14),
        Expanded(
          child: InkWell(
            onTap: who.person == null ? null : () => context.push('/person/${who.person!.id}'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(who.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(mentor.areas, style: TextStyle(fontSize: 13, color: Bua.inkBody)),
              if (rel != null) Text(rel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Bua.green)),
            ]),
          ),
        ),
        if (!isMe)
          FilledButton.tonal(
            onPressed: () async {
              final v = await showFormDialog(context, title: l.askMentorTitle(who.person?.firstName ?? who.name), fields: [
                TextSpec('msg', l.askMentorHint, multiline: true, required: true),
              ]);
              if (v == null || !context.mounted) return;
              String? id;
              if (await guarded(context, () async => id = await ref.read(repositoryProvider).askMentor(mentor.userId, v['msg'] as String))) {
                ref.invalidate(mentorshipProvider);
                if (!context.mounted) return;
                showSnack(context, l.askSent(who.person?.firstName ?? who.name));
                if (id != null) context.push('/mentors/ask/$id');
              }
            },
            child: Text(l.ask),
          ),
      ]),
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  const _StudentsTab({required this.data});

  final Mentorship data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(profileProvider)?.id;
    final mine = data.students.where((s) => s.userId == me).firstOrNull;
    final now = DateTime.now();

    Future<void> edit() async {
      final v = await showFormDialog(context, title: l.imLookingForHelp, fields: [
        TextSpec('field', l.studyField, initial: mine?.field, required: true),
        TextSpec('msg', l.whatHelp, initial: mine?.message, multiline: true, required: true),
      ]);
      if (v == null || !context.mounted) return;
      if (await guarded(context, () => ref.read(repositoryProvider).setMenteeRequest(field: v['field'] as String, message: v['msg'] as String))) {
        ref.invalidate(mentorshipProvider);
      }
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      GroupHeading(l.lookingForHelp),
      const SizedBox(height: 8),
      if (data.students.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(l.noStudentsYet, style: TextStyle(color: Bua.inkSubtle)),
        ),
      for (final s in data.students) ...[
        Builder(builder: (context) {
          final who = authorOf(ref, s.userId);
          final birth = who.person?.birthDate;
          final age = birth == null || (who.person?.birthDateApprox ?? true)
              ? null
              : now.year - birth.year - ((now.month < birth.month || (now.month == birth.month && now.day < birth.day)) ? 1 : 0);
          return Material(
            color: Bua.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: who.person == null ? null : () => context.push('/person/${who.person!.id}'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AuthorAvatar(who),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text([who.name, if (age != null) '$age'].join(' · '),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(s.field, style: TextStyle(fontSize: 13, color: Bua.green, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('“${s.message}”', style: const TextStyle(fontSize: 14, height: 1.4, fontStyle: FontStyle.italic)),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 6),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: edit,
            icon: const Icon(Icons.school_outlined, size: 18),
            label: Text(mine == null ? l.imLookingForHelp : l.editMyRequest),
          ),
        ),
        if (mine != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              if (await guarded(context, ref.read(repositoryProvider).removeMenteeRequest)) ref.invalidate(mentorshipProvider);
            },
            child: Text(l.removeMyRequest),
          ),
        ],
      ]),
    ]);
  }
}

class _OpportunitiesTab extends ConsumerWidget {
  const _OpportunitiesTab({required this.data});

  final Mentorship data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(profileProvider);

    Future<void> share() async {
      final title = TextEditingController();
      final details = TextEditingController();
      final url = TextEditingController();
      DateTime? deadline;
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => StatefulBuilder(
          builder: (c, setState) => AlertDialog(
            title: Text(l.shareOpportunity),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: title, decoration: InputDecoration(labelText: l.opportunityTitle)),
                  const SizedBox(height: 12),
                  TextField(controller: details, minLines: 2, maxLines: 5, decoration: InputDecoration(labelText: l.details)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: url,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(labelText: l.link, hintText: 'https://'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: c,
                        initialDate: deadline ?? now.add(const Duration(days: 30)),
                        firstDate: now,
                        lastDate: DateTime(now.year + 3),
                      );
                      if (d != null) setState(() => deadline = d);
                    },
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(deadline == null ? l.deadlineOptional : l.formatDate(deadline!)),
                  ),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.post)),
            ],
          ),
        ),
      );
      if (ok != true || title.text.trim().isEmpty || !context.mounted) return;
      var link = url.text.trim();
      if (link.isNotEmpty && !link.startsWith('http')) link = 'https://$link';
      if (await guarded(
        context,
        () => ref.read(repositoryProvider).shareOpportunity(
              title: title.text,
              details: details.text.trim().isEmpty ? null : details.text.trim(),
              url: link.isEmpty ? null : link,
              deadline: deadline,
            ),
      )) {
        ref.invalidate(mentorshipProvider);
      }
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      if (data.opportunities.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(l.noOpportunitiesYet, style: TextStyle(color: Bua.inkSubtle)),
        ),
      for (final o in data.opportunities) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(o.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              [
                l.sharedBy(authorOf(ref, o.postedBy).name),
                if (o.deadline != null) l.deadlineOn(l.formatDate(o.deadline!)),
              ].join(' · '),
              style: TextStyle(fontSize: 12, color: Bua.inkSubtle),
            ),
            if (o.details?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              Text(o.details!, style: const TextStyle(fontSize: 14, height: 1.4)),
            ],
            Row(children: [
              if (o.url != null)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(o.url!)),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(l.open),
                ),
              const Spacer(),
              if (o.postedBy == me?.id || (me?.isAdmin ?? false))
                IconButton(
                  tooltip: l.delete,
                  icon: Icon(Icons.delete_outline, color: Bua.inkSubtle),
                  onPressed: () async {
                    if (await guarded(context, () => ref.read(repositoryProvider).deleteOpportunity(o.id))) {
                      ref.invalidate(mentorshipProvider);
                    }
                  },
                ),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 6),
      OutlinedButton.icon(onPressed: share, icon: const Icon(Icons.add), label: Text(l.shareOpportunity)),
    ]);
  }
}
