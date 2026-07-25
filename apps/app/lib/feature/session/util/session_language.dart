String? sessionLanguageLabel(String primaryLocale) {
  final normalized = primaryLocale.trim();
  if (normalized.isEmpty) {
    return null;
  }

  return normalized.split(RegExp('[-_]')).first.toUpperCase();
}
