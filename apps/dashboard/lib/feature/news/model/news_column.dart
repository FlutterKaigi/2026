import 'package:dashboard/core/extension/date_time_extension.dart';

/// テーブル上の 1 セルの値。ローカル下書き（未保存の編集内容）を表す。
typedef NewsDraft = ({String titleJa, String titleEn, String urlJa, String urlEn, DateTime publishedAt});

/// テーブルの表示行。既存行・新規行を同じ形で扱う。
typedef NewsRow = ({
  String rowKey,
  String? newsId,
  bool isNew,
  NewsDraft draft,
  DateTime? updatedAt,
  bool isDirty,
});

/// ソート状態。null の場合はデフォルト（公開日時の降順）。
typedef NewsSort = ({NewsColumn column, bool ascending});

/// 編集中セルの識別子。
typedef NewsCellRef = ({String rowKey, NewsColumn column});

/// News 一覧テーブルの列定義。
///
/// News はこのダッシュボードが編集元のため、原本がある Sponsor と異なり全項目を
/// 一括編集の対象とする。ただし title・url は LocaleMap（ja/en の組）なので、
/// 単一文字列セルとして編集できるよう ja/en を別々の列に分割している。
enum NewsColumn {
  titleJa('タイトル (ja)', width: 260),
  titleEn('タイトル (en)', width: 260),
  publishedAt('公開日時', width: 170),
  urlJa('URL (ja)', width: 280),
  urlEn('URL (en)', width: 280),
  updatedAt('更新日時', width: 140),
  actions('操作', width: 90)
  ;

  const NewsColumn(this.label, {required this.width});

  final String label;
  final double width;

  /// ダブルクリックでインライン編集できる単一文字列列か。
  bool get isInlineTextEditable => switch (this) {
    titleJa || titleEn || urlJa || urlEn => true,
    _ => false,
  };

  /// タップで日時ピッカーを開く列か。
  bool get isDateTime => this == publishedAt;

  /// ヘッダークリックでソートできる列か。
  bool get isSortable => switch (this) {
    titleJa || titleEn || publishedAt || updatedAt => true,
    _ => false,
  };

  /// URL 形式のバリデーションが必要な列か。
  bool get isUrl => this == urlJa || this == urlEn;

  /// セルに表示する文字列値。
  String textValueOf(NewsRow row) => switch (this) {
    titleJa => row.draft.titleJa,
    titleEn => row.draft.titleEn,
    urlJa => row.draft.urlJa,
    urlEn => row.draft.urlEn,
    publishedAt => row.draft.publishedAt.formatDateTime(),
    updatedAt => row.updatedAt?.formatDateTime() ?? '—',
    actions => '',
  };

  /// インライン編集の結果を反映した [NewsDraft] を返す（[isInlineTextEditable] の列のみ有効）。
  NewsDraft applyText(NewsDraft draft, String text) => switch (this) {
    titleJa => (
      titleJa: text,
      titleEn: draft.titleEn,
      urlJa: draft.urlJa,
      urlEn: draft.urlEn,
      publishedAt: draft.publishedAt,
    ),
    titleEn => (
      titleJa: draft.titleJa,
      titleEn: text,
      urlJa: draft.urlJa,
      urlEn: draft.urlEn,
      publishedAt: draft.publishedAt,
    ),
    urlJa => (
      titleJa: draft.titleJa,
      titleEn: draft.titleEn,
      urlJa: text,
      urlEn: draft.urlEn,
      publishedAt: draft.publishedAt,
    ),
    urlEn => (
      titleJa: draft.titleJa,
      titleEn: draft.titleEn,
      urlJa: draft.urlJa,
      urlEn: text,
      publishedAt: draft.publishedAt,
    ),
    _ => draft,
  };

  /// 日時ピッカーの結果を反映した [NewsDraft] を返す。
  NewsDraft applyPublishedAt(NewsDraft draft, DateTime value) => (
    titleJa: draft.titleJa,
    titleEn: draft.titleEn,
    urlJa: draft.urlJa,
    urlEn: draft.urlEn,
    publishedAt: value,
  );

  /// ソート用の比較。[isSortable] が true の列のみ意味を持つ。
  int compare(NewsRow a, NewsRow b) => switch (this) {
    titleJa => a.draft.titleJa.compareTo(b.draft.titleJa),
    titleEn => a.draft.titleEn.compareTo(b.draft.titleEn),
    publishedAt => a.draft.publishedAt.compareTo(b.draft.publishedAt),
    updatedAt => (a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
      b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    ),
    _ => 0,
  };

  static bool _isValidUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    return uri != null && uri.hasScheme;
  }

  /// 保存前バリデーション。無効な列の集合を返す（空集合なら保存可能）。
  static Set<NewsColumn> validate(NewsDraft draft) {
    final invalid = <NewsColumn>{};
    if (draft.titleJa.trim().isEmpty) invalid.add(titleJa);
    if (draft.titleEn.trim().isEmpty) invalid.add(titleEn);
    if (!_isValidUrl(draft.urlJa)) invalid.add(urlJa);
    if (!_isValidUrl(draft.urlEn)) invalid.add(urlEn);
    return invalid;
  }
}
