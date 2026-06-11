import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web_socket_channel/io.dart';

/// Headless smoke client (§6.7).
///
/// Usage: `dart run tool/smoke_client.dart [ws-url] [path/to.wav]`
///
/// Connects to the ingest WebSocket and streams audio in 100ms chunks at
/// real-time pace. With no WAV argument it sends ~10s of a 440Hz sine (for the
/// fake transcriber) and requires two `caption` frames; with a WAV file
/// (PCM16 / 16kHz / mono — e.g. from `afconvert -f WAVE -d LEI16@16000 -c 1`)
/// it sends the file and requires one. Exits 0 on success, non-zero otherwise.
Future<void> main(List<String> args) async {
  final url = args.isNotEmpty ? args.first : 'ws://localhost:8082/v1/ingest/room-a';
  final token = Platform.environment['INGEST_TOKEN'] ?? 'dev-token';
  final wavPath = args.length > 1 ? args[1] : null;

  final List<Uint8List>? fileChunks = wavPath == null ? null : _readWavChunks(wavPath);
  final requiredCaptions = fileChunks == null ? 2 : 1;
  final totalChunks = fileChunks?.length ?? 100;
  if (fileChunks != null) {
    stdout.writeln('streaming $wavPath (${(totalChunks / 10).toStringAsFixed(1)}s) at real-time pace');
  }

  final IOWebSocketChannel channel;
  try {
    channel = IOWebSocketChannel.connect(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    await channel.ready;
  } catch (e) {
    stderr.writeln('smoke FAILED: could not connect to $url: $e');
    exit(1);
  }

  var captionCount = 0;
  final done = Completer<void>();

  channel.stream.listen(
    (message) {
      if (message is! String) return;
      final data = jsonDecode(message) as Map<String, Object?>;
      switch (data['type']) {
        case 'ready':
          stdout.writeln('ready');
        case 'interim':
          stdout.writeln('interim seq=${data['seq']} "${data['srcText']}"');
        case 'caption':
          captionCount++;
          stdout.writeln('caption seq=${data['seq']} ja="${data['ja']}" en="${data['en']}"');
          if (captionCount >= requiredCaptions && !done.isCompleted) done.complete();
        case 'error':
          stderr.writeln('error: ${data['code']} ${data['message']}');
      }
    },
    onError: (Object e) {
      if (!done.isCompleted) done.completeError(e);
    },
    onDone: () {
      if (!done.isCompleted) done.completeError(StateError('socket closed before $requiredCaptions caption(s)'));
    },
  );

  // hello
  channel.sink.add(jsonEncode({
    'type': 'hello',
    'sampleRate': 16000,
    'channels': 1,
    'format': 'pcm16le',
    'sourceLang': 'ja-JP',
  }));

  // 100ms chunks (1600 samples = 3200 bytes) at real-time pace: either WAV file
  // slices or a generated 440Hz sine.
  const sampleRate = 16000;
  const chunkMs = 100;
  const samplesPerChunk = sampleRate * chunkMs ~/ 1000;
  const freq = 440.0;
  const step = 2 * math.pi * freq / sampleRate;
  var phase = 0.0;

  final timer = Timer.periodic(const Duration(milliseconds: chunkMs), (t) {
    if (t.tick > totalChunks || done.isCompleted) {
      t.cancel();
      return;
    }
    if (fileChunks != null) {
      channel.sink.add(fileChunks[t.tick - 1]);
      return;
    }
    final bytes = Uint8List(samplesPerChunk * 2);
    final view = ByteData.view(bytes.buffer);
    for (var i = 0; i < samplesPerChunk; i++) {
      view.setInt16(i * 2, (math.sin(phase) * 0.3 * 32767).round(), Endian.little);
      phase += step;
    }
    channel.sink.add(bytes);
  });

  // Stream duration plus grace for transcription/translation round-trips.
  final timeout = Duration(milliseconds: totalChunks * chunkMs) + const Duration(seconds: 25);
  try {
    await done.future.timeout(timeout);
    timer.cancel();
    await channel.sink.close();
    stdout.writeln('smoke OK: received $captionCount caption frame(s)');
    exit(0);
  } catch (e) {
    timer.cancel();
    await channel.sink.close();
    stderr.writeln('smoke FAILED: $e');
    exit(1);
  }
}

/// Reads a WAV file, validates PCM16/16kHz/mono, and slices the data chunk into
/// 100ms (3200-byte) pieces. Exits the process with a message on bad input.
List<Uint8List> _readWavChunks(String path) {
  final Uint8List bytes;
  try {
    bytes = File(path).readAsBytesSync();
  } catch (e) {
    stderr.writeln('smoke FAILED: could not read $path: $e');
    exit(1);
  }

  String ascii(int offset) => String.fromCharCodes(bytes.sublist(offset, offset + 4));
  if (bytes.length < 44 || ascii(0) != 'RIFF' || ascii(8) != 'WAVE') {
    stderr.writeln('smoke FAILED: $path is not a WAV file');
    exit(1);
  }

  final view = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
  Uint8List? data;
  // Walk RIFF chunks ('fmt ', optional padding like 'FLLR', then 'data').
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = ascii(offset);
    final size = view.getUint32(offset + 4, Endian.little);
    if (id == 'fmt ') {
      final format = view.getUint16(offset + 8, Endian.little);
      final channels = view.getUint16(offset + 10, Endian.little);
      final rate = view.getUint32(offset + 12, Endian.little);
      final bits = view.getUint16(offset + 22, Endian.little);
      if (format != 1 || channels != 1 || rate != 16000 || bits != 16) {
        stderr.writeln('smoke FAILED: $path must be PCM16 / 16kHz / mono (got '
            'format=$format channels=$channels rate=$rate bits=$bits). Convert with:\n'
            '  afconvert -f WAVE -d LEI16@16000 -c 1 <input> <output.wav>');
        exit(1);
      }
    } else if (id == 'data') {
      data = Uint8List.sublistView(bytes, offset + 8, math.min(offset + 8 + size, bytes.length));
      break;
    }
    offset += 8 + size + (size.isOdd ? 1 : 0);
  }
  if (data == null || data.isEmpty) {
    stderr.writeln('smoke FAILED: $path has no data chunk');
    exit(1);
  }

  const chunkBytes = 3200;
  return [
    for (var i = 0; i < data.length; i += chunkBytes)
      Uint8List.sublistView(data, i, math.min(i + chunkBytes, data.length)),
  ];
}
