import 'package:app/core/i18n/strings.g.dart';

String? sessionLanguageLabel(Translations t, String primaryLocale) {
  final normalized = primaryLocale.trim();
  if (normalized.isEmpty) {
    return null;
  }

  return switch (normalized.split(RegExp('[-_]')).first.toLowerCase()) {
    'ja' => t.settings.language.japanese,
    'en' => t.settings.language.english,
    final language => language.toUpperCase(),
  };
}
