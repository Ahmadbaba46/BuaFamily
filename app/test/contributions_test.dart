import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/contributions.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/widgets/event_contributions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

import 'domain_test.dart' show buildFamily;

class _FakeRepo extends FamilyRepository {
  _FakeRepo({this.collection, this.gifts = const []})
      : super(SupabaseClient('http://localhost', 'test', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  EventCollection? collection;
  List<EventGift> gifts;
  final calls = <String>[];

  @override
  Future<EventCollection?> eventCollection(String eventId) async => collection;

  @override
  Future<List<EventGift>> eventGifts(String eventId) async => gifts;

  @override
  Future<void> openCollection(String eventId,
      {required String receiverId, num? target, String? payDetails, bool showAmounts = true}) async {
    calls.add('open $receiverId $target $payDetails $showAmounts');
    collection = EventCollection(
        eventId: eventId, receiverId: receiverId, target: target, payDetails: payDetails, showAmounts: showAmounts);
  }

  @override
  Future<void> giveGift(String eventId,
      {num? amount, String? item, GiftMethod method = GiftMethod.transfer, String? note, bool anonymous = false,
      bool sent = false}) async {
    calls.add('give $amount ${method.db} $anonymous $sent');
  }

  @override
  Future<void> updateGift(String id,
      {num? amount, String? item, GiftMethod? method, String? note, bool? anonymous, GiftStatus? status}) async {
    calls.add('update $id ${status?.name}');
  }
}

void main() {
  final event = FamilyEvent(
    id: 'e1',
    title: 'Naming of Fatima',
    startsAt: DateTime.now().add(const Duration(days: 10)),
    createdBy: 'u1',
    category: EventCategory.naming,
  );
  final t0 = DateTime.now().subtract(const Duration(days: 1));

  Widget app(_FakeRepo repo, {String me = 'u1'}) => ProviderScope(
        key: UniqueKey(),
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          profileProvider.overrideWithValue(Profile(
              id: me, displayName: 'x', role: AppRole.member, status: AccountStatus.active, personId: 'aisha')),
          graphProvider.overrideWith((ref) async => buildFamily()),
          membersProvider.overrideWith((ref) async => {
                'u1': const Member(userId: 'u1', displayName: 'Aisha', personId: 'aisha'),
                'u2': const Member(userId: 'u2', displayName: 'Musa', personId: 'musa'),
                'u3': const Member(userId: 'u3', displayName: 'Bello', personId: 'bello'),
              }),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: EventContributions(event: event))),
        ),
      );

  test('totals count what I can see; received counts once received', () {
    final t = giftTotals([
      EventGift(id: 'a', createdAt: t0, amount: 20000, status: GiftStatus.received),
      EventGift(id: 'b', createdAt: t0, amount: 5000, status: GiftStatus.sent),
      EventGift(id: 'c', createdAt: t0, item: 'A ram', method: GiftMethod.inKind),
    ]);
    expect(t.given, 25000);
    expect(t.received, 20000);
    expect(GiftMethod.of('in_kind'), GiftMethod.inKind);
    expect(giftWhat(EventGift(id: 'd', createdAt: t0, amount: 1500, item: 'Rice')), '₦1,500 + Rice');
  });

  testWidgets('whoever made the event opens contributions', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collect contributions'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Target in naira (optional)'), '200000');
    await tester.enterText(find.widgetWithText(TextField, 'How to pay (bank, account number, name)'), 'GTBank 0123');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.calls.single, 'open u1 200000 GTBank 0123 true');
    expect(find.text('Goes to aisha'), findsOneWidget);
    expect(find.text('GTBank 0123'), findsOneWidget);

    // Someone else's event: nothing to open.
    await tester.pumpWidget(app(_FakeRepo(), me: 'u2'));
    await tester.pumpAndSettle();
    expect(find.text('Collect contributions'), findsNothing);
  });

  testWidgets('a member gives; names stay hidden when asked; private amounts stay with the host', (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo(
      collection: const EventCollection(eventId: 'e1', receiverId: 'u1', target: 100000, showAmounts: false),
      gifts: [
        EventGift(id: 'g1', createdAt: t0, giverId: 'u3', method: GiftMethod.cash, status: GiftStatus.received),
        EventGift(id: 'g2', createdAt: t0, item: 'A ram', method: GiftMethod.inKind, anonymous: true),
      ],
    );
    await tester.pumpWidget(app(repo, me: 'u2'));
    await tester.pumpAndSettle();
    expect(find.text('2 gifts'), findsOneWidget);
    expect(find.text('bello'), findsOneWidget);
    expect(find.text('A relative'), findsOneWidget);
    expect(find.text('Only the host sees the amounts.'), findsOneWidget);
    expect(find.text('Target ₦100,000'), findsNothing, reason: 'amounts are private');
    expect(find.text('This goes to aisha, not to the welfare fund.'), findsOneWidget);

    await tester.tap(find.text('Give'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text("Enter an amount, or say what you're giving in kind"), findsOneWidget);
    expect(repo.calls, isEmpty);

    await tester.tap(find.text('Give'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Amount in naira'), '20000');
    await tester.tap(find.text('Hide my name from other members'));
    await tester.tap(find.text("I've already sent it"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.calls.single, 'give 20000 transfer true true');
  });

  testWidgets('the host sees totals and marks a gift received', (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo(
      collection: const EventCollection(eventId: 'e1', receiverId: 'u1', target: 100000, showAmounts: false),
      gifts: [
        EventGift(id: 'g1', createdAt: t0, giverId: 'u3', amount: 20000, status: GiftStatus.received),
        EventGift(id: 'g2', createdAt: t0, giverId: 'u2', amount: 5000, status: GiftStatus.sent, anonymous: true),
      ],
    );
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('₦25,000 given · ₦20,000 received'), findsOneWidget);
    expect(find.text('Target ₦100,000'), findsOneWidget);
    expect(find.text('musa'), findsOneWidget, reason: 'the host sees who gave, even anonymously');

    await tester.tap(find.text('musa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark received'));
    await tester.pumpAndSettle();
    expect(repo.calls.single, 'update g2 received');
  });
}
