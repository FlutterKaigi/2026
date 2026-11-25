import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/generated_tokens.dart';
import '../constants/photo_album.dart';
import '../constants/theme.dart';
import '../l10n/strings.dart';

/// トップの先頭に置く写真ゾーン（公式写真アルバムの告知）。
///
/// ぼかした写真を全面の背景に敷き、中央に短い見出しと CTA、その周りに写真（最大 10 枚）を
/// テーブルに広げたプリントのように散らして並べる。見出しより写真を目立たせるため、文字は
/// 見出しと CTA だけにしている（日程・会場・サイト名はヘッダーと下のセクションにある）。
/// 写真が無いあいだはブランドグラデーションと同系色のタイルで成立する
/// （`constants/photo_album.dart`）。
///
/// - [albumUrl] が空のあいだは「近日公開」の無効ボタンを出す。公開日までリポジトリ /
///   PR プレビューに URL を載せないための仕組み（[photoAlbumUrl] を参照）。
/// - 背景は [background] の画像、無ければ 1 枚目の写真、どちらも無ければグラデーション。
/// - 写真のタイルは装飾的なコラージュで、リンクは CTA とアンケートだけ。
/// - 写真が読み込めないとき（R2 から消したときなど）は、その写真だけを取り除いて
///   グラデーションのタイルに戻す。
///
/// レイアウト:
/// - >960px: 中央に見出し、周りに写真を散らす。写真は 16:9 のステージ（最大幅 1600px）に
///   対する % で置くので、どの幅でも同じ構図のまま拡縮する。
/// - ≤960px: 1 カラム（見出し → 写真の散らし）。写真は先頭 7 枚。
/// - ≤640px: 縦に長いボックスで主役を大きく見せ、先頭 5 枚だけを出す（専用のスロット）。
class PhotoAlbumHero extends StatelessComponent {
  const PhotoAlbumHero({
    this.albumUrl = photoAlbumUrl,
    this.photos = albumPhotos,
    this.background = albumBackground,
    super.key,
  });

  /// 公開用アルバムの URL。空文字なら公開前の表示。
  final String albumUrl;

  /// 散らして並べる写真（並び順 = 優先度）。
  final List<AlbumPhoto> photos;

  /// 背景の指定。
  final AlbumBackground background;

  bool get _isPublished => albumUrl.isNotEmpty;

  @override
  Component build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final strings = Strings(locale);
    final shown = photos.take(photoAlbumMaxPhotos).toList();
    final backdropAsset = background.asset ?? (shown.isEmpty ? null : shown.first.asset);

    return section(id: 'photo-album', classes: 'album-hero album-hero--${locale.code}', [
      div(
        classes: 'album-hero__bg',
        attributes: const {'aria-hidden': 'true'},
        styles: Styles(
          raw: {'--focus': background.focus, '--zoom': '${background.zoom}', '--blur': '${background.blur}px'},
        ),
        [
          if (backdropAsset != null)
            img(
              src: backdropAsset,
              alt: '',
              classes: 'album-hero__bg-img',
              attributes: const {'decoding': 'async', 'onerror': _removeOnError},
            ),
          div(classes: 'album-hero__scrim', []),
        ],
      ),
      div(classes: 'album-hero__inner', [
        div(classes: 'album-hero__copy', [
          // ページの h1。サイト名は画面には出さず（ヘッダーにある）、読み上げと検索のために残す。
          // 2 つの span の間の空白は表示には影響せず、読み上げの区切りになる。
          h1(classes: 'album-hero__title', [
            span(classes: 'album-hero__sr', [.text('FlutterKaigi 2026')]),
            .text(' '),
            span(classes: 'album-hero__headline', [
              span(classes: 'album-hero__headline-line', [.text(strings.photoAlbumHeadlineLine1)]),
              .text(' '),
              span(classes: 'album-hero__headline-line', [.text(strings.photoAlbumHeadlineLine2)]),
            ]),
          ]),
          div(classes: 'album-hero__actions', [
            if (_isPublished)
              a(
                href: albumUrl,
                target: Target.blank,
                classes: 'album-hero__cta',
                attributes: const {'rel': 'noopener noreferrer'},
                [
                  span([.text(strings.photoAlbumCta)]),
                  span(
                    classes: 'album-hero__cta-arrow',
                    attributes: const {'aria-hidden': 'true'},
                    [.text('↗')],
                  ),
                ],
              )
            else
              // EventInfoCard の無効 CTA と同じく、標準の disabled に任せる。
              button(
                classes: 'album-hero__cta album-hero__cta--disabled',
                type: ButtonType.button,
                disabled: true,
                [
                  span([.text(strings.photoAlbumCtaUpcoming)]),
                ],
              ),
            // 全体アンケートへのリンクは、目立たない副リンクとして添える。
            a(
              href: strings.eventSurveyUrl,
              target: Target.blank,
              classes: 'album-hero__survey',
              attributes: const {'rel': 'noopener noreferrer'},
              [
                .text(strings.heroSurveyCta),
                span(attributes: const {'aria-hidden': 'true'}, [.text(' →')]),
              ],
            ),
          ]),
        ]),
        ul(classes: 'album-hero__photos', [
          for (final (i, photo) in shown.indexed) _tile(photo, i, locale),
        ]),
      ]),
    ]);
  }

  /// 散らしのタイル 1 枚。[index] がスロット（`--N`）を決める。写真の下に文字は出さない。
  Component _tile(AlbumPhoto photo, int index, AppLocale locale) {
    final asset = photo.asset;
    return li(classes: 'album-hero__item album-hero__item--${index + 1}', [
      figure(classes: asset == null ? 'album-hero__tile album-hero__tile--empty' : 'album-hero__tile', [
        if (asset != null)
          img(
            src: asset,
            alt: photo.alt.forLocale(locale),
            // 元写真は 3:2。表示枠への切り抜きは CSS の object-fit で行う。
            width: 960,
            height: 640,
            // 先頭 5 枚はスマホにも出るので即時、6 枚目以降は遅延（スマホでは隠れて読み込まれない）。
            loading: index < 5 ? MediaLoading.eager : MediaLoading.lazy,
            classes: 'album-hero__img',
            styles: Styles(raw: {'object-position': photo.objectPosition}),
            attributes: {'decoding': 'async', 'onerror': _removeOnError, if (index == 0) 'fetchpriority': 'high'},
          )
        else
          img(
            src: 'images/icons/camera.svg',
            alt: '',
            classes: 'album-hero__placeholder-icon',
            attributes: const {'aria-hidden': 'true'},
          ),
      ]),
    ]);
  }

  /// 画像が読み込めないときの処理（`onerror`）。その画像だけを DOM から外して、下にある
  /// タイルのグラデーション（背景ならセクションのグラデーション）に戻す。写真は R2 から
  /// 配信していて、掲載の取り下げで消すことがあるので、壊れた画像のアイコンを出さないようにする。
  static const _removeOnError = 'this.remove()';

  /// 写真が無いときの背景。ブランドグラデーションに色の溜まりを重ねて、ぼかした照明の
  /// ような奥行きを出す。
  static const _fallbackBackdrop =
      'radial-gradient(52% 70% at 80% 24%, rgba(255, 0, 85, 0.55) 0%, rgba(255, 0, 85, 0) 66%), '
      'radial-gradient(60% 80% at 10% 96%, rgba(0, 17, 85, 0.9) 0%, rgba(0, 17, 85, 0) 68%), '
      'radial-gradient(46% 60% at 58% 82%, rgba(98, 0, 234, 0.75) 0%, rgba(98, 0, 234, 0) 70%), '
      '$heroGradient';

  /// 背景に重ねる scrim。ブランドの紫〜マゼンタを明るめに乗せて華やかにし、見出しのある
  /// 中央だけを `--glow` でふんわり暗くして、どんな写真でも白い文字が読めるようにする
  /// （写真の周りは暗くしない）。
  static const _scrim =
      'radial-gradient(var(--glow), rgba(10, 4, 36, 0.55) 0%, rgba(10, 4, 36, 0) 100%), '
      'linear-gradient(180deg, rgba(10, 4, 36, 0.1) 0%, rgba(10, 4, 36, 0) 30%, rgba(10, 4, 36, 0.14) 100%), '
      'linear-gradient(135deg, rgba(255, 0, 85, 0.4) 0%, rgba(98, 0, 234, 0.38) 55%, rgba(0, 17, 85, 0.12) 100%)';

  /// 写真が入るまでのタイルの色（ブランド系の 7 種。10 枚目までは巡回して使う）。`--tile-bg` で受ける。
  static const _tileBackgrounds = [
    'radial-gradient(70% 80% at 25% 20%, rgba(255, 0, 85, 0.55), transparent 62%), '
        'radial-gradient(60% 70% at 85% 90%, rgba(0, 17, 85, 0.9), transparent 70%), '
        'linear-gradient(135deg, #6200EA, #3A00A8)',
    'radial-gradient(80% 60% at 70% 15%, rgba(255, 0, 85, 0.45), transparent 60%), '
        'linear-gradient(160deg, #4B14C9, #12066B)',
    'radial-gradient(70% 70% at 20% 80%, rgba(98, 0, 234, 0.7), transparent 65%), '
        'linear-gradient(135deg, #C2005F, #5A0FB8)',
    'radial-gradient(70% 70% at 80% 20%, rgba(255, 120, 170, 0.4), transparent 60%), '
        'linear-gradient(135deg, #36188F, #0A1260)',
    'radial-gradient(70% 70% at 30% 30%, rgba(255, 0, 85, 0.5), transparent 60%), '
        'linear-gradient(135deg, #7A18C9, #2A0A78)',
    'radial-gradient(70% 70% at 70% 70%, rgba(255, 90, 160, 0.45), transparent 62%), '
        'linear-gradient(150deg, #5A14B8, #1A0A68)',
    'radial-gradient(70% 70% at 20% 30%, rgba(98, 0, 234, 0.6), transparent 62%), '
        'linear-gradient(135deg, #B0125C, #3A0F98)',
  ];

  /// 散らし配置のスロット（>960px）。位置と幅は 16:9 のステージ（幅 100%）に対する %
  /// （`y` は高さに対する %）、傾きは度、z は重なり順。中央 26%×38% は見出しと CTA のために空け、
  /// 周りに置く。1〜6 番目が大きな主役級（先頭 5 枚はスマホにも出る）、7〜10 番目は隙間を埋める小さめの写真。
  ///
  /// 写真どうしはほとんど重ねない（顔を隠さないため）。重なるのは傾きで角が触れる程度に
  /// とどめる。5 番目と 6 番目は、6 番目が下段の中央、5 番目が右下になるよう位置を入れ替えて
  /// ある（写真の並び順＝優先度は変えない）。2 番目は顔のアップで目立つので小さめにしている。
  static const _stageSlots = <_Slot>[
    _Slot(x: 2.5, y: 4.4, w: 26, ar: '3 / 2', rot: -4, z: 3),
    _Slot(x: 74, y: 7, w: 22, ar: '3 / 2', rot: 4, z: 3),
    _Slot(x: 37, y: 3.6, w: 23, ar: '3 / 2', rot: 3, z: 2),
    _Slot(x: 8, y: 37, w: 24, ar: '3 / 2', rot: 3, z: 4),
    _Slot(x: 74, y: 72, w: 22, ar: '3 / 2', rot: -4, z: 4),
    _Slot(x: 38, y: 72, w: 23, ar: '3 / 2', rot: -3, z: 2),
    _Slot(x: 19.5, y: 66.7, w: 13, ar: '3 / 4', rot: 5, z: 5),
    _Slot(x: 66.5, y: 39.1, w: 13, ar: '3 / 4', rot: -5, z: 5),
    _Slot(x: 3, y: 68.1, w: 14, ar: '1 / 1', rot: -5, z: 6),
    _Slot(x: 82, y: 40, w: 14, ar: '3 / 4', rot: 6, z: 6),
  ];

  /// タブレット（641〜960px）用のスロット。見出しの下に置く正方形のボックスに対する %。
  /// 先頭 7 枚だけを出す。6 番目と 7 番目は、6 番目が上段の中央（見出しの真下）、7 番目が
  /// 左端になるよう位置を入れ替えてある。
  static const _boxSlots = <_Slot>[
    _Slot(x: 22, y: 26, w: 56, ar: '3 / 2', rot: -3, z: 4),
    _Slot(x: 68, y: 3, w: 28, ar: '3 / 4', rot: 6, z: 5),
    _Slot(x: 0, y: 6, w: 30, ar: '4 / 3', rot: -8, z: 2),
    _Slot(x: 4, y: 62, w: 40, ar: '3 / 2', rot: 5, z: 3),
    _Slot(x: 62, y: 58, w: 32, ar: '1 / 1', rot: -6, z: 3),
    _Slot(x: 34, y: -1, w: 24, ar: '4 / 3', rot: 3, z: 1),
    _Slot(x: -1, y: 34, w: 17, ar: '3 / 4', rot: -5, z: 1),
  ];

  /// スマホ（≤640px）用のスロット。デスクトップの構図を縮めると写真が小さくなりすぎ、6 枚目以降は
  /// 隣の写真に隠れてしまうので、縦に長いボックスで主役を大きく見せ、5 枚だけにする。
  ///
  /// 5 枚目は主役（1 枚目）の右下に上端が重なる。人物写真は顔が上寄りになりやすいので、
  /// 5 枚目を 1 枚目より手前（z を上）に出し、隠れるのが 5 枚目の顔ではなく主役の隅になるようにする。
  static const _mobileSlots = <_Slot>[
    _Slot(x: 11, y: 31, w: 78, ar: '3 / 2', rot: -2, z: 4),
    _Slot(x: 66, y: 1, w: 30, ar: '3 / 4', rot: 6, z: 5),
    _Slot(x: 0, y: 2, w: 46, ar: '4 / 3', rot: -8, z: 2),
    _Slot(x: 2, y: 70, w: 56, ar: '3 / 2', rot: 5, z: 3),
    _Slot(x: 60, y: 64, w: 38, ar: '1 / 1', rot: -6, z: 5),
  ];

  @css
  static List<StyleRule> get styles => [
    css.keyframes('album-hero-rise', {
      'from': Styles(raw: const {'opacity': '0', 'transform': 'translateY(18px)'}),
      'to': Styles(raw: const {'opacity': '1', 'transform': 'none'}),
    }),
    // 写真が「ぱらっと落ちる」。最終の傾き（--rot）に収まる。
    css.keyframes('album-hero-drop', {
      'from': Styles(
        raw: const {
          'opacity': '0',
          'transform': 'translateY(-28px) rotate(calc(var(--rot) + 8deg)) scale(0.96)',
        },
      ),
      'to': Styles(raw: const {'opacity': '1', 'transform': 'rotate(var(--rot))'}),
    }),
    css('.album-hero', [
      css('&').styles(
        position: .relative(),
        display: .flex,
        alignItems: .center,
        width: 100.percent,
        color: onBrand,
        backgroundColor: const Color('#12072F'),
        raw: const {
          'overflow': 'hidden',
          'isolation': 'isolate',
          'justify-content': 'center',
          'min-height': 'calc(100dvh - var(--header-h, 4rem))',
        },
      ),

      // ── 背景 ───────────────────────────────────────────────────────
      css('.album-hero__bg').styles(
        position: .absolute(top: 0.px, left: 0.px),
        width: 100.percent,
        height: 100.percent,
        zIndex: const ZIndex(-2),
        raw: const {'overflow': 'hidden', 'background': _fallbackBackdrop},
      ),
      // 写真を拡大（ドアップ）してぼかす。明るく鮮やかに見せる。拡大でぼかしの縁も隠れる。
      css('.album-hero__bg-img').styles(
        position: .absolute(top: 0.px, left: 0.px),
        display: .block,
        width: 100.percent,
        height: 100.percent,
        raw: const {
          'object-fit': 'cover',
          'object-position': 'var(--focus, 50% 40%)',
          'transform-origin': 'var(--focus, 50% 40%)',
          'transform': 'scale(var(--zoom, 1.6))',
          'filter': 'blur(var(--blur, 18px)) brightness(1.08) saturate(1.45)',
        },
      ),
      css('.album-hero__scrim').styles(
        position: .absolute(top: 0.px, left: 0.px),
        width: 100.percent,
        height: 100.percent,
        // 見出しの背後（ステージの中央）だけをふんわり暗くする。
        raw: const {'--glow': '30% 38% at 50% 50%', 'background': _scrim},
      ),

      // ── レイアウト ──────────────────────────────────────────────────
      // 写真を置く 16:9 のステージ（最大幅 1600px）。見出しはその中央に置く。
      css('.album-hero__inner').styles(
        position: .relative(),
        display: .grid,
        raw: const {
          'place-items': 'center',
          'width': 'min(100%, 1600px)',
          'aspect-ratio': '16 / 9',
          'margin': '0 auto',
          'padding': '0',
        },
      ),

      // ── 中央: 見出し・CTA ───────────────────────────────────────────
      // 写真（z は最大 30）より手前に置く。
      css('.album-hero__copy').styles(
        position: .relative(),
        display: .flex,
        flexDirection: .column,
        alignItems: .center,
        zIndex: const ZIndex(40),
        raw: const {'min-width': '0', 'text-align': 'center'},
      ),
      css('.album-hero__title').styles(
        fontFamily: displayFontFamily,
        fontWeight: .w700,
        raw: const {'margin': '0'},
      ),
      // 読み上げと検索のためだけに残す文字（画面には出さない）。
      css('.album-hero__sr').styles(
        position: .absolute(),
        raw: const {
          'width': '1px',
          'height': '1px',
          'margin': '-1px',
          'padding': '0',
          'overflow': 'hidden',
          'clip': 'rect(0 0 0 0)',
          'clip-path': 'inset(50%)',
          'white-space': 'nowrap',
          'border': '0',
        },
      ),
      // 見出しより写真を目立たせるため、文字は控えめにする。
      css('.album-hero__headline').styles(
        display: .block,
        raw: const {
          'font-size': 'clamp(1.75rem, 3vw, 2.875rem)',
          'line-height': '1.2',
          'letter-spacing': '0.02em',
          'text-shadow': '0 2px 28px rgba(6, 2, 28, 0.55)',
          // 語の途中では切らない。
          'word-break': 'keep-all',
          'overflow-wrap': 'anywhere',
          'text-wrap': 'balance',
        },
      ),
      css('.album-hero__headline-line').styles(display: .block),
      // 英語は Poppins で字幅が広いので、見出しを少し小さくして 2 行に収める。
      css('&.album-hero--en .album-hero__headline').styles(
        raw: const {'font-size': 'clamp(1.625rem, 2.7vw, 2.5rem)', 'letter-spacing': '-0.01em'},
      ),
      css('.album-hero__actions').styles(
        display: .flex,
        flexDirection: .column,
        alignItems: .center,
        raw: const {'margin-top': 'clamp(18px, 2.2vw, 30px)', 'gap': '14px'},
      ),
      css('.album-hero__cta', [
        css('&').styles(
          display: .inlineFlex,
          alignItems: .center,
          padding: .symmetric(horizontal: 28.px, vertical: 14.px),
          gap: Gap.column(10.px),
          backgroundColor: onBrand,
          color: deepPurple,
          fontFamily: uiFontFamily,
          fontWeight: .w700,
          radius: .circular(999.px),
          border: Border.all(style: BorderStyle.none),
          textDecoration: const TextDecoration(line: TextDecorationLine.none),
          raw: {
            ...tokenFontCss(fontM3TitleMedium),
            'cursor': 'pointer',
            'box-shadow': '0 14px 36px rgba(6, 2, 28, 0.4)',
            'transition': 'transform 150ms ease, box-shadow 150ms ease',
          },
        ),
        css('&:focus-visible').styles(
          raw: const {'outline': '3px solid #FFFFFF', 'outline-offset': '3px'},
        ),
        css('.album-hero__cta-arrow').styles(
          fontFamily: displayFontFamily,
          fontWeight: .w500,
          raw: const {'font-size': '1.1em'},
        ),
      ]),
      // リンク時だけホバーで浮かせる（無効ボタンは動かさない）。
      css('a.album-hero__cta:hover').styles(
        raw: const {
          'transform': 'translateY(-2px)',
          'box-shadow': '0 18px 42px rgba(6, 2, 28, 0.5)',
        },
      ),
      // 公開前: 写真の上でも読める、すりガラス風の無効ボタン。
      css('.album-hero__cta--disabled').styles(
        backgroundColor: const Color('#FFFFFF29'),
        color: const Color('#FFFFFFCC'),
        raw: const {
          'cursor': 'not-allowed',
          'user-select': 'none',
          'box-shadow': 'none',
          'border': '1px solid rgba(255, 255, 255, 0.4)',
          'backdrop-filter': 'blur(8px)',
          '-webkit-appearance': 'none',
          'appearance': 'none',
        },
      ),
      css('.album-hero__survey').styles(
        color: onBrandMuted,
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        textDecoration: const TextDecoration(line: TextDecorationLine.underline),
        raw: const {
          'font-size': '0.875rem',
          'text-underline-offset': '5px',
          'text-decoration-color': 'rgba(255, 255, 255, 0.45)',
          'text-shadow': '0 1px 12px rgba(6, 2, 28, 0.6)',
          'transition': 'color 150ms ease, text-decoration-color 150ms ease',
        },
      ),
      css('.album-hero__survey:hover').styles(
        color: onBrand,
        raw: const {'text-decoration-color': '#FFFFFF'},
      ),
      css('.album-hero__survey:focus-visible').styles(
        raw: const {'outline': '2px solid #FFFFFF', 'outline-offset': '4px', 'border-radius': '4px'},
      ),

      // ── 写真の散らし（テーブルに広げたプリント写真） ──────────────────
      // 位置・幅・傾き・重なり順はスロットごとの CSS 変数（--x / --y / --w / --ar / --rot / --z）。
      // 位置と幅はステージに対する % なので、どの幅でも同じ構図のまま拡縮する。
      css('.album-hero__photos').styles(
        position: .absolute(top: 0.px, left: 0.px),
        width: 100.percent,
        height: 100.percent,
        padding: .zero,
        raw: const {
          'margin': '0',
          'list-style': 'none',
          // 白フチ・角丸・プレースホルダーのアイコンの大きさをステージの幅に追従させる（cqw）。
          'container-type': 'inline-size',
        },
      ),
      css('.album-hero__item').styles(
        position: .absolute(),
        raw: const {
          'left': 'var(--x)',
          'top': 'var(--y)',
          'width': 'var(--w)',
          'aspect-ratio': 'var(--ar)',
          'z-index': 'var(--z)',
          'transform': 'rotate(var(--rot))',
        },
      ),
      for (final (i, slot) in _stageSlots.indexed)
        css('.album-hero__item--${i + 1}').styles(
          raw: {...slot.vars, '--n': '${i + 1}', '--tile-bg': _tileBackgrounds[i % _tileBackgrounds.length]},
        ),
      // プリントの白フチと影。写真（img）はフチの内側に収まる。
      css('.album-hero__tile').styles(
        position: .relative(),
        width: 100.percent,
        height: 100.percent,
        raw: const {
          'box-sizing': 'border-box',
          'margin': '0',
          'overflow': 'hidden',
          'background': 'var(--tile-bg)',
          'border': 'clamp(4px, 1.15cqw, 8px) solid #FFFFFF',
          'border-radius': 'clamp(6px, 1.5cqw, 10px)',
          'box-shadow': '0 26px 50px rgba(6, 2, 28, 0.5), 0 6px 14px rgba(6, 2, 28, 0.35)',
        },
      ),
      css('.album-hero__img').styles(
        position: .absolute(top: 0.px, left: 0.px),
        display: .block,
        width: 100.percent,
        height: 100.percent,
        raw: const {'object-fit': 'cover'},
      ),
      css('.album-hero__placeholder-icon').styles(
        position: .absolute(top: 50.percent, left: 50.percent),
        height: .auto,
        raw: const {
          'width': 'clamp(24px, 5cqw, 40px)',
          'transform': 'translate(-50%, -50%)',
          'filter': 'brightness(0) invert(1)',
          'opacity': '0.4',
        },
      ),
    ]),

    // 動きが苦手な人（prefers-reduced-motion）には出さない。写真は「ぱらっと落ちる」。
    // 落ちる動きは fill-mode を backwards にして、終わったあとはホバーの transform を邪魔しない。
    css.media(MediaQuery.raw('(prefers-reduced-motion: no-preference)'), [
      css('.album-hero', [
        css('.album-hero__copy > *').styles(
          raw: const {'animation': 'album-hero-rise 700ms cubic-bezier(0.2, 0.7, 0.2, 1) both'},
        ),
        css('.album-hero__copy > :nth-child(2)').styles(raw: const {'animation-delay': '90ms'}),
        css('.album-hero__item').styles(
          raw: const {
            'animation': 'album-hero-drop 800ms cubic-bezier(0.2, 0.8, 0.2, 1) backwards',
            'animation-delay': 'calc(120ms + var(--n) * 70ms)',
          },
        ),
      ]),
    ]),
    // ホバーで写真をまっすぐ起こして手前に出す（見出しの下には潜る）。タッチ端末や動きが
    // 苦手な人には出さない。
    css.media(MediaQuery.raw('(hover: hover) and (prefers-reduced-motion: no-preference)'), [
      css('.album-hero', [
        css('.album-hero__item').styles(
          raw: const {'transition': 'transform 320ms cubic-bezier(0.2, 0.8, 0.2, 1)'},
        ),
        css('.album-hero__item:hover').styles(
          raw: const {'z-index': '30', 'transform': 'rotate(0deg) scale(1.06)'},
        ),
      ]),
    ]),

    // タブレット以下：1 カラム（見出し → 写真の散らし）。写真は正方形のボックスに入れ、
    // 構図はそのまま幅に合わせて拡縮する。
    css.media(MediaQuery.all(maxWidth: 960.px), [
      css('.album-hero', [
        css('&').styles(raw: const {'min-height': '0'}),
        // 見出しは上にあるので、ふんわり暗くする位置も上に移す。
        css('.album-hero__scrim').styles(raw: const {'--glow': '80% 16% at 50% 19%'}),
        css('.album-hero__inner').styles(
          raw: const {
            'aspect-ratio': 'auto',
            'grid-template-columns': 'minmax(0, 1fr)',
            'row-gap': '40px',
            'padding': '48px 20px 56px',
          },
        ),
        css('.album-hero__headline').styles(
          raw: const {'font-size': 'clamp(2rem, 8vw, 3rem)'},
        ),
        css('&.album-hero--en .album-hero__headline').styles(
          raw: const {'font-size': 'clamp(1.875rem, 7.2vw, 2.75rem)'},
        ),
        css('.album-hero__photos').styles(
          position: .relative(),
          raw: const {'width': '100%', 'max-width': '720px', 'height': 'auto', 'aspect-ratio': '1 / 1'},
        ),
        for (final (i, slot) in _boxSlots.indexed) css('.album-hero__item--${i + 1}').styles(raw: slot.vars),
        for (var n = _boxSlots.length + 1; n <= _stageSlots.length; n++)
          css('.album-hero__item--$n').styles(display: .none),
      ]),
    ]),

    // スマホ：縦に長いボックスで主役を大きく見せ、5 枚だけにする。
    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.album-hero', [
        css('.album-hero__photos').styles(raw: const {'aspect-ratio': '0.7 / 1'}),
        for (final (i, slot) in _mobileSlots.indexed) css('.album-hero__item--${i + 1}').styles(raw: slot.vars),
        for (var n = _mobileSlots.length + 1; n <= _stageSlots.length; n++)
          css('.album-hero__item--$n').styles(display: .none),
      ]),
    ]),
  ];
}

/// 散らし配置の 1 スロット（位置・幅は配置先の箱に対する %、傾きは度）。
class _Slot {
  const _Slot({
    required this.x,
    required this.y,
    required this.w,
    required this.ar,
    required this.rot,
    required this.z,
  });

  final double x;
  final double y;
  final double w;
  final String ar;
  final double rot;
  final int z;

  Map<String, String> get vars => {
    '--x': '$x%',
    '--y': '$y%',
    '--w': '$w%',
    '--ar': ar,
    '--rot': '${rot}deg',
    '--z': '$z',
  };
}
