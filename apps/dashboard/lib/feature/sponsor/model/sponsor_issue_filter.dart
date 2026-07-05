import 'package:dashboard/feature/sponsor/model/sponsor_column.dart';
import 'package:data/data.dart';

/// 入力漏れ（未設定項目）でスポンサーを絞り込むフィルタ。
///
/// 空文字・空白のみの値も未設定として扱う。複数選択時は AND 条件で絞り込む。
enum SponsorIssueFilter {
  missingPrimaryLogo('ロゴ(1st)未設定'),
  missingSecondaryLogo('ロゴ(2nd)未設定'),
  missingSlug('slug未設定')
  ;

  const SponsorIssueFilter(this.label);

  final String label;

  static bool _isBlank(String? value) => SponsorColumn.presence(value) == null;

  bool matches(Sponsor sponsor) => switch (this) {
    missingPrimaryLogo => _isBlank(sponsor.primaryLogoUrl),
    missingSecondaryLogo => _isBlank(sponsor.secondaryLogoUrl),
    missingSlug => _isBlank(sponsor.slug),
  };
}
