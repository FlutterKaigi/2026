import 'package:app/feature/venue_map/data/venue_floor_texture.dart';
import 'package:flutter_scene/scene.dart' as fs;

/// Entrance signs have different face proportions even within one hall.
String venueEntranceArtworkId(String hall, double width) => 'entrance_${hall}_${(width * 1000).round()}';

Future<fs.Texture2D> loadVenueArtwork(String id, {String? language}) {
  final suffix = language == null ? '' : '_${language == 'ja' ? 'ja' : 'en'}';
  return loadVenuePngTexture('assets/venue_map/walk_artwork/$id$suffix.png');
}
