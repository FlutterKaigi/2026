import 'sponsors.dart' show LocalizedText;

/// 当日タイムライン（Timetable セクション）の表示用モデル。
///
/// `sponsors.dart` と同じ構成で、このファイルは手書き・git 管理下に置き、
/// *データ* は `generated_sessions.dart` 側に持つ。生成物は
/// `tool/generate_sessions.dart` がビルド時に Firestore
/// （`sessions` / `speakers` / `venues` / `timelineEvents`）から作り、
/// git には入れない（`.gitignore` 参照）。このファイルには実データを置かない。

/// 開催日。タブ切替の単位。
enum TimetableDay {
  day1(label: 'Day 1', date: '10.29', weekday: 'THU'),
  day2(label: 'Day 2', date: '10.30', weekday: 'FRI');

  const TimetableDay({
    required this.label,
    required this.date,
    required this.weekday,
  });

  final String label;
  final String date;
  final String weekday;
}

/// セッション会場（トラック）。
class TimetableRoom {
  const TimetableRoom({required this.name, required this.colorHex});

  final LocalizedText name;

  /// 会場識別色。デザイントークン由来の色のみを使う。
  final String colorHex;
}

/// 1 セッション分の表示データ。
class TimetableSession {
  const TimetableSession({
    required this.title,
    this.speakerName,
    this.speakerAvatarUrl,
    this.description,
    this.tags = const [],
  });

  final LocalizedText title;

  /// null のとき（LT 大会など）はスピーカー行を表示しない。
  final LocalizedText? speakerName;

  /// スピーカーのアイコン画像 URL（実データでは Sessionize の profilePicture）。
  /// null のとき（写真未登録のスピーカー）はプレースホルダー画像を表示する。
  final String? speakerAvatarUrl;

  /// セッション概要（詳細ダイアログに表示）。段落は `\n` 区切り。
  /// null のときは概要ブロックを表示しない。
  final LocalizedText? description;

  final List<LocalizedText> tags;
}

/// 1 日分のタイムテーブル。
///
/// [ticks] はその日に現れる開始・終了時刻をすべて集めた行の境界（`HH:mm`
/// 昇順）で、隣り合う 2 つがグリッドの 1 行になる。各 [TimetableEntry] は
/// 自分の開始境界から終了境界までを占めるため、開始時刻の揃わないセッション
/// （30 分枠の裏で 10 分の LT が 3 本など）が 1 行に押し込められることなく、
/// 時間軸を共有したまま上下にずれて並ぶ。
class TimetableProgramme {
  const TimetableProgramme({this.ticks = const [], this.entries = const []});

  final List<String> ticks;
  final List<TimetableEntry> entries;
}

/// タイムテーブル上の 1 枠。縦位置は [TimetableProgramme.ticks] の
/// インデックスで表す（[startTick] 以上 [endTick] 未満の行を占める）。
///
/// - [TimetableEntry.session] : 会場カラムに収まるセッション。
/// - [TimetableEntry.event] : 開場・休憩などのタイムラインイベント。
///   [roomIndex] が null なら全幅バー、あればその会場カラムに収まる
///   ラベル枠（ランチステージなど）になる。
class TimetableEntry {
  const TimetableEntry.session({
    required this.startTick,
    required this.endTick,
    required int this.roomIndex,
    required TimetableSession this.session,
  }) : eventLabel = null;

  const TimetableEntry.event({
    required this.startTick,
    required this.endTick,
    this.roomIndex,
    required LocalizedText this.eventLabel,
  }) : session = null;

  final int startTick;
  final int endTick;

  /// `generatedTimetableRooms` 上の位置。全幅イベントは null。
  final int? roomIndex;
  final TimetableSession? session;
  final LocalizedText? eventLabel;
}
