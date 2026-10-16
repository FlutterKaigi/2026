import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Returns the current wall-clock time.
typedef Clock = DateTime Function();

/// Source of "now" for time-dependent UI (e.g. whether a session has ended).
///
/// Overridden in tests to pin the clock; production uses [DateTime.now].
final clockProvider = Provider<Clock>((ref) => DateTime.now);

/// [clockProvider]'s time, read again every minute, for UI that changes with
/// the time of day while it stays on screen.
final clockTickProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock();
  yield* Stream<DateTime>.periodic(const Duration(minutes: 1), (_) => clock());
});
