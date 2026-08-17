import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/news_links.dart';
import '../../constants/theme.dart';
import '../../l10n/strings.dart';

class NewsCard extends StatelessComponent {
  const NewsCard({super.key});

  @override
  Component build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final strings = Strings(locale);
    final allItems = newsForLocale(locale);
    final visibleItems = allItems.take(newsCardInitialCount);
    final hiddenItems = allItems.skip(newsCardInitialCount);

    return article(classes: 'news-card', [
      div(classes: 'news-card__head', [
        div(classes: 'news-card__icon', [
          img(
            src: 'images/icons/news.svg',
            alt: '',
            attributes: const {'aria-hidden': 'true'},
          ),
        ]),
        h2(classes: 'news-card__title', [.text(strings.newsCardTitle)]),
      ]),
      ul(classes: 'news-card__list', [
        for (final item in visibleItems) _newsItem(item),
      ]),
      // 4件目以降は <details> でアコーディオン展開する。JS 不使用（Header の
      // モバイルメニューと同じ方針）。対応ブラウザでは ::details-content で
      // 高さアニメーションが付き、非対応ブラウザでは瞬時に開閉するだけになる。
      // <summary> は HTML 上 <details> の最初の子要素である必要があるため、
      // 展開ボタンをつねにセクション末尾に見せる視覚上の並び（CSS の
      // order、下記 styles 参照）とは DOM 順が一致しない。読み上げ順は
      // 保たれるが、開いた状態で Tab すると「ボタン→その上に見えている
      // 記事リンク」の順になる（<summary> を先頭に置く HTML 制約とのトレ
      // ードオフとして許容）。
      if (hiddenItems.isNotEmpty)
        details(classes: 'news-card__more', [
          summary(classes: 'news-card__toggle', [
            span(classes: 'news-card__toggle-chip', [
              span(classes: 'news-card__toggle-label', [
                span(classes: 'news-card__toggle-text news-card__toggle-text--closed', [
                  .text(strings.newsShowAllCta),
                ]),
                span(classes: 'news-card__toggle-text news-card__toggle-text--open', [
                  .text(strings.newsShowLessCta),
                ]),
              ]),
              span(
                classes: 'news-card__toggle-arrow',
                attributes: const {'aria-hidden': 'true'},
                [.text('↓')],
              ),
            ]),
          ]),
          ul(classes: 'news-card__list', [
            for (final item in hiddenItems) _newsItem(item),
          ]),
        ]),
    ]);
  }

  Component _newsItem(NewsLink item) {
    return li(classes: 'news-card__item', [
      p(classes: 'news-card__date', [.text(item.date)]),
      a(
        href: item.url,
        target: Target.blank,
        classes: 'news-card__link',
        [.text(item.title)],
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.news-card', [
      css('&').styles(
        display: .flex,
        flexDirection: .column,
        padding: .all(49.px),
        backgroundColor: secondaryContainer,
        radius: .circular(24.px),
        border: Border.all(
          style: BorderStyle.solid,
          color: eventCardBorderNews,
          width: 1.px,
        ),
        raw: const {'gap': '32px'},
      ),
      css('.news-card__head').styles(
        display: .flex,
        alignItems: .center,
        gap: Gap.column(12.px),
      ),
      css('.news-card__icon', [
        css('&').styles(
          display: .flex,
          width: 44.px,
          height: 44.px,
          radius: .circular(16.px),
          backgroundColor: eventNewsIconBg,
          alignItems: .center,
          justifyContent: .center,
          raw: const {'flex-shrink': '0'},
        ),
        css('img').styles(width: 20.px, height: 20.px),
      ]),
      css('.news-card__title').styles(
        color: onSurface,
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {'font-size': '22px', 'line-height': '28px'},
      ),
      css('.news-card__list').styles(
        display: .flex,
        flexDirection: .column,
        padding: .zero,
        raw: const {'list-style': 'none', 'margin': '0', 'gap': '16px'},
      ),
      css('.news-card__item').styles(
        display: .flex,
        flexDirection: .column,
        gap: Gap.row(4.px),
      ),
      css('.news-card__date').styles(
        color: onSurface,
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {
          'font-size': '11px',
          'line-height': '16px',
          'letter-spacing': '0.55px',
          'text-transform': 'uppercase',
        },
      ),
      css('.news-card__link', [
        css('&').styles(
          color: onSurface,
          fontFamily: uiFontFamily,
          fontWeight: .w400,
          textDecoration: const TextDecoration(
            line: TextDecorationLine.underline,
          ),
          raw: const {
            'font-size': '22px',
            'line-height': '28px',
            'text-underline-offset': '2px',
            'transition': 'color 150ms ease',
          },
        ),
        css('&:hover').styles(color: onSecondaryContainer),
      ]),
      // 4件目以降を格納する <details>。<summary> は HTML 上つねに最初の
      // 子要素である必要がある（a11y・no-JS フォールバックのため）が、
      // 見た目上はボタンをセクション末尾に固定したい（記事一覧の続きとして
      // 展開させたい）ので、flex + order で視覚的な並びだけ入れ替える。
      // 既定では瞬時に開閉するだけだが、::details-content に対応する
      // ブラウザでは高さアニメーションが付く
      // （prefers-reduced-motion: no-preference のときのみ、下部で定義）。
      css('.news-card__more', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          raw: const {'list-style': 'none', 'margin': '0', 'padding': '0', 'gap': '0'},
        ),
        // ::details-content 対応ブラウザでの折りたたみ。非対応ブラウザでは
        // 無視され、ネイティブの瞬時開閉のみになる（機能上は問題ない）。
        // overflow は [open] でも hidden のまま維持する（UA 既定と同じ）。
        // overflow は display/content-visibility と違い
        // transition-behavior: allow-discrete の早期切替対象ではないため、
        // 開閉アニメーション中の切替タイミングが保証されない。フォーカス
        // リングが中身の端で軽く切れる可能性は残るが、未観測のため
        // hidden 維持を優先する。
        css('&::details-content').styles(
          raw: const {
            'height': '0',
            'overflow': 'hidden',
            'content-visibility': 'hidden',
          },
        ),
        // 開いている間だけ、直前の .news-card__list との間隔をリスト内の
        // item間隔（16px）に詰めて「続きが伸びる」見た目にし、隠れていた
        // 項目とボタンの間には改めて余白（24px）を空ける。閉時は既存の
        // カード全体の gap（32px）だけが効き、ボタンは元の見た目のまま。
        css('&[open]').styles(
          raw: const {'margin-top': '-16px', 'gap': '24px'},
        ),
        css('&[open]::details-content').styles(
          raw: const {'height': 'auto', 'content-visibility': 'visible'},
        ),
      ]),
      css('.news-card__toggle', [
        css('&').styles(
          display: .flex,
          justifyContent: .center,
          raw: const {'cursor': 'pointer', 'list-style': 'none', 'order': '1'},
        ),
        css('&::-webkit-details-marker').styles(raw: const {'display': 'none'}),
        css('&::marker').styles(raw: const {'display': 'none'}),
        css('&:focus-visible').styles(
          raw: const {'outline': '2px solid #65558F', 'outline-offset': '2px'},
        ),
      ]),
      css('.news-card__toggle-chip', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          gap: Gap.column(8.px),
          padding: .symmetric(horizontal: 24.px, vertical: 16.px),
          color: onSecondaryContainer,
          fontFamily: uiFontFamily,
          fontWeight: .w500,
          radius: .circular(100.px),
          raw: const {
            'font-size': '22px',
            'line-height': '24px',
            'letter-spacing': '0.15px',
            'transition': 'background-color 150ms ease',
          },
        ),
        css('.news-card__toggle-arrow').styles(
          raw: const {
            'font-size': '24px',
            'line-height': '24px',
            'transition': 'transform 200ms ease',
          },
        ),
      ]),
      // M3 State Layer (Hover 10%) — onSecondaryContainer 由来のオーバーレイ。
      // 非先頭の `&` は jaspr の Selector.resolve では置換されず
      // `$parent $selector` として連結されるだけなので、ネストせず
      // トップレベルのセレクタとして書く。
      css('.news-card__toggle:hover .news-card__toggle-chip').styles(
        backgroundColor: onSecondaryContainerHover,
      ),
      // 開いているときは「閉じる」ラベルを出し、矢印を上向き（180deg）に
      // 回転させる。一般的な「もっと見る」系アコーディオンの慣習
      // （閉:下向きシェブロン→開:上向き）に合わせている。
      css('.news-card__toggle-text--open').styles(
        raw: const {'display': 'none'},
      ),
      css('.news-card__more[open] .news-card__toggle-text--open').styles(
        raw: const {'display': 'inline'},
      ),
      css('.news-card__more[open] .news-card__toggle-text--closed').styles(
        raw: const {'display': 'none'},
      ),
      css('.news-card__more[open] .news-card__toggle-arrow').styles(
        raw: const {'transform': 'rotate(180deg)'},
      ),
    ]),

    // トランジションのみ prefers-reduced-motion で切り替える。開閉レイアウト
    // 自体（height/overflow/content-visibility）は常時有効にしておく —
    // ここに transition を混ぜると reduced-motion 時に height の再計算が
    // 効かなくなり、展開しても中身が見えなくなる。
    css.media(MediaQuery.raw('(prefers-reduced-motion: no-preference)'), [
      css('.news-card__more', [
        css('&').styles(
          raw: const {
            'interpolate-size': 'allow-keywords',
            // margin-top・gap も height と歩調を合わせて遷移させる。ここを
            // 揃えないと [open] 切替と同時にカードが瞬時にジャンプし、
            // height の遷移だけが遅れてカクついて見える。
            'transition': 'margin-top 300ms ease, gap 300ms ease',
          },
        ),
        css('&::details-content').styles(
          raw: const {
            'transition': 'height 300ms ease, content-visibility 300ms allow-discrete',
          },
        ),
      ]),
    ]),

    css.media(MediaQuery.all(maxWidth: 960.px), [
      css('.news-card').styles(
        padding: .all(32.px),
        raw: const {'gap': '24px'},
      ),
    ]),

    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.news-card', [
        css('&').styles(padding: .all(24.px)),
        css('.news-card__link').styles(
          raw: const {'font-size': '18px', 'line-height': '26px'},
        ),
        css('.news-card__toggle-chip').styles(
          raw: const {'font-size': '18px', 'line-height': '26px'},
        ),
      ]),
    ]),
  ];
}
