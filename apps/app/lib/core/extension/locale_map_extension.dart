import 'package:data/data.dart';
import 'package:flutter/widgets.dart';

/// Locale-aware accessors for the data layer's [LocaleMap] values.
extension LocaleMapX on LocaleMap {
  /// Returns Japanese for `ja`, and English for every other locale.
  String resolve(Locale locale) => locale.languageCode == 'ja' ? ja : en;
}
