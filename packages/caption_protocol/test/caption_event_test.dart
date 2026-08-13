import 'package:caption_protocol/caption_protocol.dart';
import 'package:test/test.dart';

void main() {
  final producedAt = DateTime.utc(2026, 11, 7, 1, 2, 3);

  test('caption event round-trips through JSON', () {
    final event = CaptionEvent.caption(
      roomId: 'room-a',
      sessionId: 'session-42',
      sequence: 8,
      utteranceId: 'utterance-8',
      utteranceSequence: 8,
      revision: 2,
      sourceText: 'Flutterで作っています',
      translatedText: 'We are building it with Flutter.',
      isFinal: true,
      sourceStartedAt: producedAt.subtract(const Duration(seconds: 2)),
      producedAt: producedAt,
      clearAt: producedAt.add(const Duration(seconds: 8)),
    );

    final decoded = CaptionEvent.fromJsonString(event.toJsonString());

    expect(decoded.type, CaptionEventType.caption);
    expect(decoded.streamKey, const CaptionStreamKey(roomId: 'room-a', sessionId: 'session-42'));
    expect(decoded.sequence, 8);
    expect(decoded.utteranceId, 'utterance-8');
    expect(decoded.utteranceSequence, 8);
    expect(decoded.revision, 2);
    expect(decoded.translatedText, 'We are building it with Flutter.');
    expect(decoded.isFinal, isTrue);
    expect(decoded.sourceStartedAt, producedAt.subtract(const Duration(seconds: 2)));
    expect(decoded.producedAt, producedAt);
  });

  test('rejects an unknown protocol version', () {
    expect(
      () => CaptionEvent.fromJson({
        'protocolVersion': 2,
        'type': 'clear',
        'roomId': 'room-a',
        'sessionId': 'session-42',
        'sequence': 1,
        'producedAt': producedAt.toIso8601String(),
      }),
      throwsFormatException,
    );
  });

  test('requires caption-specific fields', () {
    expect(
      () => CaptionEvent.fromJson({
        'protocolVersion': 1,
        'type': 'caption',
        'roomId': 'room-a',
        'sessionId': 'session-42',
        'sequence': 1,
        'producedAt': producedAt.toIso8601String(),
      }),
      throwsFormatException,
    );
  });

  test('requires sourceStartedAt on an otherwise complete caption event', () {
    expect(
      () => CaptionEvent.fromJson({
        'protocolVersion': 1,
        'type': 'caption',
        'roomId': 'room-a',
        'sessionId': 'session-42',
        'sequence': 1,
        'utteranceId': 'utterance-1',
        'utteranceSequence': 1,
        'revision': 0,
        'translatedText': 'Caption',
        'isFinal': true,
        'producedAt': producedAt.toIso8601String(),
        'clearAt': producedAt.add(const Duration(seconds: 4)).toIso8601String(),
      }),
      throwsFormatException,
    );
  });

  test('rejects unknown fields instead of silently changing protocol meaning', () {
    expect(
      () => CaptionEvent.fromJson({
        'protocolVersion': 1,
        'type': 'clear',
        'roomId': 'room-a',
        'sessionId': 'session-42',
        'sequence': 1,
        'producedAt': producedAt.toIso8601String(),
        'unexpected': true,
      }),
      throwsFormatException,
    );
  });

  test('rejects a caption lifetime that could leave stale text on screen', () {
    expect(
      () => CaptionEvent.caption(
        roomId: 'room-a',
        sessionId: 'session-42',
        sequence: 1,
        utteranceId: 'utterance-1',
        utteranceSequence: 1,
        revision: 0,
        translatedText: 'Caption',
        isFinal: true,
        sourceStartedAt: producedAt.subtract(const Duration(seconds: 2)),
        producedAt: producedAt,
        clearAt: producedAt.add(const Duration(minutes: 3)),
      ),
      throwsFormatException,
    );
  });

  test('rejects caption identifiers that cannot safely be used in URLs', () {
    expect(
      () => CaptionEvent.clear(
        roomId: ' room-a ',
        sessionId: 'session-42',
        sequence: 1,
        producedAt: producedAt,
      ),
      throwsFormatException,
    );
  });

  test('detects an expired caption', () {
    final event = CaptionEvent.caption(
      roomId: 'room-a',
      sessionId: 'session-42',
      sequence: 1,
      utteranceId: 'utterance-1',
      utteranceSequence: 1,
      revision: 0,
      translatedText: 'Caption',
      isFinal: true,
      sourceStartedAt: producedAt.subtract(const Duration(seconds: 2)),
      producedAt: producedAt,
      clearAt: producedAt.add(const Duration(seconds: 4)),
    );

    expect(event.isExpiredAt(producedAt.add(const Duration(seconds: 3))), isFalse);
    expect(event.isExpiredAt(producedAt.add(const Duration(seconds: 4))), isTrue);
  });

  test('detects an event produced beyond the allowed clock skew', () {
    final event = CaptionEvent.heartbeat(
      roomId: 'room-a',
      sessionId: 'session-42',
      sequence: 1,
      producedAt: producedAt.add(const Duration(seconds: 6)),
    );

    expect(event.isProducedTooFarInFutureAt(producedAt), isTrue);
  });

  test('rejects a whitespace-padded utterance identifier', () {
    expect(
      () => CaptionEvent.caption(
        roomId: 'room-a',
        sessionId: 'session-42',
        sequence: 1,
        utteranceId: ' utterance-1',
        utteranceSequence: 1,
        revision: 0,
        translatedText: 'Caption',
        isFinal: false,
        sourceStartedAt: producedAt.subtract(const Duration(seconds: 2)),
        producedAt: producedAt,
        clearAt: producedAt.add(const Duration(seconds: 4)),
      ),
      throwsFormatException,
    );
  });

  test('rejects a negative caption revision', () {
    expect(
      () => CaptionEvent.caption(
        roomId: 'room-a',
        sessionId: 'session-42',
        sequence: 1,
        utteranceId: 'utterance-1',
        utteranceSequence: 1,
        revision: -1,
        translatedText: 'Caption',
        isFinal: false,
        sourceStartedAt: producedAt.subtract(const Duration(seconds: 2)),
        producedAt: producedAt,
        clearAt: producedAt.add(const Duration(seconds: 4)),
      ),
      throwsFormatException,
    );
  });

  test('rejects caption source timestamps outside the accepted age window', () {
    expect(
      () => CaptionEvent.caption(
        roomId: 'room-a',
        sessionId: 'session-42',
        sequence: 1,
        utteranceId: 'utterance-1',
        utteranceSequence: 1,
        revision: 0,
        translatedText: 'Caption',
        isFinal: true,
        sourceStartedAt: producedAt.subtract(CaptionEvent.maximumSourceAge).subtract(const Duration(milliseconds: 1)),
        producedAt: producedAt,
        clearAt: producedAt.add(const Duration(seconds: 4)),
      ),
      throwsFormatException,
    );
  });
}
