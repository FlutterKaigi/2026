import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/generated_sessions.dart';
import '../constants/generated_tokens.dart';
import '../constants/theme.dart';
import '../constants/timetable.dart';
import '../l10n/strings.dart';
import 'app_dialog.dart';

/// Home-page Timetable section: 当日タイムライン（Day 1 / Day 2 タブ切替）。
///
/// 配色は Sponsors セクションと同じ白黒基調（ink #1D1A25 / gray #494456 /
/// #CBC3D9 系ボーダー、tinted 背景 #FDF7FF + 白カード）に揃える。
///
/// タブ切替は hamburger メニュー（`<details>`）と同様に JS なしで実現する。
/// hidden な radio input と `:checked ~` セレクタの組み合わせで表示日を
/// 切り替える（SSG のまま動く）。
///
/// データはビルド時生成の `constants/generated_sessions.dart`（Firestore
/// 由来、git 管理外）。タイムテーブル確定前は空になるため、その場合は
/// タブとグリッドを出さず準備中メッセージのみを表示する。
class TimetableSection extends StatelessComponent {
  const TimetableSection({super.key});

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    // 会場が 1 つも無い＝タイムテーブル未確定。セッションが無ければ
    // タイムラインイベントだけ出しても意味がないので同じ扱いにする。
    final hasProgramme =
        generatedTimetableRooms.isNotEmpty &&
        generatedTimetableByDay.values.any((programme) => programme.entries.isNotEmpty);
    return section(id: 'timetable', classes: 'timetable-section', [
      div(classes: 'timetable-section__inner', [
        div(classes: 'timetable-section__header', [
          h2(classes: 'timetable-section__title', [.text(strings.timetableTitle)]),
          p(classes: 'timetable-section__subtitle', [.text(strings.timetableSubtitle)]),
        ]),
        if (!hasProgramme)
          p(classes: 'timetable-empty', [.text(strings.timetableComingSoon)])
        else ...[
          // タブ切替用の radio（sr-only で視覚のみ非表示）。tabs / day グリッド
          // の兄弟要素であることが `:checked ~` セレクタの前提。キーボードでは
          // Tab でグループに入り、矢印キーで Day を切り替えられる。
          for (final day in TimetableDay.values)
            input(
              type: InputType.radio,
              id: 'timetable-${day.name}',
              name: 'timetable-day',
              classes: 'timetable-day-input',
              checked: day == TimetableDay.day1,
            ),
          div(classes: 'timetable-tabs', [
            for (final day in TimetableDay.values)
              label(
                classes: 'timetable-tab timetable-tab--${day.name}',
                htmlFor: 'timetable-${day.name}',
                [
                  span(classes: 'timetable-tab__day', [.text(day.label)]),
                  span(classes: 'timetable-tab__date', [.text('${day.date} ${day.weekday}')]),
                ],
              ),
          ]),
          for (final day in TimetableDay.values)
            div(
              classes: 'timetable-day timetable-day--${day.name}',
              // 列数は会場データ由来。CSS 側は var() 経由で受けるので、
              // 縦積みに切り替えるメディアクエリを inline style が上書きしない。
              styles: Styles(
                raw: {'--tt-cols': '4.5rem repeat(${generatedTimetableRooms.length}, minmax(0, 1fr))'},
              ),
              [
                div(classes: 'timetable-rowhead', [
                  div([]),
                  for (final room in generatedTimetableRooms)
                    div(
                      classes: 'timetable-roomhead',
                      styles: Styles(raw: {'--tt-room-color': room.colorHex}),
                      [
                        span(classes: 'timetable-roomhead__dot', []),
                        .text(room.name.resolve(strings.locale)),
                      ],
                    ),
                ]),
                // 片方の日だけ未確定というケースもある。
                if (generatedTimetableByDay[day]!.entries.isEmpty)
                  p(classes: 'timetable-empty', [.text(strings.timetableComingSoon)])
                else
                  _DayGrid(day: day, strings: strings),
              ],
            ),
        ],
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.timetable-section', [
      css('&').styles(
        display: .flex,
        justifyContent: .center,
        width: 100.percent,
        padding: .symmetric(horizontal: 24.px, vertical: 128.px),
        // Sponsors / Event セクションと同じ tinted 背景。
        raw: const {'background-color': '#FDF7FF'},
      ),
      css('.timetable-section__inner').styles(
        display: .flex,
        flexDirection: .column,
        alignItems: .center,
        width: 100.percent,
        gap: Gap.row(48.px),
        raw: const {'max-width': '1232px'},
      ),
      // 見出しまわりは Sponsors セクションと同一の様式。
      css('.timetable-section__header', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          alignItems: .center,
          gap: Gap.row(16.px),
          textAlign: .center,
        ),
        css('.timetable-section__title').styles(
          color: const Color('#1D1A25'),
          fontFamily: displayFontFamily,
          fontWeight: .w700,
          raw: const {
            'font-size': 'clamp(1.75rem, 4vw, 2.5rem)',
            'line-height': '1.2',
          },
        ),
        css('.timetable-section__subtitle').styles(
          color: const Color('#494456'),
          fontFamily: uiFontFamily,
          fontWeight: .w400,
          raw: const {
            'font-size': 'clamp(0.95rem, 2vw, 1.125rem)',
            'line-height': '1.5',
          },
        ),
      ]),

      // タイムテーブル未確定時のプレースホルダー。空のグリッドを見せるより、
      // 準備中であることを明示する。
      css('.timetable-empty').styles(
        color: const Color('#494456'),
        fontFamily: uiFontFamily,
        fontWeight: .w400,
        textAlign: .center,
        raw: const {'font-size': '0.95rem', 'line-height': '1.7'},
      ),

      // ── Day tabs（radio + label による JS なし切替） ─────────────────
      // アクティブは M3 primary 塗り（サイト全体のフォーカスリング等と同系色。
      // keycolor の deepPurple #6200EA は白黒基調のこのセクションでは浮くため
      // 使わない）。
      // radio は display: none だとフォーカス不能になり SR からも消えるため、
      // sr-only 手法で視覚のみ隠す。
      css('.timetable-day-input').styles(
        position: .absolute(),
        width: 1.px,
        height: 1.px,
        overflow: .hidden,
        raw: const {
          'margin': '-1px',
          'clip-path': 'inset(50%)',
          'white-space': 'nowrap',
        },
      ),
      css('.timetable-tabs').styles(
        display: .flex,
        justifyContent: .center,
        gap: Gap.column(8.px),
        // 320px 級の狭い画面でタブ 2 つが収まらない場合は折り返す。
        raw: const {'flex-wrap': 'wrap'},
      ),
      css('.timetable-tab', [
        css('&').styles(
          display: .flex,
          alignItems: .baseline,
          gap: Gap.column(8.px),
          padding: .symmetric(horizontal: 24.px, vertical: 10.px),
          backgroundColor: onBrand,
          color: const Color('#494456'),
          fontFamily: displayFontFamily,
          radius: .circular(999.px),
          border: Border.all(
            style: BorderStyle.solid,
            color: outlineColor,
            width: 1.px,
          ),
          raw: const {
            'cursor': 'pointer',
            'user-select': 'none',
            'transition': 'background-color 150ms ease, color 150ms ease, border-color 150ms ease',
          },
        ),
        css('&:hover').styles(backgroundColor: const Color('#1D1B2010')),
        css('.timetable-tab__day').styles(
          fontWeight: .w600,
          raw: const {'font-size': '0.95rem', 'line-height': '1.4'},
        ),
        css('.timetable-tab__date').styles(
          raw: const {'font-size': '0.75rem', 'letter-spacing': '0.05em'},
        ),
      ]),
      // アクティブタブ: :checked な radio に対応するタブを deepPurple 塗りに。
      // NOTE: jaspr の入れ子解決は文字列結合のため、カンマ区切りの各セレクタに
      // `&` を付けて全てに `.timetable-section` スコープを効かせる。
      css(
        '& #timetable-day1:checked ~ .timetable-tabs .timetable-tab--day1, '
        '& #timetable-day2:checked ~ .timetable-tabs .timetable-tab--day2',
      ).styles(
        backgroundColor: colorDeeppurpleSysLightPrimary,
        color: onBrand,
        raw: const {'border-color': colorDeeppurpleSysLightPrimaryHex},
      ),
      // radio のフォーカスを対応するタブに可視化する（sr-only な radio 本体は
      // 見えないため）。
      css(
        '& #timetable-day1:focus-visible ~ .timetable-tabs .timetable-tab--day1, '
        '& #timetable-day2:focus-visible ~ .timetable-tabs .timetable-tab--day2',
      ).styles(
        raw: const {'outline': '3px solid #65558F', 'outline-offset': '2px'},
      ),

      // ── Day grid ─────────────────────────────────────────────────────
      css('.timetable-day').styles(
        flexDirection: .column,
        width: 100.percent,
        gap: Gap.row(8.px),
        raw: const {'display': 'none'},
      ),
      css(
        '& #timetable-day1:checked ~ .timetable-day--day1, '
        '& #timetable-day2:checked ~ .timetable-day--day2',
      ).styles(raw: const {'display': 'flex'}),

      // 時刻列 + 会場カラムのグリッド。列数は `.timetable-day` に inline で
      // 載せた `--tt-cols`（会場データ由来）から受け取る。フォールバックは
      // 従来どおり 4 会場。行は `.timetable-grid` に inline で載せた
      // `--tt-rows`（その日の時刻境界の数）から受け取り、各枠は自分の
      // `grid-row` / `grid-column` で明示配置される。
      css('& .timetable-rowhead, & .timetable-grid').styles(
        display: .grid,
        gap: Gap.column(12.px),
        raw: const {'grid-template-columns': 'var(--tt-cols, 4.5rem repeat(4, minmax(0, 1fr)))'},
      ),
      css('.timetable-grid').styles(
        gap: Gap(row: 8.px, column: 12.px),
        raw: const {'grid-template-rows': 'var(--tt-rows)'},
      ),
      css('.timetable-rowhead').styles(
        raw: const {'margin-bottom': '8px'},
      ),
      css('.timetable-roomhead', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
          gap: Gap.column(8.px),
          color: const Color('#494456'),
          fontFamily: displayFontFamily,
          fontWeight: .w600,
          raw: const {'font-size': '0.9rem', 'letter-spacing': '0.08em'},
        ),
        css('.timetable-roomhead__dot').styles(
          width: 10.px,
          height: 10.px,
          radius: .circular(999.px),
          raw: const {
            'background-color': 'var(--tt-room-color)',
            'flex-shrink': '0',
          },
        ),
      ]),

      // ── 時刻の目盛り ─────────────────────────────────────────────────
      // 行の境界ごとに 1 つ。行はカードの高さで伸びるので、目盛りは行の上端
      // （= その時刻そのもの）に揃える。1 日の最後の境界だけは行を持たない
      // ため、最終行の下端に寄せる。
      css('.timetable-time', [
        css('&').styles(
          display: .flex,
          justifyContent: .end,
          alignSelf: .start,
          color: const Color('#1D1A25'),
          fontFamily: displayFontFamily,
          fontWeight: .w600,
          raw: const {
            'grid-column': '1',
            'font-size': '0.95rem',
            'line-height': '1.4',
          },
        ),
        css('&.timetable-time--last').styles(alignSelf: .end),
      ]),

      // ── セッションカード ─────────────────────────────────────────────
      // Sponsors のロゴカードと同じ「白面 + 1px ボーダー」。影は同系の
      // オフセットシャドウを淡くして質感だけ合わせる。左ボーダーの
      // 会場色（--tt-room-color）で所属 Room を示す。
      // 詳細ダイアログを開くトリガーの <button> なのでリセットも兼ねる。
      css('.timetable-card', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(8.px),
          padding: .all(20.px),
          backgroundColor: onBrand,
          radius: .circular(16.px),
          border: Border.all(
            style: BorderStyle.solid,
            color: const Color('#CBC3D933'),
            width: 1.px,
          ),
          raw: const {
            'box-shadow': '4px 4px 2px rgba(0, 0, 0, 0.08)',
            'border-left': '4px solid var(--tt-room-color)',
            'cursor': 'pointer',
            'text-align': 'left',
            'font': 'inherit',
            'transition': 'transform 150ms ease, box-shadow 150ms ease',
          },
        ),
        css('&:hover').styles(
          raw: const {
            'transform': 'translateY(-2px)',
            'box-shadow': '6px 6px 4px rgba(0, 0, 0, 0.1)',
          },
        ),
        css('&:focus-visible').styles(
          raw: const {'outline': '3px solid #65558F', 'outline-offset': '2px'},
        ),
        css('.timetable-card__title').styles(
          color: const Color('#1D1A25'),
          fontFamily: uiFontFamily,
          fontWeight: .w600,
          raw: const {'font-size': '0.95rem', 'line-height': '1.5'},
        ),
        css('.timetable-card__speaker').styles(
          display: .flex,
          alignItems: .center,
          gap: Gap.column(8.px),
          color: const Color('#494456'),
          fontFamily: uiFontFamily,
          raw: const {'font-size': '0.85rem', 'margin-top': 'auto'},
        ),
      ]),

      // ── メタ行とチップ（カード / 詳細ダイアログ共用） ────────────────
      css('.timetable-card__meta').styles(
        display: .flex,
        alignItems: .center,
        gap: Gap.column(6.px),
        raw: const {'flex-wrap': 'wrap'},
      ),
      css('.timetable-chip').styles(
        display: .flex,
        alignItems: .center,
        padding: .symmetric(horizontal: 10.px, vertical: 2.px),
        color: const Color('#494456'),
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        radius: .circular(999.px),
        border: Border.all(
          style: BorderStyle.solid,
          color: const Color('#CBC3D9'),
          width: 1.px,
        ),
        raw: const {'font-size': '0.7rem'},
      ),
      css('.timetable-chip--room').styles(
        raw: const {
          'color': 'var(--tt-room-color)',
          'border-color': 'var(--tt-room-color)',
        },
      ),
      // 会場チップ: desktop のカード内ではカラム位置で会場が分かるため
      // 非表示。カードが縦積みになる mobile とダイアログ内では表示する。
      // 時刻チップも同様に、時刻列が消える縦積み時だけ出す（ダイアログには
      // 専用の schedule 行があるので常に非表示）。
      css('.timetable-card .timetable-chip--room, & .timetable-chip--time').styles(
        raw: const {'display': 'none'},
      ),

      // スピーカーアイコン（カード / ダイアログ共用）。
      css('.timetable-avatar').styles(
        width: 24.px,
        height: 24.px,
        radius: .circular(999.px),
        raw: const {'object-fit': 'cover', 'flex-shrink': '0'},
      ),

      // ── タイムラインイベント（開場・休憩など）の全幅バー ─────────────
      // カードより一段引いた、塗りの薄い区切り表現。
      css('.timetable-event', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
          gap: Gap.column(8.px),
          padding: .symmetric(horizontal: 16.px, vertical: 12.px),
          color: const Color('#494456'),
          fontFamily: uiFontFamily,
          radius: .circular(16.px),
          raw: const {
            'grid-column': '2 / -1',
            'font-size': '0.85rem',
            'background-color': 'rgba(255, 255, 255, 0.6)',
          },
        ),
        // 時刻は左の目盛りと重複するので desktop では出さない。
        css('.timetable-event__time').styles(raw: const {'display': 'none'}),
      ]),

      // ── セッション詳細ダイアログ（AppDialog 内のコンテンツ） ─────────
      css('.timetable-dialog', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(16.px),
          // 右上の閉じるボタンとメタ行が重ならないための余白。
          padding: .only(right: 32.px),
        ),
        css('.timetable-dialog__title').styles(
          color: const Color('#1D1A25'),
          fontFamily: uiFontFamily,
          fontWeight: .w700,
          raw: const {'font-size': '1.25rem', 'line-height': '1.5'},
        ),
        css('.timetable-dialog__schedule').styles(
          color: const Color('#494456'),
          fontFamily: displayFontFamily,
          fontWeight: .w600,
          raw: const {'font-size': '0.9rem', 'letter-spacing': '0.03em'},
        ),
        css('.timetable-dialog__speaker').styles(
          display: .flex,
          alignItems: .center,
          gap: Gap.column(10.px),
          color: const Color('#494456'),
          fontFamily: uiFontFamily,
          raw: const {'font-size': '0.9rem'},
        ),
        css('.timetable-dialog__speaker .timetable-avatar').styles(
          width: 28.px,
          height: 28.px,
        ),
        css('.timetable-dialog__desc').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(8.px),
          color: const Color('#494456'),
          fontFamily: uiFontFamily,
          raw: const {'font-size': '0.9rem', 'line-height': '1.7'},
        ),
      ]),
    ]),

    // Tablet 以下: 4 カラムでは 1 枠が狭くなり過ぎるため、会場ヘッダー行を
    // 消して時間帯ごとの縦積みに切り替える（会場はカード上の room チップで
    // 判別する）。
    // NOTE: ベース側は `.timetable-section` の入れ子で出力される
    // （例: `.timetable-section .timetable-row`）ため、メディアクエリ側も
    // 同じ入れ子にして詳細度を揃えないと上書きできない。
    css.media(MediaQuery.all(maxWidth: 960.px), [
      css('.timetable-section', [
        css('&').styles(
          padding: .symmetric(horizontal: 24.px, vertical: 80.px),
        ),
        css('.timetable-rowhead').styles(raw: const {'display': 'none'}),
        // 4 カラムを畳んで開始時刻順の 1 列にする。grid の明示配置
        // （grid-row / grid-column）は flex では効かないので、枠は
        // `entries` の並び順そのままに縦に積まれる。
        css('.timetable-grid').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(8.px),
        ),
        // 目盛り列は畳んだ時点で意味を失う。時刻は各枠のチップで示す。
        css('.timetable-time').styles(raw: const {'display': 'none'}),
        css('.timetable-card .timetable-chip--room, .timetable-card .timetable-chip--time').styles(
          raw: const {'display': 'flex'},
        ),
        css('.timetable-event .timetable-event__time').styles(
          raw: const {'display': 'inline'},
        ),
      ]),
    ]),

    // Mobile: 余白を詰め、タブも小さくして 320px 級でも 1 行に収まりやすくする。
    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.timetable-section', [
        css('&').styles(
          padding: .symmetric(horizontal: 16.px, vertical: 56.px),
        ),
        css('.timetable-tab').styles(
          padding: .symmetric(horizontal: 16.px, vertical: 8.px),
        ),
      ]),
    ]),
  ];
}

/// スピーカー写真が未登録（`speakerAvatarUrl` が null）の場合の
/// フォールバック画像。
const _avatarPlaceholderSrc = 'images/icons/avatar_placeholder.svg';

/// スピーカー行（アイコン + 名前）。カードとダイアログで共用。
/// カード側は `<button>` 内に入るため phrasing content の span で構成する
/// （表示は CSS の flex で制御）。
Component _speakerRow(String classes, String? avatarUrl, String name) {
  return span(classes: classes, [
    img(
      classes: 'timetable-avatar',
      src: avatarUrl ?? _avatarPlaceholderSrc,
      alt: '',
      attributes: const {'aria-hidden': 'true', 'loading': 'lazy'},
    ),
    span([.text(name)]),
  ]);
}

/// 枠が占めるグリッド行。`grid-row: <開始境界> / <終了境界>`。
///
/// 終了時刻を持たないタイムラインイベントは開始と終了が同じ境界になり、
/// `n / n` は行を持たない指定になってしまうため 1 行ぶんに落とす。
String _gridRow(int startTick, int endTick) =>
    endTick > startTick ? '${startTick + 1} / ${endTick + 1}' : '${startTick + 1} / span 1';

/// 1 日分のグリッド本体。
///
/// 行はその日に現れる開始・終了時刻（`ticks`）で切り、各枠を自分の開始境界
/// から終了境界まで `grid-row` で明示配置する。開始が揃わない枠を 1 行に
/// 押し込めないので、30 分枠の裏で 10 分の LT が 3 本走るような並びも
/// 時間軸を保ったまま表示できる。
class _DayGrid extends StatelessComponent {
  const _DayGrid({required this.day, required this.strings});

  final TimetableDay day;
  final Strings strings;

  /// セッション詳細ダイアログの id（`popovertarget` で参照）。
  String _dialogId(int entryIndex) => 'timetable-session-${day.name}-$entryIndex';

  @override
  Component build(BuildContext context) {
    final programme = generatedTimetableByDay[day]!;
    final ticks = programme.ticks;
    // 最後の境界は行を持たない（n 個の境界に対し行は n-1 個）。その時刻だけは
    // 最終行の下端へ寄せて描き、1 日の終わりが読めるようにする。
    final rowCount = ticks.length - 1;
    return div(
      classes: 'timetable-grid',
      styles: Styles(raw: {'--tt-rows': 'repeat($rowCount, minmax(0, auto))'}),
      [
        for (final (i, tick) in ticks.indexed)
          div(
            classes: i == rowCount ? 'timetable-time timetable-time--last' : 'timetable-time',
            styles: Styles(raw: {'grid-row': '${i == rowCount ? rowCount : i + 1}'}),
            [.text(tick)],
          ),
        for (final (i, entry) in programme.entries.indexed)
          if ((entry.session, entry.roomIndex) case (final session?, final roomIndex?)) ...[
            _SessionCard(
              session: session,
              room: generatedTimetableRooms[roomIndex],
              start: ticks[entry.startTick],
              end: ticks[entry.endTick],
              gridArea: (row: _gridRow(entry.startTick, entry.endTick), column: '${roomIndex + 2}'),
              dialogId: _dialogId(i),
              strings: strings,
            ),
            // ダイアログは popover として top layer に表示されるため、
            // グリッドのレイアウトには影響しない。
            _SessionDialog(
              id: _dialogId(i),
              session: session,
              room: generatedTimetableRooms[roomIndex],
              day: day,
              start: ticks[entry.startTick],
              end: ticks[entry.endTick],
              strings: strings,
            ),
          ] else if (entry.eventLabel case final label?)
            div(
              classes: 'timetable-event',
              styles: Styles(
                raw: {'grid-row': _gridRow(entry.startTick, entry.endTick)},
              ),
              [
                // 時刻列が消える縦積み時のための時刻。desktop では非表示。
                span(classes: 'timetable-event__time', [
                  .text('${ticks[entry.startTick]} – ${ticks[entry.endTick]}'),
                ]),
                span([.text(label.resolve(strings.locale))]),
              ],
            ),
      ],
    );
  }
}

class _SessionCard extends StatelessComponent {
  const _SessionCard({
    required this.session,
    required this.room,
    required this.start,
    required this.end,
    required this.gridArea,
    required this.dialogId,
    required this.strings,
  });

  final TimetableSession session;
  final TimetableRoom room;
  final String start;
  final String end;
  final ({String row, String column}) gridArea;
  final String dialogId;
  final Strings strings;

  @override
  Component build(BuildContext context) {
    final locale = strings.locale;
    final speaker = session.speakerName?.resolve(locale);
    return button(
      classes: 'timetable-card',
      type: ButtonType.button,
      attributes: {'popovertarget': dialogId},
      styles: Styles(
        raw: {
          '--tt-room-color': room.colorHex,
          'grid-row': gridArea.row,
          'grid-column': gridArea.column,
        },
      ),
      [
        // <button> 内は phrasing content 限定のため div/p でなく span を使う。
        span(classes: 'timetable-card__meta', [
          // 時刻列が消える縦積み時のための時刻。desktop では非表示。
          span(classes: 'timetable-chip timetable-chip--time', [.text('$start – $end')]),
          span(classes: 'timetable-chip timetable-chip--room', [.text(room.name.resolve(locale))]),
          for (final tag in session.tags) span(classes: 'timetable-chip', [.text(tag.resolve(locale))]),
        ]),
        span(classes: 'timetable-card__title', [.text(session.title.resolve(locale))]),
        if (speaker != null) _speakerRow('timetable-card__speaker', session.speakerAvatarUrl, speaker),
      ],
    );
  }
}

class _SessionDialog extends StatelessComponent {
  const _SessionDialog({
    required this.id,
    required this.session,
    required this.room,
    required this.day,
    required this.start,
    required this.end,
    required this.strings,
  });

  final String id;
  final TimetableSession session;
  final TimetableRoom room;
  final TimetableDay day;
  final String start;
  final String end;
  final Strings strings;

  @override
  Component build(BuildContext context) {
    final locale = strings.locale;
    final speaker = session.speakerName?.resolve(locale);
    final description = session.description?.resolve(locale);
    return AppDialog(
      id: id,
      labelledBy: '$id-title',
      children: [
        div(
          classes: 'timetable-dialog',
          styles: Styles(raw: {'--tt-room-color': room.colorHex}),
          [
            div(classes: 'timetable-card__meta', [
              span(classes: 'timetable-chip timetable-chip--room', [.text(room.name.resolve(locale))]),
              for (final tag in session.tags) span(classes: 'timetable-chip', [.text(tag.resolve(locale))]),
            ]),
            h3(id: '$id-title', classes: 'timetable-dialog__title', [.text(session.title.resolve(locale))]),
            p(classes: 'timetable-dialog__schedule', [
              .text('${day.label} ${day.date} ${day.weekday} / $start – $end'),
            ]),
            if (speaker != null) _speakerRow('timetable-dialog__speaker', session.speakerAvatarUrl, speaker),
            if (description != null)
              div(classes: 'timetable-dialog__desc', [
                for (final paragraph in description.split('\n')) p([.text(paragraph)]),
              ]),
          ],
        ),
      ],
    );
  }
}
