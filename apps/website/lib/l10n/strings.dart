import 'package:jaspr/jaspr.dart';

enum AppLocale {
  ja(code: 'ja', homePath: '/'),
  en(code: 'en', homePath: '/en');

  const AppLocale({required this.code, required this.homePath});

  final String code;
  final String homePath;
}

class Strings {
  const Strings(this.locale);

  final AppLocale locale;

  String get venue => switch (locale) {
    AppLocale.ja => '浜松町コンベンションホール',
    AppLocale.en => 'Hamamatsucho Convention Hall',
  };

  String get heroTagline => switch (locale) {
    AppLocale.ja => '会って、話して、熱くなる',
    AppLocale.en => 'Meet, Talk, Ignite.',
  };

  String get latestUpdatesCta => switch (locale) {
    _ => 'FlutterKaigi 2026 開催のお知らせ',
    // AppLocale.en => 'Get Latest Updates',
  };

  final latestUpdatesCtaUrl =
      'https://medium.com/flutterkaigi/flutterkaigi-2026-%E9%96%8B%E5%82%AC%E3%81%AE%E3%81%8A%E7%9F%A5%E3%82%89%E3%81%9B-f78a1421fe08';

  AppLocale get other => switch (locale) {
    AppLocale.ja => AppLocale.en,
    AppLocale.en => AppLocale.ja,
  };

  String get languageToggleLabel => switch (other) {
    AppLocale.ja => '日本語',
    AppLocale.en => 'English',
  };
}

class LocaleScope extends InheritedComponent {
  const LocaleScope({
    required this.locale,
    required super.child,
    super.key,
  });

  final AppLocale locale;

  static AppLocale of(BuildContext context) {
    final scope = context.dependOnInheritedComponentOfExactType<LocaleScope>();
    assert(scope != null, 'No LocaleScope found in context');
    return scope!.locale;
  }

  static Strings stringsOf(BuildContext context) => Strings(of(context));

  @override
  bool updateShouldNotify(covariant LocaleScope oldComponent) => locale != oldComponent.locale;
}
