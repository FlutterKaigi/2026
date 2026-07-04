import 'package:data/data.dart';

/// スポンサー一覧テーブルの列定義。
///
/// スポンサー情報の原本はスプレッドシート（GAS 連携）のため、ダッシュボードで
/// 編集できるのはロゴ 2 種と slug のみ。それ以外は参照用の最小限の列だけを表示する。
enum SponsorColumn {
  nameJa('表示名 (ja)', width: 240),
  tier('ティア', width: 130),
  slug('slug', width: 200),
  primaryLogoUrl('ロゴ (プライマリー)', width: 300),
  secondaryLogoUrl('ロゴ (セカンダリー)', width: 300),
  updatedAt('更新日時', width: 140),
  actions('操作', width: 100)
  ;

  const SponsorColumn(this.label, {required this.width});

  final String label;
  final double width;

  /// ダブルクリックでインライン編集できる列か（ロゴ 2 種と slug のみ）。
  bool get isEditable => switch (this) {
    slug || primaryLogoUrl || secondaryLogoUrl => true,
    _ => false,
  };

  /// ロゴ画像のプレビューを表示する列か。
  bool get isLogo => this == primaryLogoUrl || this == secondaryLogoUrl;

  /// ヘッダークリックでソートできる列か。
  bool get isSortable => switch (this) {
    nameJa || tier || slug || updatedAt => true,
    _ => false,
  };

  /// 未設定の場合に警告表示する列か（Web サイト表示に影響が大きいもの）。
  bool get warnsWhenMissing => this == slug || this == primaryLogoUrl;

  /// null・空文字・空白のみを「未設定」として null に正規化する。
  static String? presence(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// セルに表示・編集する文字列値。未設定（空文字含む）は null。
  String? valueOf(Sponsor sponsor) => switch (this) {
    nameJa => presence(sponsor.name.ja),
    tier => sponsor.tier.name,
    slug => presence(sponsor.slug),
    primaryLogoUrl => presence(sponsor.primaryLogoUrl),
    secondaryLogoUrl => presence(sponsor.secondaryLogoUrl),
    updatedAt => null,
    actions => null,
  };

  /// テキスト編集の結果を反映した [Sponsor] を返す。
  ///
  /// 空文字は未設定 (null) として扱う。編集可能列（[isEditable]）以外は変更しない。
  Sponsor applyText(Sponsor sponsor, String text) {
    final String? value = presence(text);
    return switch (this) {
      slug => sponsor.copyWith(slug: value),
      primaryLogoUrl => sponsor.copyWith(primaryLogoUrl: value),
      secondaryLogoUrl => sponsor.copyWith(secondaryLogoUrl: value),
      _ => sponsor,
    };
  }

  /// ソート用の比較。[isSortable] が true の列のみ意味を持つ。
  int compare(Sponsor a, Sponsor b) => switch (this) {
    nameJa => a.name.ja.compareTo(b.name.ja),
    tier => a.tier.index.compareTo(b.tier.index),
    slug => (a.slug ?? '').compareTo(b.slug ?? ''),
    updatedAt => a.updatedAt.compareTo(b.updatedAt),
    _ => 0,
  };
}
