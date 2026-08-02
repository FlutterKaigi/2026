/// A GitHub account that has contributed to the FlutterKaigi 2026 repository.
class Contributor {
  const Contributor({
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.contributions,
    required this.type,
  });

  factory Contributor.fromJson(Map<String, dynamic> json) => Contributor(
    login: json['login'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
    htmlUrl: json['html_url'] as String? ?? '',
    contributions: (json['contributions'] as num?)?.toInt() ?? 0,
    type: json['type'] as String? ?? '',
  );

  final String login;
  final String avatarUrl;
  final String htmlUrl;
  final int contributions;

  /// GitHub account type such as `User`, `Bot`, or `Organization`.
  final String type;

  /// Whether this account is a regular user rather than a bot.
  bool get isUser => type == 'User';
}
