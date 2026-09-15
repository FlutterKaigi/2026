import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:app/feature/venue_map/data/venue_walk_scene.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late VenueNavigation nav;
  setUp(() {
    nav = VenueNavigation(
      jsonDecode(File('assets/venue_map/floor_plan.json').readAsStringSync()) as Map<String, dynamic>,
    );
  });

  test('spawn is on the public floor and obstacles cannot be occupied', () {
    expect(nav.canStand(VenueNavigation.spawn), isTrue);
    expect(nav.canStand(const MapPoint(-10, 100)), isFalse);
    expect(nav.canStand(const MapPoint(900, 200)), isFalse);
    expect(nav.canStand(const MapPoint(494, 450)), isFalse); // Sponsor table.
  });

  for (final id in ['mens_wc', 'womens_wc', 'accessible_wc']) {
    test('walking status identifies $id inside its floor-plan boundary', () {
      final place = nav.places.firstWhere((place) => place.id == id);
      final game = VenueWalkScene()
        ..navigation = nav
        ..position = place.anchor;
      addTearDown(game.dispose);

      expect(nav.canStand(game.position), isTrue);
      game.releaseInput();

      expect(game.status.value.location, id);
    });
  }

  test('location follows facility boundaries while hall visits remain separate', () {
    final game = VenueWalkScene()..navigation = nav;
    addTearDown(game.dispose);
    for (final place in nav.places.where((place) => place.type != 'sponsor')) {
      game
        ..position = place.anchor
        ..releaseInput();
      expect(game.status.value.location, place.id, reason: place.name);
    }
    game
      ..position = VenueNavigation.spawn
      ..releaseInput();
    expect(game.status.value.location, isNull);
    expect(game.status.value.visited, 0);
    expect(nav.hallAt(nav.places.firstWhere((place) => place.id == 'mens_wc').anchor), isNull);
  });

  test('collision checks match the full floor geometry near edges and across the floor', () {
    bool reference(MapPoint point) {
      if (!insidePolygon(point, nav.outline)) {
        return false;
      }
      for (final polygon in [nav.outline, ...nav.blocked]) {
        if (!identical(polygon, nav.outline) && insidePolygon(point, polygon)) {
          return false;
        }
        for (var i = 0; i < polygon.length; i++) {
          if (distanceToSegment(point, polygon[i], polygon[(i + 1) % polygon.length]) < VenueNavigation.radius) {
            return false;
          }
        }
      }
      return nav.walls.every((wall) => distanceToSegment(point, wall.$1, wall.$2) >= VenueNavigation.radius + 1);
    }

    final random = math.Random(2026);
    final points = [
      for (var i = 0; i < 3000; i++) MapPoint(random.nextDouble() * 1800, random.nextDouble() * 850),
      for (final (a, b) in nav.walls)
        for (final margin in [6.999, 7.001, 7.999, 8.001])
          for (final offset in [MapPoint(margin, 0), MapPoint(-margin, 0), MapPoint(0, margin), MapPoint(0, -margin)])
            MapPoint((a.x + b.x) / 2, (a.y + b.y) / 2) + offset,
    ];
    for (final point in points) {
      expect(nav.canStand(point), reference(point), reason: '$point');
    }
  });

  test('all four halls are reachable through their reviewed door openings', () {
    for (final hall in nav.places.where((p) => p.type == 'hall')) {
      final path = nav.route(VenueNavigation.spawn, hall.anchor);
      expect(path, isNotEmpty, reason: hall.name);
      expect(path.last, hall.anchor);
      var previous = VenueNavigation.spawn;
      for (final next in path) {
        expect(nav.canTravel(previous, next), isTrue, reason: '${hall.name}: $previous -> $next');
        previous = next;
      }
    }
  });

  test('routes can return from a hall to the concourse', () {
    final hall = nav.places.firstWhere((p) => p.id == 'main_hall_a');
    final path = nav.route(hall.anchor, VenueNavigation.spawn);
    expect(path, isNotEmpty);
    expect(path.last, VenueNavigation.spawn);
  });

  test('every sponsor search result leads to a reachable position outside its booth', () {
    for (final place in nav.places.where((p) => p.type == 'sponsor')) {
      final route = nav.routeToPlace(VenueNavigation.spawn, place);
      expect(route, isNotEmpty, reason: place.name);
      final target = route.last;
      expect(nav.canStand(target), isTrue, reason: place.name);
      expect(target.distanceTo(place.anchor), lessThanOrEqualTo(72), reason: place.name);
      var previous = VenueNavigation.spawn;
      for (final next in route) {
        expect(nav.canTravel(previous, next), isTrue, reason: place.name);
        previous = next;
      }
    }
  });

  test('decorations added after routing invalidate the cached walking grid', () {
    final hall = nav.places.firstWhere((p) => p.id == 'main_hall_a');
    expect(nav.routeToPlace(VenueNavigation.spawn, hall), isNotEmpty);
    final center = hall.anchor;
    nav.addObstacle([
      center + const MapPoint(-16, -16),
      center + const MapPoint(16, -16),
      center + const MapPoint(16, 16),
      center + const MapPoint(-16, 16),
    ]);
    expect(nav.canStand(center), isFalse);
    final route = nav.routeToPlace(VenueNavigation.spawn, hall);
    expect(route, isNotEmpty);
    var previous = VenueNavigation.spawn;
    for (final next in route) {
      expect(nav.canTravel(previous, next), isTrue);
      previous = next;
    }
    expect(nav.canStand(route.last), isTrue);
  });

  test('clicking a restricted area does not produce a route', () {
    expect(nav.route(VenueNavigation.spawn, const MapPoint(900, 200)), isEmpty);
    expect(nav.route(VenueNavigation.spawn, const MapPoint(2000, 800)), isEmpty);
  });

  test('losing input focus releases held controls without cancelling a selected walking route', () {
    final game = VenueWalkScene()..navigation = nav;
    addTearDown(game.dispose);
    final hall = nav.places.firstWhere((p) => p.id == 'grand_hall_a');
    final route = nav.route(VenueNavigation.spawn, hall.anchor);
    game
      ..path = route
      ..stick = const Offset(0, -1)
      ..keys.add(LogicalKeyboardKey.keyW)
      ..setSprintHeld(pressed: true);

    game.releaseInput();

    expect(game.path, route);
    expect(game.path, isNotEmpty);
    expect(game.keys, isEmpty);
    expect(game.stick, Offset.zero);
    expect(game.status.value.running, isFalse);
  });

  test('large manual steps cannot tunnel through a hall wall', () {
    const from = MapPoint(200, 280);
    final result = nav.move(from, const MapPoint(0, -240));
    expect(nav.canStand(result), isTrue);
    expect(result.y, greaterThan(144));
    expect(nav.canTravel(from, result), isTrue);
  });

  test('manual movement slides along walls', () {
    const from = MapPoint(200, 155);
    final result = nav.move(from, const MapPoint(60, -40));
    expect(result.x, greaterThan(250));
    expect(result.y, greaterThanOrEqualTo(152));
    expect(nav.canStand(result), isTrue);
  });
}
