import 'dart:math' as math;

import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:app/feature/venue_map/data/venue_walk_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  const size = Size(390, 700);
  const at = MapPoint(885, 420);

  for (final yaw in [0.0, math.pi / 2, -math.pi / 2, math.pi, .73]) {
    test('stick directions agree with the rendered camera at yaw $yaw', () {
      final game = VenueWalkScene()..yaw = yaw;
      addTearDown(game.dispose);
      game.camera
        ..position = vm.Vector3(-math.sin(yaw) * 14, 12, -math.cos(yaw) * 14)
        ..target = game.world(at);
      final origin = game.camera.worldToScreen(game.world(at), size)!;
      for (final input in [const Offset(1, 0), const Offset(0, -1), const Offset(-1, 0), const Offset(0, 1)]) {
        final delta = game.movementFor(input);
        final moved = game.camera.worldToScreen(game.world(at + delta), size)! - origin;
        final agreement = (moved.dx * input.dx + moved.dy * input.dy) / moved.distance;
        expect(agreement, greaterThan(.999), reason: 'Input $input projected to $moved');
      }
    });
  }

  test('input follows the visible camera while an orbit or overview transition is still easing', () {
    final game = VenueWalkScene()
      ..yaw = math.pi / 2
      ..overview = true
      ..viewAspect = .55;
    addTearDown(game.dispose);
    game.camera
      ..position = vm.Vector3(0, 12, -14)
      ..target = game.world(at);
    final origin = game.camera.worldToScreen(game.world(at), size)!;
    final delta = game.movementFor(const Offset(1, 0));
    final moved = game.camera.worldToScreen(game.world(at + delta), size)! - origin;
    expect(moved.dx, greaterThan(0));
    expect(moved.dy.abs(), lessThan(.001));
  });

  test('the imported model faces the viewer when posing after a quarter-turn orbit', () {
    final game = VenueWalkScene()..yaw = math.pi / 2;
    addTearDown(game.dispose);
    final origin = game.world(game.position);
    game.camera.position = origin + vm.Vector3(-14, 12, 0);
    final heading = game.cameraFacingHeading;
    // The imported GLB's authored front is -Z.
    final facing = vm.Vector3(-math.sin(heading), 0, -math.cos(heading));
    final viewer = (game.camera.position - origin)..y = 0;
    expect(facing.dot(viewer.normalized()), greaterThan(.999));
  });
}
