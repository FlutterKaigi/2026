import 'package:caption_protocol/caption_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('uses safe defaults for optional producer fields', () {
    final request = CaptionIngestRequest.fromJson({
      'roomId': 'main',
      'sessionId': 'opening',
      'utteranceId': 'opening-1',
      'utteranceSequence': 1,
      'revision': 0,
      'translatedText': 'Welcome to FlutterKaigi.',
      'sourceStartedAt': '2026-11-07T01:00:00.000Z',
    });

    expect(request.isFinal, isTrue);
    expect(request.utteranceId, 'opening-1');
    expect(request.utteranceSequence, 1);
    expect(request.revision, 0);
    expect(request.sourceStartedAt, DateTime.utc(2026, 11, 7, 1));
    expect(request.clearAfter, const Duration(seconds: 8));
  });

  test('rejects a caption that would remain indefinitely', () {
    expect(
      () => CaptionIngestRequest.fromJson({
        'roomId': 'main',
        'sessionId': 'opening',
        'utteranceId': 'opening-1',
        'utteranceSequence': 1,
        'revision': 0,
        'translatedText': 'Welcome',
        'sourceStartedAt': '2026-11-07T01:00:00.000Z',
        'clearAfterMs': 0,
      }),
      throwsFormatException,
    );
  });

  test('requires a nonnegative revision and safe identifiers', () {
    expect(
      () => CaptionIngestRequest.fromJson({
        'roomId': ' main',
        'sessionId': 'opening',
        'utteranceId': 'opening-1',
        'utteranceSequence': 1,
        'revision': -1,
        'translatedText': 'Welcome',
        'sourceStartedAt': '2026-11-07T01:00:00.000Z',
      }),
      throwsFormatException,
    );
  });

  test('rejects unknown caption and clear fields', () {
    expect(
      () => CaptionIngestRequest.fromJson({
        'roomId': 'main',
        'sessionId': 'opening',
        'utteranceId': 'opening-1',
        'utteranceSequence': 1,
        'revision': 0,
        'translatedText': 'Welcome',
        'sourceStartedAt': '2026-11-07T01:00:00.000Z',
        'unexpected': true,
      }),
      throwsFormatException,
    );
    expect(
      () => CaptionClearRequest.fromJson({
        'roomId': 'main',
        'sessionId': 'opening',
        'unexpected': true,
      }),
      throwsFormatException,
    );
  });

  test('rejects producer-controlled line breaks in display text', () {
    expect(
      () => CaptionIngestRequest.fromJson({
        'roomId': 'main',
        'sessionId': 'opening',
        'utteranceId': 'opening-1',
        'utteranceSequence': 1,
        'revision': 0,
        'translatedText': 'first line\nsecond line',
        'sourceStartedAt': '2026-11-07T01:00:00.000Z',
      }),
      throwsFormatException,
    );
  });

  test('requires sourceStartedAt as an explicit UTC timestamp', () {
    final base = <String, Object?>{
      'roomId': 'main',
      'sessionId': 'opening',
      'utteranceId': 'opening-1',
      'utteranceSequence': 1,
      'revision': 0,
      'translatedText': 'Welcome',
    };

    expect(() => CaptionIngestRequest.fromJson(base), throwsFormatException);
    expect(
      () => CaptionIngestRequest.fromJson({...base, 'sourceStartedAt': '2026-11-07T01:00:00+09:00'}),
      throwsFormatException,
    );
  });
}
