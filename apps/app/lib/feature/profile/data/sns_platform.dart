import 'package:data/data.dart';

/// Services selectable for a profile's [SnsLink].
///
/// [key] is the value stored in [SnsLink.type]. The keys match the staff
/// member links edited in the dashboard so both can share icons and labels.
enum SnsPlatform {
  x('x', 'X', 'res/assets/icons/link_x.svg'),
  github('github', 'GitHub', 'res/assets/icons/link_github.svg'),
  bluesky('bluesky', 'Bluesky', null),
  mixi2('mixi2', 'mixi2', null),
  zenn('zenn', 'Zenn', null),
  qiita('qiita', 'Qiita', null),
  note('note', 'note', null),
  medium('medium', 'Medium', null),
  other('web', null, null);

  const SnsPlatform(this.key, this._label, this.iconAsset);

  /// Value persisted in [SnsLink.type].
  final String key;

  final String? _label;

  /// Dedicated icon asset, or `null` to fall back to the generic globe icon.
  final String? iconAsset;

  /// Brand name, or `null` for [other] (localized by the caller).
  String? get label => _label;

  String? get _profileUrlPrefix => switch (this) {
    x => 'https://x.com/',
    github => 'https://github.com/',
    bluesky => 'https://bsky.app/profile/',
    mixi2 => 'https://mixi.social/@',
    zenn => 'https://zenn.dev/',
    qiita => 'https://qiita.com/',
    note => 'https://note.com/',
    medium => 'https://medium.com/@',
    other => null,
  };

  bool get supportsUserId => _profileUrlPrefix != null;

  /// 入力された ID または URL を、保存・リンク表示用の HTTPS URL に揃える。
  /// 既存の URL はパスやクエリを含めて維持する。
  String? normalizeInput(String value) {
    final input = value.trim();
    if (isValidSnsLinkUrl(input)) {
      return input;
    }
    final prefix = _profileUrlPrefix;
    if (prefix == null) {
      return null;
    }
    final id = input.startsWith('@') ? input.substring(1) : input;
    if (!_isValidUserId(id)) {
      return null;
    }
    return '$prefix$id';
  }

  /// 補完したプロフィール URL は、再編集時に ID だけを表示する。
  /// 投稿リンクや独自ドメインなどは URL のまま表示して情報を失わない。
  String inputValue(String value) {
    final prefix = _profileUrlPrefix;
    if (prefix == null || !value.startsWith(prefix)) {
      return value;
    }
    final id = value.substring(prefix.length);
    return _isValidUserId(id) && normalizeInput(id) == value ? id : value;
  }

  bool _isValidUserId(String id) {
    if (this == bluesky) {
      // Bluesky のハンドルにはドメインまで入力する。独自ドメインにも対応する。
      return RegExp(r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z][a-zA-Z0-9-]*$').hasMatch(id);
    }
    return id != '.' && id != '..' && RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(id);
  }

  /// Resolves the platform for a stored [SnsLink.type], treating unknown keys
  /// (including legacy `twitter`) as [other] or [x] respectively.
  static SnsPlatform fromKey(String key) {
    final normalized = key.trim().toLowerCase();
    if (normalized == 'twitter') {
      return SnsPlatform.x;
    }
    for (final platform in values) {
      if (platform.key == normalized) {
        return platform;
      }
    }
    return SnsPlatform.other;
  }
}

/// Whether [value] is an `https://` URL with a host, which is what profile
/// links must be so they can be opened safely from another attendee's device.
bool isValidSnsLinkUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}
