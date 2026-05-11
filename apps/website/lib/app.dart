import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/footer.dart';
import 'components/header.dart';
import 'l10n/strings.dart';
import 'pages/home.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return Router(
      routes: [
        Route(
          path: AppLocale.ja.homePath,
          title: 'FlutterKaigi 2026',
          builder: (context, state) => const _Shell(locale: AppLocale.ja),
        ),
        Route(
          path: AppLocale.en.homePath,
          title: 'FlutterKaigi 2026',
          builder: (context, state) => const _Shell(locale: AppLocale.en),
        ),
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

class _Shell extends StatelessComponent {
  const _Shell({required this.locale});

  final AppLocale locale;

  @override
  Component build(BuildContext context) {
    return LocaleScope(
      locale: locale,
      child: div(classes: 'main', [
        const Header(),
        const Home(),
        const Footer(),
      ]),
    );
  }
}
