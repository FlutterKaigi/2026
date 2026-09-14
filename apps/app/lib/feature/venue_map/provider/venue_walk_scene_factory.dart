import 'package:app/feature/venue_map/data/venue_walk_scene.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Creates an owned scene; the view releases it on retry or disposal.
final venueWalkSceneFactoryProvider = Provider<VenueWalkScene Function({required bool showcase})>(
  (ref) =>
      ({required showcase}) => VenueWalkScene(showcase: showcase),
);
