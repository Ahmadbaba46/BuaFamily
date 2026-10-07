import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/l10n.dart';
import '../../models/messages.dart';
import '../../models/person.dart' show searchFold;
import '../../models/social.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/bua.dart';
import '../widgets/chat_view.dart';
import '../widgets/common.dart';
import '../widgets/dm_bubble.dart';
import '../widgets/social.dart';
import 'messages_screen.dart' show openDmWith;

/// A group's photo, or a group icon.
class GroupAvatar extends ConsumerWidget {
  const GroupAvatar(this.group, {super.key, this.radius = 20});

  final ChatGroup? group;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = group?.photoPath;
    final photo = path == null ? null : ref.watch(dmMediaProvider(path)).value;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Bua.greenTint,
      backgroundImage: photo == null ? null : MemoryImage(photo),
      child: photo == null ? Icon(Icons.groups_outlined, size: radius, color: Bua.green) : null,
    );
  }
}

/// What a group notice says: "Musa added Bello".
String groupEventText(AppLocalizations l, Map<String, dynamic>? event, String? actorId, String Function(String) nameOf) {
  final actor = actorId == null ? '' : nameOf(actorId);
  final user = event?['user'] is String ? nameOf(event!['user'] as String) : '';
  final name = event?['name'] as String? ?? '';
  return switch (event?['type']) {
    'created' => l.groupEventCreated(actor, name),
    'added' => l.groupEventAdded(actor, user),
    'removed' => l.groupEventRemoved(actor, user),
    'left' => l.groupEventLeft(user),
    'renamed' => l.groupEventRenamed(actor, name),
    'photo' => event?['removed'] == true ? l.groupEventPhotoRemoved(actor) : l.groupEventPhoto(actor),
    'only_admins' => event?['on'] == true ? l.groupEventOnlyAdmins(actor) : l.groupEventEveryone(actor),
    _ => '',
  };
}

/// Choose several family members (with an account, not me, not [exclude]).
Future<List<String>?> pickMembers(BuildContext context, {Set<String> exclude = const {}, required String title}) =>
    showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _MembersPicker(exclude: exclude, title: title),
    );

class _MembersPicker extends ConsumerStatefulWidget {
  const _MembersPicker({required this.exclude, required this.title});

  final Set<String> exclude;
  final String title;

  @override
  ConsumerState<_MembersPicker> createState() => _MembersPickerState();
}

class _MembersPickerState extends ConsumerState<_MembersPicker> {
  final _chosen = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      builder: (context, scroll) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Row(children: [
            Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge)),
            FilledButton(
              onPressed: _chosen.isEmpty ? null : () => Navigator.pop(context, _chosen.toList()),
              child: Text(_chosen.isEmpty ? l.groupAddMembers : l.groupSelected(_chosen.length)),
            ),
          ]),
        ),
        Expanded(
          child: MemberChecklist(
            exclude: widget.exclude,
            chosen: _chosen,
            onChanged: () => setState(() {}),
            scroll: scroll,
          ),
        ),
      ]),
    );
  }
}

/// Family members to tick, with a search box and "Select all".
class MemberChecklist extends ConsumerStatefulWidget {
  const MemberChecklist({
    super.key,
    required this.chosen,
    required this.onChanged,
    this.exclude = const {},
    this.scroll,
  });

  final Set<String> chosen;
  final VoidCallback onChanged;
  final Set<String> exclude;
  final ScrollController? scroll;

  @override
  ConsumerState<MemberChecklist> createState() => _MemberChecklistState();
}

class _MemberChecklistState extends ConsumerState<MemberChecklist> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final me = ref.watch(profileProvider)?.id;
    final members = ref.watch(membersProvider);
    return AsyncBody(
      value: members,
      onRetry: () => ref.invalidate(membersProvider),
      builder: (map) {
        final everyone = [
          for (final m in map.values)
            if (m.userId != me && !widget.exclude.contains(m.userId)) (m, authorOf(ref, m.userId)),
        ]..sort((a, b) => a.$2.name.toLowerCase().compareTo(b.$2.name.toLowerCase()));
        if (everyone.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(widget.exclude.isEmpty ? l.noOtherMembers : l.groupEveryoneIn,
                  textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
            ),
          );
        }
        final q = searchFold(_query.trim());
        final shown = everyone.where((e) => q.isEmpty || searchFold(e.$2.name).contains(q)).toList();
        final allChosen = shown.every((e) => widget.chosen.contains(e.$1.userId));
        return ListView(controller: widget.scroll, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchByName),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (shown.length > 1)
            CheckboxListTile(
              value: allChosen,
              title: Text(l.groupSelectAll, style: const TextStyle(fontWeight: FontWeight.w600)),
              onChanged: (v) {
                for (final e in shown) {
                  v == true ? widget.chosen.add(e.$1.userId) : widget.chosen.remove(e.$1.userId);
                }
                widget.onChanged();
              },
            ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.searchNothing(_query), textAlign: TextAlign.center, style: TextStyle(color: Bua.inkMuted)),
            ),
          for (final (Member m, Author a) in shown)
            CheckboxListTile(
              value: widget.chosen.contains(m.userId),
              secondary: AuthorAvatar(a),
              title: Text(a.name),
              subtitle: a.relation(l) == null ? null : Text(a.relation(l)!),
              onChanged: (v) {
                v == true ? widget.chosen.add(m.userId) : widget.chosen.remove(m.userId);
                widget.onChanged();
              },
            ),
        ]);
      },
    );
  }
}

/// Start a group: a name, who's in it.
class NewGroupScreen extends ConsumerStatefulWidget {
  const NewGroupScreen({super.key});

  @override
  ConsumerState<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends ConsumerState<NewGroupScreen> {
  final _name = TextEditingController();
  final _about = TextEditingController();
  final _chosen = <String>{};
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l = context.l10n;
    if (_name.text.trim().isEmpty) return showSnack(context, l.groupNeedName);
    if (_chosen.isEmpty) return showSnack(context, l.groupNeedMembers);
    setState(() => _busy = true);
    String? id;
    final ok = await guarded(context, () async {
      id = await ref
          .read(repositoryProvider)
          .createGroup(_name.text, _chosen.toList(), about: _about.text.trim().isEmpty ? null : _about.text.trim());
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok && id != null) context.pushReplacement('/groups/$id');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.newGroup)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _create,
        icon: _busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.check),
        label: Text(_chosen.isEmpty ? l.groupCreate : '${l.groupCreate} · ${_chosen.length}'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(children: [
            TextField(
              controller: _name,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.groupName, counterText: ''),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _about,
              maxLength: 500,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.groupAboutOptional, counterText: ''),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Expanded(child: CardTitle(l.groupAddMembers)),
            if (_chosen.isNotEmpty) Text(l.groupSelected(_chosen.length), style: TextStyle(color: Bua.inkSubtle)),
          ]),
        ),
        Expanded(child: MemberChecklist(chosen: _chosen, onChanged: () => setState(() {}))),
      ]),
    );
  }
}

/// A group conversation.
class GroupChatScreen extends ConsumerWidget {
  const GroupChatScreen({super.key, required this.groupId});

  final String groupId;

  void _info(BuildContext context, WidgetRef ref, DmMessage m, List<GroupMember> members, String? me) {
    final l = context.l10n;
    final others = members.where((x) => x.current && x.userId != me && !x.joinedAt.isAfter(m.createdAt)).toList();
    bool has(DateTime? at) => at != null && !at.isBefore(m.createdAt);
    final read = others.where((x) => has(x.readAt)).toList();
    final delivered = others.where((x) => !has(x.readAt) && has(x.deliveredAt)).toList();
    final waiting = others.where((x) => !has(x.readAt) && !has(x.deliveredAt)).toList();
    Widget section(String title, List<GroupMember> list, DateTime? Function(GroupMember) at, MessageStatus? s) =>
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              if (s != null) ...[Ticks(s), const SizedBox(width: 6)],
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
          for (final x in list)
            ListTile(
              dense: true,
              leading: AuthorAvatar(authorOf(ref, x.userId), radius: 16),
              title: Text(authorOf(ref, x.userId).name),
              trailing: at(x) == null ? null : Text(l.ago(at(x)!), style: TextStyle(color: Bua.inkSubtle, fontSize: 12)),
            ),
        ]);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.75),
          child: ListView(shrinkWrap: true, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l.groupMessageInfo, style: Theme.of(c).textTheme.titleMedium),
            ),
            if (read.isNotEmpty) section(l.groupReadBy, read, (x) => x.readAt, MessageStatus.read),
            if (delivered.isNotEmpty)
              section(l.groupDeliveredTo, delivered, (x) => x.deliveredAt, MessageStatus.delivered),
            if (waiting.isNotEmpty) section(l.groupNotDelivered, waiting, (_) => null, MessageStatus.sent),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(profileProvider)?.id;
    final groups = ref.watch(groupsProvider);
    final group = groups.value?.where((g) => g.id == groupId).firstOrNull;
    final members = ref.watch(groupMembersProvider(groupId)).value ?? const <GroupMember>[];
    final current = members.where((m) => m.current).toList();
    final mine = current.where((m) => m.userId == me).firstOrNull;
    final iAdmin = mine?.admin ?? false;
    String nameOf(String userId) => userId == me ? l.you : authorOf(ref, userId).name;

    final names = [
      for (final m in current)
        if (m.userId != me) authorOf(ref, m.userId).name,
      if (mine != null) l.you,
    ].join(', ');

    return ChatView(
      channel: GroupChannel(() => ref.read(repositoryProvider), groupId),
      messages: ref.watch(groupMessagesProvider(groupId)),
      onRetry: () => ref.invalidate(groupMessagesProvider(groupId)),
      reactions: ref.watch(groupReactionsProvider(groupId)).value ?? const [],
      me: me,
      nameOf: nameOf,
      showAuthors: true,
      statusOf: (m) => groupStatus(members, m.createdAt, me),
      canDelete: (m) => m.authorId == me || iAdmin,
      eventText: (m) => groupEventText(l, m.event, m.authorId, nameOf),
      onInfo: (m) => _info(context, ref, m, members, me),
      privateNote: l.groupPrivate,
      notFound: groups.hasValue && group == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.groupNotFound, textAlign: TextAlign.center, style: TextStyle(color: Bua.inkSubtle)),
              ),
            )
          : null,
      composer: members.isNotEmpty && mine == null
          ? ChatComposerNote(text: l.groupYouLeft)
          : group != null && group.onlyAdminsSend && !iAdmin
              ? ChatComposerNote(text: l.groupOnlyAdminsNote)
              : null,
      appBar: (context, typing) => AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/messages')),
        titleSpacing: 0,
        title: InkWell(
          onTap: () => context.push('/groups/$groupId/info'),
          child: Row(children: [
            GroupAvatar(group, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(group?.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                if (typing.isNotEmpty)
                  Text(typing.length == 1 ? l.groupTypingOne(nameOf(typing.first)) : l.groupTypingMany,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Bua.green))
                else if (names.isNotEmpty)
                  Text(names,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Bua.inkSubtle)),
              ]),
            ),
          ]),
        ),
        actions: [
          IconButton(
            tooltip: l.groupInfo,
            onPressed: () => context.push('/groups/$groupId/info'),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}

/// A group's name, photo, description, members and settings.
class GroupInfoScreen extends ConsumerWidget {
  const GroupInfoScreen({super.key, required this.groupId});

  final String groupId;

  Future<void> _edit(BuildContext context, WidgetRef ref, ChatGroup g) async {
    final l = context.l10n;
    final name = TextEditingController(text: g.name);
    final about = TextEditingController(text: g.about ?? '');
    final save = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.groupEdit),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: name,
            maxLength: 80,
            decoration: InputDecoration(labelText: l.groupName, counterText: ''),
          ),
          TextField(
            controller: about,
            maxLength: 500,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(labelText: l.groupAbout, counterText: ''),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.save)),
        ],
      ),
    );
    final newName = name.text.trim();
    final newAbout = about.text.trim();
    name.dispose();
    about.dispose();
    if (save != true || !context.mounted) return;
    if (newName.isEmpty) return showSnack(context, l.groupNeedName);
    await guarded(context, () => ref.read(repositoryProvider).updateGroup(groupId, name: newName, about: newAbout));
  }

  Future<void> _photo(BuildContext context, WidgetRef ref, ChatGroup g) async {
    final l = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.groupChangePhoto),
            onTap: () => Navigator.pop(c, 'change'),
          ),
          if (g.photoPath != null)
            ListTile(
              leading: Icon(Icons.delete_outline, color: Bua.danger),
              title: Text(l.groupRemovePhoto),
              onTap: () => Navigator.pop(c, 'remove'),
            ),
        ]),
      ),
    );
    if (!context.mounted || choice == null) return;
    final repo = ref.read(repositoryProvider);
    if (choice == 'remove') {
      await guarded(context, () => repo.setGroupPhoto(groupId, null));
      return;
    }
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (f == null || !context.mounted) return;
    final bytes = await f.readAsBytes();
    final name = f.name.toLowerCase();
    if (!context.mounted) return;
    await guarded(context,
        () => repo.setGroupPhoto(groupId, bytes, extension: name.contains('.') ? name.split('.').last : 'jpg'));
  }

  Future<void> _member(BuildContext context, WidgetRef ref, GroupMember m, bool iAdmin) async {
    final l = context.l10n;
    final who = authorOf(ref, m.userId);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(l.groupSendMessage),
            onTap: () => Navigator.pop(c, 'message'),
          ),
          if (who.person != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(who.name),
              onTap: () => Navigator.pop(c, 'profile'),
            ),
          if (iAdmin)
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(m.admin ? l.groupRemoveAdmin : l.groupMakeAdmin),
              onTap: () => Navigator.pop(c, 'admin'),
            ),
          if (iAdmin)
            ListTile(
              leading: Icon(Icons.person_remove_outlined, color: Bua.danger),
              title: Text(l.groupRemoveMember),
              onTap: () => Navigator.pop(c, 'remove'),
            ),
        ]),
      ),
    );
    if (!context.mounted || choice == null) return;
    final repo = ref.read(repositoryProvider);
    switch (choice) {
      case 'message':
        await openDmWith(context, ref, m.userId);
      case 'profile':
        await context.push('/person/${who.person!.id}');
      case 'admin':
        await guarded(context, () => repo.setGroupAdmin(groupId, m.userId, !m.admin));
      case 'remove':
        if (!await confirm(context, l.groupConfirmRemove(who.name)) || !context.mounted) return;
        await guarded(context, () => repo.removeFromGroup(groupId, m.userId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(profileProvider)?.id;
    final group = ref.watch(groupsProvider).value?.where((g) => g.id == groupId).firstOrNull;
    final members = ref.watch(groupMembersProvider(groupId));
    final repo = ref.read(repositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.groupInfo)),
      body: group == null
          ? Center(child: Text(l.groupNotFound, style: TextStyle(color: Bua.inkSubtle)))
          : AsyncBody(
              value: members,
              onRetry: () => ref.invalidate(groupMembersProvider(groupId)),
              builder: (all) {
                final current = all.where((m) => m.current).toList()
                  ..sort((a, b) => a.userId == me
                      ? -1
                      : b.userId == me
                          ? 1
                          : (b.admin ? 1 : 0) - (a.admin ? 1 : 0));
                final mine = current.where((m) => m.userId == me).firstOrNull;
                final iAdmin = mine?.admin ?? false;
                return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
                  Center(
                    child: GestureDetector(
                      onTap: iAdmin ? () => _photo(context, ref, group) : null,
                      child: Stack(children: [
                        GroupAvatar(group, radius: 48),
                        if (iAdmin)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Bua.green,
                              child: Icon(Icons.photo_camera, size: 16, color: Bua.surface),
                            ),
                          ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(group.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                  Text(l.groupMembersCount(current.length),
                      textAlign: TextAlign.center, style: TextStyle(color: Bua.inkSubtle)),
                  if (group.about != null) ...[
                    const SizedBox(height: 12),
                    Text(group.about!, textAlign: TextAlign.center),
                  ],
                  if (iAdmin)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _edit(context, ref, group),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(l.groupEdit),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (mine != null)
                    SectionCard(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ToggleRow(
                          title: l.groupMute,
                          subtitle: l.groupMuteHint,
                          value: mine.muted,
                          onChanged: (v) => guarded(context, () => repo.muteGroup(groupId, v)),
                        ),
                      ),
                      if (iAdmin)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ToggleRow(
                            title: l.groupOnlyAdmins,
                            value: group.onlyAdminsSend,
                            onChanged: (v) => guarded(context, () => repo.updateGroup(groupId, onlyAdminsSend: v)),
                          ),
                        ),
                    ]),
                  const SizedBox(height: 12),
                  SectionCard(title: l.groupMembersCount(current.length), children: [
                    if (iAdmin)
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Bua.green,
                            child: Icon(Icons.person_add_alt_1, color: Bua.surface),
                          ),
                          title: Text(l.groupAddMembers),
                          onTap: () async {
                            final picked = await pickMembers(context,
                                exclude: {for (final m in current) m.userId}, title: l.groupAddMembers);
                            if (picked != null && picked.isNotEmpty && context.mounted) {
                              await guarded(context, () => repo.addToGroup(groupId, picked));
                            }
                          },
                        ),
                      ),
                    for (final m in current)
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          leading: AuthorAvatar(authorOf(ref, m.userId)),
                          title: Text(m.userId == me ? l.you : authorOf(ref, m.userId).name),
                          subtitle: authorOf(ref, m.userId).relation(l) == null
                              ? null
                              : Text(authorOf(ref, m.userId).relation(l)!),
                          trailing: m.admin ? Pill(l.groupAdminBadge) : null,
                          onTap: m.userId == me ? null : () => _member(context, ref, m, iAdmin),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  if (mine != null)
                    SectionCard(children: [
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          leading: Icon(Icons.logout, color: Bua.danger),
                          title: Text(l.groupLeave, style: TextStyle(color: Bua.danger)),
                          onTap: () async {
                            if (!await confirm(context, l.groupConfirmLeave) || !context.mounted) return;
                            if (await guarded(context, () => repo.leaveGroup(groupId)) && context.mounted) {
                              context.go('/messages');
                            }
                          },
                        ),
                      ),
                    ]),
                ]);
              },
            ),
    );
  }
}
