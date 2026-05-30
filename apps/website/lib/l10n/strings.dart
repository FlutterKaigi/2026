import 'package:jaspr/jaspr.dart';

import '../constants/build_config.dart';

enum AppLocale {
  ja(code: 'ja', homePath: '/', relativeHref: ''),
  en(code: 'en', homePath: '/en', relativeHref: 'en/')
  ;

  const AppLocale({
    required this.code,
    required this.homePath,
    required this.relativeHref,
  });

  final String code;

  /// Absolute path used as the Jaspr Router route definition (drives SSG output dirs).
  final String homePath;

  /// Path relative to `baseHref`. Combined into [linkHref] to produce navigation targets.
  final String relativeHref;

  /// Hyperlink target for navigation. Prefixed with `baseHref` so the same markup
  /// works for both production (`/`) and PR previews (`/pr-preview/pr-N/`).
  String get linkHref => '$baseHref$relativeHref';
}

class Strings {
  const Strings(this.locale);

  final AppLocale locale;

  String get venue => switch (locale) {
    AppLocale.ja => '浜松町コンベンションホール',
    AppLocale.en => 'Hamamatsucho Convention Hall',
  };

  String get heroTagline => switch (locale) {
    AppLocale.ja => '会って、話して、熱くなる。',
    AppLocale.en => 'Connect, Converse, Ignite.',
  };

  String get heroThemeName => '〜Assemble〜';

  String get latestUpdatesCta => switch (locale) {
    AppLocale.ja => 'FlutterKaigi 2026 スポンサー募集について',
    AppLocale.en => 'FlutterKaigi 2026 Sponsorship Opportunities',
  };

  String get latestUpdatesCtaUrl => switch (locale) {
    AppLocale.ja => 'https://medium.com/flutterkaigi/flutterkaigi-2026-opportunities-guide-ja-0e8cdb0a4acb',
    AppLocale.en => 'https://medium.com/flutterkaigi/flutterkaigi-2026-opportunities-guide-en-1e5bd6c14461',
  };

  String get footerCopyright => switch (locale) {
    AppLocale.ja =>
      '© 2026 FlutterKaigi 実行委員会. Flutter および関連するロゴは Google LLC の商標です。当イベントは Google LLC の承認または提携を受けておりません。',
    AppLocale.en =>
      '© 2026 FlutterKaigi Executive Committee. Flutter and the related logo are trademarks of Google LLC. We are not endorsed by or affiliated with Google LLC.',
  };

  String get footerCodeOfConduct => switch (locale) {
    AppLocale.ja => '行動規範',
    AppLocale.en => 'Code of Conduct',
  };

  String get footerCodeOfConductUrl => switch (locale) {
    AppLocale.ja => 'https://docs.flutterkaigi.jp/Code-of-Conduct.ja',
    AppLocale.en => 'https://docs.flutterkaigi.jp/Code-of-Conduct',
  };

  String get footerPrivacyPolicy => switch (locale) {
    AppLocale.ja => 'プライバシーポリシー',
    AppLocale.en => 'Privacy Policy',
  };

  String get footerPrivacyPolicyUrl => switch (locale) {
    AppLocale.ja => 'https://docs.flutterkaigi.jp/Privacy-Policy.ja',
    AppLocale.en => 'https://docs.flutterkaigi.jp/Privacy-Policy',
  };

  String get footerExclusionOfAntiSocialForces => switch (locale) {
    AppLocale.ja => '反社会的勢力排除に関する基本方針',
    AppLocale.en => 'Exclusion of Anti-Social Forces',
  };

  String get footerExclusionUrl => switch (locale) {
    AppLocale.ja => 'https://docs.flutterkaigi.jp/Exclusion-of-Anti-Social-Forces.ja',
    AppLocale.en => 'https://docs.flutterkaigi.jp/Exclusion-of-Anti-Social-Forces',
  };

  String get footerContact => switch (locale) {
    AppLocale.ja => 'お問い合わせ',
    AppLocale.en => 'Contact',
  };

  static const footerContactUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSdXjVagTv38Co0A0nwjm5V3k5V3FZZCsB7F-wFQbJxonp5pFg/viewform?usp=publish-editor';

  String get footerRepository => 'Repository';

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
