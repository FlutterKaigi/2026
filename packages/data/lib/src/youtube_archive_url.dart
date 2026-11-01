/// Parses supported HTTPS YouTube links used for session and event recordings.
/// Invalid or absent values are hidden by public clients and rejected by editors.
Uri? youtubeArchiveUri(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty || RegExp(r'\s').hasMatch(value)) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty || uri.port != 443) return null;
  const hosts = {
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'music.youtube.com',
    'youtu.be',
    'youtube-nocookie.com',
    'www.youtube-nocookie.com',
  };
  return hosts.contains(uri.host) ? uri : null;
}

/// Converts a supported video link to a privacy-enhanced YouTube player URL.
///
/// Only YouTube's 11-character video IDs are embedded; channel, playlist and
/// malformed links return null so clients can retain their external link.
/// Only a valid start time is copied. Autoplay and script settings are omitted.
Uri? youtubeArchiveEmbedUri(String? raw) {
  final uri = youtubeArchiveUri(raw);
  if (uri == null) return null;
  try {
    final parameters = uri.queryParametersAll;
    final id = _archiveVideoId(uri, parameters);
    if (id == null || !RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)) return null;
    final start =
        _integerSeconds(_singleParameter(parameters, 'start')) ??
        _timestampSeconds(_singleParameter(parameters, 't')) ??
        _timestampSeconds(uri.fragment.startsWith('t=') ? uri.fragment.substring(2) : null);
    return Uri.https(
      'www.youtube-nocookie.com',
      '/embed/$id',
      start == null ? null : {'start': '$start'},
    );
  } on FormatException {
    return null;
  }
}

String? _archiveVideoId(Uri uri, Map<String, List<String>> parameters) {
  final segments = uri.pathSegments;
  if (uri.host == 'youtu.be') return segments.length == 1 ? segments.single : null;
  if (segments.length == 1 && segments.single == 'watch') return _singleParameter(parameters, 'v');
  if (segments.length == 2 && const {'embed', 'live', 'shorts'}.contains(segments.first)) return segments.last;
  return null;
}

String? _singleParameter(Map<String, List<String>> parameters, String key) {
  final values = parameters[key];
  return values != null && values.length == 1 ? values.single : null;
}

int? _integerSeconds(String? value) {
  if (value == null || !RegExp(r'^\d+$').hasMatch(value)) return null;
  final seconds = int.tryParse(value);
  return seconds != null && seconds <= 2147483647 ? seconds : null;
}

int? _timestampSeconds(String? value) {
  if (value == null || value.isEmpty) return null;
  final seconds = _integerSeconds(value);
  if (seconds != null) return seconds;
  final match = RegExp(r'^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$').firstMatch(value);
  if (match == null) return null;
  final hours = _integerSeconds(match.group(1) ?? '0');
  final minutes = _integerSeconds(match.group(2) ?? '0');
  final remaining = _integerSeconds(match.group(3) ?? '0');
  if (hours == null || minutes == null || remaining == null) return null;
  final total = hours * 3600 + minutes * 60 + remaining;
  return total <= 2147483647 ? total : null;
}
