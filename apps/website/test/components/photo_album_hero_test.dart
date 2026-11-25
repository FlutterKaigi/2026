import 'dart:convert';

import 'package:jaspr/server.dart';
import 'package:test/test.dart';
import 'package:website/components/photo_album_hero.dart';
import 'package:website/constants/event_info.dart';
import 'package:website/constants/photo_album.dart';
import 'package:website/l10n/strings.dart';

const _albumUrl = 'https://example.com/album';

void main() {
  setUpAll(Jaspr.initializeApp);

  group('PhotoAlbumHero after release', () {
    test('links the CTA to the album in a new tab, next to the survey link', () async {
      final html = await _render(const PhotoAlbumHero(albumUrl: _albumUrl));

      expect(html, contains('href="$_albumUrl"'));
      expect(html, contains('rel="noopener noreferrer"'));
      expect(html, contains('アルバムを見る'));
      expect(html, isNot(contains('disabled type="button"')));
      expect(html, isNot(contains('近日公開')));
      // CTA と、アンケートの副リンク。
      expect('<a '.allMatches(html), hasLength(2));
      expect(html, contains('docs.google.com/forms'));
      expect(html, contains('全体アンケートのお願い'));
    });
  });

  group('PhotoAlbumHero before release', () {
    test('shows a disabled pill and only the survey link while the album URL is empty', () async {
      final html = await _render(const PhotoAlbumHero(albumUrl: ''));

      // クラス名 `--disabled` ではなく、実際の disabled 属性を確認する。
      expect(html, contains('disabled type="button"'));
      expect(html, contains('近日公開</span>'));
      expect(html, isNot(contains('アルバムを見る')));
      expect('<a '.allMatches(html), hasLength(1));
      expect(html, contains('全体アンケートのお願い'));
    });
  });

  group('PhotoAlbumHero copy', () {
    test('has a single h1 with the site name (screen-reader only) and the two-line headline (ja)', () async {
      final html = await _render(const PhotoAlbumHero(albumUrl: _albumUrl));

      expect('<h1 '.allMatches(html), hasLength(1));
      expect(html, contains('class="album-hero__sr">FlutterKaigi 2026</span>'));
      expect(html, contains('>あの瞬間を</span>'));
      expect(html, contains('>もう一度</span>'));
      expect(html, contains('album-hero--ja'));
      // 句読点は付けない。
      expect(html, isNot(contains('あの瞬間を、')));
      expect(html, isNot(contains('もう一度。')));
    });

    test('is localized for en', () async {
      final html = await _render(const PhotoAlbumHero(albumUrl: _albumUrl), locale: AppLocale.en);

      expect(html, contains('>Relive</span>'));
      expect(html, contains('>that moment</span>'));
      expect(html, isNot(contains('that moment.')));
      expect(html, contains('View the Album'));
      expect(html, contains('Take the Event Survey'));
      expect(html, contains('album-hero--en'));
      expect(html, isNot(contains('アルバムを見る')));
    });

    test('keeps the copy to the headline and the actions', () async {
      // 日程・会場・リード文・サイト名の見出し表示は、ヘッダーと下のセクションにあるので出さない。
      for (final albumUrl in [_albumUrl, '']) {
        for (final locale in AppLocale.values) {
          final html = await _render(PhotoAlbumHero(albumUrl: albumUrl), locale: locale);

          expect(html, isNot(contains('10.29')));
          expect(html, isNot(contains('album-hero__meta')));
          expect(html, isNot(contains('album-hero__lead')));
          expect(html, isNot(contains('album-hero__eyebrow')));
          expect(html, isNot(contains('浜松町コンベンションホール')));
          expect(html, isNot(contains('Hamamatsucho')));
          expect(html, isNot(contains('公式写真アルバムを')));
        }
      }
    });
  });

  group('PhotoAlbumHero photos', () {
    test('renders one tile per photo in its own slot, with no caption text', () async {
      final html = await _render(const PhotoAlbumHero());

      expect('<figure '.allMatches(html), hasLength(albumPhotos.length));
      for (final (i, photo) in albumPhotos.indexed) {
        expect(html, contains('album-hero__item--${i + 1}"'));
        // 見た目は写真だけ。何の写真かは alt（読み上げ用）で伝える。
        expect(html, contains('alt="${photo.alt.ja}"'));
        expect(html, contains('src="${photo.asset}"'));
      }
      expect(html, isNot(contains('<figcaption')));
      expect(html, isNot(contains('album-hero__caption')));
    });

    test('falls back to gradient placeholders and a gradient backdrop without assets', () async {
      // 実データ（constants/photo_album.dart）が写真入りでも結果が変わらないよう、画像の無い写真を渡す。
      final photos = [
        for (var i = 0; i < photoAlbumMaxPhotos; i++)
          AlbumPhoto(
            alt: LocalizedText(ja: '写真$i', en: 'Photo $i'),
          ),
      ];
      final html = await _render(PhotoAlbumHero(photos: photos, background: const AlbumBackground()));

      expect('album-hero__tile--empty'.allMatches(html), hasLength(photoAlbumMaxPhotos));
      expect('images/icons/camera.svg'.allMatches(html), hasLength(photoAlbumMaxPhotos));
      expect(html, isNot(contains('album-hero__bg-img')));
      expect(html, isNot(contains('album-hero__img')));
      expect(html, isNot(contains('onerror')));
    });

    test('renders real photos with alt text, crop and loading hints', () async {
      final html = await _render(
        PhotoAlbumHero(
          photos: [
            const AlbumPhoto(
              asset: 'images/album/01.webp',
              alt: LocalizedText(ja: '会場に集まった参加者', en: 'Attendees gathered at the venue'),
              objectPosition: '50% 30%',
            ),
            for (var i = 2; i <= photoAlbumMaxPhotos; i++)
              AlbumPhoto(
                asset: 'images/album/0$i.webp',
                alt: LocalizedText(ja: '写真$i', en: 'Photo $i'),
              ),
          ],
        ),
      );

      expect(html, contains('src="images/album/01.webp"'));
      expect(html, contains('alt="会場に集まった参加者"'));
      expect(html, contains('style="object-position: 50% 30%"'));
      // 2 枚目以降の alt もそのまま出る。
      expect(html, contains('alt="写真2"'));
      // 先頭 5 枚はスマホにも出るので即時、6 枚目以降はスマホで隠れるので遅延読み込み。
      expect('loading="eager"'.allMatches(html), hasLength(5));
      expect('loading="lazy"'.allMatches(html), hasLength(photoAlbumMaxPhotos - 5));
      expect('decoding="async"'.allMatches(html), hasLength(photoAlbumMaxPhotos + 1)); // タイル + 背景
      // 読み込めなくなった画像（R2 から消したなど）は取り除いて、壊れたアイコンを出さずにグラデーションのタイルに戻す。
      expect('onerror="this.remove()"'.allMatches(html), hasLength(photoAlbumMaxPhotos + 1)); // タイル + 背景
      // 最大のタイル（1 枚目）だけを高優先度で取得する。
      expect('fetchpriority="high"'.allMatches(html), hasLength(1));
      expect(html, isNot(contains('album-hero__tile--empty')));
      expect(html, isNot(contains('images/icons/camera.svg')));
    });

    test('serves every photo and the backdrop from the R2 album prefix', () {
      // 写真はリポジトリに入れず R2 から配信する（public-buckets/album-photos/）。
      const r2Album = 'https://2026-bucket.flutterkaigi.jp/album/';

      expect(albumBackground.asset, startsWith(r2Album));
      expect(albumPhotos.length, lessThanOrEqualTo(photoAlbumMaxPhotos));
      for (final photo in albumPhotos) {
        expect(photo.asset, startsWith(r2Album));
      }
      // 同じ写真を 2 つの枠に置いていない。
      expect({for (final photo in albumPhotos) photo.asset}, hasLength(albumPhotos.length));
    });

    test('ignores photos beyond the available tiles', () async {
      final photos = [
        for (var i = 0; i < photoAlbumMaxPhotos + 2; i++)
          AlbumPhoto(
            asset: 'images/album/x$i.webp',
            alt: LocalizedText(ja: '写真$i', en: 'Photo $i'),
          ),
      ];
      final html = await _render(PhotoAlbumHero(photos: photos));

      expect('<figure '.allMatches(html), hasLength(photoAlbumMaxPhotos));
      expect(html, isNot(contains('alt="写真$photoAlbumMaxPhotos"')));
    });
  });

  group('PhotoAlbumHero backdrop', () {
    test('reuses the first photo when no backdrop image is set', () async {
      final html = await _render(
        const PhotoAlbumHero(
          photos: [
            AlbumPhoto(
              asset: 'images/album/01.webp',
              alt: LocalizedText(ja: '集合写真', en: 'Group Photo'),
            ),
          ],
          background: AlbumBackground(focus: '60% 30%', zoom: 1.5, blur: 7),
        ),
      );

      // 背景は装飾なので支援技術には見せず、拡大の中心と倍率、ぼかしの強さを CSS 変数で渡す。
      expect(html, contains('aria-hidden="true"'));
      expect(html, contains('class="album-hero__bg-img"'));
      expect(html, contains('--focus: 60% 30%'));
      expect(html, contains('--zoom: 1.5'));
      expect(html, contains('--blur: 7.0px'));
      expect('src="images/album/01.webp"'.allMatches(html), hasLength(2)); // 背景 + タイル
    });

    test('prefers an explicit backdrop image', () async {
      final html = await _render(
        const PhotoAlbumHero(
          photos: [
            AlbumPhoto(
              asset: 'images/album/01.webp',
              alt: LocalizedText(ja: '集合写真', en: 'Group Photo'),
            ),
          ],
          background: AlbumBackground(asset: 'images/album/bg.webp'),
        ),
      );

      expect(html, contains('src="images/album/bg.webp"'));
      expect('src="images/album/01.webp"'.allMatches(html), hasLength(1));
      // ぼかしを指定しなければ、これまでどおりの強さ（18px）。
      expect(html, contains('--blur: 18.0px'));
    });
  });
}

Future<String> _render(Component hero, {AppLocale locale = AppLocale.ja}) async {
  final response = await renderComponent(LocaleScope(locale: locale, child: hero), standalone: true);
  return utf8.decode(response.body);
}
