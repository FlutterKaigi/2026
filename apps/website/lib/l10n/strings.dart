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

  /// Jaspr Router route path (absolute, **no** baseHref) for a sponsor detail
  /// page — this drives the SSG output directory.
  String sponsorRoutePath(String slug) => '${homePath == '/' ? '' : homePath}/sponsors/$slug';

  /// Navigation href (baseHref-prefixed) for a sponsor detail page.
  String sponsorHref(String slug) => '${linkHref}sponsors/$slug';

  /// Navigation href to the Event Info section on the home page.
  String get eventInfoAnchorHref => '$linkHref#event-info';

  /// Navigation href to the Sponsors section on the home page.
  String get sponsorsAnchorHref => '$linkHref#sponsors';

  /// Navigation href to the Job Boards section on the home page.
  String get jobBoardsAnchorHref => '$linkHref#job-boards';

  /// The other supported locale (the site ships exactly two).
  AppLocale get other => this == AppLocale.ja ? AppLocale.en : AppLocale.ja;
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

  // ── Header ──────────────────────────────────────────────────────────

  String get navMenuAriaLabel => switch (locale) {
    AppLocale.ja => 'メニュー',
    AppLocale.en => 'Navigation menu',
  };

  // ── Event section ───────────────────────────────────────────────────

  String get eventInfoCardTitle => switch (locale) {
    AppLocale.ja => 'Event Information',
    AppLocale.en => 'Event Information',
  };

  String get eventInfoDateLabel => switch (locale) {
    AppLocale.ja => '日程',
    AppLocale.en => 'DATE',
  };

  String get eventInfoVenueLabel => switch (locale) {
    AppLocale.ja => '会場',
    AppLocale.en => 'VENUE',
  };

  String get eventInfoTicketsLabel => switch (locale) {
    AppLocale.ja => 'チケット',
    AppLocale.en => 'TICKETS',
  };

  String get eventInfoGetTicketsCta => switch (locale) {
    AppLocale.ja => 'チケットを購入',
    AppLocale.en => 'Get Tickets',
  };

  String get eventInfoSubmitSessionCta => switch (locale) {
    AppLocale.ja => 'セッションを応募',
    AppLocale.en => 'Submit Your Session',
  };

  String get eventInfoComingSoon => switch (locale) {
    AppLocale.ja => 'Coming soon...',
    AppLocale.en => 'Coming soon...',
  };

  /// `date` 部分はマイルストーン側のロケール対応済み文字列を埋め込む。
  String eventInfoTicketsOpensAt(String date) => switch (locale) {
    AppLocale.ja => '$date 販売開始',
    AppLocale.en => 'Opens $date',
  };

  String get eventInfoTicketsAriaLabel => switch (locale) {
    AppLocale.ja => 'チケット販売は準備中です',
    AppLocale.en => 'Tickets are not on sale yet',
  };

  String get roadmapCardTitle => switch (locale) {
    AppLocale.ja => 'Roadmap',
    AppLocale.en => 'Roadmap',
  };

  String get newsCardTitle => switch (locale) {
    AppLocale.ja => 'News',
    AppLocale.en => 'News',
  };

  String get newsViewAllCta => switch (locale) {
    AppLocale.ja => 'すべてのニュースを見る',
    AppLocale.en => 'View All News',
  };

  String get latestUpdatesCta => switch (locale) {
    AppLocale.ja => 'セッション応募受付中!',
    AppLocale.en => 'Session Submissions Now Open!',
  };

  String get latestUpdatesCtaUrl => switch (locale) {
    AppLocale.ja =>
      'https://medium.com/flutterkaigi/flutterkaigi-2026-%E3%83%97%E3%83%AD%E3%83%9D%E3%83%BC%E3%82%B6%E3%83%AB%E5%BF%9C%E5%8B%9F%E3%81%AE%E3%82%B9%E3%82%B9%E3%83%A1-ea8978e0fd89',
    AppLocale.en =>
      'https://medium.com/flutterkaigi/a-guide-to-submitting-a-proposal-for-flutterkaigi-2026-3fda9a01121d',
  };

  // ── Sponsors ────────────────────────────────────────────────────────

  String get sponsorsNav => 'Sponsors';

  String get sponsorsTitle => 'Sponsors';

  String get sponsorsSubtitle => switch (locale) {
    AppLocale.ja => 'FlutterKaigi 2026 を支えてくださるスポンサーの皆様',
    AppLocale.en => 'The sponsors supporting FlutterKaigi 2026',
  };

  /// Accessible label for a sponsor logo tile linking to its detail page.
  String sponsorCardAriaLabel(String name) => switch (locale) {
    AppLocale.ja => '$name の詳細を見る',
    AppLocale.en => 'View details for $name',
  };

  String get sponsorBackToList => switch (locale) {
    AppLocale.ja => 'スポンサー一覧に戻る',
    AppLocale.en => 'Back to Sponsors',
  };

  String get sponsorConnectHeading => 'Connect';

  /// Tier badge text on the detail page (CSS upper-cases it).
  String sponsorTierBadge(String tierLabel) => switch (locale) {
    AppLocale.ja => '$tierLabel スポンサー',
    AppLocale.en => '$tierLabel Sponsor',
  };

  String get footerCopyright => switch (locale) {
    AppLocale.ja => '© 2021 - 2026 FlutterKaigi 実行委員会.',
    AppLocale.en => '© 2021 - 2026 FlutterKaigi Executive Committee.',
  };

  List<String> get footerTrademark => switch (locale) {
    AppLocale.ja => const [
      'Flutter および関連するロゴは Google LLC の商標です。FlutterKaigi は Google LLC の承認または提携を受けておりません。',
      'Flutter の名称およびロゴは Google LLC の商標です。',
      'RevCommは、株式会社 RevComm の登録商標または商標です。',
    ],
    AppLocale.en => const [
      'Flutter and the related logo are trademarks of Google LLC. FlutterKaigi is not affiliated with or otherwise sponsored by Google LLC.',
      'The Flutter name and the Flutter logo are trademarks of Google LLC.',
      'RevComm is a registered trademark or trademark of RevComm Inc.',
    ],
  };

  // ── Job Boards ──────────────────────────────────────────────────────

  /// Section subtitle on the home Job Boards section.
  String get jobBoardsSubtitle => switch (locale) {
    AppLocale.ja => 'Flutter エンジニアを募集しているスポンサー企業の求人情報をチェックしよう。',
    AppLocale.en => 'Explore open roles at the sponsor companies hiring Flutter engineers.',
  };

  /// CTA label on Job Board cards and the detail page block.
  String get jobBoardsCta => switch (locale) {
    AppLocale.ja => '採用情報',
    AppLocale.en => 'Open Roles',
  };

  /// Accessible aria-label for a Job Board CTA link.
  String jobBoardsCardAriaLabel(String name) => switch (locale) {
    AppLocale.ja => '$name の採用情報を見る（新しいタブで開く）',
    AppLocale.en => 'View open roles at $name (opens in a new tab)',
  };

  /// Footer link label for the Job Boards section.
  String get footerJobBoards => switch (locale) {
    AppLocale.ja => 'ジョブボード',
    AppLocale.en => 'Job Boards',
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

  AppLocale get other => locale.other;

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
