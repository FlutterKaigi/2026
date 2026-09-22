/// Generates `packages/data/lib/src/country/generated_countries.dart` from
/// Unicode CLDR territory data.
///
/// Run via:
///
/// ```sh
/// fvm dart run melos countries:generate
/// ```
///
/// or directly:
///
/// ```sh
/// fvm dart run tool/generate_countries.dart
/// ```
///
/// The generated file is checked into git; re-run this script only when the
/// pinned CLDR version below is bumped. It downloads three JSON files from the
/// `unicode-org/cldr-json` repository at that version:
///
/// - `cldr-localenames-full/main/ja/territories.json` (Japanese names)
/// - `cldr-localenames-full/main/en/territories.json` (English names)
/// - `cldr-core/supplemental/territoryContainment.json` (UN M.49 regions)
///
/// Output rules:
///
/// - Only two-letter codes are kept (ISO 3166-1 alpha-2 plus `XK`). CLDR's
///   non-ISO groupings (`EU`, `UN`, `QO`, `ZZ`, …) and the exceptionally
///   reserved codes (`AC`, `CP`, `DG`, `TA`, `IC`, `EA`) are dropped.
/// - Each country is assigned the UN M.49 macro-region (Asia / Oceania /
///   Americas / Europe / Africa) that contains it.
/// - Countries are emitted grouped by region in picker order, sorted by
///   English name within a region, with Japan pinned to the top of Asia.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _cldrVersion = '48.2.0';
const _cldrBase = 'https://raw.githubusercontent.com/unicode-org/cldr-json/$_cldrVersion/cldr-json';
const _outFile = 'packages/data/lib/src/country/generated_countries.dart';

/// CLDR `-alt-short` names are only used where the long form is unwieldy in a
/// picker (e.g. `中華人民共和国香港特別行政区` → `香港`).
const _preferShortName = {'HK', 'MO', 'PS'};

/// Two-letter CLDR codes that are not selectable countries or regions.
const _excludedCodes = {
  'AC', 'CP', 'DG', 'TA', 'IC', 'EA', // exceptionally reserved (not ISO assigned)
  'EU', 'EZ', 'UN', 'QO', 'ZZ', 'XA', 'XB', // CLDR groupings / pseudo locales
};

/// UN M.49 macro-region code → generated `CountryRegion` enum value.
const _macroRegions = {
  '142': 'asia',
  '009': 'oceania',
  '019': 'americas',
  '150': 'europe',
  '002': 'africa',
};

/// Picker order of regions, and the country pinned first within each.
const _regionOrder = ['asia', 'oceania', 'americas', 'europe', 'africa'];
const _pinnedFirst = {'asia': 'JP'};

Future<void> main(List<String> args) async {
  final ja = await _fetchTerritoryNames('ja');
  final en = await _fetchTerritoryNames('en');
  final containment = await _fetchContainment();

  final regionByCode = <String, String>{};
  for (final MapEntry(key: macro, value: region) in _macroRegions.entries) {
    for (final leaf in _leavesOf(macro, containment)) {
      regionByCode[leaf] = region;
    }
  }

  final twoLetter = RegExp(r'^[A-Z]{2}$');
  final countries = <_Country>[];
  for (final code in en.keys) {
    if (!twoLetter.hasMatch(code) || _excludedCodes.contains(code)) continue;
    final region = regionByCode[code];
    if (region == null) {
      throw StateError('No UN M.49 region found for $code (${en[code]}).');
    }
    final nameJa = _displayName(ja, code);
    final nameEn = _displayName(en, code);
    if (nameJa == null || nameEn == null) {
      throw StateError('Missing CLDR name for $code (ja: $nameJa, en: $nameEn).');
    }
    countries.add(_Country(code: code, region: region, nameJa: nameJa, nameEn: nameEn));
  }

  countries.sort((a, b) {
    final regionCompare = _regionOrder.indexOf(a.region).compareTo(_regionOrder.indexOf(b.region));
    if (regionCompare != 0) return regionCompare;
    final pinned = _pinnedFirst[a.region];
    if (a.code == pinned) return -1;
    if (b.code == pinned) return 1;
    final nameCompare = a.nameEn.toLowerCase().compareTo(b.nameEn.toLowerCase());
    return nameCompare != 0 ? nameCompare : a.code.compareTo(b.code);
  });

  final out = StringBuffer()
    ..writeln('// GENERATED FILE — do not edit by hand.')
    ..writeln('// Source: Unicode CLDR $_cldrVersion (unicode-org/cldr-json)')
    ..writeln('// Regenerate via: fvm dart run melos countries:generate')
    ..writeln('//')
    ..writeln('// The territory names below are derived from CLDR data, distributed under')
    ..writeln('// the Unicode License v3 (https://www.unicode.org/license.txt):')
    ..writeln('//')
    ..writeln('// Copyright © 1991-2025 Unicode, Inc. All rights reserved.')
    ..writeln('// Permission is hereby granted, free of charge, to any person obtaining a')
    ..writeln('// copy of data files and any associated documentation (the "Data Files")')
    ..writeln('// or software and any associated documentation (the "Software") to deal in')
    ..writeln('// the Data Files or Software without restriction, including without')
    ..writeln('// limitation the rights to use, copy, modify, merge, publish, distribute,')
    ..writeln('// and/or sell copies of the Data Files or Software, and to permit persons')
    ..writeln('// to whom the Data Files or Software are furnished to do so, provided that')
    ..writeln('// either (a) this copyright and permission notice appear with all copies')
    ..writeln('// of the Data Files or Software, or (b) this copyright and permission')
    ..writeln('// notice appear in associated Documentation.')
    ..writeln('//')
    ..writeln('// THE DATA FILES AND SOFTWARE ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY')
    ..writeln('// KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF')
    ..writeln('// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF')
    ..writeln('// THIRD PARTY RIGHTS.')
    ..writeln()
    ..writeln("import '../model/locale_map.dart';")
    ..writeln("import 'country.dart';")
    ..writeln()
    ..writeln('/// Every selectable country or region, grouped by [CountryRegion] in picker')
    ..writeln('/// order and sorted by English name within each region (Japan first in Asia).')
    ..writeln('const countries = <Country>[');
  String? currentRegion;
  for (final country in countries) {
    if (country.region != currentRegion) {
      currentRegion = country.region;
      out.writeln('  // ── ${country.region} ──');
    }
    out
      ..write('  Country(code: ${_dartString(country.code)}, region: CountryRegion.${country.region}, ')
      ..writeln('name: LocaleMap(ja: ${_dartString(country.nameJa)}, en: ${_dartString(country.nameEn)})),');
  }
  out.writeln('];');

  final file = File(_outFile);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(out.toString());
  stdout.writeln('Wrote ${countries.length} countries to $_outFile');
}

Future<Map<String, String>> _fetchTerritoryNames(String locale) async {
  final json = await _fetchJson('$_cldrBase/cldr-localenames-full/main/$locale/territories.json');
  final main = json['main'] as Map<String, dynamic>;
  final localeData = main[locale] as Map<String, dynamic>;
  final displayNames = localeData['localeDisplayNames'] as Map<String, dynamic>;
  final territories = displayNames['territories'] as Map<String, dynamic>;
  return territories.map((key, value) => MapEntry(key, value as String));
}

Future<Map<String, List<String>>> _fetchContainment() async {
  final json = await _fetchJson('$_cldrBase/cldr-core/supplemental/territoryContainment.json');
  final supplemental = json['supplemental'] as Map<String, dynamic>;
  final containment = supplemental['territoryContainment'] as Map<String, dynamic>;
  return containment.map((key, value) {
    final entry = value as Map<String, dynamic>;
    final contains = entry['_contains'] as List<dynamic>;
    return MapEntry(key, contains.cast<String>());
  });
}

Future<Map<String, dynamic>> _fetchJson(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw HttpException('GET $url failed with ${response.statusCode}', uri: Uri.parse(url));
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}

/// Collects the two-letter leaves under [code] by walking the containment
/// tree. CLDR keys grouping variants as `<code>-status-grouping`; those are
/// skipped so each leaf is reached through its canonical parent only.
Iterable<String> _leavesOf(String code, Map<String, List<String>> containment) sync* {
  final children = containment[code];
  if (children == null) {
    yield code;
    return;
  }
  for (final child in children) {
    yield* _leavesOf(child, containment);
  }
}

String? _displayName(Map<String, String> names, String code) {
  if (_preferShortName.contains(code)) {
    final short = names['$code-alt-short'];
    if (short != null) return short;
  }
  return names[code];
}

String _dartString(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$');
  return "'$escaped'";
}

final class _Country {
  const _Country({
    required this.code,
    required this.region,
    required this.nameJa,
    required this.nameEn,
  });

  final String code;
  final String region;
  final String nameJa;
  final String nameEn;
}
