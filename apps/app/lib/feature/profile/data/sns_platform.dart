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
  other('web', null, null)
  ;

  const SnsPlatform(this.key, this._label, this.iconAsset);

  /// Value persisted in [SnsLink.type].
  final String key;

  final String? _label;

  /// Dedicated icon asset, or `null` to fall back to the generic globe icon.
  final String? iconAsset;

  /// Brand name, or `null` for [other] (localized by the caller).
  String? get label => _label;

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
