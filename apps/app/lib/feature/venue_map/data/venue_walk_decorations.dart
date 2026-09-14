import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/feature/venue_map/data/venue_creative_board_layout.dart';
import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_scene/scene.dart' as fs;
import 'package:vector_math/vector_math.dart' as vm;

/// Sample exhibition furniture. The reviewed floor plan itself is unchanged.
class VenueWalkDecorations {
  VenueWalkDecorations({required this.navigation, required this.world});

  final VenueNavigation navigation;
  final vm.Vector3 Function(MapPoint, double) world;
  final root = fs.Node(name: 'Demo exhibition decorations');
  late final layout = VenueCreativeBoardLayout(navigation);
  static const _green = Color(0xff205c50);
  static const _cream = Color(0xfff8f5e9);
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
      final texture = await _label(
        title: hall.name,
        eyebrow: 'FlutterKaigi 2026',
        width: 7.3 - .04,
        height: 1.75 - .04,
        color: colors[i],
      );
      _placard(MapPoint(p.x, p.y - 8), width: 7.3, height: 1.75, elevation: 1.9, texture: texture, color: colors[i]);
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
      final texture = await _sponsorLabel(
        place,
        width: signWidth - .04,
        height: signHeight - .04,
      );
      _placard(
        p,
        width: signWidth,
        height: signHeight,
        elevation: 1.23,
        texture: texture,
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
      texture: await _backdrop(),
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
      texture: await _podiumTexture(),
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
  }

  void _obstacle(MapPoint p, double w, double h) => navigation.blocked.add([
    MapPoint(p.x - w / 2, p.y - h / 2),
    MapPoint(p.x + w / 2, p.y - h / 2),
    MapPoint(p.x + w / 2, p.y + h / 2),
    MapPoint(p.x - w / 2, p.y + h / 2),
  ]);

  vm.Vector4 _linear(Color c) {
    double f(double v) => v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
    return vm.Vector4(f(c.r), f(c.g), f(c.b), c.a);
  }

  fs.PhysicallyBasedMaterial _material(Color color) => fs.PhysicallyBasedMaterial()
    ..baseColorFactor = _linear(color)
    ..roughnessFactor = .9;

  fs.Node _box(
    MapPoint p, {
    required double width,
    required double height,
    required double depth,
    required double elevation,
    required Color color,
    double yaw = 0,
  }) {
    final node = fs.Node(mesh: fs.Mesh(fs.CuboidGeometry(vm.Vector3(width, height, depth)), _material(color)))
      ..position = world(p, elevation)
      ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), yaw);
    root.add(node);
    return node;
  }

  fs.UnlitMaterial _textured(fs.Texture2D texture) =>
      fs.UnlitMaterial(colorTexture: texture)
        ..baseColorTextureTransform = fs.TextureTransform(offset: vm.Vector2(0, 1), scale: vm.Vector2(1, -1));

  void _placard(
    MapPoint p, {
    required double width,
    required double height,
    required double elevation,
    required fs.Texture2D texture,
    required Color color,
    double yaw = 0,
    double depth = .09,
    bool bothSides = true,
  }) {
    final board = _box(p, width: width, height: height, depth: depth, elevation: elevation, color: color, yaw: yaw);
    final mesh = fs.Mesh(fs.PlaneGeometry(width: width - .04, depth: height - .04), _textured(texture));
    final upright = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -math.pi / 2);
    board.add(
      fs.Node(mesh: mesh)
        ..position = vm.Vector3(0, 0, -depth / 2 - .006)
        ..rotation = upright,
    );
    if (bothSides) {
      board.add(
        fs.Node(mesh: mesh)
          ..position = vm.Vector3(0, 0, depth / 2 + .006)
          ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), math.pi) * upright,
      );
    }
  }

  void _text(ui.Canvas canvas, String text, Offset position, double width, double size, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Noto Sans JP',
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.18,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final scale = math.min<double>(1, width / painter.width);
    canvas
      ..save()
      ..translate(position.dx + (width - painter.width * scale) / 2, position.dy)
      ..scale(scale);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
    painter.dispose();
  }

  Future<fs.Texture2D> _finish(ui.PictureRecorder recorder, int width, int height) async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    try {
      return await fs.Texture2D.fromImage(image);
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  Future<fs.Texture2D> _label({
    required String title,
    required String eyebrow,
    required double width,
    required double height,
    required Color color,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const w = 1024;
    final h = (w * height / width).round();
    final band = h * .24;
    canvas.drawColor(_cream, BlendMode.src);
    canvas.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), band), Paint()..color = color);
    _text(canvas, eyebrow, Offset(32, band * .19), w - 64, band * .48, _cream);
    _text(canvas, title, Offset(32, band + (h - band) * .24), w - 64, (h - band) * .40, color);
    return _finish(recorder, w, h);
  }

  Future<fs.Texture2D> _sponsorLabel(MapPlace place, {required double width, required double height}) async {
    // Match the visible face, so narrow and wide booths preserve glyph shapes.
    const pixelsWide = 768;
    final pixelsHigh = (pixelsWide * height / width).round();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..drawColor(_cream, BlendMode.src);

    // Break only at legal prefixes/suffixes or a complete parenthetical note.
    // The brand itself stays on one line, including long Japanese names.
    var brand = place.name;
    final prefix = RegExp(r'^(株式会社|\(株\)|（株）)').firstMatch(brand)?.group(0);
    if (prefix != null) {
      brand = brand.substring(prefix.length);
    }
    final qualifier = RegExp(r'(\([^()]+\)|（[^（）]+）)$').firstMatch(brand)?.group(0);
    if (qualifier != null) {
      brand = brand.substring(0, brand.length - qualifier.length).trimRight();
    }
    final suffix = brand.endsWith('株式会社') ? '株式会社' : null;
    if (suffix != null) {
      brand = brand.substring(0, brand.length - suffix.length);
    }
    final area = Rect.fromLTRB(28, 24, pixelsWide - 28, pixelsHigh - 24);
    // Keep the physical type size equal across wide and narrow boards. Short
    // names must not grow to fill the available space more than other brands.
    final pixelsPerUnit = pixelsWide / width;
    final fontSize = .18 * pixelsPerUnit;
    final lines = <TextPainter>[];
    for (final text in [
      ?prefix,
      brand,
      ?suffix,
      ?qualifier,
    ]) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Noto Sans JP',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1.14,
            color: _green,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      lines.add(painter);
    }
    final gap = .035 * pixelsPerUnit;
    final blockWidth = lines.fold<double>(0, (width, line) => math.max(width, line.width));
    final blockHeight = lines.fold<double>(0, (sum, line) => sum + line.height) + gap * (lines.length - 1);
    // Fit the complete name as one block, keeping every line the same size.
    final blockScale = math.min<double>(1, math.min(area.width / blockWidth, area.height / blockHeight));
    var y = area.center.dy - blockHeight * blockScale / 2;
    for (final line in lines) {
      canvas
        ..save()
        ..translate(area.center.dx - line.width * blockScale / 2, y)
        ..scale(blockScale);
      line.paint(canvas, Offset.zero);
      canvas.restore();
      y += (line.height + gap) * blockScale;
      line.dispose();
    }
    return _finish(recorder, pixelsWide, pixelsHigh);
  }

  Future<fs.Texture2D> _backdrop() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const shades = [Color(0xff303030), Color(0xff2d2d2d), Color(0xff292929)];
    for (var panel = 0; panel < 3; panel++) {
      canvas.drawRect(Rect.fromLTWH(panel * 1024 / 3, 0, 1024 / 3, 826), Paint()..color = shades[panel]);
    }
    final text = TextPainter(
      text: const TextSpan(
        text: 'FlutterKaigi',
        style: TextStyle(
          fontFamily: 'Noto Sans JP',
          fontSize: 48,
          fontWeight: FontWeight.w500,
          color: Color(0xfff8f8fa),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final scale = 310 / (text.width + 64);
    canvas.save();
    canvas.translate(512 - 155, 265 - 27 * scale);
    canvas.scale(scale);
    _mark(canvas, const Rect.fromLTWH(0, 0, 52, 52));
    text.paint(canvas, Offset(64, (52 - text.height) / 2));
    canvas.restore();
    text.dispose();
    return _finish(recorder, 1024, 826);
  }

  Future<fs.Texture2D> _podiumTexture() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..drawColor(_charcoal, BlendMode.src);
    _mark(canvas, const Rect.fromLTWH(166, 245, 180, 177));
    return _finish(recorder, 512, 896);
  }

  void _mark(ui.Canvas canvas, Rect bounds) {
    // Reuse the white FlutterKaigi mark paths from website/web/images/logo.svg.
    canvas.save();
    canvas.translate(bounds.left, bounds.top);
    canvas.scale(bounds.width / 106.667, bounds.height / 104.82);
    canvas.translate(-122.667, -132);
    final paint = Paint()..color = const Color(0xfff8f8fa);
    canvas.drawPath(
      Path()
        ..moveTo(196.509, 132)
        ..lineTo(143.165, 184.411)
        ..lineTo(159.58, 200.539)
        ..lineTo(229.334, 132)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(196.509, 180.378)
        ..lineTo(167.783, 208.599)
        ..lineTo(196.509, 236.82)
        ..lineTo(229.334, 236.82)
        ..lineTo(200.611, 208.599)
        ..lineTo(229.334, 180.378)
        ..close(),
      paint,
    );
    canvas.drawOval(Rect.fromCenter(center: const Offset(140.747, 219.028), width: 36.16, height: 35.526), paint);
    canvas.restore();
  }
}
