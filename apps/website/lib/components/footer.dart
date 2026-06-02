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
  static const _footerTextColor = Color('#64748B');

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
      div(classes: 'footer__legal', [
        p(classes: 'footer__copyright', [.text(strings.footerCopyright)]),
        for (final line in strings.footerTrademark) p(classes: 'footer__trademark', [.text(line)]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('footer', [
      css('&').styles(
        display: .flex,
        flexDirection: .column,
        alignItems: .center,
        width: 100.percent,
        padding: .symmetric(horizontal: 2.em, vertical: 2.5.em),
        backgroundColor: surface,
        color: onSurface,
        gap: Gap.row(2.em),
        raw: const {
          'border-top': '1px solid rgba(29, 27, 32, 0.08)',
          'text-align': 'center',
        },
      ),
      css('a').styles(
        textDecoration: const TextDecoration(line: TextDecorationLine.underline),
      ),
      css('.footer__nav', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          alignItems: .center,
          gap: Gap.row(1.5.em),
        ),
        css('.footer__nav-row').styles(
          display: .flex,
          justifyContent: .center,
          raw: const {
            'flex-wrap': 'wrap',
            'gap': '1.5em',
          },
        ),
        css('.footer__link').styles(
          color: _footerTextColor,
          fontFamily: uiFontFamily,
          raw: const {
            'font-size': '0.75rem',
            'transition': 'color 150ms ease',
          },
        ),
        css('.footer__link:hover').styles(color: deepPurple),
      ]),
      css('.footer__legal', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          alignItems: .center,
        ),
        css('.footer__copyright').styles(
          color: _footerTextColor,
          fontFamily: uiFontFamily,
          raw: const {'font-size': '0.75rem', 'line-height': '1.95'},
        ),
        css('.footer__trademark').styles(
          color: _footerTextColor,
          fontFamily: uiFontFamily,
          raw: const {'font-size': '0.625rem', 'line-height': '1.95'},
        ),
      ]),
    ]),

    css.media(MediaQuery.all(maxWidth: 720.px), [
      css('footer', [
        css('&').styles(
          gap: Gap.row(2.em),
          padding: .symmetric(horizontal: 1.25.em, vertical: 2.em),
        ),
      ]),
    ]),
  ];
}
