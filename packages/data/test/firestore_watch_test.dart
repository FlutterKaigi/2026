import 'dart:async';

import 'package:data/src/repository/firestore_watch.dart';
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

    final value = waitForUsableInitialSnapshot(
      source.stream,
      isUsableInitialSnapshot: (value) => value != 'empty-cache',
    ).first;

    source
      ..add('empty-cache')
      ..add('server-value');

    expect(await value, 'server-value');
  });

  test('forwards source errors unchanged', () async {
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

  test('drops metadata-only updates after the initial value', () async {
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
}
