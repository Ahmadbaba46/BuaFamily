import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/models/notification.dart';
import 'package:bua_family/ui/screens/admin_screen.dart';
import 'package:bua_family/ui/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 5, 7);
  AppNotification n(NotificationKind kind, Map<String, dynamic> data) =>
      AppNotification(id: 'x', kind: kind, createdAt: now, data: data);

  test('the weekly summary and alerts read clearly in both languages', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ha = await AppLocalizations.delegate.load(const Locale('ha'));
    final week = n(NotificationKind.weeklySummary,
        {'active': 12, 'moments': 5, 'photos': 30, 'money_in': 25000, 'waiting_suggestions': 2, 'waiting_accounts': 1});
    expect(notificationText(en, week), 'This week: 12 active, 5 moments, 30 photos, ₦25,000 in. 3 waiting for you.');
    expect(notificationText(ha, week), startsWith('Wannan mako: mutum 12 sun shiga'));
    expect(notificationText(en, n(NotificationKind.weeklySummary, {'active': 1})),
        'This week: 1 active, 0 moments, 0 photos, ₦0 in.');
    expect(
        notificationText(en,
            n(NotificationKind.adminAlert, {'alert': 'blood_no_offer', 'blood_group': 'O-', 'patient': 'Hauwa', 'hours': 2})),
        'No donor yet for O- blood for Hauwa (2 h). Please call around.');
    expect(notificationText(en, n(NotificationKind.adminAlert, {'alert': 'fund_low', 'balance': 4000, 'threshold': 10000})),
        'The welfare fund is down to ₦4,000, below ₦10,000.');
    expect(notificationText(ha, n(NotificationKind.adminAlert, {'alert': 'waiting', 'suggestions': 2, 'accounts': 1})),
        'Sun jira fiye da kwana 3: shawarwari 2, sababbin asusu 1.');
    expect(AppNotification.fromJson({
      'id': 'a',
      'kind': 'admin_alert',
      'created_at': now.toIso8601String(),
      'data': {'alert': 'fund_low'},
    })?.kind, NotificationKind.adminAlert);
  });

  testWidgets('admins set the weekly summary and the fund alert level', (tester) async {
    final saved = <Map<String, dynamic>>[];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AdminUpdatesCard(
          settings: const AppSettings(fundAlertBelow: 50000),
          save: (c) async => saved.add(c),
        ),
      ),
    ));
    expect(find.text('₦50,000'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(saved.last, {'weekly_summary': false});

    await tester.tap(find.text('Warn when the fund is below'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '20000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved.last, {'fund_alert_below': 20000});

    // Emptied: off.
    await tester.tap(find.text('Warn when the fund is below'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved.last, {'fund_alert_below': null});
  });
}
