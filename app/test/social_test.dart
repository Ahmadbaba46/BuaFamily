import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/notification.dart';
import 'package:bua_family/models/social.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/event_screen.dart';
import 'package:bua_family/ui/screens/events_screen.dart';
import 'package:bua_family/ui/screens/home_screen.dart';
import 'package:bua_family/ui/screens/notification_settings_screen.dart';
import 'package:bua_family/ui/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain_test.dart' show buildFamily;

void main() {
  final graph = buildFamily();
  final now = DateTime(2026, 1, 1, 12);

  final members = {
    'u1': const Member(userId: 'u1', displayName: 'Aisha', personId: 'aisha'),
    'u2': const Member(userId: 'u2', displayName: 'Bello', personId: 'bello'),
    'u3': const Member(userId: 'u3', displayName: 'Admin', personId: 'sani', isAdmin: true),
  };

  final posts = [
    Post(
      id: 'p1',
      authorId: 'u3',
      createdAt: now.subtract(const Duration(days: 2)),
      kind: PostKind.announcement,
      body: 'Family meeting moved to Sunday',
      pinned: true,
    ),
    Post(
      id: 'p2',
      authorId: 'u2',
      createdAt: now.subtract(const Duration(hours: 2)),
      body: 'Maryam is home with us. Alhamdulillah.',
      likeCount: 24,
      commentCount: 8,
    ),
  ];

  final events = [
    FamilyEvent(
      id: 'e1',
      title: 'Naming ceremony',
      category: EventCategory.naming,
      startsAt: DateTime(2026, 1, 10, 8),
      place: 'Gwale, Kano',
      createdBy: 'u2',
      rsvps: const [Rsvp(userId: 'u2', response: RsvpResponse.going, guests: 2)],
    ),
    FamilyEvent(
      id: 'e2',
      title: 'Walima',
      category: EventCategory.wedding,
      startsAt: DateTime(2026, 2, 14, 14),
      createdBy: 'u3',
      rsvps: const [Rsvp(userId: 'u1', response: RsvpResponse.going)],
    ),
    FamilyEvent(id: 'e0', title: 'Last reunion', startsAt: DateTime(2025, 12, 1), createdBy: 'u3'),
  ];

  final notifications = [
    AppNotification(
      id: 'n1',
      kind: NotificationKind.birthday,
      createdAt: now.subtract(const Duration(hours: 4)),
      data: const {'person_id': 'kabir', 'name': 'Kabir Bua', 'age': 18},
      link: '/person/kabir',
    ),
    AppNotification(
      id: 'n2',
      kind: NotificationKind.event,
      createdAt: now.subtract(const Duration(days: 2)),
      data: const {'title': 'Naming ceremony'},
      actorId: 'u2',
      readAt: now,
    ),
    AppNotification(
      id: 'n3',
      kind: NotificationKind.comment,
      createdAt: now.subtract(const Duration(days: 3)),
      data: const {'body': 'Lovely'},
      actorId: 'u3',
    ),
  ];

  Widget app(Widget home, {String locale = 'en'}) {
    const profile = Profile(
      id: 'u1',
      displayName: 'Aisha',
      role: AppRole.member,
      status: AccountStatus.active,
      personId: 'aisha',
    );
    return ProviderScope(
      overrides: [
        profileProvider.overrideWithValue(profile),
        graphProvider.overrideWith((ref) async => graph),
        settingsProvider.overrideWith((ref) async => const AppSettings()),
        membersProvider.overrideWith((ref) async => members),
        feedProvider.overrideWith((ref) async => posts),
        eventsProvider.overrideWith((ref) async => events),
        myLikesProvider.overrideWith((ref) async => {'p2'}),
        albumsProvider.overrideWith((ref) async => const <Album>[]),
        commentsProvider.overrideWith((ref, target) async => const <Comment>[]),
        notificationsProvider.overrideWith((ref) => Stream.value(notifications)),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  testWidgets('home greets, shows birthdays, pinned announcement and moments', (tester) async {
    await tester.pumpWidget(app(HomeScreen(now: now)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Thursday, 1 January · '), findsOneWidget);
    expect(find.text('Salamu alaikum, aisha'), findsOneWidget);
    // Everyone in the test family is born on 1 January; the first card is the eldest.
    expect(find.text('ahmadu turns 106'), findsOneWidget);
    expect(find.text('ANNOUNCEMENT · PINNED'), findsOneWidget);
    expect(find.text('Family meeting moved to Sunday'), findsOneWidget);
    expect(find.textContaining('sani (admin)'), findsOneWidget);
    // Author relation: Bello is Aisha's brother.
    expect(find.text('bello'), findsOneWidget);
    expect(find.textContaining('Your brother'), findsOneWidget);
    expect(find.text('Ma sha Allah · 24'), findsOneWidget);
    expect(find.text('8 comments'), findsOneWidget);
  });

  testWidgets('events list upcoming with my reply, and past events', (tester) async {
    await tester.pumpWidget(app(EventsScreen(now: now)));
    await tester.pumpAndSettle();

    expect(find.text('Naming ceremony'), findsOneWidget);
    expect(find.text('JAN'), findsOneWidget);
    expect(find.text('Reply needed'), findsOneWidget);
    expect(find.text('3 going'), findsOneWidget, reason: 'Bello plus two guests');
    expect(find.text("You're going"), findsOneWidget);
    expect(find.text('Last reunion'), findsNothing);
    expect(find.text('Latest announcements'), findsOneWidget);

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();
    expect(find.text('Last reunion'), findsOneWidget);
    expect(find.text('Naming ceremony'), findsNothing);
  });

  testWidgets('events in Hausa', (tester) async {
    await tester.pumpWidget(app(EventsScreen(now: now), locale: 'ha'));
    await tester.pumpAndSettle();
    expect(find.text('Masu zuwa'), findsOneWidget);
    expect(find.text('JAN'), findsOneWidget);
    expect(find.text('Ana jiran amsarka'), findsOneWidget);
  });

  testWidgets('event page shows details, reply options and wishes', (tester) async {
    await tester.pumpWidget(app(const EventScreen(eventId: 'e1')));
    await tester.pumpAndSettle();

    expect(find.text('NAMING CEREMONY'), findsOneWidget);
    expect(find.text('Hosted by bello'), findsOneWidget);
    expect(find.text('Saturday, 10 January'), findsOneWidget);
    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('WISHES'), findsOneWidget);
    expect(find.text('3 GOING'), findsOneWidget);
  });

  test('calendar link uses UTC times', () {
    final e = FamilyEvent(id: 'x', title: 'Meet', startsAt: DateTime.utc(2026, 10, 18, 15), createdBy: 'u');
    final link = calendarLink(e).toString();
    expect(link, contains('dates=20261018T150000Z%2F20261018T170000Z'));
    expect(link, contains('text=Meet'));
  });

  test('event is upcoming until the end of its day', () {
    final e = FamilyEvent(id: 'x', title: 'Meet', startsAt: DateTime(2026, 1, 1, 9), createdBy: 'u');
    expect(e.isUpcoming(DateTime(2026, 1, 1, 20)), isTrue);
    expect(e.isUpcoming(DateTime(2026, 1, 2, 0, 1)), isFalse);
  });

  test('parses PostgREST rows with embedded counts', () {
    final p = Post.fromJson({
      'id': 'p',
      'author_id': 'u',
      'created_at': '2026-10-03T10:00:00Z',
      'kind': 'moment',
      'body': 'hi',
      'albums': {'title': 'Sallah 2026'},
      'photos': [
        {
          'id': 'ph',
          'storage_path': 'uploads/u/a.jpg',
          'uploaded_by': 'u',
          'created_at': '2026-10-03T10:00:00Z',
          'photo_people': [
            {'person_id': 'musa', 'tagged_by': 'u'},
          ],
          'like_count': [
            {'count': 3},
          ],
          'comment_count': [
            {'count': 0},
          ],
        },
      ],
      'post_people': [
        {'person_id': 'musa'},
      ],
      'like_count': [
        {'count': 5},
      ],
      'comment_count': [
        {'count': 2},
      ],
    });
    expect(p.albumTitle, 'Sallah 2026');
    expect(p.likeCount, 5);
    expect(p.commentCount, 2);
    expect(p.photos.single.people, ['musa']);
    expect(p.photos.single.taggedBy['musa'], 'u');
    expect(p.photos.single.likeCount, 3);
    expect(p.people, ['musa']);
  });

  testWidgets('home bell shows unread notifications', (tester) async {
    await tester.pumpWidget(app(HomeScreen(now: now)));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Notifications, 2'), findsOneWidget);
  });

  testWidgets('notifications list today and earlier, in the reader\'s language', (tester) async {
    await tester.pumpWidget(app(NotificationsScreen(now: now)));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text("Kabir Bua's birthday today (18)"), findsOneWidget);
    expect(find.text('New event: Naming ceremony'), findsOneWidget);
    expect(find.text('New comment: “Lovely”'), findsOneWidget);
    expect(find.text('Mark all as read'), findsOneWidget);

    await tester.pumpWidget(app(NotificationsScreen(now: now), locale: 'ha'));
    await tester.pumpAndSettle();
    expect(find.text('Ranar haihuwar Kabir Bua yau (18)'), findsOneWidget);
    expect(find.text('Sabon taro: Naming ceremony'), findsOneWidget);
  });

  testWidgets('notification settings explain that SMS is off', (tester) async {
    await tester.pumpWidget(app(const NotificationSettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Get SMS on this phone'), findsOneWidget);
    expect(find.textContaining('SMS is not switched on'), findsOneWidget);
  });

  test('phone numbers are normalised like the database does', () {
    expect(normalizePhone('0803 123 4567'), '2348031234567');
    expect(normalizePhone('+234 803 123 4567'), '2348031234567');
    expect(normalizePhone('803-123-4567'), '2348031234567');
    expect(normalizePhone('+44 7700 900123'), '447700900123');
    expect(normalizePhone('12345'), isNull);
    expect(formatPhone('2348031234567'), '+234 803 123 4567');
  });
}
