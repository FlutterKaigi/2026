import '../l10n/strings.dart';

// News カードに掲載するニュース項目を、日本語と英語でそれぞれ独立して管理する。
// 後で CSV や Headless CMS 等から自動生成する場合、`_newsJa` / `_newsEn` の
// const リテラルだけを差し替えれば良いように分離している。

/// News カード内のニュース1件。
class NewsLink {
  const NewsLink({
    required this.date,
    required this.title,
    required this.url,
  });

  /// 表示用の日付文字列（例: "MAY 15, 2026" / "2026年5月15日"）。
  /// uppercase はビュー側で適用するので、ここでは生の文字列のまま入れる。
  final String date;

  /// ニュース見出し。
  final String title;

  /// 詳細ページ（Medium 記事等）の URL。
  final String url;
}

const _newsJa = <NewsLink>[
  NewsLink(
    date: '2026年6月17日',
    title: 'FlutterKaigi 2026 プロポーザル応募のススメ',
    url:
        'https://medium.com/flutterkaigi/flutterkaigi-2026-%E3%83%97%E3%83%AD%E3%83%9D%E3%83%BC%E3%82%B6%E3%83%AB%E5%BF%9C%E5%8B%9F%E3%81%AE%E3%82%B9%E3%82%B9%E3%83%A1-ea8978e0fd89',
  ),
  NewsLink(
    date: '2026年5月11日',
    title: 'FlutterKaigi 2026 スポンサー募集について',
    url: 'https://medium.com/flutterkaigi/flutterkaigi-2026-opportunities-guide-ja-0e8cdb0a4acb',
  ),
  NewsLink(
    date: '2026年3月9日',
    title: 'FlutterKaigi 2026 開催のお知らせ',
    url: 'https://medium.com/flutterkaigi/flutterkaigi-2026-開催のお知らせ-f78a1421fe08',
  ),
];

const _newsEn = <NewsLink>[
  NewsLink(
    date: 'JUN 17, 2026',
    title: 'A Guide to Submitting a Proposal for FlutterKaigi 2026',
    url: 'https://medium.com/flutterkaigi/a-guide-to-submitting-a-proposal-for-flutterkaigi-2026-3fda9a01121d',
  ),
  NewsLink(
    date: 'MAY 11, 2026',
    title: 'FlutterKaigi 2026 Sponsorship Opportunities',
    url: 'https://medium.com/flutterkaigi/flutterkaigi-2026-opportunities-guide-en-1e5bd6c14461',
  ),
  NewsLink(
    date: 'MAR 9, 2026',
    title: 'Announcement: FlutterKaigi 2026',
    url: 'https://medium.com/flutterkaigi/flutterkaigi-2026-開催のお知らせ-f78a1421fe08',
  ),
];

/// 指定ロケールに対応するニュース一覧を返す。
List<NewsLink> newsForLocale(AppLocale locale) => switch (locale) {
  AppLocale.ja => _newsJa,
  AppLocale.en => _newsEn,
};

/// 「すべてのニュース」遷移先（ロケール非依存）。
const newsViewAllUrl = 'https://medium.com/flutterkaigi';
