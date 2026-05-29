import '../l10n/strings.dart';

// Roadmap カードに並べるマイルストーン。後から CSV → Generated Dart に
// 置き換えられるよう、ここはプレーンな const リテラルのみで完結させている。
//
// 仮に `roadmap.csv` のスキーマを考えるとこんな並びになる想定：
// date,date_ja,date_en,title_ja,title_en,gate
// 2026-05-15,2026年5月15日,"May 15, 2026",スポンサー募集開始,Call for Sponsors Opens,sponsors
// ...

/// CTA など他コンポーネントから「特定のマイルストーン」を引くためのタグ。
enum MilestoneGate { sponsors, tickets, sessions, conference }

/// 表示状態。`now` との比較で自動算出する。
enum MilestoneStatus {
  /// 既に過ぎたマイルストーン。
  past,

  /// 次に到来する直近のマイルストーン（ハイライト対象）。
  upNext,

  /// それより先のマイルストーン。
  future,
}

/// Roadmap タイムライン上の1項目。
class RoadmapMilestone {
  const RoadmapMilestone({
    required this.year,
    required this.month,
    required this.day,
    required this.dateJa,
    required this.dateEn,
    required this.titleJa,
    required this.titleEn,
    this.gate,
  });

  /// `const` リテラルで持つために年月日を素朴な int で保持。
  /// `DateTime` 自体は非 const のため、必要なときに [date] で組み立てる。
  final int year;
  final int month;
  final int day;

  /// 当該マイルストーンの実日時。状態判定（past/upNext/future）に用いる。
  DateTime get date => DateTime(year, month, day);

  final String dateJa;
  final String dateEn;
  final String titleJa;
  final String titleEn;

  /// 他コンポーネント（CTA 等）と連動させるためのタグ。
  final MilestoneGate? gate;

  String dateFor(AppLocale locale) =>
      switch (locale) { AppLocale.ja => dateJa, AppLocale.en => dateEn };

  String titleFor(AppLocale locale) =>
      switch (locale) { AppLocale.ja => titleJa, AppLocale.en => titleEn };
}

const eventRoadmap = <RoadmapMilestone>[
  RoadmapMilestone(
    year: 2026,
    month: 5,
    day: 15,
    dateJa: '2026年5月15日',
    dateEn: 'May 15, 2026',
    titleJa: 'スポンサー募集開始',
    titleEn: 'Call for Sponsors Opens',
    gate: MilestoneGate.sponsors,
  ),
  RoadmapMilestone(
    year: 2026,
    month: 7,
    day: 26,
    dateJa: '2026年7月26日',
    dateEn: 'July 26, 2026',
    titleJa: 'チケット販売開始',
    titleEn: 'Ticket Sales Open',
    gate: MilestoneGate.tickets,
  ),
  RoadmapMilestone(
    year: 2026,
    month: 10,
    day: 29,
    dateJa: '2026年10月29日 – 30日',
    dateEn: 'October 29–30, 2026',
    titleJa: 'カンファレンス開催',
    titleEn: 'Conference Day',
    gate: MilestoneGate.conference,
  ),
];

/// `now` 時点での状態を返す。`all` は同時に評価したい全マイルストーンの集合
/// （通常は `eventRoadmap`）。upNext は未来側で最も早い1件だけ。
MilestoneStatus milestoneStatus(
  RoadmapMilestone m,
  DateTime now, {
  required Iterable<RoadmapMilestone> all,
}) {
  if (!m.date.isAfter(now)) return MilestoneStatus.past;
  final futureSorted = [
    for (final x in all)
      if (x.date.isAfter(now)) x,
  ]..sort((a, b) => a.date.compareTo(b.date));
  if (futureSorted.isNotEmpty && identical(futureSorted.first, m)) {
    return MilestoneStatus.upNext;
  }
  return MilestoneStatus.future;
}

/// 指定 gate のマイルストーンを返す。見つからない場合は null。
RoadmapMilestone? milestoneByGate(MilestoneGate gate) {
  for (final m in eventRoadmap) {
    if (m.gate == gate) return m;
  }
  return null;
}
