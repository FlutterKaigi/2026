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
        for (final item in newsForLocale(locale))
          li(classes: 'news-card__item', [
            p(classes: 'news-card__date', [.text(item.date)]),
            a(
              href: item.url,
              target: Target.blank,
              classes: 'news-card__link',
              [.text(item.title)],
            ),
          ]),
      ]),
      div(classes: 'news-card__cta-wrap', [
        a(
          href: newsViewAllUrl,
          target: Target.blank,
          classes: 'news-card__cta',
          [
            span([.text(strings.newsViewAllCta)]),
            span(
              classes: 'news-card__cta-arrow',
              attributes: const {'aria-hidden': 'true'},
              [.text('→')],
            ),
          ],
        ),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.news-card', [
      css('&').styles(
        display: .flex,
        flexDirection: .column,
        padding: .all(49.px),
        backgroundColor: const Color('#FFDAD6'),
        radius: .circular(24.px),
        border: Border.all(
          style: BorderStyle.solid,
          color: const Color('#D9C3C94D'),
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
          backgroundColor: const Color('#FFB4AB'),
          alignItems: .center,
          justifyContent: .center,
          raw: const {'flex-shrink': '0'},
        ),
        css('img').styles(width: 20.px, height: 20.px),
      ]),
      css('.news-card__title').styles(
        color: const Color('#1D1A25'),
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
        color: const Color('#1D1A25'),
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
          color: const Color('#1D1A25'),
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
        css('&:hover').styles(color: const Color('#73332F')),
      ]),
      css('.news-card__cta-wrap').styles(
        display: .flex,
        justifyContent: .center,
      ),
      css('.news-card__cta', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          gap: Gap.column(8.px),
          padding: .symmetric(horizontal: 24.px, vertical: 16.px),
          color: const Color('#73332F'),
          fontFamily: uiFontFamily,
          fontWeight: .w500,
          radius: .circular(100.px),
          textDecoration: const TextDecoration(line: TextDecorationLine.none),
          raw: const {
            'font-size': '22px',
            'line-height': '24px',
            'letter-spacing': '0.15px',
            'transition': 'background-color 150ms ease',
          },
        ),
        css('&:hover').styles(
          backgroundColor: const Color('#73332F1A'),
        ),
        css('.news-card__cta-arrow').styles(
          raw: const {'font-size': '24px', 'line-height': '24px'},
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
      ]),
    ]),
  ];
}
