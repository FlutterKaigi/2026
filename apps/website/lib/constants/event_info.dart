import '../l10n/strings.dart';

// 後から CSV 等から再生成しやすいよう、イベントの掲載情報を集約したデータ層。
// News は `news_links.dart`、Roadmap は `roadmap_milestones.dart` を参照。
// UI のラベル（DATE / VENUE / TICKETS 等）は `strings.dart` 側に置く。

/// 日英で値を持つ素朴な多言語文字列。
class LocalizedText {
  const LocalizedText({required this.ja, required this.en});

  final String ja;
  final String en;

  String forLocale(AppLocale locale) => switch (locale) {
    AppLocale.ja => ja,
    AppLocale.en => en,
  };
}

/// 開催日。
const eventDate = LocalizedText(
  ja: '2026年10月29日 – 30日',
  en: 'October 29–30, 2026',
);

/// 開催会場名。
const eventVenue = LocalizedText(
  ja: '浜松町コンベンションホール',
  en: 'Hamamatsucho Convention Hall',
);

/// チケット購入ページの URL。販売開始までは UI 側で Disabled 扱い。
const eventGetTicketsUrl = 'https://github.com/FlutterKaigi/2026';

/// セッション応募ページの URL。応募開始までは UI 側で Disabled 扱い。
const eventSubmitSessionUrl = 'https://github.com/FlutterKaigi/2026';

/// Event セクション右下に並べるソーシャルリンクのカード。
const eventSocialCards = <SocialCard>[
  SocialCard(
    iconAsset: 'images/icons/medium.svg',
    label: LocalizedText(ja: 'Medium', en: 'Medium'),
    handle: '@flutterkaigi',
    url: 'https://medium.com/flutterkaigi',
  ),
  SocialCard(
    iconAsset: 'images/icons/x.svg',
    label: LocalizedText(ja: 'Follow on X', en: 'Follow on X'),
    handle: '@FlutterKaigi',
    url: 'https://x.com/FlutterKaigi',
  ),
];

/// Medium / X 等のソーシャルカード。
class SocialCard {
  const SocialCard({
    required this.iconAsset,
    required this.label,
    required this.handle,
    required this.url,
  });

  final String iconAsset;
  final LocalizedText label;
  final String handle;
  final String url;
}
