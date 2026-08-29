import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Returns the current wall-clock time.
typedef Clock = DateTime Function();

/// Source of "now" for time-dependent UI (e.g. whether a session has ended).
///
/// Overridden in tests to pin the clock; production uses [DateTime.now].
final clockProvider = Provider<Clock>((ref) => DateTime.now);
