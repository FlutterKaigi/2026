import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

const _app = 'apps/app';
const _iosIcons = '$_app/ios/Runner/Assets.xcassets/AppIcon.appiconset';
const _composer = '$_app/ios/Runner/FlutterKaigi2026.icon/Assets';
const _android = '$_app/android/app/src/main';
const _web = '$_app/web';

/// Run from the repository root; pass --check to detect outdated outputs.
void main(List<String> arguments) {
  if (arguments.isNotEmpty && (arguments.length != 1 || arguments.single != '--check')) {
    stderr.writeln('Usage: fvm dart run tool/generate_app_icons.dart [--check]');
    exitCode = 64;
    return;
  }
  final check = arguments.contains('--check');
  final sourceBytes = File('$_app/res/assets/shuriken-logo.png').readAsBytesSync();
  final logo = img.decodePng(sourceBytes)!;
  final outputs = <String, List<int>>{};

  img.Image background(int size, {int channels = 3}) => img.Image(
    width: size,
    height: size,
    numChannels: channels,
  )..clear(img.ColorRgb8(0x62, 0x00, 0xea));

  img.Image compose(
    int size, {
    img.Image? artwork,
    bool transparent = false,
    double fraction = 0.84,
    int channels = 3,
  }) {
    final canvas = transparent
        ? img.Image(width: size, height: size, numChannels: 4)
        : background(size, channels: channels);
    final resized = img.copyResize(
      artwork ?? logo,
      width: (size * fraction).round(),
      interpolation: img.Interpolation.cubic,
    );
    return img.compositeImage(
      canvas,
      resized,
      dstX: (size - resized.width) ~/ 2,
      dstY: (size - resized.height) ~/ 2,
      blend: transparent ? img.BlendMode.direct : img.BlendMode.alpha,
    );
  }

  void png(String path, img.Image image) => outputs[path] = img.encodePng(image);

  final contents = jsonDecode(File('$_iosIcons/Contents.json').readAsStringSync()) as Map<String, dynamic>;
  for (final entry in (contents['images'] as List).cast<Map<String, dynamic>>()) {
    final size = double.parse((entry['size'] as String).split('x').first);
    final scale = double.parse((entry['scale'] as String).replaceAll('x', ''));
    png('$_iosIcons/${entry['filename']}', compose((size * scale).round()));
  }
  final composerLayers = _composerLayers(logo);
  for (final layer in composerLayers.entries) {
    png('$_composer/${layer.key}.png', compose(1024, artwork: layer.value, transparent: true));
  }

  final glassForeground = _glassForeground({
    for (final layer in composerLayers.entries)
      layer.key: compose(1024, artwork: layer.value, transparent: true, fraction: 0.75),
  });
  final composerSettings =
      jsonDecode(File('$_app/ios/Runner/FlutterKaigi2026.icon/icon.json').readAsStringSync()) as Map<String, dynamic>;
  final gradient = ((composerSettings['fill'] as Map)['linear-gradient'] as List)
      .cast<String>()
      .map((color) => color.replaceFirst('srgb:', '').split(',').take(3).map((v) => double.parse(v) * 255).toList())
      .toList();
  img.Image glassBackground(int size, {double viewport = 1}) {
    final result = img.Image(width: size, height: size, numChannels: 4);
    for (final pixel in result) {
      final t = ((pixel.y / (size - 1) - 0.5) / viewport + 0.5).clamp(0.0, 1.0);
      pixel.setRgba(
        _mix(gradient.first[0], gradient.last[0], t),
        _mix(gradient.first[1], gradient.last[1], t),
        _mix(gradient.first[2], gradient.last[2], t),
        255,
      );
    }
    return result;
  }

  img.Image glassIcon(int size) => img.compositeImage(
    glassBackground(size),
    img.copyResize(glassForeground, width: size, interpolation: img.Interpolation.cubic),
  );

  const densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
  const launcherNames = ['ic_launcher', 'ic_launcher_round', 'ic_launcher_foreground', 'ic_launcher_background'];
  final obsolete = <String>['$_composer/IconGroup 2.png', '$_composer/shuriken-2026.png'];
  for (final density in densities.entries) {
    final directory = '$_android/res/mipmap-${density.key}';
    final legacySize = (48 * density.value).round();
    final adaptiveSize = (108 * density.value).round();
    png('$directory/ic_launcher.png', glassIcon(legacySize));
    png('$directory/ic_launcher_round.png', img.copyCropCircle(glassIcon(legacySize)));
    // Map the 72 dp viewport into 108 dp layers. The 54 dp shuriken fits
    // the 66 dp safe circle, including its diagonal tips.
    png(
      '$directory/ic_launcher_foreground.png',
      compose(
        adaptiveSize,
        artwork: glassForeground,
        transparent: true,
        fraction: 2 / 3,
      ),
    );
    png('$directory/ic_launcher_background.png', glassBackground(adaptiveSize, viewport: 2 / 3));
    obsolete.addAll(launcherNames.map((name) => '$directory/$name.webp'));
  }
  png('$_android/ic_launcher-playstore.png', glassIcon(512));

  for (final size in [180, 192, 512]) {
    png('$_web/icons/flutterkaigi-$size.png', glassIcon(size));
  }
  // Maskable PWA icons keep all essential artwork in the central 80% circle.
  png(
    '$_web/icons/flutterkaigi-maskable-512.png',
    img.compositeImage(
      glassBackground(512),
      compose(512, artwork: glassForeground, transparent: true, fraction: 0.65 / 0.75),
    ),
  );
  outputs['$_web/favicon.ico'] = img.IcoEncoder().encodeImages([
    for (final size in [16, 32, 48]) glassIcon(size),
  ]);
  outputs['$_web/flutterkaigi-favicon.svg'] = utf8.encode(
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <image width="512" height="512" href="data:image/png;base64,${base64Encode(outputs['$_web/icons/flutterkaigi-512.png']!)}"/>
</svg>
''',
  );

  final outdated = <String>[];
  for (final output in outputs.entries) {
    final file = File(output.key);
    if (check) {
      final current = file.existsSync() ? file.readAsBytesSync() : <int>[];
      if (current.length != output.value.length ||
          Iterable.generate(current.length).any((i) => current[i] != output.value[i])) {
        outdated.add(output.key);
      }
    } else {
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(output.value);
    }
  }
  for (final path in obsolete) {
    final file = File(path);
    if (!file.existsSync()) continue;
    if (check) {
      outdated.add(path);
    } else {
      file.deleteSync();
    }
  }
  if (outdated.isNotEmpty) {
    stderr.writeln('App icons need regeneration:\n${outdated.join('\n')}');
    exitCode = 1;
  } else {
    stdout.writeln('${check ? 'Verified' : 'Generated'} ${outputs.length} app icon assets.');
  }
}

int _mix(num from, num to, double amount) => (from + (to - from) * amount).round().clamp(0, 255);

/// Render the approved iOS material as static Android and Web artwork. Only the
/// interior shapes get lighting; the launcher supplies the outer icon mask.
img.Image _glassForeground(Map<String, img.Image> layers) {
  final size = layers.values.first.width;
  final result = img.Image(width: size, height: size, numChannels: 4);

  // Source-over with straight alpha keeps translucent edges clean when the
  // foreground is later composited over Android's independent background.
  void overlay(int x, int y, num r, num g, num b, double alpha) {
    if (alpha == 0) return;
    final pixel = result.getPixel(x, y);
    final remainder = pixel.a / 255 * (1 - alpha);
    final combined = alpha + remainder;
    pixel.setRgba(
      ((r * alpha + pixel.r * remainder) / combined).round(),
      ((g * alpha + pixel.g * remainder) / combined).round(),
      ((b * alpha + pixel.b * remainder) / combined).round(),
      (combined * 255).round(),
    );
  }

  void glass(img.Image mask, List<int> top, List<int> bottom, double shadowOpacity) {
    final blurred = img.gaussianBlur(img.Image.from(mask), radius: 8);
    double alphaAt(int x, int y) => mask.isBoundsSafe(x, y) ? mask.getPixel(x, y).a / 255 : 0;
    for (final pixel in blurred) {
      if (pixel.y + 6 < size) overlay(pixel.x, pixel.y + 6, 0, 0, 25, pixel.a / 255 * shadowOpacity);
    }
    for (final pixel in mask) {
      final alpha = pixel.a / 255;
      if (alpha == 0) continue;
      final t = ((pixel.y / size - 0.25) / 0.65).clamp(0.0, 1.0);
      final highlight = (alpha - alphaAt(pixel.x - 2, pixel.y - 3)).clamp(0.0, 1.0) * 0.85;
      final lowerEdge = (alpha - alphaAt(pixel.x + 2, pixel.y + 3)).clamp(0.0, 1.0) * 0.45;
      final edge = (highlight + lowerEdge).clamp(0.0, 1.0);
      overlay(
        pixel.x,
        pixel.y,
        _mix(_mix(top[0], bottom[0], t), 255, edge),
        _mix(_mix(top[1], bottom[1], t), 255, edge),
        _mix(_mix(top[2], bottom[2], t), 255, edge),
        alpha,
      );
    }
  }

  glass(layers['shuriken-glass']!, [255, 255, 255], [144, 152, 183], 0.28);
  glass(layers['badge-purple']!, [106, 0, 244], [92, 0, 224], 0.3);
  for (final pixel in layers['mark-white']!) {
    overlay(pixel.x, pixel.y, 255, 255, 255, pixel.a / 255);
  }
  return result;
}

/// Separate the existing two-color logo without redrawing its shapes or type.
/// Native Icon Composer materials supply the reflections and shadows.
Map<String, img.Image> _composerLayers(img.Image logo) {
  img.Image layer() => img.Image(width: logo.width, height: logo.height, numChannels: 4);
  final silhouette = layer();
  final badge = layer();
  final lettering = layer();
  final purpleMask = img.Image(width: logo.width, height: logo.height);

  // #6200EA has no green. Green measures white coverage, while the blue
  // difference measures purple coverage, including antialiased edges.
  double purple(img.Pixel pixel) => ((pixel.b - pixel.g) / 234).clamp(0.0, 1.0);
  for (final pixel in logo) {
    final coverage = purple(pixel);
    if (coverage > 0.02) purpleMask.setPixelRgb(pixel.x, pixel.y, 255, 255, 255);
    final alpha = ((pixel.g / 255 + coverage).clamp(0.0, 1.0) * pixel.a).round();
    silhouette.setPixelRgba(pixel.x, pixel.y, 255, 255, 255, alpha);
  }
  // Filling enclosed holes recovers the badge beneath the white lettering.
  final exterior = img.maskFlood(purpleMask, 0, 0);
  for (final pixel in logo) {
    final x = pixel.x;
    final y = pixel.y;
    if (x == 0 || y == 0 || x == logo.width - 1 || y == logo.height - 1) continue;
    final index = y * logo.width + x;
    final interior =
        exterior[index] == 0 &&
        exterior[index - 1] == 0 &&
        exterior[index + 1] == 0 &&
        exterior[index - logo.width] == 0 &&
        exterior[index + logo.width] == 0;
    final alpha = interior ? 255 : (purple(pixel) * pixel.a).round();
    badge.setPixelRgba(x, y, 0x62, 0, 0xea, alpha);
    if (interior) lettering.setPixelRgba(x, y, 255, 255, 255, (pixel.g / 255 * pixel.a).round());
  }
  return {'shuriken-glass': silhouette, 'badge-purple': badge, 'mark-white': lettering};
}
