/// News ドメインモデル。
///
/// この File は手書きで Git 管理される。実データは `generated_news.dart` に
/// 生成され、`tool/generate_news.dart` が `news` Firestore コレクション
/// （packages/data、ダッシュボードが書き込むものと同じ）から生成する。
/// スポンサー情報 (`generated_sponsors.dart`) と異なり、ニュースは機密情報
/// ではないため生成後のファイルも gitignore せず Git 管理する。
library;

import '../l10n/strings.dart';
import 'generated_news.dart';

/// ニュース1件（Firestore `news` コレクションの1ドキュメントに対応）。
class NewsEntry {
  const NewsEntry({
    required this.id,
    required this.titleJa,
    required this.titleEn,
    required this.urlJa,
    required this.urlEn,
    required this.publishedAt,
  });

  final String id;
  final String titleJa;
  final String titleEn;
  final String urlJa;
  final String urlEn;

  /// 公開日時（UTC）。日付表示のフォーマットにのみ使用する。
  final DateTime publishedAt;

  String titleFor(AppLocale locale) => switch (locale) {
    AppLocale.ja => titleJa,
    AppLocale.en => titleEn,
  };

  String urlFor(AppLocale locale) => switch (locale) {
    AppLocale.ja => urlJa,
    AppLocale.en => urlEn,
  };

  /// 表示用の日付文字列（例: "2026年6月17日" / "JUN 17, 2026"）。
  /// uppercase 等の見た目はここで確定させ、ビュー側では変換しない。
  String dateFor(AppLocale locale) {
    final d = publishedAt;
    return switch (locale) {
      AppLocale.ja => '${d.year}年${d.month}月${d.day}日',
      AppLocale.en => '${_monthAbbrEn[d.month]} ${d.day}, ${d.year}',
    };
  }
}

const _monthAbbrEn = [
  '', // 1-indexed
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

/// NewsCard に表示する1件（指定ロケールで解決済みの表示用データ）。
class NewsLink {
  const NewsLink({
    required this.date,
    required this.title,
    required this.url,
  });

  /// 表示用の日付文字列。
  final String date;

  /// ニュース見出し。
  final String title;

  /// 詳細ページ（Medium 記事等）の URL。
  final String url;
}

/// NewsCard に表示する最大件数。それ以降は「すべてのニュース」から辿る。
const _maxNewsCardItems = 3;

/// 指定ロケールのニュース一覧（公開日降順、最大 [_maxNewsCardItems] 件）を返す。
List<NewsLink> newsForLocale(AppLocale locale) {
  final sorted = [...generatedNews]..sort(
    (a, b) => b.publishedAt.compareTo(a.publishedAt),
  );
  return [
    for (final n in sorted.take(_maxNewsCardItems))
      NewsLink(
        date: n.dateFor(locale),
        title: n.titleFor(locale),
        url: n.urlFor(locale),
      ),
  ];
}

/// 「すべてのニュース」遷移先（ロケール非依存）。
const newsViewAllUrl = 'https://medium.com/flutterkaigi';
