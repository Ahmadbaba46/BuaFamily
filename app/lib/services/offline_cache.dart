import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthRetryableFetchException;

/// A copy of what was last loaded (tree, members, feed, events...), kept on
/// the phone so the app still opens and reads without a connection.
///
/// Stored as JSON files in the app's private folder (in the browser, or if
/// there is no folder: the app's preferences). Cleared on sign-out.
class OfflineCache {
  OfflineCache._();

  static final instance = OfflineCache._();

  /// True while something on screen came from the saved copy because the
  /// network couldn't be reached.
  final usingSaved = ValueNotifier<bool>(false);

  static const _prefix = 'offline:';
  bool _disabled = false;
  Directory? _dir;

  Future<Directory?> _folder() async {
    if (_disabled || kIsWeb) return null;
    try {
      return _dir ??= await Directory('${(await getApplicationSupportDirectory()).path}/offline').create(recursive: true);
    } catch (_) {
      _disabled = true; // e.g. in tests
      return null;
    }
  }

  String _file(String key) => key.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

  Future<void> put(String key, Object? json) async {
    try {
      final text = jsonEncode(json);
      final dir = await _folder();
      if (dir == null) {
        await (await SharedPreferences.getInstance()).setString('$_prefix$key', text);
      } else {
        await File('${dir.path}/${_file(key)}.json').writeAsString(text, flush: true);
      }
    } catch (_) {}
  }

  Future<Object?> get(String key) async {
    try {
      String? text;
      final dir = await _folder();
      if (dir == null) {
        text = (await SharedPreferences.getInstance()).getString('$_prefix$key');
      } else {
        final file = File('${dir.path}/${_file(key)}.json');
        if (await file.exists()) text = await file.readAsString();
      }
      return text == null ? null : jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    usingSaved.value = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
        await prefs.remove(k);
      }
      final dir = await _folder();
      if (dir != null && await dir.exists()) await dir.delete(recursive: true);
      _dir = null;
    } catch (_) {}
  }
}

/// The request failed because there is no connection (not because it was refused).
bool isOfflineError(Object e) {
  if (e is TimeoutException || e is AuthRetryableFetchException) return true;
  final text = e.toString();
  return const [
    'SocketException',
    'ClientException',
    'Failed host lookup',
    'Connection refused',
    'Connection reset',
    'Network is unreachable',
    'XMLHttpRequest error',
    'Failed to fetch',
  ].any(text.contains);
}

/// Loads [fetch] and saves a copy under [key]; without a connection, answers
/// from the saved copy instead (and says so through [OfflineCache.usingSaved]).
Future<T> cachedRead<T>(String key, Future<Object?> Function() fetch, T Function(Object? raw) parse) async {
  final cache = OfflineCache.instance;
  try {
    final raw = await fetch();
    unawaited(cache.put(key, raw));
    cache.usingSaved.value = false;
    return parse(raw);
  } catch (e) {
    if (!isOfflineError(e)) rethrow;
    final saved = await cache.get(key);
    if (saved == null) rethrow;
    cache.usingSaved.value = true;
    return parse(saved);
  }
}

/// JSON rows (from the network or the saved copy) as typed maps.
List<Map<String, dynamic>> jsonRows(Object? raw) =>
    [for (final r in (raw as List? ?? const [])) Map<String, dynamic>.from(r as Map)];
