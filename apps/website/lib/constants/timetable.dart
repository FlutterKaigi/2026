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
  day2(label: 'Day 2', date: '10.30', weekday: 'FRI')
  ;

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

  final String name;

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

/// 1 つの時間帯（タイムテーブルの 1 行）。
///
/// - [TimetableSlot.sessions] : 会場ごとの並列セッション。[byRoom] は
///   `generatedTimetableRooms` と同じ並び。null は空き枠。セッションは必ず
///   いずれか 1 つの会場に属する（全会場またぎのセッションは存在しない）。
/// - [TimetableSlot.event] : 開場・休憩などのタイムラインイベント（全幅バー）。
class TimetableSlot {
  const TimetableSlot.sessions(this.start, this.end, this.byRoom) : eventLabel = null;

  const TimetableSlot.event(this.start, this.end, LocalizedText label) : byRoom = const [], eventLabel = label;

  final String start;
  final String end;
  final List<TimetableSession?> byRoom;
  final LocalizedText? eventLabel;
}
