import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/theme.dart';
import '../l10n/strings.dart';

class Footer extends StatelessComponent {
  const Footer({super.key});

  static const _pastYears = [2025, 2024, 2023, 2022, 2021];

  static const _socialLinks = <({String label, String href})>[
    (label: 'X', href: 'https://x.com/FlutterKaigi'),
    (label: 'GitHub', href: 'https://github.com/FlutterKaigi'),
    (label: 'Discord', href: 'https://discord.gg/flutterkaigi'),
    (label: 'Medium', href: 'https://medium.com/flutterkaigi'),
  ];

  static const _repositoryUrl = 'https://github.com/FlutterKaigi/2026';

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    final legalLinks = <({String label, String href})>[
      (label: strings.footerCodeOfConduct, href: strings.footerCodeOfConductUrl),
      (label: strings.footerPrivacyPolicy, href: strings.footerPrivacyPolicyUrl),
      (label: strings.footerExclusionOfAntiSocialForces, href: strings.footerExclusionUrl),
      (label: strings.footerContact, href: Strings.footerContactUrl),
      (label: strings.footerRepository, href: _repositoryUrl),
    ];

    return footer([
      div(classes: 'footer__brand', [
        a(
          href: strings.locale.homePath,
          classes: 'footer__brand-name',
          [.text('FlutterKaigi 2026')],
        ),
        p(classes: 'footer__copyright', [.text(strings.footerCopyright)]),
      ]),
      nav(
        classes: 'footer__nav',
        attributes: const {'aria-label': 'Footer'},
        [
          div(classes: 'footer__nav-row', [
            for (final year in _pastYears)
              a(
                href: 'https://$year.flutterkaigi.jp/',
                target: Target.blank,
                classes: 'footer__link',
                [.text(year.toString())],
              ),
          ]),
          div(classes: 'footer__nav-row', [
            for (final link in _socialLinks)
              a(
                href: link.href,
                target: Target.blank,
                classes: 'footer__link',
                [.text(link.label)],
              ),
          ]),
          div(classes: 'footer__nav-row', [
            for (final link in legalLinks)
              a(
                href: link.href,
                target: Target.blank,
                classes: 'footer__link',
                [.text(link.label)],
              ),
          ]),
        ],
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('footer', [
      css('&').styles(
        display: .flex,
        width: 100.percent,
        padding: .symmetric(horizontal: 2.em, vertical: 2.5.em),
        backgroundColor: surface,
        color: onSurface,
        gap: Gap.column(2.em),
        raw: const {'border-top': '1px solid rgba(29, 27, 32, 0.08)'},
      ),
      css('a').styles(
        textDecoration: const TextDecoration(line: TextDecorationLine.none),
      ),
      css('.footer__brand', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(0.75.em),
          raw: const {'flex-shrink': '0', 'max-width': '380px'},
        ),
        css('.footer__brand-name').styles(
          color: onSurface,
          fontFamily: displayFontFamily,
          fontWeight: .w700,
          raw: const {'font-size': '1.125rem'},
        ),
        css('.footer__copyright').styles(
          color: onSurfaceVariant,
          fontFamily: uiFontFamily,
          raw: const {'font-size': '0.75rem', 'line-height': '1.6'},
        ),
      ]),
      css('.footer__nav', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(1.em),
          raw: const {'margin-left': 'auto'},
        ),
        css('.footer__nav-row').styles(
          display: .flex,
          raw: const {
            'flex-wrap': 'wrap',
            'gap': '0.5em 1.5em',
          },
        ),
        css('.footer__link').styles(
          color: onSurfaceVariant,
          fontFamily: uiFontFamily,
          raw: const {
            'font-size': '0.875rem',
            'transition': 'color 150ms ease',
          },
        ),
        css('.footer__link:hover').styles(color: deepPurple),
      ]),
    ]),

    css.media(MediaQuery.all(maxWidth: 720.px), [
      css('footer', [
        css('&').styles(
          flexDirection: .column,
          gap: Gap.row(2.em),
          padding: .symmetric(horizontal: 1.25.em, vertical: 2.em),
        ),
        css('.footer__nav').styles(raw: const {'margin-left': '0'}),
      ]),
    ]),
  ];
}
