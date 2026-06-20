import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitializer.ensureInitialized(options: Env.firebaseOptions);
  usePathUrlStrategy();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'FlutterKaigi 2026 管理ダッシュボード',
      home: Scaffold(body: Center(child: Text('FlutterKaigi 2026 管理ダッシュボード'))),
    );
  }
}
