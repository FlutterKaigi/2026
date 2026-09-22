import 'dart:async';

import 'package:app/core/designsystem/theme/app_theme.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/theme_mode.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/force_update/data/force_update_provider.dart';
import 'package:app/feature/force_update/ui/force_update_blocker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Root application widget wiring routing, theming and localization together.
class App extends HookConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // 強制アップデートは起動直後とフォアグラウンド復帰のたびに確認する。
    useEffect(() {
      var disposed = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!disposed) {
          unawaited(ref.read(forceUpdateProvider.notifier).check());
        }
      });
      return () => disposed = true;
    }, const []);
    useOnAppLifecycleStateChange((_, current) {
      if (current == AppLifecycleState.resumed) {
        unawaited(ref.read(forceUpdateProvider.notifier).check());
      }
    });

    return MaterialApp.router(
      onGenerateTitle: (context) => Translations.of(context).app.title,
      routerConfig: router,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: themeMode,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final navigationBarColor = appNavigationBarColor(colorScheme);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            systemNavigationBarColor: navigationBarColor,
            systemNavigationBarDividerColor: navigationBarColor,
            systemNavigationBarIconBrightness: colorScheme.brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          ),
          // 全ルートを一度に塞ぐため、Navigator の外側でブロッキング UI を重ねる。
          child: ForceUpdateBlocker(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
