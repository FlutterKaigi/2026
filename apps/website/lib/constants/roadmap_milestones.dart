import '../l10n/strings.dart';

// Roadmap カードに並べるマイルストーン。後から CSV → Generated Dart に
// 置き換えられるよう、ここはプレーンな const リテラルのみで完結させている。
//
// 仮に `roadmap.csv` のスキーマを考えるとこんな並びになる想定：
// date_ja,date_en,title_ja,title_en,gate
// 2026年5月15日,"May 15, 2026",スポンサー募集開始,Call for Sponsors Opens,sponsors
// ...

/// CTA など他コンポーネントから「特定のマイルストーン」を引くためのタグ。
enum MilestoneGate { sponsors, tickets, sessions, conference }

/// Roadmap タイムライン上の1項目。
class RoadmapMilestone {
  const RoadmapMilestone({
    required this.dateJa,
    required this.dateEn,
    required this.titleJa,
    required this.titleEn,
    this.gate,
  });

  final String dateJa;
  final String dateEn;
  final String titleJa;
  final String titleEn;

  /// 他コンポーネント（CTA 等）と連動させるためのタグ。
  final MilestoneGate? gate;

  String dateFor(AppLocale locale) => switch (locale) {
    AppLocale.ja => dateJa,
    AppLocale.en => dateEn,
  };

  String titleFor(AppLocale locale) => switch (locale) {
    AppLocale.ja => titleJa,
    AppLocale.en => titleEn,
  };
}

const eventRoadmap = <RoadmapMilestone>[
  RoadmapMilestone(
    dateJa: '2026年5月15日',
    dateEn: 'May 15, 2026',
    titleJa: 'スポンサー募集開始',
    titleEn: 'Call for Sponsors Opens',
    gate: MilestoneGate.sponsors,
  ),
  RoadmapMilestone(
    dateJa: '2026年6月17日',
    dateEn: 'June 17, 2026',
    titleJa: 'セッション募集開始',
    titleEn: 'Call for Proposals Opens',
    gate: MilestoneGate.sessions,
  ),
  RoadmapMilestone(
    dateJa: '2026年7月27日',
    dateEn: 'July 27, 2026',
    titleJa: 'チケット販売開始',
    titleEn: 'Ticket Sales Open',
    gate: MilestoneGate.tickets,
  ),
  RoadmapMilestone(
    dateJa: '2026年10月29日 – 30日',
    dateEn: 'October 29–30, 2026',
    titleJa: 'カンファレンス開催',
    titleEn: 'Conference Day',
    gate: MilestoneGate.conference,
  ),
];

/// 指定 gate のマイルストーンを返す。見つからない場合は null。
RoadmapMilestone? milestoneByGate(MilestoneGate gate) {
  for (final m in eventRoadmap) {
    if (m.gate == gate) return m;
  }
  return null;
}
