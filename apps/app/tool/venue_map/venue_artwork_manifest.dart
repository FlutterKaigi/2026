import 'dart:io';

import 'package:crypto/crypto.dart';

const venueArtworkDirectory = 'assets/venue_map/walk_artwork';

/// Geometry determines the visible face aspect ratios. Changes to these inputs
/// require rebaking so sponsor names and sign proportions cannot silently drift.
Map<String, String> venueArtworkInputHashes() => {
  for (final path in [
    'assets/venue_map/floor_plan.json',
    'res/assets/fonts/NotoSansJP/NotoSansJP-VariableFont.ttf',
    'lib/feature/venue_map/data/venue_walk_architecture.dart',
    'lib/feature/venue_map/data/venue_walk_decorations.dart',
    'lib/feature/venue_map/data/venue_walk_artwork.dart',
    'lib/feature/venue_map/data/venue_walk_navigation.dart',
    'tool/venue_map/venue_artwork_painter.dart',
    'tool/venue_map/generate_walk_artwork.dart',
  ])
    path: sha256.convert(File(path).readAsBytesSync()).toString(),
};
