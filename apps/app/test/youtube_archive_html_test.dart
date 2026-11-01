import 'package:app/feature/session/ui/widget/youtube_archive_html.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identifies the installed native app using its lowercase package name', () {
    expect(youtubeArchiveAppOrigin('jp.flutterkaigi.Conf2026').toString(), 'https://jp.flutterkaigi.conf2026');
    expect(youtubeArchiveAppOrigin('jp.flutterkaigi.conf2026.dev').host, 'jp.flutterkaigi.conf2026.dev');
  });

  test('keeps inline playback user-initiated and supplies the YouTube client origin', () {
    final html = youtubeArchivePlayerHtml(
      embedUri: Uri.parse('https://www.youtube-nocookie.com/embed/M7lc1UVf-VE?start=90'),
      origin: Uri.parse('https://jp.flutterkaigi.conf2026'),
      title: 'Conference recording',
    );

    expect(html, contains('start=90'));
    expect(html, contains('autoplay=0'));
    expect(html, contains('playsinline=1'));
    expect(html, contains('origin=https%3A%2F%2Fjp.flutterkaigi.conf2026'));
    expect(html, contains('referrerpolicy="strict-origin-when-cross-origin"'));
    expect(html, contains('allowfullscreen'));
    expect(html, isNot(contains('playVideo(')));
  });

  test('escapes session titles rather than treating them as player HTML', () {
    final html = youtubeArchivePlayerHtml(
      embedUri: Uri.parse('https://www.youtube-nocookie.com/embed/M7lc1UVf-VE'),
      origin: Uri.parse('https://2026-app.flutterkaigi.jp'),
      title: '"><script>alert(1)</script>',
    );

    expect(html, isNot(contains('<script>alert(1)</script>')));
    expect(html, contains('&lt;script&gt;alert(1)&lt;&#47;script&gt;'));
  });
}
