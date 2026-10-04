import 'dart:io';

import 'package:bua_family/services/offline_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final cache = OfflineCache.instance;

  test('a successful load is saved, and used when the network is gone', () async {
    final first = await cachedRead('u:feed', () async => [
          {'id': 'p1', 'body': 'Sallah day'},
        ], jsonRows);
    expect(first.single['body'], 'Sallah day');
    expect(cache.usingSaved.value, isFalse);
    await Future<void>.delayed(Duration.zero); // saving happens in the background

    final offline = await cachedRead<List<Map<String, dynamic>>>(
      'u:feed',
      () async => throw const SocketException('Failed host lookup: example.supabase.co'),
      jsonRows,
    );
    expect(offline.single['body'], 'Sallah day');
    expect(cache.usingSaved.value, isTrue);

    // Back online: the bar goes away.
    await cachedRead('u:feed', () async => const <Map<String, dynamic>>[], jsonRows);
    expect(cache.usingSaved.value, isFalse);
  });

  test('real errors are not hidden behind the saved copy', () async {
    await cachedRead('u:events', () async => [<String, dynamic>{}], jsonRows);
    await Future<void>.delayed(Duration.zero);
    expect(
      () => cachedRead('u:events', () async => throw StateError('permission denied'), jsonRows),
      throwsStateError,
    );
  });

  test('nothing saved yet: the network error comes through', () async {
    expect(
      () => cachedRead('u:never', () async => throw const SocketException('offline'), jsonRows),
      throwsA(isA<SocketException>()),
    );
  });

  test('signing out clears the saved copy', () async {
    await cache.put('u:graph', {'persons': []});
    expect(await cache.get('u:graph'), isNotNull);
    await cache.clear();
    expect(await cache.get('u:graph'), isNull);
  });

  test('which errors mean "no connection"', () {
    expect(isOfflineError(const SocketException('x')), isTrue);
    expect(isOfflineError(Exception('ClientException: XMLHttpRequest error.')), isTrue);
    expect(isOfflineError(StateError('42501 permission denied')), isFalse);
  });
}
