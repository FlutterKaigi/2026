import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:app/feature/venue_map/data/venue_walk_scene.dart';

/// Resolve at render time so changing language also updates an active route.
String venueWalkPlaceName(Translations t, VenueNavigation navigation, String id) {
  if (id == 'entrance') {
    return t.venueWalk.entrance;
  }
  for (final place in navigation.places) {
    if (place.id == id) {
      return place.nameFor(t.$meta.locale.languageCode);
    }
  }
  return t.venueWalk.selectedPoint;
}

String venueWalkNotice(Translations t, VenueNavigation navigation, WalkStatus status) => switch (status.notice) {
  WalkNotice.unreachable => t.venueWalk.unreachable,
  WalkNotice.arrived => t.venueWalk.arrivedAt(
    place: venueWalkPlaceName(t, navigation, status.arrivedAt ?? 'selected_point'),
  ),
  null => '',
};

extension VenuePhotoPoseLocalizations on VenuePhotoPose {
  String label(Translations t) => switch (this) {
    VenuePhotoPose.standing => t.venueWalk.photo.poses.standing,
    VenuePhotoPose.wave => t.venueWalk.photo.poses.wave,
    VenuePhotoPose.sitting => t.venueWalk.photo.poses.sitting,
    VenuePhotoPose.jumping => t.venueWalk.photo.poses.jumping,
  };
}
