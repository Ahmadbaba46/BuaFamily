import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/models/account.dart';
import 'package:bua_family/services/app_update.dart';
import 'package:bua_family/state/providers.dart';
import 'package:bua_family/ui/screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(AppSettings settings) => ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) async => settings),
          packageInfoProvider.overrideWith((ref) async => ('1.0.250', '250')),
          androidReleaseProvider.overrideWith((ref) async => const AndroidRelease(
                build: 251,
                version: '1.0.251',
                path: 'android/bua-family-1.0.251.apk',
                notes: 'Family metrics for admins.',
              )),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AboutScreen(),
        ),
      );

  testWidgets('About shows the version, the features and the developer', (tester) async {
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(const AppSettings(
      developerName: 'Ahmad Baba',
      developerCompany: 'Fuyoudhat Tech Support',
      developerPhone: '0803 123 4567',
      developerWebsite: 'https://example.com',
    )));
    await tester.pumpAndSettle();

    expect(find.text('Bua Family'), findsOneWidget);
    expect(find.text('Version 1.0.250 · build 250'), findsOneWidget);
    expect(find.text('Newest Android app: 1.0.251'), findsOneWidget);
    expect(find.text('Family metrics for admins.'), findsOneWidget);
    expect(find.text('Family tree'), findsOneWidget);
    expect(find.text('Blood donors'), findsOneWidget);
    expect(find.text('Ahmad Baba'), findsOneWidget);
    expect(find.text('Fuyoudhat Tech Support'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Website'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    expect(find.textContaining('Fuyoudhat Tech Support. All rights reserved.'), findsOneWidget);
  });

  testWidgets('no contact buttons until an admin adds them', (tester) async {
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const AppSettings(developerCompany: 'Fuyoudhat Tech Support')));
    await tester.pumpAndSettle();
    expect(find.text('Call'), findsNothing);
    expect(find.text('Fuyoudhat Tech Support'), findsOneWidget);
  });
}
