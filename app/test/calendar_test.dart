import 'package:bua_family/data/repository.dart';
import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/calendar.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/calendar_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthClientOptions, SupabaseClient;

class _FakeRepo extends FamilyRepository {
  _FakeRepo(this.cal)
      : super(SupabaseClient('https://abc.supabase.co', 'test',
            authOptions: const AuthClientOptions(autoRefreshToken: false)));

  CalendarFeed? cal;
  final calls = <String>[];

  @override
  Future<CalendarFeed?> calendarFeed() async => cal;

  @override
  Future<void> calendarLink({bool reset = false}) async {
    calls.add(reset ? 'reset' : 'link');
    cal = CalendarFeed(token: reset ? 'new' : 'tok');
  }

  @override
  Future<void> calendarSettings({bool? enabled, bool? birthdays, bool? remembrance}) async {
    calls.add('settings $enabled $birthdays $remembrance');
    final f = cal!;
    cal = CalendarFeed(
      token: f.token,
      enabled: enabled ?? f.enabled,
      includeBirthdays: birthdays ?? f.includeBirthdays,
      includeRemembrance: remembrance ?? f.includeRemembrance,
    );
  }
}

void main() {
  Widget app(_FakeRepo repo) => ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CalendarFeedScreen(),
        ),
      );

  test('links for each calendar app', () {
    final links = _FakeRepo(null).calendarLinks('abc123');
    expect(links.https, 'https://abc.supabase.co/functions/v1/calendar?token=abc123');
    expect(links.webcal, 'webcal://abc.supabase.co/functions/v1/calendar?token=abc123');
    expect(links.google,
        'https://calendar.google.com/calendar/render?cid=${Uri.encodeComponent('webcal://abc.supabase.co/functions/v1/calendar?token=abc123')}');
  });

  testWidgets('get a link, copy it, choose what it holds, renew or turn it off', (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    final repo = _FakeRepo(null);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('Add to Google Calendar'), findsNothing);
    await tester.tap(find.text('Get my calendar link'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['link']);
    expect(find.text('Add to Google Calendar'), findsOneWidget);
    expect(find.text('Add to iPhone or Outlook'), findsOneWidget);
    expect(find.text('Not added to a calendar yet'), findsOneWidget);

    await tester.tap(find.text('Copy the link'));
    await tester.pumpAndSettle();
    expect(copied, 'https://abc.supabase.co/functions/v1/calendar?token=tok');

    await tester.tap(find.text('Birthdays'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'settings null false null');
    expect(repo.cal!.includeBirthdays, isFalse);

    await tester.ensureVisible(find.text('Get a new link'));
    await tester.tap(find.text('Get a new link'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'reset');

    await tester.ensureVisible(find.text('Turn off my calendar link'));
    await tester.tap(find.text('Turn off my calendar link'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, 'settings false null null');
    expect(find.text('Get my calendar link'), findsOneWidget);
  });
}
