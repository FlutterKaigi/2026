import 'dart:async';

/// Rate-limits updates to at most one emission per [interval], always emitting
/// the most recent value (leading edge + trailing edge). Consecutive emissions
/// are spaced at least [interval] apart, so the output rate never exceeds
/// 1/[interval] (1Hz by default) — see §5.2 / §5.3.
class InterimThrottle<T> {
  InterimThrottle(this._onEmit, {this.interval = const Duration(seconds: 1)});

  final void Function(T value) _onEmit;
  final Duration interval;

  T? _pending;
  bool _hasPending = false;
  bool _windowOpen = false;
  Timer? _timer;
  bool _closed = false;

  /// Records [value]. Emits immediately when outside the rate-limit window,
  /// otherwise stores it for a trailing emission when the window elapses.
  void update(T value) {
    if (_closed) return;
    _pending = value;
    _hasPending = true;
    if (!_windowOpen) {
      _flush();
      _windowOpen = true;
      _timer = Timer(interval, _onWindowEnd);
    }
  }

  void _onWindowEnd() {
    if (_closed) return;
    if (_hasPending) {
      _flush();
      _timer = Timer(interval, _onWindowEnd);
    } else {
      _windowOpen = false;
    }
  }

  void _flush() {
    if (!_hasPending) return;
    final value = _pending as T;
    _hasPending = false;
    _pending = null;
    _onEmit(value);
  }

  /// Cancels any pending trailing emission and releases the timer.
  void dispose() {
    _closed = true;
    _hasPending = false;
    _pending = null;
    _timer?.cancel();
    _timer = null;
  }
}
