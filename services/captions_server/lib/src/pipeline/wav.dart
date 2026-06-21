import 'dart:typed_data';

/// Wraps raw PCM16LE bytes in a canonical 44-byte WAV (RIFF) header.
Uint8List pcm16ToWav(Uint8List pcm, {int sampleRate = 16000, int channels = 1}) {
  const headerLength = 44;
  final wav = Uint8List(headerLength + pcm.length);
  final header = ByteData.view(wav.buffer, 0, headerLength);

  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  final byteRate = sampleRate * channels * 2;
  ascii(0, 'RIFF');
  header.setUint32(4, 36 + pcm.length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, channels * 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  header.setUint32(40, pcm.length, Endian.little);

  wav.setRange(headerLength, wav.length, pcm);
  return wav;
}
