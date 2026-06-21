import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'audio_capture.dart';
import 'uplink.dart';

/// Root widget for the broadcaster (staff) tool.
class BroadcasterApp extends StatelessWidget {
  const BroadcasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Captions Broadcaster',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const BroadcasterPage(),
    );
  }
}

/// Single-screen UI: pick an input device and stream PCM16 audio to the
/// captions server, previewing the interim/caption frames it returns.
class BroadcasterPage extends StatefulWidget {
  const BroadcasterPage({super.key});

  @override
  State<BroadcasterPage> createState() => _BroadcasterPageState();
}

class _BroadcasterPageState extends State<BroadcasterPage> {
  static const _defaultServerUrl = String.fromEnvironment(
    'CAPTIONS_SERVER_URL',
    defaultValue: 'ws://localhost:8082',
  );
  static const _defaultRoomId = String.fromEnvironment(
    'CAPTIONS_ROOM_ID',
    defaultValue: 'room-a',
  );
  static const _defaultToken = String.fromEnvironment(
    'INGEST_TOKEN',
    defaultValue: 'dev-token',
  );

  final _serverUrl = TextEditingController(text: _defaultServerUrl);
  final _roomId = TextEditingController(text: _defaultRoomId);
  final _token = TextEditingController(text: _defaultToken);

  final AudioCapture _audio = AudioCapture();
  late final Uplink _uplink;

  List<InputDevice> _devices = [];
  InputDevice? _device;

  LinkState _link = LinkState.disconnected;
  bool _running = false;
  double _level = 0;
  int _bytesAccum = 0;
  int _bytesPerSec = 0;
  Timer? _rateTimer;

  String _interimText = '';
  String _captionText = '';

  @override
  void initState() {
    super.initState();
    _uplink = Uplink(
      onStateChanged: (s) {
        if (mounted) setState(() => _link = s);
      },
      onMessage: _onMessage,
    );
    _loadDevices();
  }

  @override
  void dispose() {
    _rateTimer?.cancel();
    unawaited(_audio.dispose());
    unawaited(_uplink.stop());
    _serverUrl.dispose();
    _roomId.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    try {
      final devices = await _audio.listInputDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _device = devices.isNotEmpty ? devices.first : null;
      });
    } catch (_) {
      // Listing can fail before permission is granted; ignore for now.
    }
  }

  void _onMessage(Map<String, Object?> message) {
    if (!mounted) return;
    switch (message['type']) {
      case 'interim':
        setState(() => _interimText = '${message['srcText']}');
      case 'caption':
        setState(() => _captionText = '${message['ja']}\n${message['en']}');
      case 'error':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'server error: ${message['code']} ${message['message']}',
            ),
          ),
        );
    }
  }

  Future<void> _start() async {
    final messenger = ScaffoldMessenger.of(context);
    final granted = await _audio.hasPermission();
    if (!mounted) return;
    if (!granted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('マイク/ライン入力の権限がありません。')),
      );
      return;
    }

    _uplink.start(
      serverUrl: _serverUrl.text.trim(),
      roomId: _roomId.text.trim(),
      token: _token.text.trim(),
    );

    try {
      await _audio.start(
        device: _device,
        onChunk: (chunk) {
          _uplink.send(chunk);
          _bytesAccum += chunk.length;
        },
        onLevel: (rms) {
          if (mounted) setState(() => _level = rms);
        },
      );
    } catch (e) {
      await _uplink.stop();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('録音開始に失敗しました: $e')));
      return;
    }

    _rateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _bytesPerSec = _bytesAccum;
        _bytesAccum = 0;
      });
    });
    if (mounted) setState(() => _running = true);
  }

  Future<void> _stop() async {
    _rateTimer?.cancel();
    _rateTimer = null;
    await _audio.stop();
    await _uplink.stop();
    if (!mounted) return;
    setState(() {
      _running = false;
      _level = 0;
      _bytesPerSec = 0;
    });
  }

  String get _linkLabel => switch (_link) {
    LinkState.disconnected => '未接続',
    LinkState.connecting => '接続中…',
    LinkState.connected => '接続済み',
    LinkState.reconnectWaiting => '再接続待ち…',
  };

  Color get _linkColor => switch (_link) {
    LinkState.connected => Colors.green,
    LinkState.connecting => Colors.orange,
    LinkState.reconnectWaiting => Colors.red,
    LinkState.disconnected => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Captions Broadcaster')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _serverUrl,
              enabled: !_running,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _roomId,
                    enabled: !_running,
                    decoration: const InputDecoration(
                      labelText: 'Room ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _token,
                    enabled: !_running,
                    decoration: const InputDecoration(
                      labelText: 'Token',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<InputDevice>(
                    initialValue: _device,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Input device',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final d in _devices)
                        DropdownMenuItem(
                          value: d,
                          child: Text(d.label, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: _running
                        ? null
                        : (d) => setState(() => _device = d),
                  ),
                ),
                IconButton(
                  tooltip: 'デバイス再読み込み',
                  onPressed: _running ? null : _loadDevices,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _running ? null : _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _running ? _stop : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
                const Spacer(),
                Icon(Icons.circle, size: 12, color: _linkColor),
                const SizedBox(width: 6),
                Text(_linkLabel),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '送信レート: $_bytesPerSec bytes/sec',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('音量'),
                const SizedBox(width: 8),
                Expanded(child: LinearProgressIndicator(value: _level)),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            Text('プレビュー', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _PreviewCard(title: 'interim (原文)', body: _interimText),
            const SizedBox(height: 8),
            _PreviewCard(title: 'caption (ja / en)', body: _captionText),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(body.isEmpty ? '—' : body),
          ],
        ),
      ),
    );
  }
}
