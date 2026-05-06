import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/header.dart';
import 'pages/home.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'main', [
      const Header(),
      Router(
        routes: [
          Route(path: '/', title: 'FlutterKaigi 2026', builder: (context, state) => const Home()),
        ],
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.main').styles(
      display: .flex,
      flexDirection: .column,
      minHeight: 100.vh,
    ),
  ];
}
