import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/meta.dart';
import '../constants/build_config.dart';
import '../constants/site.dart';
import '../constants/sponsors.dart';
import '../constants/theme.dart';
import '../l10n/strings.dart';

/// Sponsor detail page at `sponsors/{slug}` (Figma node 668:3547).
///
/// Layout: back link → full-width logo banner → two columns (tier badge +
/// name + Connect links on the left, PR text on the right). Per-page OGP is
/// injected via `Document.head()`.
class SponsorDetailPage extends StatelessComponent {
  const SponsorDetailPage({super.key, required this.sponsor});

  final Sponsor sponsor;

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    final locale = strings.locale;
    final name = sponsor.name.resolve(locale);
    final prText = sponsor.prText.resolve(locale).trim();
    // Split on newlines so each line becomes its own text node joined by
    // explicit <br>s (see the render below). We deliberately do NOT use
    // `white-space: pre-wrap` to honour the author's line breaks: Jaspr
    // pretty-prints the built HTML and indents a multi-line text node onto its
    // own line, and pre-wrap would render that formatting indentation as a
    // visible first-line indent. Explicit <br>s let the surrounding formatting
    // whitespace collapse normally.
    final prLines = prText.split('\n');
    // Connect セクションには X と公式サイト（other）のみ表示する。
    // recruit は非表示（サイト上に出さない方針）。
    final visibleLinks = sponsor.links
        .where(
          (l) => l.type == SponsorLinkType.x || l.type == SponsorLinkType.other,
        )
        .toList();
    // Job Boards ブロック用 URL（Firestore sponsors.jobBoardUrl を直接使用）。
    final jobBoardUrl = sponsor.jobBoardUrl;

    return Component.fragment([
      Document.head(
        meta: {'description': _clip(prText, 160)},
        children: [
          ogMeta('og:title', '$name | FlutterKaigi 2026'),
          ogMeta('og:description', _clip(prText, 200)),
          ogMeta('og:image', _absUrl(sponsor.ogpImage)),
          ogMeta('og:type', 'article'),
          ogMeta('og:url', '$siteOrigin${locale.sponsorHref(sponsor.slug)}/'),
        ],
      ),
      section(classes: 'sponsor-detail', [
        div(classes: 'sponsor-detail__inner', [
          a(
            href: locale.sponsorsAnchorHref,
            classes: 'sponsor-detail__back',
            // Static multipage site: there's no client router, but browsers
            // natively restore scroll position on Back. So when the visitor
            // arrived from the list, go back to restore the exact list scroll
            // position.
            //
            // BUT if the visitor switched language on this detail page, the
            // previous history entry is the *other-language* detail page (the
            // language switch is a plain <a href> that pushes a new entry), so
            // history.back() would return there instead of the list. We detect
            // that via the same-origin referrer (browsers send the full path
            // for same-origin navigations): when it points at a sponsor detail
            // page ('/sponsors/'), we skip back() and fall through to the
            // #sponsors anchor, which lands on the top page's sponsor section in
            // the *current* (switched) language. External/direct opens also fall
            // through to the anchor.
            attributes: const {
              'onclick':
                  'if(document.referrer.indexOf("/sponsors/")<0&&window.history.length>1){window.history.back();return false;}',
            },
            [
              span(
                classes: 'sponsor-detail__back-arrow',
                attributes: const {'aria-hidden': 'true'},
                [.text('←')],
              ),
              span([.text(strings.sponsorBackToList)]),
            ],
          ),
          div(classes: 'sponsor-detail__banner', [
            img(
              classes: 'sponsor-detail__logo',
              src: sponsor.wideLogo,
              alt: name,
            ),
          ]),
          div(classes: 'sponsor-detail__body', [
            div(classes: 'sponsor-detail__meta', [
              span(
                classes: 'sponsor-detail__badge badge--${sponsor.tier.name}',
                [.text(strings.sponsorTierBadge(sponsor.tier.label))],
              ),
              h1(classes: 'sponsor-detail__name', [.text(name)]),
              if (jobBoardUrl != null)
                div(classes: 'sponsor-detail__links', [
                  h2(classes: 'sponsor-detail__links-title', [
                    .text('Job Boards'),
                  ]),
                  div(classes: 'sponsor-detail__links-list', [
                    a(
                      href: jobBoardUrl,
                      target: Target.blank,
                      classes: 'connect-link',
                      attributes: const {'rel': 'noopener noreferrer'},
                      [
                        span(classes: 'connect-link__icon', [
                          img(
                            src: 'images/icons/link_briefcase.svg',
                            alt: '',
                            attributes: const {'aria-hidden': 'true'},
                          ),
                        ]),
                        span(classes: 'connect-link__title', [.text(strings.jobBoardsCta)]),
                        span(
                          classes: 'connect-link__ext',
                          attributes: const {'aria-hidden': 'true'},
                          [.text('↗')],
                        ),
                      ],
                    ),
                  ]),
                ]),
              if (visibleLinks.isNotEmpty)
                div(classes: 'sponsor-detail__links', [
                  h2(classes: 'sponsor-detail__links-title', [
                    .text(strings.sponsorConnectHeading),
                  ]),
                  div(classes: 'sponsor-detail__links-list', [
                    for (final link in visibleLinks)
                      a(
                        href: link.url,
                        target: Target.blank,
                        classes: 'connect-link',
                        attributes: const {'rel': 'noopener noreferrer'},
                        [
                          span(classes: 'connect-link__icon', [
                            img(
                              src: sponsorLinkIconAsset(link.type),
                              alt: '',
                              attributes: const {'aria-hidden': 'true'},
                            ),
                          ]),
                          span(classes: 'connect-link__title', [.text(link.url)]),
                          span(
                            classes: 'connect-link__ext',
                            attributes: const {'aria-hidden': 'true'},
                            [.text('↗')],
                          ),
                        ],
                      ),
                  ]),
                ]),
            ]),
            div(classes: 'sponsor-detail__desc', [
              div(classes: 'sponsor-detail__pr', [
                for (var i = 0; i < prLines.length; i++) ...[
                  if (i > 0) br(),
                  .text(prLines[i]),
                ],
              ]),
            ]),
          ]),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.sponsor-detail', [
      css('&').styles(
        display: .flex,
        justifyContent: .center,
        width: 100.percent,
        padding: .symmetric(horizontal: 24.px, vertical: 48.px),
        raw: const {'background-color': '#FDF7FF'},
      ),
      css('.sponsor-detail__inner').styles(
        display: .flex,
        flexDirection: .column,
        width: 100.percent,
        gap: Gap.row(24.px),
        raw: const {'max-width': '1232px'},
      ),

      // Back link.
      css('.sponsor-detail__back', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          gap: Gap.column(8.px),
          color: const Color('#4700AF'),
          fontFamily: uiFontFamily,
          textDecoration: const TextDecoration(line: TextDecorationLine.none),
          raw: const {'font-size': '16px', 'width': 'fit-content'},
        ),
        css('&:hover').styles(
          raw: const {'text-decoration': 'underline', 'text-underline-offset': '0.2em'},
        ),
        css('.sponsor-detail__back-arrow').styles(raw: const {'font-size': '18px'}),
      ]),

      // Logo banner: the logo is the bucket image used as-is (no baked padding),
      // centered and contained. Horizontal clear space is 15% (logo capped at
      // 70% width, matching the sponsors-section / Job Boards convention). The
      // height is fixed via max-height so a square logo stays contained instead
      // of stretching the banner tall.
      css('.sponsor-detail__banner', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
          width: 100.percent,
          backgroundColor: onBrand,
          radius: .circular(16.px),
          border: Border.all(
            style: BorderStyle.solid,
            color: const Color('#CBC3D933'),
            width: 1.px,
          ),
          // No padding here: horizontal clear space is set on the <img> via the
          // 70% cap so it stays 15% instead of stacking with banner padding.
          raw: const {
            'min-height': 'clamp(220px, 30vw, 360px)',
          },
        ),
        css('.sponsor-detail__logo').styles(
          // 一部のロゴ素材は外周に白いグロー（白縁のにじみ）がアルファに焼き込まれて
          // おり、純白以外の面では灰色く浮く。img 自体に白プレートを明示し、どの面に
          // 置かれてもグローが見えないようにする。
          backgroundColor: onBrand,
          raw: const {
            'max-width': '70%',
            'max-height': 'clamp(180px, 26vw, 312px)',
            'object-fit': 'contain',
          },
        ),
      ]),

      // Two-column body.
      css('.sponsor-detail__body').styles(
        display: .flex,
        alignItems: .start,
        width: 100.percent,
        gap: Gap.column(48.px),
        padding: .symmetric(vertical: 24.px),
      ),
      css('.sponsor-detail__meta').styles(
        display: .flex,
        flexDirection: .column,
        gap: Gap.row(24.px),
        width: 100.percent,
        raw: const {'max-width': '460px', 'flex-shrink': '0'},
      ),

      // Tier badge.
      css('.sponsor-detail__badge', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          alignSelf: .start,
          padding: .symmetric(horizontal: 16.px, vertical: 6.px),
          color: onBrand,
          fontFamily: uiFontFamily,
          fontWeight: .w700,
          radius: .circular(999.px),
          raw: const {
            'font-size': '14px',
            'letter-spacing': '0.8px',
            'text-transform': 'uppercase',
            'background': '#65558F',
          },
        ),
        // Platinum: a bright, cool metallic sheen (brighter than Silver) with a
        // dark slate label so the precious-metal look stays legible.
        css('&.badge--platinum').styles(
          color: const Color('#2B2F36'),
          raw: const {
            'background': 'linear-gradient(135deg, #D6DBE0 0%, #F2F4F6 22%, #B8BFC8 50%, #EDEFF2 78%, #C3C9D0 100%)',
            'border': '1px solid #FFFFFFB3',
            'box-shadow': '0 1px 2px rgba(45, 47, 56, 0.18)',
          },
        ),
        css('&.badge--gold').styles(
          raw: const {'background': 'linear-gradient(90deg, #F4B400 0%, #E59400 100%)'},
        ),
        css('&.badge--silver').styles(
          raw: const {'background': 'linear-gradient(90deg, #9AA0A6 0%, #7C8388 100%)'},
        ),
        css('&.badge--bronze').styles(
          raw: const {'background': 'linear-gradient(90deg, #C7864F 0%, #A86B3C 100%)'},
        ),
        // Tool shares Individual's purple (per design feedback).
        css('&.badge--tool').styles(
          raw: const {'background': 'linear-gradient(90deg, #7E57C2 0%, #65558F 100%)'},
        ),
        css('&.badge--student').styles(
          raw: const {'background': 'linear-gradient(90deg, #2E9E5B 0%, #228A4C 100%)'},
        ),
        css('&.badge--community').styles(
          raw: const {'background': 'linear-gradient(90deg, #1E88E5 0%, #1565C0 100%)'},
        ),
        css('&.badge--individual').styles(
          raw: const {'background': 'linear-gradient(90deg, #7E57C2 0%, #65558F 100%)'},
        ),
      ]),

      css('.sponsor-detail__name').styles(
        color: const Color('#1D1A25'),
        fontFamily: displayFontFamily,
        fontWeight: .w700,
        raw: const {'font-size': 'clamp(1.375rem, 3vw, 1.875rem)', 'line-height': '1.25'},
      ),

      // Connect links card.
      css('.sponsor-detail__links', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(16.px),
          width: 100.percent,
          padding: .all(25.px),
          radius: .circular(12.px),
          border: Border.all(
            style: BorderStyle.solid,
            color: const Color('#CBC3D9'),
            width: 1.px,
          ),
          raw: const {'background-color': '#F3EBFB'},
        ),
        css('.sponsor-detail__links-title').styles(
          color: const Color('#1D1A25'),
          fontFamily: uiFontFamily,
          fontWeight: .w500,
          raw: const {'font-size': '16px', 'line-height': '24px'},
        ),
        css('.sponsor-detail__links-list').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(8.px),
        ),
        // NOTE: do NOT name these "sponsor-link" — ad blockers carry cosmetic
        // filters (e.g. ##.sponsor-link) that set display:none on such elements,
        // which hid every outbound link while the container stayed (empty card).
        // Same rationale as the icon filenames in sponsors.dart (avoid "sponsor").
        css('.connect-link', [
          css('&').styles(
            display: .flex,
            alignItems: .center,
            gap: Gap.column(12.px),
            padding: .all(8.px),
            color: const Color('#494456'),
            fontFamily: uiFontFamily,
            radius: .circular(8.px),
            textDecoration: const TextDecoration(line: TextDecorationLine.none),
            raw: const {'font-size': '16px', 'transition': 'background-color 150ms ease'},
          ),
          css('&:hover').styles(raw: const {'background-color': '#FFFFFF99'}),
          css('.connect-link__icon', [
            css('&').styles(
              display: .flex,
              alignItems: .center,
              justifyContent: .center,
              raw: const {'flex-shrink': '0'},
            ),
            css('img').styles(width: 20.px, height: 20.px),
          ]),
          css('.connect-link__title').styles(
            raw: const {'flex': '1 1 auto', 'min-width': '0', 'overflow-wrap': 'anywhere'},
          ),
          css('.connect-link__ext').styles(
            color: onSurfaceVariant,
            raw: const {'font-size': '14px', 'flex-shrink': '0'},
          ),
        ]),
      ]),

      // Description / PR text.
      css('.sponsor-detail__desc', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(16.px),
          raw: const {'flex': '1 1 0', 'min-width': '0'},
        ),
        css('.sponsor-detail__pr').styles(
          color: const Color('#494456'),
          fontFamily: uiFontFamily,
          raw: const {
            'font-size': '16px',
            'line-height': '1.7',
            'overflow-wrap': 'anywhere',
          },
        ),
      ]),
    ]),

    // Stack columns on narrower viewports.
    css.media(MediaQuery.all(maxWidth: 860.px), [
      css('.sponsor-detail__body').styles(flexDirection: .column, gap: Gap.row(32.px)),
      css('.sponsor-detail__meta').styles(raw: const {'max-width': '100%'}),
    ]),
    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.sponsor-detail').styles(
        padding: .symmetric(horizontal: 16.px, vertical: 32.px),
      ),
    ]),
  ];
}

/// Collapses whitespace and clips to [max] characters for meta descriptions.
String _clip(String s, int max) {
  final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.length <= max) return t;
  return '${t.substring(0, max - 1).trimRight()}…';
}

/// Absolute URL for an OGP asset path (or a passthrough remote URL).
String _absUrl(String asset) => asset.startsWith('http') ? asset : '$siteOrigin$baseHref$asset';
