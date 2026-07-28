import 'dart:collection';

import 'package:flutter/foundation.dart';

typedef LicenseGroups = Map<String, List<List<LicenseParagraph>>>;

/// Reads bundled package licenses and groups them by package name.
class LicenseRepository {
  const LicenseRepository();

  Future<LicenseGroups> fetchAll() async {
    final entries = await LicenseRegistry.licenses.toList();
    final grouped = <String, List<List<LicenseParagraph>>>{};
    for (final entry in entries) {
      for (final package in entry.packages) {
        (grouped[package] ??= []).add(entry.paragraphs.toList());
      }
    }
    return SplayTreeMap<String, List<List<LicenseParagraph>>>.from(grouped);
  }
}
