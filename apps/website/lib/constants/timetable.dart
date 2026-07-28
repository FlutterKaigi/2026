import 'generated_tokens.dart';
import 'sponsors.dart' show LocalizedText;

/// 当日タイムライン（Timetable セクション）の表示用モデルとサンプルデータ。
///
/// モデル定義はこのまま本実装で使う。後半のサンプルデータ部分のみ、実データ
/// 連携（Sessionize → Firestore → `generated_sponsors.dart` と同じビルド時
/// 生成の `generated_timetable.dart`）で置き換える想定。

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
///   [timetableRooms] と同じ並び。null は空き枠。セッションは必ず
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

// ── サンプルデータ（デザイン確認用） ──────────────────────────────────

// 会場色はデザイントークンにある判別可能な 4 色相を Room ごとに割り当てる:
// M3 primary（紫）/ secondary（レンガ）/ tertiary（青）+ keycolor の deepnavy（濃紺）。
// いずれも白地で AA コントラストを満たす。
const timetableRooms = [
  TimetableRoom(name: 'Room A', colorHex: colorDeeppurpleSysLightPrimaryHex),
  TimetableRoom(name: 'Room B', colorHex: colorDeeppurpleSysLightSecondaryHex),
  TimetableRoom(name: 'Room C', colorHex: colorDeeppurpleSysLightTertiaryHex),
  TimetableRoom(name: 'Room D', colorHex: colorKeycolorsDeepnavyHex),
];

const _tagKeynote = LocalizedText(ja: 'Keynote', en: 'Keynote');
const _tagLt = LocalizedText(ja: 'LT', en: 'LT');
const _tagHandsOn = LocalizedText(ja: 'ハンズオン', en: 'Hands-on');
const _tagJa = LocalizedText(ja: '日本語', en: 'JA');
const _tagEn = LocalizedText(ja: '英語', en: 'EN');

// 詳細ダイアログのデザイン確認用に全セッション共通で入れているダミー概要。
const _sampleDescription = LocalizedText(
  ja:
      'このセッション概要はデザイン確認用のダミーテキストです。本実装では Sessionize から取り込んだ概要文がここに表示されます。\n'
      '対象者や前提知識といった補足情報も、この領域にそのまま続けて表示する想定です。レイアウト確認のため、複数段落のテキストを配置しています。',
  en:
      'This abstract is placeholder text for design review. In production, the session description imported from Sessionize will appear here.\n'
      'Supplementary details such as the target audience and prerequisites will follow in this same area. Multiple paragraphs are included to verify the layout.',
);

const _doorsOpen = LocalizedText(ja: '開場・受付', en: 'Doors Open & Registration');
const _lunch = LocalizedText(ja: 'ランチ休憩', en: 'Lunch Break');
const _shortBreak = LocalizedText(ja: '休憩', en: 'Break');
const _closing = LocalizedText(ja: 'クロージング', en: 'Closing');

const Map<TimetableDay, List<TimetableSlot>> timetableByDay = {
  TimetableDay.day1: [
    TimetableSlot.event('10:00', '10:30', _doorsOpen),
    TimetableSlot.sessions('10:30', '11:10', [
      TimetableSession(
        title: LocalizedText(
          ja: 'Flutter 2026: Impeller 時代のレンダリングを理解する',
          en: 'Flutter 2026: Understanding Rendering in the Impeller Era',
        ),
        speakerName: LocalizedText(ja: '佐藤 みどり', en: 'Midori Sato'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
        description: _sampleDescription,
        tags: [_tagKeynote, _tagJa],
      ),
      null,
      null,
      null,
    ]),
    TimetableSlot.sessions('11:20', '12:00', [
      TimetableSession(
        title: LocalizedText(
          ja: 'Riverpod 3 で始める堅牢な状態管理',
          en: 'Robust State Management with Riverpod 3',
        ),
        speakerName: LocalizedText(ja: '鈴木 一郎', en: 'Ichiro Suzuki'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
        description: _sampleDescription,
        tags: [_tagJa],
      ),
      TimetableSession(
        title: LocalizedText(
          ja: 'Platform Channels から FFI へ — ネイティブ連携の現在地',
          en: 'From Platform Channels to FFI — Native Interop Today',
        ),
        speakerName: LocalizedText(ja: '田中 花子', en: 'Hanako Tanaka'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/women/65.jpg',
        description: _sampleDescription,
        tags: [_tagEn],
      ),
      TimetableSession(
        title: LocalizedText(
          ja: 'Flutter エンジニアのための Firebase 設計パターン',
          en: 'Firebase Design Patterns for Flutter Engineers',
        ),
        speakerName: LocalizedText(ja: '斎藤 悠', en: 'Yu Saito'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/men/75.jpg',
        description: _sampleDescription,
        tags: [_tagJa],
      ),
      TimetableSession(
        title: LocalizedText(
          ja: 'Flutter × Flame で始めるゲーム開発',
          en: 'Getting Started with Game Dev in Flutter and Flame',
        ),
        speakerName: LocalizedText(ja: '森 千夏', en: 'Chinatsu Mori'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/women/21.jpg',
        description: _sampleDescription,
        tags: [_tagJa],
      ),
    ]),
    TimetableSlot.event('12:00', '13:00', _lunch),
    TimetableSlot.sessions('13:00', '13:40', [
      TimetableSession(
        title: LocalizedText(
          ja: 'Flutter アプリのアクセシビリティ対応 実践ガイド',
          en: 'A Practical Guide to Accessibility in Flutter',
        ),
        speakerName: LocalizedText(ja: '高橋 健', en: 'Ken Takahashi'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/men/41.jpg',
        description: _sampleDescription,
        tags: [_tagJa],
      ),
      TimetableSession(
        title: LocalizedText(
          ja: 'build_runner を高速化する実践テクニック',
          en: 'Practical Techniques to Speed Up build_runner',
        ),
        speakerName: LocalizedText(ja: '伊藤 さくら', en: 'Sakura Ito'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/women/17.jpg',
        description: _sampleDescription,
        tags: [_tagJa],
      ),
      TimetableSession(
        title: LocalizedText(
          ja: 'アニメーション実装パターン大全',
          en: 'A Compendium of Flutter Animation Patterns',
        ),
        speakerName: LocalizedText(ja: '井上 颯太', en: 'Sota Inoue'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
        description: _sampleDescription,
        tags: [_tagEn],
      ),
      TimetableSession(
        title: LocalizedText(
          ja: 'はじめての Widget テスト',
          en: 'Your First Widget Tests',
        ),
        speakerName: LocalizedText(ja: '山本 結衣', en: 'Yui Yamamoto'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/women/57.jpg',
        description: _sampleDescription,
        tags: [_tagHandsOn, _tagJa],
      ),
    ]),
    TimetableSlot.event('13:40', '14:00', _shortBreak),
    TimetableSlot.sessions('14:00', '14:40', [
      TimetableSession(
        title: LocalizedText(
          ja: 'Flutter Web を本番投入して学んだこと',
          en: 'Lessons from Shipping Flutter Web to Production',
        ),
        speakerName: LocalizedText(ja: '渡辺 大輔', en: 'Daisuke Watanabe'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/men/85.jpg',
        description: _sampleDescription,
        tags: [_tagEn],
      ),
      TimetableSession(
        title: LocalizedText(
          ja: 'Add-to-App: 既存ネイティブアプリへの段階的導入',
          en: 'Add-to-App: Incremental Adoption in Native Apps',
        ),
        speakerName: LocalizedText(ja: '木村 芽衣', en: 'Mei Kimura'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/women/33.jpg',
        description: _sampleDescription,
        tags: [_tagJa],
      ),
      TimetableSession(
        title: LocalizedText(
          ja: 'Flutter アプリの E2E テスト戦略',
          en: 'E2E Testing Strategies for Flutter Apps',
        ),
        speakerName: LocalizedText(ja: '林 大和', en: 'Yamato Hayashi'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/men/54.jpg',
        description: _sampleDescription,
        tags: [_tagJa],
      ),
      null,
    ]),
    TimetableSlot.sessions('14:50', '15:30', [
      TimetableSession(
        title: LocalizedText(ja: 'ライトニングトーク', en: 'Lightning Talks'),
        description: _sampleDescription,
        tags: [_tagLt],
      ),
      null,
      null,
      null,
    ]),
    TimetableSlot.event('15:30', '16:00', _closing),
  ],
  TimetableDay.day2: [
    TimetableSlot.event('10:00', '10:30', _doorsOpen),
    TimetableSlot.sessions('10:30', '11:10', [
      TimetableSession(
        title: LocalizedText(
          ja: 'jaspr で作る静的サイト — FlutterKaigi 公式サイトの舞台裏',
          en: 'Static Sites with jaspr — Behind the FlutterKaigi Website',
        ),
        speakerName: LocalizedText(ja: '中村 蓮', en: 'Ren Nakamura'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/men/11.jpg',
        description: _sampleDescription,
        tags: [_tagJa],
      ),
      TimetableSession(
        title: LocalizedText(
          ja: 'Dart 3 系マイグレーション大全',
          en: 'The Complete Guide to Dart 3 Migrations',
        ),
        speakerName: LocalizedText(ja: '小林 太一', en: 'Taichi Kobayashi'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/men/67.jpg',
        description: _sampleDescription,
        tags: [_tagJa],
      ),
      TimetableSession(
        title: LocalizedText(
          ja: 'Shorebird で実現するコード配信',
          en: 'Code Push with Shorebird',
        ),
        speakerName: LocalizedText(ja: '清水 凛', en: 'Rin Shimizu'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/women/79.jpg',
        description: _sampleDescription,
        tags: [_tagEn],
      ),
      null,
    ]),
    TimetableSlot.sessions('11:20', '12:00', [
      TimetableSession(
        title: LocalizedText(
          ja: 'アプリ内課金のつらみと向き合う',
          en: 'Facing the Pain of In-App Purchases',
        ),
        speakerName: LocalizedText(ja: '加藤 美咲', en: 'Misaki Kato'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/women/26.jpg',
        description: _sampleDescription,
        tags: [_tagJa],
      ),
      TimetableSession(
        title: LocalizedText(
          ja: 'Flutter × 生成 AI — エージェント時代のアプリ設計',
          en: 'Flutter × Generative AI — App Design in the Agent Era',
        ),
        speakerName: LocalizedText(ja: '吉田 拓海', en: 'Takumi Yoshida'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/men/36.jpg',
        description: _sampleDescription,
        tags: [_tagEn],
      ),
      null,
      TimetableSession(
        title: LocalizedText(
          ja: 'デザインシステムとデザイントークンの実装',
          en: 'Implementing Design Systems and Design Tokens',
        ),
        speakerName: LocalizedText(ja: '松本 陽菜', en: 'Hina Matsumoto'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/women/90.jpg',
        description: _sampleDescription,
        tags: [_tagHandsOn, _tagJa],
      ),
    ]),
    TimetableSlot.event('12:00', '13:00', _lunch),
    TimetableSlot.sessions('13:00', '13:40', [
      TimetableSession(
        title: LocalizedText(
          ja: 'マルチプラットフォーム時代の CI/CD 戦略',
          en: 'CI/CD Strategies for the Multi-Platform Era',
        ),
        speakerName: LocalizedText(ja: '山口 葵', en: 'Aoi Yamaguchi'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/women/12.jpg',
        description: _sampleDescription,
        tags: [_tagJa],
      ),
      TimetableSession(
        title: LocalizedText(
          ja: 'Flutter × Wasm の現在地',
          en: 'The State of Flutter on Wasm',
        ),
        speakerName: LocalizedText(ja: '岡田 直樹', en: 'Naoki Okada'),
        speakerAvatarUrl: 'https://randomuser.me/api/portraits/men/49.jpg',
        description: _sampleDescription,
        tags: [_tagJa],
      ),
      null,
      null,
    ]),
    TimetableSlot.event('13:40', '14:00', _shortBreak),
    TimetableSlot.sessions('14:00', '14:40', [
      TimetableSession(
        title: LocalizedText(ja: 'ライトニングトーク', en: 'Lightning Talks'),
        description: _sampleDescription,
        tags: [_tagLt],
      ),
      null,
      null,
      null,
    ]),
    TimetableSlot.event('14:50', '15:30', _closing),
  ],
};
