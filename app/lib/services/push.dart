import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/providers.dart';

// The family's Firebase project ("buafamily"). These are public app
// identifiers, not secrets. The iOS API key would be supplied at build time
// (config.json); without it push is simply off there.
const _projectId = 'buafamily';
const _senderId = '974364501102';
const _webApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: 'AIzaSyAmZ5PxnlZA17w9Gd-TxcnCQqa0PS7cma8');
const _androidApiKey =
    String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: 'AIzaSyA-q9JQoH51Z8rDGHXSlsMAscLtoHElwmU');
const _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');

/// Optional: the project's own Web Push key. Without it Firebase uses its default one.
const _vapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

/// 'android', 'ios' or 'web' when push can work here; null otherwise.
String? get pushPlatformName {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => null,
  };
}

FirebaseOptions? get firebaseOptions {
  final (apiKey, appId) = switch (pushPlatformName) {
    'web' => (_webApiKey, '1:974364501102:web:01aa414fffd213efbbb27f'),
    'android' => (_androidApiKey, '1:974364501102:android:73facee05ff31edcbbb27f'),
    'ios' => (_iosApiKey, '1:974364501102:ios:6be78a1aeef1d60bbbb27f'),
    _ => ('', ''),
  };
  if (apiKey.isEmpty) return null;
  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: _senderId,
    projectId: _projectId,
    authDomain: kIsWeb ? 'buafamily.firebaseapp.com' : null,
    storageBucket: 'buafamily.firebasestorage.app',
    iosBundleId: pushPlatformName == 'ios' ? 'com.fuyoudhat.buafamily' : null,
  );
}

/// Starts Firebase. Never throws, and gives up after a while, so a network
/// that blocks Google (or a slow one) never stops the app from opening.
Future<bool> initFirebase() async {
  final options = firebaseOptions;
  if (options == null) return false;
  // Widget tests run as "Android" but have no Firebase to talk to.
  if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return false;
  try {
    await Firebase.initializeApp(options: options).timeout(const Duration(seconds: 20));
    return true;
  } catch (e) {
    debugPrint('Push notifications unavailable: $e');
    return false;
  }
}

/// Firebase started in the background, after the app is already showing.
final firebaseReadyProvider = FutureProvider<bool>((ref) => initFirebase());

enum PushPermission { granted, denied, notAsked }

/// A notification that arrived while the app was open on screen. Phones only
/// show notifications by themselves when the app is in the background.
class ForegroundPush {
  const ForegroundPush({required this.title, required this.body, this.id, this.link});

  final String? id;
  final String title;
  final String body;
  final String? link;
}

/// What the app needs from the phone or browser. Swapped out in tests.
abstract class PushPlatform {
  bool get available;
  String get platform;
  Future<PushPermission> permission();
  Future<PushPermission> requestPermission();
  Future<String?> token();
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;

  /// Pages to open: notifications tapped while the app was closed or in the background.
  Stream<String> get onOpen;

  /// Notifications that arrive while the app is open (the app shows them itself).
  Stream<ForegroundPush> get onForeground;
}

class NoPushPlatform implements PushPlatform {
  const NoPushPlatform();
  @override
  bool get available => false;
  @override
  String get platform => '';
  @override
  Future<PushPermission> permission() async => PushPermission.denied;
  @override
  Future<PushPermission> requestPermission() async => PushPermission.denied;
  @override
  Future<String?> token() async => null;
  @override
  Future<void> deleteToken() async {}
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
  @override
  Stream<String> get onOpen => const Stream.empty();
  @override
  Stream<ForegroundPush> get onForeground => const Stream.empty();
}

class FirebasePushPlatform implements PushPlatform {
  FirebasePushPlatform() {
    FirebaseMessaging.onMessageOpenedApp.listen(_opened);
    FirebaseMessaging.instance.getInitialMessage().then((m) {
      if (m != null) _opened(m);
    });
    // In the foreground the bell updates live, so no banner on top of it.
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: false, badge: true, sound: false);
  }

  final _opens = StreamController<String>.broadcast();
  final _fcm = FirebaseMessaging.instance;

  void _opened(RemoteMessage m) {
    final link = m.data['link'];
    if (link is String && link.startsWith('/')) _opens.add(link);
  }

  @override
  bool get available => true;
  @override
  String get platform => pushPlatformName!;

  static PushPermission _map(AuthorizationStatus s) => switch (s) {
        AuthorizationStatus.authorized || AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notAsked,
      };

  @override
  Future<PushPermission> permission() async => _map((await _fcm.getNotificationSettings()).authorizationStatus);
  @override
  Future<PushPermission> requestPermission() async => _map((await _fcm.requestPermission()).authorizationStatus);
  @override
  Future<String?> token() => _fcm.getToken(vapidKey: kIsWeb && _vapidKey.isNotEmpty ? _vapidKey : null);
  @override
  Future<void> deleteToken() => _fcm.deleteToken();
  @override
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;
  @override
  Stream<String> get onOpen => _opens.stream;
  @override
  Stream<ForegroundPush> get onForeground => FirebaseMessaging.onMessage.map((m) {
        final link = m.data['link'];
        return ForegroundPush(
          id: m.data['id'] as String?,
          title: m.notification?.title ?? '',
          body: m.notification?.body ?? '',
          link: link is String && link.startsWith('/') ? link : null,
        );
      });
}

/// The real platform once Firebase is up; until then (or without it) none.
final pushPlatformProvider = Provider<PushPlatform>(
  (ref) => ref.watch(firebaseReadyProvider).value ?? false ? FirebasePushPlatform() : const NoPushPlatform(),
);

class PushState {
  const PushState({this.on = false, this.permission = PushPermission.notAsked, this.busy = false});

  /// The member turned notifications on for this device.
  final bool on;
  final PushPermission permission;
  final bool busy;

  PushState copyWith({bool? on, PushPermission? permission, bool? busy}) =>
      PushState(on: on ?? this.on, permission: permission ?? this.permission, busy: busy ?? this.busy);
}

enum PushResult { on, off, blocked, unavailable, failed }

/// Notifications on this device: asks permission, keeps the device's token
/// registered for whoever is signed in, and forgets it on sign-out.
class PushController extends Notifier<PushState> {
  static const _key = 'push_on';
  StreamSubscription<String>? _refreshSub;

  late PushPlatform _platform;

  @override
  PushState build() {
    _platform = ref.watch(pushPlatformProvider);
    ref.onDispose(() {
      _refreshSub?.cancel();
      _refreshSub = null;
    });
    _load();
    return const PushState();
  }

  Future<void> _load() async {
    if (!_platform.available) return;
    var on = false;
    try {
      on = (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {}
    final permission = await _platform.permission();
    state = state.copyWith(on: on && permission == PushPermission.granted, permission: permission);
  }

  Future<void> _remember(bool on) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, on);
    } catch (_) {}
  }

  Future<void> _register(String token) =>
      ref.read(repositoryProvider).registerPushToken(token, _platform.platform);

  /// Turn on: asks permission if needed, then registers this device.
  Future<PushResult> enable() async {
    if (!_platform.available) return PushResult.unavailable;
    state = state.copyWith(busy: true);
    try {
      var permission = await _platform.permission();
      if (permission != PushPermission.granted) permission = await _platform.requestPermission();
      if (permission != PushPermission.granted) {
        state = state.copyWith(permission: permission, on: false, busy: false);
        return PushResult.blocked;
      }
      final token = await _platform.token();
      if (token == null) throw StateError('No token');
      await _register(token);
      _listenForRefresh();
      await _remember(true);
      state = state.copyWith(on: true, permission: permission, busy: false);
      return PushResult.on;
    } catch (e) {
      debugPrint('Push enable failed: $e');
      state = state.copyWith(busy: false);
      return PushResult.failed;
    }
  }

  /// Turn off on this device.
  Future<PushResult> disable() async {
    state = state.copyWith(busy: true);
    await forgetDevice();
    await _remember(false);
    state = state.copyWith(on: false, busy: false);
    return PushResult.off;
  }

  /// After sign-in (or app start): keep this device registered if it was on.
  Future<void> resume() async {
    await _load();
    if (!state.on) return;
    try {
      final token = await _platform.token();
      if (token != null) await _register(token);
      _listenForRefresh();
    } catch (e) {
      debugPrint('Push resume failed: $e');
    }
  }

  /// Before sign-out: stop this device getting the account's notifications.
  Future<void> forgetDevice() async {
    if (!_platform.available) return;
    try {
      final token = await _platform.token();
      if (token != null) await ref.read(repositoryProvider).unregisterPushToken(token);
    } catch (e) {
      debugPrint('Push forget failed: $e');
    }
  }

  void _listenForRefresh() {
    _refreshSub ??= _platform.onTokenRefresh.listen((t) => _register(t).catchError((_) {}));
  }
}

final pushControllerProvider = NotifierProvider<PushController, PushState>(PushController.new);
