import 'dart:convert';
import 'dart:io' show HttpClient, Platform;
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// Tells senders their message reached this phone (two grey ticks) as soon as
/// the notification arrives, even when the app is closed.
void listenForPushInBackground() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  if (Platform.environment.containsKey('FLUTTER_TEST')) return;
  try {
    FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);
  } catch (_) {
    // No Firebase on this build: nothing to do.
  }
}

@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage message) async {
  if (message.data['kind'] != 'direct_message') return;
  DartPluginRegistrant.ensureInitialized();
  await markMessagesDelivered();
}

/// Calls dm_mark_delivered with the sign-in saved on the phone. It never
/// refreshes the sign-in (the app does that), so it does nothing once the
/// saved one has run out; the app marks them when it next opens.
Future<void> markMessagesDelivered() async {
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = 'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';
    final saved = prefs.getString(key);
    if (saved == null) return;
    final session = jsonDecode(saved) as Map<String, dynamic>;
    final token = session['access_token'] as String?;
    final expiresAt = (session['expires_at'] as num?)?.toInt();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (token == null || expiresAt == null || expiresAt < now + 30) return;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/rpc/dm_mark_delivered'));
      req.headers
        ..set('apikey', supabaseKey)
        ..set('Authorization', 'Bearer $token')
        ..set('Content-Type', 'application/json');
      req.write('{}');
      final res = await req.close();
      await res.drain<void>();
    } finally {
      client.close();
    }
  } catch (_) {
    // Best effort: the app marks them when it opens.
  }
}
