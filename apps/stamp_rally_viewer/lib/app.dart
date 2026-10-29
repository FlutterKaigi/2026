import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'history_page.dart';
import 'login_page.dart';
import 'providers.dart';

class StampRallyViewerApp extends StatelessWidget {
  const StampRallyViewerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FlutterKaigi 2026 スタンプラリー状況確認',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ja'),
    supportedLocales: const [Locale('ja')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF086D77)),
      scaffoldBackgroundColor: const Color(0xFFF5F8FA),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ),
    home: const _AccountGate(),
  );
}

class _AccountGate extends ConsumerWidget {
  const _AccountGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(authStateProvider)) {
    AsyncData(value: final user?) when !user.isAnonymous => HistoryPage(key: ValueKey(user.uid), user: user),
    AsyncData() => const LoginPage(),
    AsyncError() => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ログイン状態を確認できませんでした。通信環境を確認して再試行してください。'),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => ref.invalidate(authStateProvider), child: const Text('再試行')),
            ],
          ),
        ),
      ),
    ),
    _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
  };
}
