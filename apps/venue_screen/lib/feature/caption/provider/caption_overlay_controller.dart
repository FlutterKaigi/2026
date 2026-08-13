import 'dart:async';

import 'package:caption_protocol/caption_protocol.dart';
import 'package:flutter/foundation.dart';
import 'package:venue_screen/core/config/venue_screen_config.dart';
import 'package:venue_screen/feature/caption/data/caption_socket.dart';

enum CaptionConnectionStatus { configurationError, connecting, connected, stale, disconnected }

typedef OverlayClock = DateTime Function();

final class CaptionOverlayController extends ChangeNotifier {
  CaptionOverlayController({
    required this.config,
    required CaptionSocketConnector connector,
    OverlayClock? clock,
  }) : _connector = connector,
       _clock = clock ?? _utcNow;

  final VenueScreenConfig config;
  final CaptionSocketConnector _connector;
  final OverlayClock _clock;

  CaptionSocket? _socket;
  // Kept for explicit teardown on disconnect, staleness, and disposal.
  // ignore: cancel_subscriptions
  StreamSubscription<Object?>? _subscription;
  Timer? _clearTimer;
  Timer? _healthTimer;
  Timer? _reconnectTimer;
  var _generation = 0;
  var _reconnectAttempt = 0;
  var _lastSequence = -1;
  var _started = false;
  var _disposed = false;
  var _droppedMessageCount = 0;
  CaptionEvent? _caption;
  CaptionConnectionStatus _status = CaptionConnectionStatus.connecting;
  DateTime? _lastMessageAt;

  CaptionEvent? get caption => _caption;
  CaptionConnectionStatus get status => _status;
  DateTime? get lastMessageAt => _lastMessageAt;
  int get droppedMessageCount => _droppedMessageCount;

  void start() {
    if (_disposed || _started) {
      return;
    }
    _started = true;
    if (!config.isValid) {
      _setStatus(CaptionConnectionStatus.configurationError);
      return;
    }
    _connect();
  }

  void _connect() {
    if (_disposed) {
      return;
    }
    final generation = ++_generation;
    // A newly connected relay replays its current caption. Reset the local
    // ordering window so that replay can restore a caption hidden on disconnect.
    _lastSequence = -1;
    _setStatus(CaptionConnectionStatus.connecting);
    _armHealthTimeout(generation);
    try {
      final socket = _connector.connect(config.webSocketUri);
      _socket = socket;
      _subscription = socket.messages.listen(
        (message) => _handleMessage(message, generation),
        onError: (_) => _handleDisconnect(generation),
        onDone: () => _handleDisconnect(generation),
        cancelOnError: true,
      );
    } on Object {
      _handleDisconnect(generation);
    }
  }

  void _handleMessage(Object? message, int generation) {
    if (_disposed || generation != _generation || message is! String) {
      return;
    }

    CaptionEvent event;
    try {
      event = CaptionEvent.fromJsonString(message);
    } on FormatException {
      _droppedMessageCount++;
      _notify();
      return;
    }
    if (event.roomId != config.roomId || event.sessionId != config.sessionId) {
      _droppedMessageCount++;
      _notify();
      return;
    }
    if (event.isProducedTooFarInFutureAt(_clock())) {
      _droppedMessageCount++;
      _notify();
      return;
    }

    _lastMessageAt = _clock().toUtc();
    _reconnectAttempt = 0;
    _setStatus(CaptionConnectionStatus.connected);
    _armHealthTimeout(generation);
    if (event.type == CaptionEventType.heartbeat) {
      return;
    }
    if (event.sequence <= _lastSequence) {
      _droppedMessageCount++;
      _notify();
      return;
    }
    _lastSequence = event.sequence;

    switch (event.type) {
      case CaptionEventType.caption:
        if (event.isExpiredAt(_clock())) {
          _setCaption(null);
          return;
        }
        _setCaption(event);
        _clearTimer?.cancel();
        final remaining = event.clearAt!.difference(_clock().toUtc());
        final safeRemaining = remaining > CaptionEvent.maximumDisplayDuration
            ? CaptionEvent.maximumDisplayDuration
            : remaining;
        _clearTimer = Timer(safeRemaining, () => _setCaption(null));
      case CaptionEventType.clear:
        _setCaption(null);
      case CaptionEventType.heartbeat:
        break;
    }
  }

  void _armHealthTimeout(int generation) {
    _healthTimer?.cancel();
    _healthTimer = Timer(config.staleAfter, () {
      if (_disposed || generation != _generation) {
        return;
      }
      _setStatus(CaptionConnectionStatus.stale);
      _setCaption(null);
      _restart(generation);
    });
  }

  void _handleDisconnect(int generation) {
    if (_disposed || generation != _generation) {
      return;
    }
    _setStatus(CaptionConnectionStatus.disconnected);
    _setCaption(null);
    _tearDownConnection();
    _scheduleReconnect(generation);
  }

  void _restart(int generation) {
    if (_disposed || generation != _generation) {
      return;
    }
    _tearDownConnection();
    _scheduleReconnect(generation);
  }

  void _tearDownConnection() {
    _healthTimer?.cancel();
    _healthTimer = null;
    final subscription = _subscription;
    _subscription = null;
    final socket = _socket;
    _socket = null;
    unawaited(subscription?.cancel());
    unawaited(socket?.close());
  }

  void _scheduleReconnect(int generation) {
    if (_disposed || generation != _generation || _reconnectTimer?.isActive == true) {
      return;
    }
    final exponent = _reconnectAttempt.clamp(0, 3);
    final delaySeconds = 1 << exponent;
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectTimer = null;
      _connect();
    });
  }

  void _setCaption(CaptionEvent? value) {
    _clearTimer?.cancel();
    if (identical(_caption, value)) {
      return;
    }
    _caption = value;
    _notify();
  }

  void _setStatus(CaptionConnectionStatus value) {
    if (_status == value) {
      return;
    }
    _status = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _clearTimer?.cancel();
    _healthTimer?.cancel();
    _reconnectTimer?.cancel();
    _tearDownConnection();
    super.dispose();
  }
}

DateTime _utcNow() => DateTime.now().toUtc();
