import 'dart:convert';
import 'dart:io';

import 'package:app/feature/venue_map/data/venue_creative_board_layout.dart';
import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late VenueNavigation navigation;
  late VenueCreativeBoardLayout layout;
  setUp(() {
    navigation = VenueNavigation(
      jsonDecode(File('assets/venue_map/floor_plan.json').readAsStringSync()) as Map<String, dynamic>,
    );
    layout = VenueCreativeBoardLayout(navigation);
  });

  test('creative board furniture stays in its reviewed allocation', () {
    for (final footprint in layout.obstacles) {
      expect(footprint.left, greaterThanOrEqualTo(layout.area.left));
      expect(footprint.top, greaterThanOrEqualTo(layout.area.top));
      expect(footprint.right, lessThanOrEqualTo(layout.area.right));
      expect(footprint.bottom, lessThanOrEqualTo(layout.area.bottom));
    }
  });

  test('creative board furniture leaves every sponsor footprint clear', () {
    for (final sponsor in navigation.places.where((p) => p.type == 'sponsor')) {
      for (final footprint in layout.obstacles) {
        expect(footprint.overlaps(VenueCreativeBoardLayout.boundsOf(sponsor)), isFalse, reason: sponsor.name);
      }
    }
  });

  test('the concourse and every sponsor approach remain reachable after installation', () {
    layout.registerObstacles(navigation);
    expect(navigation.canTravel(const MapPoint(540, 450), const MapPoint(1325, 450)), isTrue);
    for (final sponsor in navigation.places.where((p) => p.type == 'sponsor')) {
      final rect = VenueCreativeBoardLayout.boundsOf(sponsor);
      final approach = rect.height > rect.width
          ? MapPoint(rect.right + 25, rect.center.dy)
          : MapPoint(rect.center.dx, rect.center.dy < 450 ? rect.bottom + 30 : rect.top - 30);
      expect(navigation.route(VenueNavigation.spawn, approach), isNotEmpty, reason: sponsor.name);
    }
  });

  test('the photo spot is accessible and the panel and podium cannot be walked through', () {
    layout.registerObstacles(navigation);
    expect(navigation.route(VenueNavigation.spawn, layout.photoSpot), isNotEmpty);
    for (final footprint in layout.obstacles) {
      expect(navigation.canStand(MapPoint(footprint.center.dx, footprint.center.dy)), isFalse);
    }
    for (final hall in navigation.places.where((p) => p.type == 'hall')) {
      expect(navigation.route(layout.photoSpot, hall.anchor), isNotEmpty, reason: hall.name);
    }
  });
}
