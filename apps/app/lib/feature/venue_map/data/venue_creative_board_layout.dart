import 'dart:math' as math;
import 'dart:ui';

import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';

/// Exhibit dimensions in the shared floor plan's coordinates.
class VenueCreativeBoardLayout {
  VenueCreativeBoardLayout(VenueNavigation navigation)
    : area = boundsOf(navigation.places.singleWhere((p) => p.id == 'creative_board'));

  final Rect area;
  // Keep the panel and lectern inside the existing creative_board allocation.
  Rect get board => Rect.fromLTWH(area.left + area.width * .245, area.top + 3, area.width * .72, 3);
  Rect get podium => Rect.fromLTWH(area.left + 4, area.top + 8, 16, 12);
  MapPoint get photoSpot => MapPoint(board.center.dx, area.bottom + 44);

  List<Rect> get obstacles => [board, podium];

  void registerObstacles(VenueNavigation navigation) {
    for (final rect in obstacles) {
      navigation.blocked.add([
        MapPoint(rect.left, rect.top),
        MapPoint(rect.right, rect.top),
        MapPoint(rect.right, rect.bottom),
        MapPoint(rect.left, rect.bottom),
      ]);
    }
  }

  static Rect boundsOf(MapPlace place) => Rect.fromLTRB(
    place.polygon.map((p) => p.x).reduce(math.min),
    place.polygon.map((p) => p.y).reduce(math.min),
    place.polygon.map((p) => p.x).reduce(math.max),
    place.polygon.map((p) => p.y).reduce(math.max),
  );
}
