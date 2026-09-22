import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// The original scene's painting recipes, baked with the bundled font.
/// Keep dimensions, line breaking, colors and font weights identical to the
/// scene artwork; only the time at which rasterization happens has changed.
class VenueArtworkPainter {
  static const _green = Color(0xff205c50);
  static const _cream = Color(0xfff8f5e9);
  static const _charcoal = Color(0xff2c2c2c);

  Future<ui.Image> tread() async {
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
    return _finish(recorder, 256, 128);
  }

  Future<ui.Image> sign(
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
    return _finish(recorder, pixelsWide, pixelsHigh);
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

  Future<ui.Image> stage({
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

  Future<ui.Image> sponsor(String name, {required double width, required double height}) async {
    // Match the visible face, so narrow and wide booths preserve glyph shapes.
    const pixelsWide = 768;
    final pixelsHigh = (pixelsWide * height / width).round();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..drawColor(_cream, BlendMode.src);

    // Break only at legal prefixes/suffixes or a complete parenthetical note.
    // The brand itself stays on one line, including long Japanese names.
    var brand = name;
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

  Future<ui.Image> backdrop() async {
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

  Future<ui.Image> podium() async {
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

  Future<ui.Image> _finish(ui.PictureRecorder recorder, int width, int height) async {
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(width, height);
    } finally {
      picture.dispose();
    }
  }
}
