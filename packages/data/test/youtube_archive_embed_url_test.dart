import 'package:data/archive_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const videoId = 'dQw4w9WgXcQ';
  const embedUrl = 'https://www.youtube-nocookie.com/embed/$videoId';

  group('youtubeArchiveEmbedUri', () {
    for (final url in [
      'https://youtube.com/watch?v=$videoId',
      'https://www.youtube.com/watch?v=$videoId&list=playlist',
      'https://m.youtube.com/watch?v=$videoId',
      'https://music.youtube.com/watch?v=$videoId',
      'https://youtu.be/$videoId',
      'https://youtube.com/embed/$videoId',
      'https://youtube.com/live/$videoId',
      'https://youtube.com/shorts/$videoId',
      'https://youtube-nocookie.com/embed/$videoId',
      'https://www.youtube-nocookie.com/embed/$videoId',
    ]) {
      test('normalizes $url', () {
        expect(youtubeArchiveEmbedUri(' $url '), Uri.parse(embedUrl));
      });
    }
    for (final (suffix, seconds) in [
      ('?start=30', 30),
      ('?start=0', 0),
      ('?t=90', 90),
      ('?t=90s', 90),
      ('?t=1m30s', 90),
      ('?t=1h2m3s', 3723),
      ('?t=2h', 7200),
      ('#t=1m30s', 90),
      ('?start=15&t=1h#t=2h', 15),
      ('?start=invalid&t=25', 25),
    ]) {
      test('preserves sanitized timestamp $suffix', () {
        expect(youtubeArchiveEmbedUri('https://youtu.be/$videoId$suffix'), Uri.parse('$embedUrl?start=$seconds'));
      });
    }
    for (final suffix in [
      '?start=-1',
      '?start=1.5',
      '?start=9999999999999999999999999',
      '?start=2147483648',
      '?start=1h',
      '?start=5&start=30',
      '?t=invalid',
      '?t=-2s',
      '?t=1.5m',
      '?t=2s1m',
      '?t=',
      '?t=9999999999999999999999999h',
      '?t=5&t=30',
      '#t=javascript:alert(1)',
      '#t=2m&autoplay=1',
    ]) {
      test('ignores malformed timestamp $suffix', () {
        expect(youtubeArchiveEmbedUri('https://youtu.be/$videoId$suffix'), Uri.parse(embedUrl));
      });
    }
    test('drops autoplay, script configuration and arbitrary query parameters', () {
      final uri = youtubeArchiveEmbedUri(
        'https://youtube.com/watch?v=$videoId&autoplay=1&enablejsapi=1&origin=https://evil.example&start=42',
      );
      expect(uri, Uri.parse('$embedUrl?start=42'));
      expect(uri!.queryParameters, {'start': '42'});
    });
    for (final url in <String?>[
      null,
      '',
      'not a URL',
      'http://youtube.com/watch?v=$videoId',
      'https://youtube.com.evil.example/watch?v=$videoId',
      'https://user@youtube.com/watch?v=$videoId',
      'https://youtube.com:8443/watch?v=$videoId',
      'https://youtube.com/',
      'https://youtube.com/channel/$videoId',
      'https://youtube.com/@flutter',
      'https://youtube.com/playlist?list=$videoId',
      'https://youtube.com/watch',
      'https://youtube.com/watch?v=$videoId&v=aaaaaaaaaaa',
      'https://youtube.com/watch?v=tooShort',
      'https://youtube.com/watch?v=${videoId}x',
      'https://youtube.com/watch?v=invalid!id!',
      'https://youtube.com/embed/$videoId/extra',
      'https://youtube.com/embed/',
      'https://youtube.com/embed/%2F$videoId',
      'https://youtube.com/watch?v=%FF',
      'https://youtu.be/$videoId/extra',
      'https://youtu.be/watch?v=$videoId',
      'https://youtu.be/',
    ]) {
      test('rejects unsupported or unsafe URL $url', () {
        expect(youtubeArchiveEmbedUri(url), isNull);
      });
    }
  });
}
