import 'package:data/data.dart';
import 'package:flutter/widgets.dart';

/// Locale-aware accessors for the data layer's [LocaleMap] values.
extension LocaleMapX on LocaleMap {
  /// Returns the value for the requested locale, falling back to the other
  /// locale when the requested value is empty.
  String resolve(Locale locale) {
    final isJapanese = locale.languageCode == 'ja';
    final primary = isJapanese ? ja : en;
    final fallback = isJapanese ? en : ja;

    if (primary.trim().isNotEmpty) {
      return primary;
    }
    if (fallback.trim().isNotEmpty) {
      return fallback;
    }
    return '';
  }
}
