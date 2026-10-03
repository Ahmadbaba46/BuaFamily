import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/community.dart';
import 'package:bua_family/models/social.dart' show Member;
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/mentorship_screen.dart';
import 'package:bua_family/ui/screens/polls_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain_test.dart' show buildFamily;

void main() {
  final now = DateTime.now();

  final mentorship = Mentorship(
    mentors: const [
      Mentor(userId: 'u2', areas: 'Medicine · residency applications'),
      Mentor(userId: 'u1', areas: 'Teaching'),
    ],
    students: [
      MenteeRequest(userId: 'u3', field: 'Computer Science', message: 'Help me choose a final-year project', createdAt: now),
    ],
    asks: [MentorAsk(id: 'a1', mentorUserId: 'u1', fromUserId: 'u3', message: 'Can we talk on Saturday?', createdAt: now)],
    opportunities: [
      Opportunity(
        id: 'o1',
        title: 'PTDF scholarship',
        postedBy: 'u2',
        createdAt: now,
        url: 'https://example.com',
        deadline: DateTime(2026, 10, 31),
        details: 'For postgraduate study.',
      ),
    ],
  );

  final polls = [
    Poll(
      id: 'p1',
      question: 'What should the family meeting cover?',
      createdBy: 'u2',
      createdAt: now,
      context: 'For the family meeting',
      closesAt: now.add(const Duration(days: 10)),
      options: const [
        PollOption(id: 'a', label: 'Welfare fund rules', votes: 15),
        PollOption(id: 'b', label: 'Reunion 2026 plans', votes: 7),
        PollOption(id: 'c', label: 'Family land in Katsina', votes: 4),
      ],
      myOptionId: 'a',
      resultsVisible: true,
      total: 26,
      eligible: 46,
    ),
    Poll(
      id: 'p2',
      question: 'Where should Reunion 2026 be held?',
      createdBy: 'u1',
      createdAt: now,
      closesAt: now.add(const Duration(days: 20)),
      options: const [
        PollOption(id: 'k', label: 'Kano · family house'),
        PollOption(id: 'd', label: 'Kaduna'),
      ],
    ),
    Poll(
      id: 'p3',
      question: 'Monthly welfare contribution',
      createdBy: 'u2',
      createdAt: now.subtract(const Duration(days: 30)),
      closed: true,
      options: const [
        PollOption(id: 'x', label: '₦2,000', votes: 31),
        PollOption(id: 'y', label: '₦5,000', votes: 19),
      ],
      resultsVisible: true,
      total: 50,
      eligible: 60,
    ),
  ];

  Widget app(Widget home) => ProviderScope(
        overrides: [
          profileProvider.overrideWithValue(const Profile(
            id: 'u1',
            displayName: 'Aisha',
            role: AppRole.member,
            status: AccountStatus.active,
            personId: 'aisha',
          )),
          graphProvider.overrideWith((ref) async => buildFamily()),
          membersProvider.overrideWith((ref) async => const {
                'u1': Member(userId: 'u1', displayName: 'Aisha', personId: 'aisha'),
                'u2': Member(userId: 'u2', displayName: 'Usman', personId: 'usman'),
                'u3': Member(userId: 'u3', displayName: 'Kabir', personId: 'kabir'),
              }),
          mentorshipProvider.overrideWith((ref) async => mentorship),
          pollsProvider.overrideWith((ref) async => polls),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  test('poll leader and percentages', () {
    final p = polls.first;
    expect(p.leader?.id, 'a');
    expect(p.percent(p.options.first), 58);
    expect(p.isOpen(now), isTrue);
    expect(polls.last.isOpen(now), isFalse);
  });

  testWidgets('mentors tab lists mentors, asks to me and the latest opportunity', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const MentorshipScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Medicine · residency applications'), findsOneWidget);
    expect(find.textContaining('PTDF scholarship'), findsOneWidget);
    expect(find.textContaining('Can we talk on Saturday?'), findsOneWidget);
    // I can ask other mentors, not myself, and can edit my own offer.
    expect(find.text('Ask'), findsOneWidget);
    expect(find.text('Edit my mentoring'), findsOneWidget);
  });

  testWidgets('students and opportunities tabs', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const MentorshipScreen(initialTab: 'students')));
    await tester.pumpAndSettle();
    expect(find.text('Computer Science'), findsOneWidget);

    await tester.tap(find.text('Opportunities'));
    await tester.pumpAndSettle();
    expect(find.text('For postgraduate study.'), findsOneWidget);
  });

  testWidgets('polls show results after voting, a ballot before, and decisions', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const PollsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('58%'), findsOneWidget);
    expect(find.text('26 of 46 members voted'), findsOneWidget);
    expect(find.text('Vote'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Decided'), 200);
    expect(find.text('Decided'), findsOneWidget);
    expect(find.textContaining('Monthly welfare contribution: ₦2,000'), findsOneWidget);

    // Changing my vote brings the ballot back.
    await tester.tap(find.text('Change my vote'));
    await tester.pumpAndSettle();
    expect(find.text('58%'), findsNothing);
  });

  testWidgets('a new poll needs a question and two choices', (tester) async {
    tall(tester);
    await tester.pumpWidget(app(const NewPollScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Where to meet?');
    await tester.tap(find.text('Post'));
    await tester.pump();
    expect(find.text('Add a question and at least two choices.'), findsOneWidget);

    await tester.tap(find.text('Add a choice'));
    await tester.pump();
    expect(find.text('Choice 3'), findsOneWidget);
  });
}
