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
    AppLocale.en => 'Meet, Talk, Get Fired Up.',
  };

  String get latestUpdatesCta => switch (locale) {
    AppLocale.ja => 'FlutterKaigi 2026 開催のお知らせ',
    AppLocale.en => 'FlutterKaigi 2026 Opportunities Guide',
  };

  String get latestUpdatesCtaUrl => switch (locale) {
    AppLocale.ja =>
      'https://medium.com/flutterkaigi/flutterkaigi-2026-opportunities-guide-ja-0e8cdb0a4acb',
    AppLocale.en =>
      'https://medium.com/flutterkaigi/flutterkaigi-2026-opportunities-guide-en-1e5bd6c14461',
  };

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
