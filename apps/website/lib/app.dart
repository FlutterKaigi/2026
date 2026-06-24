import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/footer.dart';
import 'components/header.dart';
import 'components/meta.dart';
import 'constants/generated_sponsors.dart';
import 'constants/sponsors.dart';
import 'l10n/strings.dart';
import 'pages/home.dart';
import 'pages/sponsor_detail.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    // Each locale gets a home route plus one explicit route per sponsor.
    // Explicit (non-parameterized) routes are required for static-site
    // generation — jaspr's SSG renders exactly the route paths the router
    // reports, and parameterized (`:slug`) routes are unsupported there.
    return Router(
      routes: [
        for (final locale in AppLocale.values) ...[
          Route(
            path: locale.homePath,
            title: 'FlutterKaigi 2026',
            builder: (context, state) => _HomeShell(locale: locale),
          ),
          for (final sponsor in generatedSponsors)
            Route(
              path: locale.sponsorRoutePath(sponsor.slug),
              title: '${sponsor.name.resolve(locale)} | FlutterKaigi 2026',
              builder: (context, state) => _SponsorShell(locale: locale, sponsor: sponsor),
            ),
        ],
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    css(':root').styles(raw: const {'--header-h': '4rem'}),
    css('.main').styles(
      display: .flex,
      flexDirection: .column,
      minHeight: 100.vh,
    ),
  ];
}

class _HomeShell extends StatelessComponent {
  const _HomeShell({required this.locale});

  final AppLocale locale;

  @override
  Component build(BuildContext context) {
    return LocaleScope(
      locale: locale,
      child: div(classes: 'main', [
        const Header(),
        const SiteHead(),
        const Home(),
        const Footer(),
      ]),
    );
  }
}

class _SponsorShell extends StatelessComponent {
  const _SponsorShell({required this.locale, required this.sponsor});

  final AppLocale locale;
  final Sponsor sponsor;

  @override
  Component build(BuildContext context) {
    return LocaleScope(
      locale: locale,
      child: div(classes: 'main', [
        const Header(),
        SponsorDetailPage(sponsor: sponsor),
        const Footer(),
      ]),
    );
  }
}
