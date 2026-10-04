import 'package:bua_family/l10n/l10n.dart';
import 'package:bua_family/services/app_update.dart';
import 'package:bua_family/ui/screens/get_app_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final release = AndroidRelease(
    build: 260,
    version: '1.0.260',
    path: 'bua-family-1.0.260.apk',
    notes: 'Banners for notifications',
    publishedAt: DateTime(2026, 10, 4),
  );

  Widget app(Widget home, {int? installed, AndroidRelease? published, Map<String, dynamic> info = const {}}) =>
      ProviderScope(
        overrides: [
          publicInfoProvider.overrideWith((ref) async => info),
          androidReleaseProvider.overrideWith((ref) async => published),
          installedBuildProvider.overrideWith((ref) async => installed),
        ],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  test('the version comes from the build script file name', () {
    expect(versionFromFileName('bua-family-1.0.250.apk'), (250, '1.0.250'));
    expect(versionFromFileName('app-release.apk'), isNull);
  });

  testWidgets('an older Android app offers the update on Home', (tester) async {
    await tester.pumpWidget(app(const Scaffold(body: UpdateBanner()), installed: 250, published: release));
    await tester.pumpAndSettle();
    expect(find.text('A new version of the app is ready'), findsOneWidget);
    expect(find.textContaining('1.0.260'), findsOneWidget);
  });

  testWidgets('no banner when up to date', (tester) async {
    await tester.pumpWidget(app(const Scaffold(body: UpdateBanner()), installed: 260, published: release));
    await tester.pumpAndSettle();
    expect(find.text('A new version of the app is ready'), findsNothing);
  });

  testWidgets('no banner on the website', (tester) async {
    await tester.pumpWidget(app(const Scaffold(body: UpdateBanner()), published: release));
    await tester.pumpAndSettle();
    expect(find.text('A new version of the app is ready'), findsNothing);
  });

  testWidgets('the download page shows the version, notes and how to install', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const GetAppScreen(), published: release));
    await tester.pumpAndSettle();
    expect(find.text('Bua Family for Android'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Banners for notifications'), findsOneWidget);
    expect(find.textContaining('Open the downloaded file'), findsOneWidget);
  });

  testWidgets('the download page knows when you are up to date', (tester) async {
    await tester.pumpWidget(app(const GetAppScreen(), installed: 260, published: release));
    await tester.pumpAndSettle();
    expect(find.text('You have the latest version.'), findsOneWidget);
  });

  testWidgets('the download page says when nothing is published', (tester) async {
    await tester.pumpWidget(app(const GetAppScreen()));
    await tester.pumpAndSettle();
    expect(find.text("The Android app hasn't been published yet."), findsOneWidget);
  });

  testWidgets('once the app is on Google Play, the download page sends people there', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const GetAppScreen(),
        published: release,
        info: const {'play_store_url': 'https://play.google.com/store/apps/details?id=$androidPackage'}));
    await tester.pumpAndSettle();
    expect(find.text('Get it on Google Play'), findsOneWidget);
    expect(find.text('Or download the app file (APK)'), findsOneWidget);
    expect(find.text('Download'), findsNothing);
  });

  test('the Play page is the saved link, or the usual one', () {
    expect(playStoreUrlOf(null), 'https://play.google.com/store/apps/details?id=com.fuyoudhat.buafamily');
    expect(playStoreUrlOf(const {'play_store_url': 'https://play.google.com/x'}), 'https://play.google.com/x');
  });
}
