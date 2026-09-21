import 'package:app/feature/profile/data/sns_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('social IDs become the selected service profile URL and can be edited again', () {
    const cases = [
      (SnsPlatform.x, 'FlutterKaigi', 'https://x.com/FlutterKaigi'),
      (SnsPlatform.github, 'FlutterKaigi', 'https://github.com/FlutterKaigi'),
      (SnsPlatform.linkedin, 'example-user', 'https://www.linkedin.com/in/example-user'),
      (SnsPlatform.devto, 'example', 'https://dev.to/example'),
      (SnsPlatform.bluesky, 'bsky.app', 'https://bsky.app/profile/bsky.app'),
      (SnsPlatform.bluesky, 'example.bsky.social', 'https://bsky.app/profile/example.bsky.social'),
      (SnsPlatform.mixi2, 'mixi2', 'https://mixi.social/@mixi2'),
      (SnsPlatform.zenn, 'example', 'https://zenn.dev/example'),
      (SnsPlatform.qiita, 'example', 'https://qiita.com/example'),
      (SnsPlatform.note, 'example', 'https://note.com/example'),
      (SnsPlatform.medium, 'example', 'https://medium.com/@example'),
    ];
    for (final (platform, id, url) in cases) {
      expect(platform.normalizeInput(' $id '), url);
      expect(platform.normalizeInput('@$id'), url);
      expect(platform.inputValue(url), id);
      expect(platform.normalizeInput(platform.inputValue(url)), url);
    }
  });

  test('Mastodon addresses include the server and round-trip without losing URL information', () {
    const platform = SnsPlatform.mastodon;
    expect(platform.normalizeInput(' @example@fosstodon.org '), 'https://fosstodon.org/@example');
    expect(platform.normalizeInput('example@mastodon.social'), 'https://mastodon.social/@example');
    expect(platform.inputValue('https://fosstodon.org/@example'), '@example@fosstodon.org');
    for (final url in [
      'https://fosstodon.org/@example/123',
      'https://fosstodon.org/@example?ref=profile',
      'https://fosstodon.org/@example#posts',
      'https://fosstodon.org/users/example',
    ]) {
      expect(platform.inputValue(url), url);
      expect(platform.normalizeInput(url), url);
    }
    for (final input in [
      'example',
      '@example',
      '@example@localhost',
      '@example@server/path',
      '@example@server.example:443',
      '@example@server.example?x=1',
      '@example@server.example@evil.example',
    ]) {
      expect(platform.normalizeInput(input), isNull, reason: input);
    }
  });

  test('full URLs remain compatible and keep extra path and query information', () {
    const urls = [
      'https://x.com/FlutterKaigi/status/123',
      'https://x.com/FlutterKaigi?lang=ja#profile',
      'https://twitter.com/FlutterKaigi',
      'https://github.com/FlutterKaigi/2026',
      'https://example.com/profile',
    ];
    for (final platform in SnsPlatform.values) {
      for (final url in urls) {
        expect(platform.normalizeInput(url), url);
        expect(platform.normalizeInput(platform.inputValue(url)), url);
      }
    }
  });

  test('other links still require an HTTPS URL', () {
    expect(SnsPlatform.other.normalizeInput('FlutterKaigi'), isNull);
    expect(SnsPlatform.other.normalizeInput('https://example.com'), 'https://example.com');
    expect(SnsPlatform.other.inputValue('https://example.com'), 'https://example.com');
  });

  test('invalid input cannot be interpreted as a profile path or another scheme', () {
    for (final platform in SnsPlatform.values) {
      for (final input in [
        '',
        ' ',
        '@',
        '@@example',
        '.',
        '..',
        '../example',
        'x.com/example',
        'has space',
        'a/b',
        'a?b',
        'a#b',
        'a%2fb',
        'http://example.com',
        'javascript:alert(1)',
      ]) {
        expect(platform.normalizeInput(input), isNull, reason: '$platform: $input');
      }
    }
    expect(SnsPlatform.bluesky.normalizeInput('example'), isNull);
    expect(SnsPlatform.bluesky.normalizeInput('example_.bsky.social'), isNull);
  });
}
