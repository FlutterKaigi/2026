import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Connection state of the [Uplink].
enum LinkState { disconnected, connecting, connected, reconnectWaiting }

/// Manages the ingest WebSocket: connects to `<serverUrl>/v1/ingest/<roomId>`,
/// sends the `hello` frame, streams audio bytes, surfaces incoming frames, and
/// auto-reconnects with exponential backoff (1s → 2s → … → 30s).
///
/// Audio sent while disconnected is dropped (the §5.5 reconnect ring-buffer is
/// an optional enhancement, omitted in this prototype).
class Uplink {
  Uplink({required this.onStateChanged, required this.onMessage});

  final void Function(LinkState state) onStateChanged;
  final void Function(Map<String, Object?> message) onMessage;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  bool _running = false;
  int _attempt = 0;

  String _serverUrl = '';
  String _roomId = '';
  String _token = '';
  String _sourceLang = 'ja-JP';

  LinkState _state = LinkState.disconnected;
  LinkState get state => _state;

  void _setState(LinkState s) {
    _state = s;
    onStateChanged(s);
  }

  Uri _ingestUri() {
    final base = _serverUrl.endsWith('/')
        ? _serverUrl.substring(0, _serverUrl.length - 1)
        : _serverUrl;
    return Uri.parse('$base/v1/ingest/$_roomId');
  }

  /// Begins connecting and keeps the connection alive until [stop] is called.
  void start({
    required String serverUrl,
    required String roomId,
    required String token,
    String sourceLang = 'ja-JP',
  }) {
    _serverUrl = serverUrl;
    _roomId = roomId;
    _token = token;
    _sourceLang = sourceLang;
    _running = true;
    _attempt = 0;
    unawaited(_connect());
  }

  Future<void> _connect() async {
    if (!_running) return;
    _setState(LinkState.connecting);
    try {
      final channel = IOWebSocketChannel.connect(
        _ingestUri(),
        headers: {'Authorization': 'Bearer $_token'},
      );
      await channel.ready;
      if (!_running) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _attempt = 0;
      _setState(LinkState.connected);
      channel.sink.add(
        jsonEncode({
          'type': 'hello',
          'sampleRate': 16000,
          'channels': 1,
          'format': 'pcm16le',
          'sourceLang': _sourceLang,
        }),
      );
      _sub = channel.stream.listen(
        (data) {
          if (data is! String) return;
          try {
            final decoded = jsonDecode(data);
            if (decoded is Map<String, Object?>) onMessage(decoded);
          } catch (_) {
            // Ignore malformed frames in the prototype.
          }
        },
        onError: (Object _) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (!_running) {
      _setState(LinkState.disconnected);
      return;
    }
    _attempt++;
    final delaySeconds = (1 << (_attempt - 1).clamp(0, 5)).clamp(
      1,
      30,
    ); // 1,2,4,8,16,30
    _setState(LinkState.reconnectWaiting);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: delaySeconds),
      () => unawaited(_connect()),
    );
  }

  /// Sends a binary audio chunk when connected; drops it otherwise.
  void send(Uint8List bytes) {
    if (_state == LinkState.connected) {
      _channel?.sink.add(bytes);
    }
  }

  /// Stops the uplink and closes the socket.
  Future<void> stop() async {
    _running = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
    _setState(LinkState.disconnected);
  }
}
