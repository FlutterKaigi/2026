import 'dart:convert';
import 'dart:io';

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
      final target = nav.approach(VenueNavigation.spawn, place);
      expect(target, isNotNull, reason: place.name);
      expect(nav.canStand(target!), isTrue, reason: place.name);
      expect(target.distanceTo(place.anchor), lessThanOrEqualTo(72), reason: place.name);
      var previous = VenueNavigation.spawn;
      for (final next in nav.route(previous, target)) {
        expect(nav.canTravel(previous, next), isTrue, reason: place.name);
        previous = next;
      }
    }
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
