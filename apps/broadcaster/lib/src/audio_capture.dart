import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

/// Captures PCM16 / 16kHz / mono audio from an input device using `record`,
/// delivering raw chunks and a per-chunk RMS level.
class AudioCapture {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;

  /// Whether microphone/line-in permission is granted (requests if needed).
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Lists available audio input devices.
  Future<List<InputDevice>> listInputDevices() => _recorder.listInputDevices();

  /// Starts capturing. [onChunk] receives PCM16 byte chunks; [onLevel] receives
  /// a 0..1 RMS level per chunk.
  Future<void> start({
    InputDevice? device,
    required void Function(Uint8List chunk) onChunk,
    required void Function(double rms) onLevel,
  }) async {
    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        device: device,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );
    _sub = stream.listen((chunk) {
      onChunk(chunk);
      onLevel(_rms(chunk));
    });
  }

  /// Stops capturing.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  /// Releases the recorder.
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _recorder.dispose();
  }

  double _rms(Uint8List bytes) {
    final samples = bytes.length ~/ 2;
    if (samples == 0) return 0;
    final view = ByteData.view(bytes.buffer, bytes.offsetInBytes, samples * 2);
    var sumSquares = 0.0;
    for (var i = 0; i < samples; i++) {
      final sample = view.getInt16(i * 2, Endian.little) / 32768.0;
      sumSquares += sample * sample;
    }
    return math.sqrt(sumSquares / samples).clamp(0.0, 1.0);
  }
}
