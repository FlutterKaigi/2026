import 'dart:async';

import 'package:data/src/repository/firestore_watch.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits cached data immediately and keeps one source subscription', () async {
    var listenCount = 0;
    final source = StreamController<String>(
      onListen: () => listenCount++,
    );
    addTearDown(source.close);

    final values = waitForUsableInitialSnapshot(
      source.stream,
      isUsableInitialSnapshot: (value) => value != 'empty-cache',
    ).take(2).toList();

    source
      ..add('cached-data')
      ..add('server-update');

    expect(await values, ['cached-data', 'server-update']);
    expect(listenCount, 1);
  });

  test('suppresses an empty cache until the server confirms a value', () async {
    final source = StreamController<String>();
    addTearDown(source.close);

    final values = waitForUsableInitialSnapshot(
      source.stream,
      isUsableInitialSnapshot: (value) => value != 'empty-cache',
    ).first;

    source
      ..add('empty-cache')
      ..add('server-value');

    expect(await values, 'server-value');
  });

  test('reports unavailable when no usable initial snapshot arrives', () async {
    final source = StreamController<String>();
    addTearDown(source.close);

    final values = waitForUsableInitialSnapshot(
      source.stream,
      isUsableInitialSnapshot: (value) => value != 'empty-cache',
      timeout: const Duration(milliseconds: 10),
    ).toList();

    source.add('empty-cache');

    await expectLater(
      values,
      throwsA(
        isA<FirebaseException>()
            .having((error) => error.plugin, 'plugin', 'cloud_firestore')
            .having((error) => error.code, 'code', 'unavailable'),
      ),
    );
  });

  test('forwards source errors without waiting for the timeout', () async {
    final source = StreamController<String>();
    addTearDown(source.close);
    final sourceError = StateError('listener failed');

    final values = waitForUsableInitialSnapshot(
      source.stream,
      isUsableInitialSnapshot: (_) => true,
    ).toList();

    source.addError(sourceError);

    await expectLater(values, throwsA(same(sourceError)));
  });

  test('can fall back to the last empty cache value on timeout', () async {
    final source = StreamController<String>();
    addTearDown(source.close);

    final value = waitForUsableInitialSnapshot(
      source.stream,
      isUsableInitialSnapshot: (value) => value != 'empty-cache',
      useLastRejectedValueOnTimeout: true,
      timeout: const Duration(milliseconds: 10),
    ).first;

    source.add('empty-cache');

    expect(await value, 'empty-cache');
  });

  test('drops rejected updates after the initial value', () async {
    final source = StreamController<String>();
    addTearDown(source.close);

    final values = waitForUsableInitialSnapshot(
      source.stream,
      isUsableInitialSnapshot: (_) => true,
      shouldForwardAfterInitial: (value) => value != 'metadata-only',
    ).take(2).toList();

    source
      ..add('cached-data')
      ..add('metadata-only')
      ..add('server-update');

    expect(await values, ['cached-data', 'server-update']);
  });

  test('reports unavailable when the source ends before its first value', () async {
    final source = StreamController<String>();

    final values = waitForUsableInitialSnapshot(
      source.stream,
      isUsableInitialSnapshot: (_) => true,
    ).toList();
    await source.close();

    await expectLater(
      values,
      throwsA(
        isA<FirebaseException>().having(
          (error) => error.code,
          'code',
          'unavailable',
        ),
      ),
    );
  });

  test('propagates cancellation to the source subscription', () async {
    var cancelled = false;
    final source = StreamController<String>(
      onCancel: () => cancelled = true,
    );
    addTearDown(source.close);

    final subscription = waitForUsableInitialSnapshot(
      source.stream,
      isUsableInitialSnapshot: (_) => true,
    ).listen((_) {});
    await subscription.cancel();

    expect(cancelled, isTrue);
  });

  test('propagates pause and resume to the source subscription', () async {
    var paused = false;
    var resumed = false;
    final source = StreamController<String>(
      onPause: () => paused = true,
      onResume: () => resumed = true,
    );
    addTearDown(source.close);

    final subscription = waitForUsableInitialSnapshot(
      source.stream,
      isUsableInitialSnapshot: (_) => true,
    ).listen((_) {});
    subscription.pause();
    await Future<void>.delayed(Duration.zero);
    subscription.resume();
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(paused, isTrue);
    expect(resumed, isTrue);
  });

  test('cancels a source that reports a synchronous listen error', () async {
    var cancelled = false;
    late StreamController<String> source;
    source = StreamController<String>(
      sync: true,
      onListen: () => source.addError(StateError('sync failure')),
      onCancel: () => cancelled = true,
    );
    addTearDown(source.close);

    final values = waitForUsableInitialSnapshot(
      source.stream,
      isUsableInitialSnapshot: (_) => true,
    ).toList();

    await expectLater(values, throwsStateError);
    expect(cancelled, isTrue);
  });
}
