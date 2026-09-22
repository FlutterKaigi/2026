import 'dart:math' as math;

import 'package:app/feature/venue_map/data/venue_box_batch.dart';
import 'package:app/feature/venue_map/data/venue_creative_board_layout.dart';
import 'package:app/feature/venue_map/data/venue_localized_signs.dart';
import 'package:app/feature/venue_map/data/venue_walk_artwork.dart';
import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_scene/scene.dart' as fs;
import 'package:vector_math/vector_math.dart' as vm;

/// Sample exhibition furniture. The reviewed floor plan itself is unchanged.
class VenueWalkDecorations {
  VenueWalkDecorations({required this.navigation, required this.world, required this.localizedSigns});

  final VenueNavigation navigation;
  final VenueLocalizedSigns localizedSigns;
  final vm.Vector3 Function(MapPoint, double) world;
  final root = fs.Node(name: 'Demo exhibition decorations');
  final _boxes = VenueBoxBatch();
  final _materials = <Color, fs.PhysicallyBasedMaterial>{};
  late final layout = VenueCreativeBoardLayout(navigation);
  static const _green = Color(0xff205c50);
  static const _charcoal = Color(0xff2c2c2c);
  static const _unit = .04;

  Future<void> build() async {
    final halls = navigation.places.where((p) => p.type == 'hall').toList();
    const colors = [Color(0xff7656ad), Color(0xff3b83b0), Color(0xffb67558), Color(0xff3c826a)];
    for (var i = 0; i < halls.length; i++) {
      final hall = halls[i];
      final north = hall.polygon.map((p) => p.y).reduce(math.min);
      final p = MapPoint(hall.anchor.x, north + 23);
      _box(p, width: 7.6, height: .18, depth: 1.4, elevation: .10, color: colors[i]);
      _obstacle(p, 7.6 / _unit, 1.4 / _unit);
      final material = await localizedSigns.create(
        (language) => loadVenueArtwork('stage_${hall.id}', language: language),
      );
      _placard(MapPoint(p.x, p.y - 8), width: 7.3, height: 1.75, elevation: 1.9, material: material, color: colors[i]);
      for (final dx in [-3.2, 3.2]) {
        _box(
          MapPoint(p.x + dx / _unit, p.y - 8),
          width: .09,
          height: 1.1,
          depth: .09,
          elevation: .73,
          color: colors[i],
        );
      }
    }

    for (final raw in (navigation.data['booths']! as List).cast<Map<String, Object?>>()) {
      final rect = (raw['rect']! as List).cast<num>();
      final place = navigation.places.firstWhere((p) => p.id == raw['id']);
      final p = MapPoint(rect[0] + rect[2] / 2, rect[1] + rect[3] / 2);
      final sideways = rect[3] > rect[2];
      final width = math.max(rect[2], rect[3]) * _unit;
      final depth = math.min(rect[2], rect[3]) * _unit;
      final yaw = sideways ? math.pi / 2 : 0.0;
      _box(p, width: width, height: .06, depth: depth, elevation: .58, color: const Color(0xffd4bf97), yaw: yaw);
      final signWidth = width * .94;
      final double signHeight = math.min(1, width * .51);
      final material = await localizedSigns.create(
        (language) => loadVenueArtwork(place.id, language: language),
      );
      _placard(
        p,
        width: signWidth,
        height: signHeight,
        elevation: 1.23,
        material: material,
        color: _green,
        yaw: yaw,
      );
      for (final sign in [-1, 1]) {
        final offset = width * .34 / _unit * sign;
        _box(
          MapPoint(p.x + (sideways ? 0 : offset), p.y + (sideways ? offset : 0)),
          width: .035,
          height: .7,
          depth: .035,
          elevation: .9,
          color: _green,
        );
      }
    }

    final boardHeight = layout.board.width * _unit / 1.24;
    _placard(
      MapPoint(layout.board.center.dx, layout.board.center.dy),
      width: layout.board.width * _unit,
      height: boardHeight,
      depth: layout.board.height * _unit,
      elevation: boardHeight / 2 + .04,
      material: _textured(await loadVenueArtwork('backdrop')),
      color: _charcoal,
      bothSides: false,
    );
    final podiumHeight = boardHeight * .45;
    _placard(
      MapPoint(layout.podium.center.dx, layout.podium.center.dy),
      width: layout.podium.width * _unit,
      height: podiumHeight,
      depth: layout.podium.height * _unit,
      elevation: podiumHeight / 2 + .04,
      material: _textured(await loadVenueArtwork('podium')),
      color: _charcoal,
      bothSides: false,
    );
    root.add(
      fs.Node(
        mesh: fs.Mesh(
          fs.PlaneGeometry(width: layout.area.width * _unit, depth: layout.area.height * _unit),
          _material(const Color(0xff757678)),
        ),
      )..position = world(MapPoint(layout.area.center.dx, layout.area.center.dy), .034),
    );
    layout.registerObstacles(navigation);
    root.add(_boxes.root);
  }

  void _obstacle(MapPoint p, double w, double h) => navigation.addObstacle([
    MapPoint(p.x - w / 2, p.y - h / 2),
    MapPoint(p.x + w / 2, p.y - h / 2),
    MapPoint(p.x + w / 2, p.y + h / 2),
    MapPoint(p.x - w / 2, p.y + h / 2),
  ]);

  vm.Vector4 _linear(Color c) {
    double f(double v) => v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
    return vm.Vector4(f(c.r), f(c.g), f(c.b), c.a);
  }

  fs.PhysicallyBasedMaterial _material(Color color) => _materials.putIfAbsent(
    color,
    () => fs.PhysicallyBasedMaterial()
      ..baseColorFactor = _linear(color)
      ..roughnessFactor = .9,
  );

  void _box(
    MapPoint p, {
    required double width,
    required double height,
    required double depth,
    required double elevation,
    required Color color,
    double yaw = 0,
  }) {
    _boxes.add(
      position: world(p, elevation),
      size: vm.Vector3(width, height, depth),
      material: _material(color),
      yaw: yaw,
    );
  }

  fs.UnlitMaterial _textured(fs.Texture2D texture) =>
      fs.UnlitMaterial(colorTexture: texture)
        ..baseColorTextureTransform = fs.TextureTransform(offset: vm.Vector2(0, 1), scale: vm.Vector2(1, -1));

  void _placard(
    MapPoint p, {
    required double width,
    required double height,
    required double elevation,
    required fs.Material material,
    required Color color,
    double yaw = 0,
    double depth = .09,
    bool bothSides = true,
  }) {
    _box(p, width: width, height: height, depth: depth, elevation: elevation, color: color, yaw: yaw);
    final board = fs.Node()
      ..position = world(p, elevation)
      ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), yaw);
    root.add(board);
    final mesh = fs.Mesh(fs.PlaneGeometry(width: width - .04, depth: height - .04), material);
    final upright = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -math.pi / 2);
    board.add(
      fs.Node(mesh: mesh)
        ..castsShadows = false
        ..position = vm.Vector3(0, 0, -depth / 2 - .006)
        ..rotation = upright,
    );
    if (bothSides) {
      board.add(
        fs.Node(mesh: mesh)
          ..castsShadows = false
          ..position = vm.Vector3(0, 0, depth / 2 + .006)
          ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), math.pi) * upright,
      );
    }
  }
}
