import 'package:app/feature/live_captions/util/caption_target_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCaptionTarget', () {
    test('素の venueId を受け付ける', () {
      expect(parseCaptionTarget('hall-a'), 'hall-a');
      expect(parseCaptionTarget(' hall-b \n'), 'hall-b');
    });

    test('captions パスを含む URL から venueId を取り出す', () {
      expect(
        parseCaptionTarget('https://2026.flutterkaigi.jp/captions/hall-a'),
        'hall-a',
      );
      expect(
        parseCaptionTarget('https://example.com/app/captions/hall-b/'),
        'hall-b',
      );
    });

    test('アプリのディープリンク形式から venueId を取り出す', () {
      expect(
        parseCaptionTarget('flutterkaigi2026://captions/hall-a'),
        'hall-a',
      );
      expect(
        parseCaptionTarget('flutterkaigi2026:///captions/hall-b'),
        'hall-b',
      );
    });

    test('venueId として不正なペイロードは null', () {
      expect(parseCaptionTarget(''), isNull);
      expect(parseCaptionTarget('Hall A'), isNull);
      expect(parseCaptionTarget('https://example.com/'), isNull);
      expect(parseCaptionTarget('https://example.com/captions/'), isNull);
      expect(parseCaptionTarget('https://example.com/captions/UPPER'), isNull);
    });
  });
}
