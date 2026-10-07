/// Contributions ("gudummawa") on a wedding, naming or other event.
library;

enum GiftMethod {
  transfer('transfer'),
  cash('cash'),
  inKind('in_kind'),
  other('other');

  const GiftMethod(this.db);
  final String db;

  static GiftMethod of(String? v) => values.firstWhere((m) => m.db == v, orElse: () => GiftMethod.transfer);
}

enum GiftStatus { pledged, sent, received }

/// Contributions opened on an event: who receives them and how to pay.
class EventCollection {
  const EventCollection({
    required this.eventId,
    required this.receiverId,
    this.target,
    this.payDetails,
    this.showAmounts = true,
    this.open = true,
    this.createdBy,
  });

  final String eventId;
  final String receiverId;
  final num? target;

  /// Bank, account number, account name.
  final String? payDetails;

  /// Whether members see each other's amounts (the host always does).
  final bool showAmounts;
  final bool open;
  final String? createdBy;

  factory EventCollection.fromJson(Map<String, dynamic> j) => EventCollection(
        eventId: j['event_id'] as String,
        receiverId: j['receiver_id'] as String,
        target: j['target'] as num?,
        payDetails: j['pay_details'] as String?,
        showAmounts: j['show_amounts'] as bool? ?? true,
        open: j['open'] as bool? ?? true,
        createdBy: j['created_by'] as String?,
      );
}

/// One gift, as I may see it: [giverId] is null when the giver chose to stay
/// anonymous, [amount] when amounts are kept for the host.
class EventGift {
  const EventGift({
    required this.id,
    required this.createdAt,
    this.giverId,
    this.amount,
    this.item,
    this.method = GiftMethod.transfer,
    this.note,
    this.anonymous = false,
    this.status = GiftStatus.pledged,
    this.receivedAt,
  });

  final String id;
  final String? giverId;
  final num? amount;
  final String? item;
  final GiftMethod method;
  final String? note;
  final bool anonymous;
  final GiftStatus status;
  final DateTime createdAt;
  final DateTime? receivedAt;

  factory EventGift.fromJson(Map<String, dynamic> j) => EventGift(
        id: j['id'] as String,
        giverId: j['giver_id'] as String?,
        amount: j['amount'] as num?,
        item: j['item'] as String?,
        method: GiftMethod.of(j['method'] as String?),
        note: j['note'] as String?,
        anonymous: j['anonymous'] as bool? ?? false,
        status: GiftStatus.values.asNameMap()[j['status']] ?? GiftStatus.pledged,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        receivedAt: j['received_at'] == null ? null : DateTime.parse(j['received_at'] as String).toLocal(),
      );
}

/// What has been given and received, in naira (of the amounts I can see).
({num given, num received}) giftTotals(Iterable<EventGift> gifts) {
  num given = 0, received = 0;
  for (final g in gifts) {
    final a = g.amount ?? 0;
    given += a;
    if (g.status == GiftStatus.received) received += a;
  }
  return (given: given, received: received);
}
