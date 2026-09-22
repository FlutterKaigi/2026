import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/theme.dart';
import '../l10n/strings.dart';

/// 共通ダイアログ。Popover API（`popover` 属性）で JS なしに開閉する。
///
/// 開くトリガーは任意の場所に置いた `button(attributes: {'popovertarget': id})`。
/// ESC キー・ダイアログ外クリックで閉じる挙動（light dismiss）と
/// フォーカス管理はブラウザが標準で提供する。
///
/// 意図した仕様上の注意:
/// - `popover` は非モーダル。背景を暗転させてはいるが背面要素は操作可能で、
///   ダイアログ外クリックは light dismiss と同時に背面要素も活性化する。
/// - Popover API 非対応の古いブラウザでは開閉できない（author スタイルの
///   `display: none` により、中身が露出してレイアウトが崩れることはない）。
class AppDialog extends StatelessComponent {
  const AppDialog({
    required this.id,
    required this.children,
    this.labelledBy,
    super.key,
  });

  /// `popovertarget` で参照するドキュメント内で一意な id。
  final String id;

  /// `aria-labelledby` に設定する、ダイアログの見出し要素の id。
  final String? labelledBy;

  final List<Component> children;

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    return div(
      id: id,
      classes: 'app-dialog',
      attributes: {
        'popover': '',
        // popover 属性はロールを与えないため明示する。
        'role': 'dialog',
        'aria-labelledby': ?labelledBy,
      },
      [
        button(
          classes: 'app-dialog__close',
          type: ButtonType.button,
          attributes: {
            'popovertarget': id,
            'popovertargetaction': 'hide',
            'aria-label': strings.dialogCloseLabel,
          },
          [
            span(attributes: const {'aria-hidden': 'true'}, [.text('✕')]),
          ],
        ),
        // スクロール領域。閉じるボタンはこの外にあるため、内容が長くても
        // スクロールで画面外に流れない。
        div(classes: 'app-dialog__body', children),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    css('.app-dialog', [
      // UA デフォルト（position: fixed + inset: 0 + margin: auto）による
      // 中央配置を活かし、サイズと見た目だけ上書きする。
      // display: none は Popover API 非対応ブラウザ向けのフォールバック
      // （対応ブラウザでは UA スタイルと同値）。
      css('&').styles(
        backgroundColor: onBrand,
        radius: .circular(16.px),
        raw: const {
          'display': 'none',
          'border': 'none',
          'padding': '0',
          'width': 'min(640px, calc(100vw - 32px))',
          'max-height': 'min(80dvh, 720px)',
          'overflow': 'hidden',
          'box-shadow': '0 24px 48px rgba(29, 26, 32, 0.24)',
        },
      ),
      // 開時の表示。非対応ブラウザでは :popover-open が未知の擬似クラスと
      // してルールごと無効になるため、上の display: none が維持される。
      css('&:popover-open').styles(
        display: .flex,
        flexDirection: .column,
      ),
      css('&::backdrop').styles(
        raw: const {'background-color': 'rgba(29, 26, 32, 0.5)'},
      ),
      css('.app-dialog__body').styles(
        padding: .all(32.px),
        raw: const {'overflow': 'auto', 'min-height': '0'},
      ),
      css('.app-dialog__close', [
        css('&').styles(
          position: .absolute(top: 12.px, right: 12.px),
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
          width: 36.px,
          height: 36.px,
          color: const Color('#494456'),
          radius: .circular(999.px),
          raw: const {
            'border': 'none',
            'background': 'none',
            'cursor': 'pointer',
            'font-size': '1rem',
          },
        ),
        css('&:hover').styles(backgroundColor: const Color('#1D1B2010')),
        css('&:focus-visible').styles(
          raw: const {'outline': '2px solid #65558F', 'outline-offset': '2px'},
        ),
      ]),
    ]),

    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.app-dialog', [
        css('.app-dialog__body').styles(padding: .all(24.px)),
      ]),
    ]),
  ];
}
