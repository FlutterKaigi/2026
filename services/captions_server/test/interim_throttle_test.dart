import 'package:captions_server/captions_server.dart';
import 'package:test/test.dart';

void main() {
  test('10 rapid updates emit at <=1Hz and the last value wins', () async {
    final sw = Stopwatch()..start();
    final emits = <({int value, int atMs})>[];
    final throttle = InterimThrottle<int>(
      (v) => emits.add((value: v, atMs: sw.elapsedMilliseconds)),
      interval: const Duration(milliseconds: 200),
    );

    // 10 updates well within a single interval.
    for (var i = 1; i <= 10; i++) {
      throttle.update(i);
    }

    // Allow the trailing emission to fire.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    throttle.dispose();

    expect(emits, isNotEmpty);
    expect(emits.last.value, 10, reason: 'the most recent value must win');
    expect(emits.length, lessThanOrEqualTo(2), reason: 'only leading + trailing for a sub-interval burst');
    for (var i = 1; i < emits.length; i++) {
      expect(
        emits[i].atMs - emits[i - 1].atMs,
        greaterThanOrEqualTo(190),
        reason: 'consecutive emissions are spaced at least one interval apart (<=1Hz)',
      );
    }
  });

  test('a single update emits exactly once with that value', () async {
    var count = 0;
    int? last;
    final throttle = InterimThrottle<int>(
      (v) {
        count++;
        last = v;
      },
      interval: const Duration(milliseconds: 100),
    );

    throttle.update(42);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    throttle.dispose();

    expect(count, 1);
    expect(last, 42);
  });

  test('dispose cancels a pending trailing emission', () async {
    final emitted = <int>[];
    final throttle = InterimThrottle<int>(
      emitted.add,
      interval: const Duration(milliseconds: 200),
    );

    throttle.update(1); // leading emit
    throttle.update(2); // pending trailing
    throttle.dispose(); // should cancel the trailing emit of 2

    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(emitted, [1]);
  });
}
