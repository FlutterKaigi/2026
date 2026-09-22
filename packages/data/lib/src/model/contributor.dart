import 'package:freezed_annotation/freezed_annotation.dart';

part 'contributor.freezed.dart';
part 'contributor.g.dart';

/// A GitHub account that has contributed to the FlutterKaigi 2026 repository.
///
/// Documents are refreshed daily from the GitHub API by
/// `.github/workflows/refresh_contributors.yaml`; the document ID is the
/// GitHub login.
@freezed
abstract class Contributor with _$Contributor {
  const factory Contributor({
    required String login,
    required String avatarUrl,
    required String htmlUrl,
    required int contributions,
  }) = _Contributor;

  factory Contributor.fromJson(Map<String, dynamic> json) => _$ContributorFromJson(json);
}
