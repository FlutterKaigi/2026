import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/feature/venue_map/data/venue_escalator_layout.dart';
import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_scene/scene.dart' as fs;
import 'package:vector_math/vector_math.dart' as vm;

/// Architectural details for the demo, located using the shared map data.
class VenueWalkArchitecture {
  VenueWalkArchitecture({required this.navigation, required this.world, required this.escalators});

  final VenueNavigation navigation;
  final List<VenueEscalatorLayout> escalators;
  final vm.Vector3 Function(MapPoint, double) world;
  final root = fs.Node(name: 'Venue entrances and escalators');
  late final fs.Node _entranceHeader;
  late final vm.Vector3 _entranceCenter;
  late final double _entranceWidth;
  final _headerMaterials = <fs.Material>[];
  double _headerOpacity = 1;
  static const _unit = .04;
  late final _cube = fs.CuboidGeometry(vm.Vector3.all(1));
  late final _steel = _material(const Color(0xffb7c4c8), metallic: .82, roughness: .3);
  late final _darkMetal = _material(const Color(0xff485b61), metallic: .7, roughness: .38);
  late final _rubber = _material(const Color(0xff20282a), roughness: .62);
  late final _wood = _material(const Color(0xffb7a181), roughness: .78);
  late final _green = _material(const Color(0xff205c50), roughness: .76);
  late final _yellow = _material(const Color(0xffddba58), roughness: .65);
  late final _glass = _material(const Color(0x559fd2d0), roughness: .16)
    ..alphaMode = fs.AlphaMode.blend
    ..doubleSided = true;

  Future<void> build() async {
    final tread = fs.PhysicallyBasedMaterial(baseColorTexture: await _treadTexture())
      ..metallicFactor = .78
      ..roughnessFactor = .42;
    for (final layout in escalators) {
      _escalator(layout, tread);
    }
    await _hallEntrances();
    await _mainEntrance();
    for (final (id, title, caption, color) in [
      ('mens_wc', 'WC', '男性用トイレ', const Color(0xff446c88)),
      ('womens_wc', 'WC', '女性用トイレ', const Color(0xff9b5c76)),
      ('accessible_wc', 'WC', '多目的トイレ', const Color(0xff397b6d)),
    ]) {
      final place = navigation.places.firstWhere((p) => p.id == id);
      final north = place.polygon.map((p) => p.y).reduce(math.min);
      final width = id == 'accessible_wc' ? 1.42 : 2.1;
      final sign = _sign(
        await _signTexture(title, caption, color, width: width, height: .56),
        width: width,
        height: .56,
      )..position = world(MapPoint(place.anchor.x, north), 1.25);
      root.add(sign);
    }
  }

  fs.PhysicallyBasedMaterial _material(Color color, {double metallic = 0, double roughness = .7}) {
    double linear(double v) => v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
    return fs.PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(linear(color.r), linear(color.g), linear(color.b), color.a)
      ..metallicFactor = metallic
      ..roughnessFactor = roughness;
  }

  void _escalator(VenueEscalatorLayout layout, fs.Material tread) {
    final length = layout.length;
    final width = layout.width;
    final half = length / 2;
    final parts = _ArchitectureParts(_cube, name: 'Escalator ${layout.id}');
    // Local -X is the boarding end; both banks face the central landing.
    parts.root
      ..position = world(layout.center, .03)
      ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), layout.boardsAtEastEnd ? math.pi : 0);

    // Height is illustrative: this single-floor demo does not model travel
    // between floors. Every part stays inside the existing blocked footprint.
    final level = layout.surfaceHeight;
    final slope = math.atan2(layout.rise, length);
    parts.box(
      vm.Vector3(0, (level(-half) + level(half)) / 2 - .14, 0),
      vm.Vector3(math.sqrt(length * length + layout.rise * layout.rise), .18, width),
      _darkMetal,
      rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), slope),
    );
    if (!layout.connectsUpstairs) {
      final shaftLength = length - VenueEscalatorLayout.landingLength;
      const shaftCenter = VenueEscalatorLayout.landingLength / 2;
      final bottom = level(half) - .28;
      parts.box(vm.Vector3(shaftCenter, bottom, 0), vm.Vector3(shaftLength, .06, width), _darkMetal);
      for (final side in [-1, 1]) {
        parts.box(
          vm.Vector3(shaftCenter, bottom / 2, side * (width / 2 - .012)),
          vm.Vector3(shaftLength, -bottom, .024),
          _darkMetal,
        );
      }
      parts.box(vm.Vector3(half - .012, bottom / 2, 0), vm.Vector3(.024, -bottom, width), _darkMetal);
    }
    const count = 24;
    final pitch = (length - 1.12) / count;
    final stepWidth = width - .22;
    for (var i = 0; i < count; i++) {
      final x = -half + .56 + (i + .5) * pitch;
      final h = level(x);
      parts.box(vm.Vector3(x, h - .08, 0), vm.Vector3(pitch - .012, .16, stepWidth), tread);
      parts.box(vm.Vector3(x - pitch / 2 + .025, h + .007, 0), vm.Vector3(.026, .014, stepWidth), _yellow);
    }
    for (final x in [-half + .28, half - .28]) {
      final h = level(x);
      parts.box(vm.Vector3(x, h - .06, 0), vm.Vector3(.55, .12, stepWidth), _steel);
      for (var line = 0; line < 9; line++) {
        parts.box(
          vm.Vector3(x, h + .005, (line - 4) * stepWidth / 10),
          vm.Vector3(.5, .008, .012),
          _darkMetal,
        );
      }
    }

    for (final side in [-1, 1]) {
      final z = side * (width / 2 - .055);
      final start = -half + .4;
      final end = half - .4;
      final startH = level(start);
      final endH = level(end);
      final angle = math.atan2(endH - startH, end - start);
      final slopeLength = math.sqrt(math.pow(end - start, 2) + math.pow(endH - startH, 2));
      parts.box(
        vm.Vector3(0, (startH + endH) / 2 + .10, z),
        vm.Vector3(slopeLength, .2, .09),
        _steel,
        rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), angle),
      );
      // Thin glass panels reveal the steps through the balustrade.
      final pane = fs.GeometryBuilder(deduplicate: false);
      final corners = [
        vm.Vector3(start, startH + .16, z),
        vm.Vector3(end, endH + .16, z),
        vm.Vector3(end, endH + .78, z),
        vm.Vector3(start, startH + .78, z),
      ];
      for (final normalSign in [-1, 1]) {
        pane.normal(vm.Vector3(0, 0, normalSign.toDouble()));
        final indices = corners.map(pane.addVertex).toList();
        if (normalSign == 1) {
          pane
            ..addTriangle(indices[0], indices[1], indices[2])
            ..addTriangle(indices[0], indices[2], indices[3]);
        } else {
          pane
            ..addTriangle(indices[2], indices[1], indices[0])
            ..addTriangle(indices[3], indices[2], indices[0]);
        }
      }
      parts.root.add(fs.Node(mesh: fs.Mesh(pane.build(retainCpuData: false), _glass))..castsShadows = false);
      for (var post = 0; post < 3; post++) {
        final x = start + (end - start) * post / 2;
        final h = startH + (endH - startH) * post / 2;
        parts.box(vm.Vector3(x, h + .46, z), vm.Vector3(.035, .63, .032), _steel);
      }
      final points = [
        vm.Vector3(start, startH + .8, z),
        vm.Vector3(start + .34, startH + .8, z),
        vm.Vector3(end - .34, endH + .8, z),
        vm.Vector3(end, endH + .8, z),
        vm.Vector3(end + .21, endH + .70, z),
        vm.Vector3(end + .29, endH + .45, z),
        vm.Vector3(end + .21, endH + .19, z),
        vm.Vector3(end, endH + .10, z),
        vm.Vector3(end - .34, endH + .10, z),
        vm.Vector3(start + .34, startH + .10, z),
        vm.Vector3(start, startH + .10, z),
        vm.Vector3(start - .21, startH + .19, z),
        vm.Vector3(start - .29, startH + .45, z),
        vm.Vector3(start - .21, startH + .70, z),
        vm.Vector3(start, startH + .8, z),
      ];
      parts.root.add(
        fs.Node(
          mesh: fs.Mesh(
            fs.TubeGeometry(fs.CatmullRomPath(points), radius: .043, radialSegments: 8, stations: 88),
            _rubber,
          ),
        )..shadowStatic = true,
      );
    }
    parts.finish();
    root.add(parts.root);
  }

  Future<void> _hallEntrances() async {
    final signs = <(String, double), fs.Texture2D>{};
    for (final raw in (navigation.data['publicEntrances']! as List).cast<Map<String, Object?>>()) {
      final hall = navigation.places.firstWhere((p) => p.id == raw['placeId']);
      final polygon = (raw['polygon']! as List).map(readPoint).toList();
      final minX = polygon.map((p) => p.x).reduce(math.min);
      final maxX = polygon.map((p) => p.x).reduce(math.max);
      final minY = polygon.map((p) => p.y).reduce(math.min);
      final maxY = polygon.map((p) => p.y).reduce(math.max);
      final center = MapPoint((minX + maxX) / 2, (minY + maxY) / 2);
      final width = (maxY - minY) * _unit;
      final inward = hall.anchor.x < center.x ? -1.0 : 1.0;
      final parts = _ArchitectureParts(_cube, name: '${hall.name} open entrance');
      parts.root.position = world(center, .025);
      // Jambs and open leaves sit at the opening edges, within the wall's
      // existing navigation clearance; no new barrier crosses the doorway.
      for (final side in [-1, 1]) {
        final z = side * (width / 2 - .035);
        parts.box(vm.Vector3(0, .93, z), vm.Vector3(.20, 1.86, .065), _steel);
        parts.box(vm.Vector3(inward * .27, .87, z), vm.Vector3(.46, 1.72, .055), _wood);
        parts.box(vm.Vector3(inward * .38, .9, z - side * .045), vm.Vector3(.035, .34, .035), _darkMetal);
      }
      parts.box(vm.Vector3(0, 1.88, 0), vm.Vector3(.21, .12, width), _steel);
      parts.box(vm.Vector3(0, .012, 0), vm.Vector3(.35, .024, width - .13), _darkMetal);
      parts.finish();
      root.add(parts.root);
      final texture = signs[(hall.id, width)] ??= await _signTexture(
        hall.name,
        '入口',
        const Color(0xff205c50),
        width: width,
        height: .36,
      );
      final sign = _sign(texture, width: width, height: .36)
        ..position = world(center, 2.14)
        ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), math.pi / 2);
      root.add(sign);
    }
  }

  Future<void> _mainEntrance() async {
    final place = navigation.places.firstWhere((p) => p.id == 'entrance_hall_lounge');
    final y = place.polygon.map((p) => p.y).reduce(math.max) - 12;
    final wallXs = navigation.walls
        .where(
          (wall) => wall.$1.x == wall.$2.x && math.min(wall.$1.y, wall.$2.y) < y && math.max(wall.$1.y, wall.$2.y) > y,
        )
        .map((wall) => wall.$1.x);
    final left = wallXs.where((x) => x < place.anchor.x).reduce(math.max);
    final right = wallXs.where((x) => x > place.anchor.x).reduce(math.min);
    final width = (right - left) * _unit;
    _entranceCenter = world(MapPoint((left + right) / 2, y), .025);
    _entranceWidth = width;
    final parts = _ArchitectureParts(_cube, name: 'Main entrance');
    parts.root.position = world(MapPoint((left + right) / 2, y), .025);
    parts.box(vm.Vector3(0, .014, 0), vm.Vector3(width - .14, .025, 1.05), _green);
    parts.finish();
    // Fade the sign and its posts together, retaining the mat and wall edges.
    final frame = _ArchitectureParts(_cube, name: 'Main entrance sign and posts');
    final timber = _material(const Color(0xffb7a181), roughness: .78);
    final steel = _material(const Color(0xffb7c4c8), metallic: .82, roughness: .3);
    _headerMaterials.addAll([timber, steel]);
    // Posts align with the existing walls and fit their collision clearance.
    for (final sign in [-1, 1]) {
      frame.box(vm.Vector3(sign * width / 2, 1.5, 0), vm.Vector3(.08, 3, .18), timber);
      frame.box(vm.Vector3(sign * width / 2, .16, 0), vm.Vector3(.08, .32, .19), steel);
    }
    frame.box(vm.Vector3(0, 3.01, 0), vm.Vector3(width + .08, .16, .18), timber);
    frame.finish(staticShadows: false);
    _entranceHeader = frame.root;
    _entranceHeader.add(
      _sign(
        await _signTexture(
          'FlutterKaigi 2026',
          '5F  /  WELCOME',
          const Color(0xff205c50),
          width: width - .22,
          height: .54,
        ),
        width: width - .22,
        height: .54,
        fadingMaterials: _headerMaterials,
      )..position = vm.Vector3(0, 3.35, 0),
    );
    parts.root.add(_entranceHeader);
    root.add(parts.root);
  }

  void updateView(
    fs.PerspectiveCamera camera, {
    required vm.Vector3 focus,
    required double dt,
    required bool overview,
    bool snap = false,
  }) {
    final opacity = venueEntranceHeaderOpacity(
      camera: camera.position,
      focus: focus,
      center: _entranceCenter,
      width: _entranceWidth,
      overview: overview,
    );
    _headerOpacity += (opacity - _headerOpacity) * (snap ? 1 : 1 - math.exp(-dt * 12));
    _entranceHeader.visible = _headerOpacity > .01;
    for (final material in _headerMaterials) {
      final mode = _headerOpacity > .995 ? fs.AlphaMode.opaque : fs.AlphaMode.blend;
      switch (material) {
        case fs.PhysicallyBasedMaterial():
          material
            ..baseColorFactor = (material.baseColorFactor.clone()..w = _headerOpacity)
            ..alphaMode = mode;
        case fs.UnlitMaterial():
          material
            ..baseColorFactor = (material.baseColorFactor.clone()..w = _headerOpacity)
            ..alphaMode = mode;
      }
    }
  }

  fs.Node _sign(
    fs.Texture2D texture, {
    required double width,
    required double height,
    List<fs.Material>? fadingMaterials,
  }) {
    final frame = fadingMaterials == null ? _green : _material(const Color(0xff205c50), roughness: .76);
    final sign = fs.Node(mesh: fs.Mesh(fs.CuboidGeometry(vm.Vector3(width, height, .065)), frame));
    final material = fs.UnlitMaterial(colorTexture: texture)
      ..baseColorTextureTransform = fs.TextureTransform(offset: vm.Vector2(0, 1), scale: vm.Vector2(1, -1));
    fadingMaterials?.addAll([frame, material]);
    final mesh = fs.Mesh(fs.PlaneGeometry(width: width - .025, depth: height - .025), material);
    for (final side in [-1, 1]) {
      sign.add(
        fs.Node(mesh: mesh)
          ..position = vm.Vector3(0, 0, side * .035)
          ..rotation =
              vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), side == -1 ? 0 : math.pi) *
              vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -math.pi / 2),
      );
    }
    return sign;
  }

  Future<fs.Texture2D> _treadTexture() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 256, 128),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(256, 0),
          const [Color(0xff829296), Color(0xffc5ced0), Color(0xff91a1a5)],
          const [0, .42, 1],
        ),
    );
    for (var y = 0; y < 128; y += 8) {
      canvas.drawRect(Rect.fromLTWH(0, y.toDouble(), 256, 2), Paint()..color = const Color(0xff48585c));
      canvas.drawRect(Rect.fromLTWH(0, y + 2.0, 256, 1), Paint()..color = const Color(0xffd4dddd));
    }
    return _texture(recorder, 256, 128);
  }

  Future<fs.Texture2D> _signTexture(
    String title,
    String caption,
    Color color, {
    required double width,
    required double height,
  }) async {
    const pixelsWide = 1024;
    // The sign's visible face has a .025-unit frame inset.
    final pixelsHigh = (pixelsWide * (height - .025) / (width - .025)).round();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(color, BlendMode.src);
    void text(String value, double y, double size, FontWeight weight) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: 'Noto Sans JP',
            fontSize: size,
            fontWeight: weight,
            color: const Color(0xfff8f5e9),
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final scale = math.min<double>(1, (pixelsWide - 68) / painter.width);
      canvas
        ..save()
        ..translate((pixelsWide - painter.width * scale) / 2, y)
        ..scale(scale);
      painter.paint(canvas, Offset.zero);
      canvas.restore();
      painter.dispose();
    }

    text(title, pixelsHigh * .10, pixelsHigh * .375, FontWeight.w600);
    text(caption, pixelsHigh * .69, pixelsHigh * .18, FontWeight.w500);
    return _texture(recorder, pixelsWide, pixelsHigh);
  }

  Future<fs.Texture2D> _texture(ui.PictureRecorder recorder, int width, int height) async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    try {
      return await fs.Texture2D.fromImage(image);
    } finally {
      image.dispose();
      picture.dispose();
    }
  }
}

/// Fade only when the close camera and its subject straddle the entrance.
/// A distant view, overview, or a view from outside the gate keeps the sign.
double venueEntranceHeaderOpacity({
  required vm.Vector3 camera,
  required vm.Vector3 focus,
  required vm.Vector3 center,
  required double width,
  required bool overview,
}) {
  final dz = focus.z - camera.z;
  if (overview || dz.abs() < .0001) {
    return 1;
  }
  final t = (center.z - camera.z) / dz;
  if (t <= 0 || t >= 1) {
    return 1;
  }
  final x = camera.x + (focus.x - camera.x) * t;
  final insideGate = (width / 2 - (x - center.x).abs() + .35).clamp(0.0, 1.0);
  final close = ((6 - (camera.z - center.z).abs()) / 2).clamp(0.0, 1.0);
  return 1 - insideGate * close;
}

/// Repeated trim and steps share one unit box and one draw per material.
class _ArchitectureParts {
  _ArchitectureParts(this.geometry, {required String name}) : root = fs.Node(name: name);

  final fs.Node root;
  final fs.Geometry geometry;
  final _batches = <fs.Material, fs.InstancedMesh>{};

  void box(vm.Vector3 position, vm.Vector3 size, fs.Material material, {vm.Quaternion? rotation}) {
    final batch = _batches.putIfAbsent(material, () => fs.InstancedMesh(geometry: geometry, material: material));
    batch.addInstance(vm.Matrix4.compose(position, rotation ?? vm.Quaternion.identity(), size));
  }

  void finish({bool staticShadows = true}) {
    for (final batch in _batches.values) {
      root.add(
        fs.Node()
          ..shadowStatic = staticShadows
          ..addComponent(fs.InstancedMeshComponent(batch)),
      );
    }
  }
}
