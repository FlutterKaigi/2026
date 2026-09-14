import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:app/feature/venue_map/data/venue_escalator_layout.dart';
import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final data = jsonDecode(File('assets/venue_map/floor_plan.json').readAsStringSync()) as Map<String, Object?>;
  final runs = (data['escalators']! as List).cast<Map<String, Object?>>().map(VenueEscalatorLayout.new).toList();
  final holes = runs.map((run) => run.floorOpening).whereType<Rect>().toList();

  test('the west bank connects upstairs and the east bank connects downstairs', () {
    expect(runs, hasLength(4));
    for (final run in runs) {
      expect(run.surfaceHeight(-run.length / 2), closeTo(.14, .00001));
      expect(
        run.surfaceHeight(run.length / 2),
        run.id.startsWith('west-') ? greaterThan(0) : lessThan(0),
        reason: run.id,
      );
      expect(run.boardsAtEastEnd, run.id.startsWith('west-'));
    }
  });

  test('each run slopes continuously in the direction of its connected floor', () {
    for (final run in runs) {
      var previous = run.surfaceHeight(-run.length / 2);
      for (var i = 1; i <= 100; i++) {
        final next = run.surfaceHeight(-run.length / 2 + run.length * i / 100);
        expect((next - previous) * run.rise, greaterThanOrEqualTo(0), reason: run.id);
        previous = next;
      }
    }
  });

  test('only the lower-floor runs cut a shaft, preserving the central boarding plates', () {
    expect(holes, hasLength(2));
    for (final run in runs) {
      final hole = run.floorOpening;
      if (run.connectsUpstairs) {
        expect(hole, isNull);
      } else {
        expect(hole!.left, greaterThan(run.footprint.left));
        expect(hole.right, run.footprint.right);
        expect(hole.top, run.footprint.top);
        expect(hole.bottom, run.footprint.bottom);
      }
    }
  });

  for (final (name, bounds) in [
    ('map image', const Rect.fromLTWH(0, 0, 1774, 810)),
    ('structural slab', const Rect.fromLTWH(26, 77, 1718, 686)),
  ]) {
    test('$name retains exactly the floor outside the two shafts', () {
      final patches = venueFloorPatches(bounds, holes);
      double area(Rect rect) => rect.width * rect.height;
      final remaining = patches.fold<double>(0, (sum, patch) => sum + area(patch));
      expect(remaining, closeTo(area(bounds) - holes.fold<double>(0, (sum, hole) => sum + area(hole)), .00001));
      for (var i = 0; i < patches.length; i++) {
        expect(patches[i].isEmpty, isFalse);
        expect(holes.any(patches[i].overlaps), isFalse);
        expect(patches.skip(i + 1).any(patches[i].overlaps), isFalse);
      }
    });
  }

  test('shaft openings remain blocked while the shared landing stays accessible', () {
    final navigation = VenueNavigation(data);
    for (final hole in holes) {
      expect(navigation.canStand(MapPoint(hole.center.dx, hole.center.dy)), isFalse);
    }
    const landing = MapPoint(939, 716);
    expect(navigation.route(VenueNavigation.spawn, landing), isNotEmpty);
    for (final hall in navigation.places.where((p) => p.type == 'hall')) {
      expect(navigation.route(landing, hall.anchor), isNotEmpty, reason: hall.name);
    }
  });

  test('replacing the flat artwork preserves the floor area and leaves both shafts open', () {
    const bounds = Rect.fromLTWH(0, 0, 1774, 810);
    final artwork = runs.map((run) => run.floorArtworkBounds).toList();
    final textured = venueFloorPatches(bounds, [...holes, ...artwork]);
    final clean = artwork.expand((bounds) => venueFloorPatches(bounds, holes)).toList();
    final combined = [...textured, ...clean];
    double area(Rect rect) => rect.width * rect.height;
    expect(
      combined.fold<double>(0, (sum, patch) => sum + area(patch)),
      closeTo(area(bounds) - holes.fold<double>(0, (sum, hole) => sum + area(hole)), .00001),
    );
    for (var i = 0; i < combined.length; i++) {
      expect(holes.any(combined[i].overlaps), isFalse);
      expect(combined.skip(i + 1).any(combined[i].overlaps), isFalse);
    }
    for (final run in runs) {
      expect(textured.any(run.footprint.overlaps), isFalse, reason: run.id);
      final landing = Offset(
        run.boardsAtEastEnd ? run.footprint.right - 7 : run.footprint.left + 7,
        run.footprint.center.dy,
      );
      expect(clean.any((patch) => patch.contains(landing)), isTrue, reason: run.id);
    }
  });

  test('the legacy west runs angled tails are removed outside the model footprint too', () {
    for (final run in runs.where((run) => run.boardsAtEastEnd)) {
      final oldTail = Offset(run.footprint.left - 10, run.footprint.bottom - 1);
      expect(run.footprint.contains(oldTail), isFalse);
      expect(run.floorArtworkBounds.contains(oldTail), isTrue);
    }
  });
}
