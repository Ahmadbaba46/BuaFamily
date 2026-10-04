import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../state/providers.dart';

/// Where the website lives, for links shared outside the app.
const siteUrl = String.fromEnvironment('SITE_URL', defaultValue: 'https://buafamily.vercel.app');

/// Built for Google Play (`--dart-define=PLAY_STORE=true`): updates come from
/// Play, never from a downloaded file (Play doesn't allow that).
const isPlayBuild = bool.fromEnvironment('PLAY_STORE');

/// The Android app's id on Google Play.
const androidPackage = 'com.fuyoudhat.buafamily';

/// What anyone may see: the Google Play link, the developer's contact.
final publicInfoProvider =
    FutureProvider<Map<String, dynamic>>((ref) => ref.watch(repositoryProvider).publicInfo());

/// The app's Google Play page: the link an admin saved, or the usual one.
String playStoreUrlOf(Map<String, dynamic>? info) =>
    info?['play_store_url'] as String? ?? 'https://play.google.com/store/apps/details?id=$androidPackage';

/// The Android build an admin last published (Admin → Settings → Android app).
class AndroidRelease {
  const AndroidRelease({required this.build, required this.version, required this.path, this.notes, this.publishedAt});

  final int build;
  final String version;

  /// File in the public 'releases' bucket.
  final String path;
  final String? notes;
  final DateTime? publishedAt;

  factory AndroidRelease.fromJson(Map<String, dynamic> j) => AndroidRelease(
        build: (j['build'] as num).toInt(),
        version: j['version'] as String? ?? '1.0.${j['build']}',
        path: j['path'] as String,
        notes: j['notes'] as String?,
        publishedAt: DateTime.tryParse(j['published_at'] as String? ?? '')?.toLocal(),
      );
}

final androidReleaseProvider =
    FutureProvider<AndroidRelease?>((ref) => ref.watch(repositoryProvider).androidRelease());

/// True in the installed Android app (not the website, not tests).
bool get isAndroidApp =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android && !Platform.environment.containsKey('FLUTTER_TEST');

/// 'android', 'ios' or 'web', for activity reports.
String get activityPlatform => kIsWeb
    ? 'web'
    : switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        _ => 'web',
      };

/// This app's own build number; null outside the Android app.
final installedBuildProvider = FutureProvider<int?>((ref) async {
  if (!isAndroidApp) return null;
  try {
    return int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
  } catch (_) {
    return null;
  }
});

/// The newer build to offer, when this Android app is older than the published one.
final updateAvailableProvider = Provider<AndroidRelease?>((ref) {
  final release = ref.watch(androidReleaseProvider).value;
  final installed = ref.watch(installedBuildProvider).value;
  if (release == null || installed == null) return null;
  return release.build > installed ? release : null;
});

/// "1.0.250" from a file name like bua-family-1.0.250.apk (what the build script makes).
(int, String)? versionFromFileName(String name) {
  final m = RegExp(r'(\d+)\.(\d+)\.(\d+)\.apk$', caseSensitive: false).firstMatch(name);
  if (m == null) return null;
  return (int.parse(m.group(3)!), '${m.group(1)}.${m.group(2)}.${m.group(3)}');
}
