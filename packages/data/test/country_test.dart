import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generated list has unique ISO alpha-2 codes and both names', () {
    final codes = countries.map((country) => country.code).toSet();
    expect(codes.length, countries.length);
    for (final country in countries) {
      expect(country.code, matches(RegExp(r'^[A-Z]{2}$')), reason: country.code);
      expect(country.name.ja, isNotEmpty, reason: country.code);
      expect(country.name.en, isNotEmpty, reason: country.code);
    }
  });

  test('Japan leads the list and Asia comes first', () {
    expect(countries.first.code, 'JP');
    expect(countries.first.region, CountryRegion.asia);

    final regionOrder = <CountryRegion>[];
    for (final country in countries) {
      if (regionOrder.isEmpty || regionOrder.last != country.region) {
        regionOrder.add(country.region);
      }
    }
    expect(regionOrder, CountryRegion.values, reason: 'regions must be contiguous and in enum order');
  });

  test('countries are sorted by English name within a region (except the pinned JP)', () {
    for (final region in CountryRegion.values) {
      final names = [
        for (final country in countries)
          if (country.region == region && country.code != 'JP') country.name.en.toLowerCase(),
      ];
      expect(names, [...names]..sort(), reason: region.name);
    }
  });

  test('includes ISO regions required by the profile spec', () {
    expect(findCountry('TW')?.name.ja, '台湾');
    expect(findCountry('HK')?.name.ja, '香港');
    expect(findCountry('MO')?.name.ja, 'マカオ');
    expect(findCountry('XK')?.name.en, 'Kosovo');
  });

  test('findCountry is case-insensitive and null for unknown codes', () {
    expect(findCountry('jp')?.code, 'JP');
    expect(findCountry(' us ')?.code, 'US');
    expect(findCountry('ZZ'), isNull);
    expect(findCountry(''), isNull);
  });

  test('flagEmoji maps the code to regional indicator symbols', () {
    expect(findCountry('JP')!.flagEmoji, '🇯🇵');
    expect(findCountry('US')!.flagEmoji, '🇺🇸');
  });
}
