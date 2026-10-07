import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/contributions.dart';
import '../../models/fund.dart' show naira;
import '../../models/social.dart';
import '../../state/providers.dart';
import '../screens/messages_screen.dart' show pickMember;
import '../theme.dart';
import 'bua.dart';
import 'common.dart';
import 'form_dialog.dart';
import 'social.dart';

String giftMethodLabel(AppLocalizations l, GiftMethod m) => switch (m) {
  GiftMethod.transfer => l.giftsMethodTransfer,
  GiftMethod.cash => l.giftsMethodCash,
  GiftMethod.inKind => l.giftsMethodInKind,
  GiftMethod.other => l.giftsMethodOther,
};

String giftStatusLabel(AppLocalizations l, GiftStatus s) => switch (s) {
  GiftStatus.pledged => l.giftsPledged,
  GiftStatus.sent => l.giftsSent,
  GiftStatus.received => l.giftsReceived,
};

/// What a gift is, in a few words: "₦20,000", "A ram", or both.
String giftWhat(EventGift g) =>
    [if (g.amount != null) naira(g.amount!), if (g.item?.trim().isNotEmpty ?? false) g.item!.trim()].join(' + ');

/// Contributions ("gudummawa") on an event: open them, give, and (for the
/// host) see who gave what and mark gifts received.
class EventContributions extends ConsumerWidget {
  const EventContributions({super.key, required this.event});

  final FamilyEvent event;

  void _refresh(WidgetRef ref) {
    ref.invalidate(eventCollectionProvider(event.id));
    ref.invalidate(eventGiftsProvider(event.id));
  }

  /// Open contributions, or change their settings.
  Future<void> _settings(BuildContext context, WidgetRef ref, EventCollection? c) async {
    final l = context.l10n;
    final me = ref.read(profileProvider)?.id;
    // Whoever opens them receives them; the host can hand that to someone else after.
    final receiver = c?.receiverId ?? me;
    if (receiver == null) return;
    final v = await showFormDialog(
      context,
      title: c == null ? l.giftsOpen : l.giftsSettings,
      note: l.giftsOpenHint,
      fields: [
        TextSpec('target', l.giftsTarget, number: true, initial: c?.target?.toInt()),
        TextSpec('pay', l.giftsPayDetails, multiline: true, initial: c?.payDetails),
        SwitchSpec('show', l.giftsShowAmounts, initial: c?.showAmounts ?? true),
      ],
    );
    if (v == null || !context.mounted) return;
    final repo = ref.read(repositoryProvider);
    final target = v['target'] as int?;
    final pay = (v['pay'] as String?)?.trim();
    final ok = await guarded(
      context,
      () => c == null
          ? repo.openCollection(
              event.id,
              receiverId: receiver,
              target: target,
              payDetails: pay,
              showAmounts: v['show'] as bool? ?? true,
            )
          : repo.updateCollection(
              event.id,
              target: target,
              clearTarget: target == null,
              payDetails: pay ?? '',
              showAmounts: v['show'] as bool?,
            ),
    );
    if (ok) _refresh(ref);
  }

  Future<void> _changeReceiver(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final who = await pickMember(context, ref, title: l.giftsReceiver, includeMe: true);
    if (who == null || !context.mounted) return;
    if (await guarded(context, () => ref.read(repositoryProvider).updateCollection(event.id, receiverId: who))) {
      _refresh(ref);
    }
  }

  /// Give, or change what I gave.
  Future<void> _give(BuildContext context, WidgetRef ref, [EventGift? mine]) async {
    final l = context.l10n;
    final v = await showFormDialog(
      context,
      title: l.giftsGiveTitle,
      fields: [
        TextSpec('amount', l.giftsAmount, number: true, initial: mine?.amount?.toInt()),
        ChoiceSpec<GiftMethod>(
          'method',
          l.giftsMethod,
          options: {for (final m in GiftMethod.values) m: giftMethodLabel(l, m)},
          initial: mine?.method ?? GiftMethod.transfer,
        ),
        TextSpec('item', l.giftsItem, initial: mine?.item),
        TextSpec('note', l.giftsNote, multiline: true, initial: mine?.note),
        SwitchSpec('anonymous', l.giftsAnonymous, initial: mine?.anonymous ?? false),
        if (mine == null || mine.status == GiftStatus.pledged)
          SwitchSpec('sent', l.giftsAlreadySent, initial: mine?.status == GiftStatus.sent),
      ],
    );
    if (v == null || !context.mounted) return;
    final amount = v['amount'] as int?;
    final method = v['method'] as GiftMethod? ?? GiftMethod.transfer;
    final item = (v['item'] as String?)?.trim();
    if ((amount == null || amount <= 0) && !(method == GiftMethod.inKind && (item?.isNotEmpty ?? false))) {
      showSnack(context, l.giftsNeedAmount);
      return;
    }
    final repo = ref.read(repositoryProvider);
    final sent = v['sent'] as bool? ?? false;
    final ok = await guarded(
      context,
      () => mine == null
          ? repo.giveGift(
              event.id,
              amount: amount,
              item: item,
              method: method,
              note: (v['note'] as String?)?.trim(),
              anonymous: v['anonymous'] as bool? ?? false,
              sent: sent,
            )
          : repo.updateGift(
              mine.id,
              amount: amount,
              item: item ?? '',
              method: method,
              note: (v['note'] as String?)?.trim() ?? '',
              anonymous: v['anonymous'] as bool?,
              status: sent ? GiftStatus.sent : null,
            ),
    );
    if (ok) _refresh(ref);
  }

  Future<void> _setStatus(BuildContext context, WidgetRef ref, EventGift g, GiftStatus s) async {
    if (await guarded(context, () => ref.read(repositoryProvider).updateGift(g.id, status: s))) _refresh(ref);
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref, EventGift g) async {
    if (!await confirm(context, context.l10n.giftsConfirmWithdraw) || !context.mounted) return;
    if (await guarded(context, () => ref.read(repositoryProvider).deleteGift(g.id))) _refresh(ref);
  }

  String _listText(AppLocalizations l, WidgetRef ref, List<EventGift> gifts) {
    final t = giftTotals(gifts);
    return [
      '${event.title} · ${l.giftsTitle}',
      for (final (i, g) in gifts.indexed)
        '${i + 1}. ${g.giverId == null ? l.giftsAnonymousGiver : authorOf(ref, g.giverId!).name}'
            '${giftWhat(g).isEmpty ? '' : ' — ${giftWhat(g)}'} (${giftStatusLabel(l, g.status)})',
      if (t.given > 0) l.giftsTotals(naira(t.given), naira(t.received)),
    ].join('\n');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(profileProvider);
    final collection = ref.watch(eventCollectionProvider(event.id));
    final mayOpen = event.createdBy == me?.id || (me?.isAdmin ?? false);
    final c = collection.value;
    if (c == null) {
      if (!mayOpen || !collection.hasValue) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: DashedBox(
          onTap: () => _settings(context, ref, null),
          child: Row(
            children: [
              Icon(Icons.redeem_outlined, color: Bua.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.giftsOpen, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(l.giftsOpenHint, style: TextStyle(fontSize: 13, color: Bua.inkMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final runs = mayOpen || c.receiverId == me?.id;
    final receiver = authorOf(ref, c.receiverId);
    final gifts = ref.watch(eventGiftsProvider(event.id)).value ?? const <EventGift>[];
    final mine = gifts.where((g) => g.giverId == me?.id).toList();
    final amountsShown = c.showAmounts || runs;
    final totals = giftTotals(gifts);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SectionCard(
        title: l.giftsTitle,
        trailing: runs
            ? PopupMenuButton<String>(
                onSelected: (v) async {
                  final repo = ref.read(repositoryProvider);
                  switch (v) {
                    case 'settings':
                      await _settings(context, ref, c);
                    case 'receiver':
                      await _changeReceiver(context, ref);
                    case 'open':
                      if (await guarded(context, () => repo.updateCollection(event.id, open: !c.open))) _refresh(ref);
                    case 'copy':
                      await Clipboard.setData(ClipboardData(text: _listText(l, ref, gifts)));
                      if (context.mounted) showSnack(context, l.giftsListCopied);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'settings', child: Text(l.giftsSettings)),
                  PopupMenuItem(value: 'receiver', child: Text(l.giftsReceiver)),
                  PopupMenuItem(value: 'copy', child: Text(l.giftsCopyList)),
                  PopupMenuItem(value: 'open', child: Text(c.open ? l.giftsClose : l.giftsReopen)),
                ],
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AuthorAvatar(receiver, radius: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.giftsGoesTo(receiver.name), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(l.giftsCount(gifts.length), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                if (amountsShown && totals.given > 0)
                  Text(
                    l.giftsTotals(naira(totals.given), naira(totals.received)),
                    style: TextStyle(fontSize: 13, color: Bua.inkMuted),
                  ),
                if (amountsShown && c.target != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (totals.given / c.target!).clamp(0, 1).toDouble(),
                      minHeight: 8,
                      backgroundColor: Bua.track,
                      color: Bua.green,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(l.giftsOfTarget(naira(c.target!)), style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                ],
                if (!c.showAmounts)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(l.giftsPrivateAmounts, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                  ),
                if (c.payDetails?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    decoration: BoxDecoration(color: Bua.ground, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(child: SelectableText(c.payDetails!.trim(), style: const TextStyle(height: 1.4))),
                        IconButton(
                          tooltip: l.giftsCopyDetails,
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: c.payDetails!.trim()));
                            if (context.mounted) showSnack(context, l.giftsDetailsCopied);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(l.giftsNotWelfare(receiver.name), style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
                const SizedBox(height: 10),
                if (c.open)
                  FilledButton.icon(
                    onPressed: () => _give(context, ref),
                    icon: const Icon(Icons.redeem_outlined),
                    label: Text(l.giftsGive),
                  )
                else
                  Text(
                    l.giftsClosed,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Bua.inkMuted),
                  ),
              ],
            ),
          ),
          for (final g in gifts)
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: g.giverId == null
                    ? CircleAvatar(
                        radius: 18,
                        backgroundColor: Bua.track,
                        child: Icon(Icons.person_outline, size: 18, color: Bua.inkSubtle),
                      )
                    : AuthorAvatar(authorOf(ref, g.giverId!), radius: 18),
                title: Text(
                  g.giverId == null
                      ? l.giftsAnonymousGiver
                      : g.giverId == me?.id
                      ? l.giftsYours
                      : authorOf(ref, g.giverId!).name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (giftWhat(g).isNotEmpty) giftWhat(g),
                    giftMethodLabel(l, g.method),
                    if (g.note?.isNotEmpty ?? false) '“${g.note}”',
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Pill(
                  giftStatusLabel(l, g.status),
                  background: g.status == GiftStatus.received ? Bua.greenTint : Bua.track,
                  color: g.status == GiftStatus.received ? Bua.green : Bua.inkMuted,
                ),
                onTap: g.giverId != me?.id && !runs ? null : () => _giftMenu(context, ref, g, runs, mine.contains(g)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _giftMenu(BuildContext context, WidgetRef ref, EventGift g, bool runs, bool isMine) async {
    final l = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMine && g.status == GiftStatus.pledged)
              ListTile(
                leading: const Icon(Icons.check),
                title: Text(l.giftsMarkSent),
                onTap: () => Navigator.pop(c, 'sent'),
              ),
            if (isMine && g.status != GiftStatus.received)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l.giftsEdit),
                onTap: () => Navigator.pop(c, 'edit'),
              ),
            if (runs && g.status != GiftStatus.received)
              ListTile(
                leading: Icon(Icons.done_all, color: Bua.green),
                title: Text(l.giftsMarkReceived),
                onTap: () => Navigator.pop(c, 'received'),
              ),
            if (runs && g.status == GiftStatus.received)
              ListTile(
                leading: const Icon(Icons.undo),
                title: Text(l.giftsMarkNotReceived),
                onTap: () => Navigator.pop(c, 'unreceived'),
              ),
            if ((isMine && g.status != GiftStatus.received) || runs)
              ListTile(
                leading: Icon(Icons.delete_outline, color: Bua.danger),
                title: Text(l.giftsWithdraw),
                onTap: () => Navigator.pop(c, 'withdraw'),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case 'sent':
        await _setStatus(context, ref, g, GiftStatus.sent);
      case 'edit':
        await _give(context, ref, g);
      case 'received':
        await _setStatus(context, ref, g, GiftStatus.received);
      case 'unreceived':
        await _setStatus(context, ref, g, GiftStatus.sent);
      case 'withdraw':
        await _withdraw(context, ref, g);
    }
  }
}
