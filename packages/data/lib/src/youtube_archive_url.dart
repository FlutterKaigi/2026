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
