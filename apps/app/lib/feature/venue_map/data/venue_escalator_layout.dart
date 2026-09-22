import 'dart:ui';

import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';

/// Connections relative to the displayed floor, not the belt's travel direction.
/// The official entrance photo signs the west bank toward 6F; the facility
/// floor guide shows the other connection from 5F to 4F.
class VenueEscalatorLayout {
  VenueEscalatorLayout(Map<String, Object?> data)
    : id = data['id']! as String,
      connectsUpstairs = data['bank'] == 'west',
      boardsAtEastEnd = data['landing'] == 'east',
      footprint = Rect.fromLTRB(
        (data['x0']! as num).toDouble(),
        (data['y0']! as num).toDouble(),
        (data['x1']! as num).toDouble(),
        (data['y1']! as num).toDouble(),
      );

  final String id;
  final bool connectsUpstairs;
  final bool boardsAtEastEnd;
  final Rect footprint;
  static const unit = .04;
  static const landingLength = .56;

  MapPoint get center => MapPoint(footprint.center.dx, footprint.center.dy);
  double get length => footprint.width * unit;
  double get width => footprint.height * unit;
  double get rise => connectsUpstairs ? 3 : -3;

  /// Local -X is the shared central landing, at this floor's height.
  double surfaceHeight(double x) => .14 + ((x + length / 2 - .66) / (length - 1.32)).clamp(0.0, 1.0) * rise;

  /// The plan-view artwork also includes the west run's 11 px angled tail
  /// and its antialiased outline. The east end stops at the service wall.
  Rect get floorArtworkBounds => Rect.fromLTRB(
    footprint.left - (boardsAtEastEnd ? 13 : 2),
    footprint.top - 2,
    footprint.right + (boardsAtEastEnd ? 2 : 0),
    footprint.bottom + 2,
  );

  /// The central boarding plate keeps its floor underneath. Only the run
  /// descending to the lower floor needs an opening in the floor and slab.
  Rect? get floorOpening {
    if (connectsUpstairs) {
      return null;
    }
    const landingPixels = landingLength / unit;
    return Rect.fromLTRB(
      footprint.left + (boardsAtEastEnd ? 0 : landingPixels),
      footprint.top,
      footprint.right - (boardsAtEastEnd ? landingPixels : 0),
      footprint.bottom,
    );
  }
}

/// Non-overlapping rectangles covering the floor except its shaft openings.
List<Rect> venueFloorPatches(Rect bounds, Iterable<Rect> openings) {
  final holes = openings.map((hole) => hole.intersect(bounds)).where((hole) => !hole.isEmpty).toList();
  final xs = {
    bounds.left,
    bounds.right,
    for (final hole in holes) ...[hole.left, hole.right],
  }.toList()..sort();
  final ys = {
    bounds.top,
    bounds.bottom,
    for (final hole in holes) ...[hole.top, hole.bottom],
  }.toList()..sort();
  return [
    for (var x = 0; x < xs.length - 1; x++)
      for (var y = 0; y < ys.length - 1; y++)
        if (!holes.any((hole) => hole.contains(Offset((xs[x] + xs[x + 1]) / 2, (ys[y] + ys[y + 1]) / 2))))
          Rect.fromLTRB(xs[x], ys[y], xs[x + 1], ys[y + 1]),
  ];
}
