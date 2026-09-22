import '../model/locale_map.dart';
import 'generated_countries.dart';

/// UN M.49 macro-region a [Country] belongs to.
///
/// Declared in the order the country picker groups them: Asia first because
/// the majority of attendees come from Japan, followed by the neighbouring
/// regions.
enum CountryRegion {
  asia,
  oceania,
  americas,
  europe,
  africa,
}

/// A country or region selectable as a user's origin.
///
/// [code] is the ISO 3166-1 alpha-2 code (plus the CLDR-only `XK` for Kosovo).
/// It is the value persisted in Firestore; names are display-only and are
/// resolved from the CLDR territory names in the app locale.
///
/// Instances come from the generated [countries] list only, so identity
/// comparison is sufficient; look countries up by [code] via [findCountry].
final class Country {
  const Country({
    required this.code,
    required this.region,
    required this.name,
  });

  /// ISO 3166-1 alpha-2 code, e.g. `JP`.
  final String code;

  /// Macro-region used to group the country in the picker.
  final CountryRegion region;

  /// Localized display names (CLDR territory names).
  final LocaleMap name;

  /// Regional indicator symbol pair for [code], rendered as a flag emoji by
  /// iOS and Android system emoji fonts.
  String get flagEmoji {
    const regionalIndicatorBase = 0x1F1E6;
    const letterA = 0x41;
    return String.fromCharCodes([
      for (final unit in code.codeUnits) regionalIndicatorBase + (unit - letterA),
    ]);
  }

  @override
  String toString() => 'Country($code)';
}

final _countriesByCode = <String, Country>{for (final country in countries) country.code: country};

/// Looks up a [Country] by ISO 3166-1 alpha-2 [code] (case-insensitive), or
/// `null` when the code is not in [countries].
Country? findCountry(String code) => _countriesByCode[code.trim().toUpperCase()];
