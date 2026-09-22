import 'dart:convert';
import 'dart:io';

import 'package:app/core/i18n/strings.g.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/venue_map/venue_artwork_manifest.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled signs match the floor plan, font, painting recipes and translations', () async {
    final manifest =
        jsonDecode(File('$venueArtworkDirectory/manifest.json').readAsStringSync()) as Map<String, dynamic>;
    expect(
      manifest['inputs'],
      venueArtworkInputHashes(),
      reason: 'Run flutter test tool/venue_map/generate_walk_artwork.dart from apps/app',
    );
    expect(manifest['entranceCaptions'], {
      for (final locale in [AppLocale.ja, AppLocale.en])
        locale.languageCode: (await locale.build()).venueWalk.entranceSign,
    });
    final images = (manifest['images'] as Map<String, dynamic>).cast<String, Map<String, dynamic>>();
    expect(images.length, 82);
    for (final entry in images.entries) {
      // Read the actual application bundle, catching omitted pubspec assets too.
      final data = await rootBundle.load('$venueArtworkDirectory/${entry.key}');
      expect(
        sha256.convert(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)).toString(),
        entry.value['sha256'],
        reason: entry.key,
      );
      expect(data.getUint32(16), entry.value['width'], reason: entry.key);
      expect(data.getUint32(20), entry.value['height'], reason: entry.key);
    }
  });
}
