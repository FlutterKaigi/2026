import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/venue_map/data/venue_walk_artwork.dart';
import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'venue_artwork_manifest.dart';
import 'venue_artwork_painter.dart';

/// Run from apps/app: flutter test tool/venue_map/generate_walk_artwork.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('bake the existing venue artwork with the bundled Noto Sans JP font', () async {
    final font = FontLoader('Noto Sans JP')
      ..addFont(rootBundle.load('res/assets/fonts/NotoSansJP/NotoSansJP-VariableFont.ttf'));
    await font.load();
    final data = jsonDecode(File('assets/venue_map/floor_plan.json').readAsStringSync()) as Map<String, Object?>;
    final navigation = VenueNavigation(data);
    final painter = VenueArtworkPainter();
    final directory = Directory(venueArtworkDirectory)..createSync(recursive: true);
    final images = <String, Object>{};
    Future<void> save(String id, Future<ui.Image> Function() render) async {
      if (images.containsKey('$id.png')) {
        return;
      }
      final image = await render();
      try {
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
        File('${directory.path}/$id.png').writeAsBytesSync(bytes);
        images['$id.png'] = {'width': image.width, 'height': image.height, 'sha256': sha256.convert(bytes).toString()};
      } finally {
        image.dispose();
      }
    }

    const unit = .04;
    const green = Color(0xff205c50);
    final entranceCaptions = <String, String>{};
    for (final locale in [AppLocale.ja, AppLocale.en]) {
      final language = locale.languageCode;
      final caption = (await locale.build()).venueWalk.entranceSign;
      entranceCaptions[language] = caption;
      for (final raw in (data['publicEntrances']! as List).cast<Map<String, Object?>>()) {
        final hall = navigation.places.firstWhere((place) => place.id == raw['placeId']);
        final polygon = (raw['polygon']! as List).map(readPoint);
        final width = (polygon.map((p) => p.y).reduce(math.max) - polygon.map((p) => p.y).reduce(math.min)) * unit;
        await save(
          '${venueEntranceArtworkId(hall.id, width)}_$language',
          () => painter.sign(hall.nameFor(language), caption, green, width: width, height: .36),
        );
      }
      for (final (id, color) in [
        ('mens_wc', const Color(0xff446c88)),
        ('womens_wc', const Color(0xff9b5c76)),
        ('accessible_wc', const Color(0xff397b6d)),
      ]) {
        final place = navigation.places.firstWhere((place) => place.id == id);
        await save(
          'wc_${id}_$language',
          () => painter.sign(
            'WC',
            place.nameFor(language),
            color,
            width: id == 'accessible_wc' ? 1.42 : 2.1,
            height: .56,
          ),
        );
      }
      final halls = navigation.places.where((place) => place.type == 'hall').toList();
      const colors = [Color(0xff7656ad), Color(0xff3b83b0), Color(0xffb67558), Color(0xff3c826a)];
      for (var i = 0; i < halls.length; i++) {
        final hall = halls[i];
        await save(
          'stage_${hall.id}_$language',
          () => painter.stage(
            title: hall.nameFor(language),
            eyebrow: 'FlutterKaigi 2026',
            width: 7.3 - .04,
            height: 1.75 - .04,
            color: colors[i],
          ),
        );
      }
      for (final raw in (data['booths']! as List).cast<Map<String, Object?>>()) {
        final rect = (raw['rect']! as List).cast<num>();
        final place = navigation.places.firstWhere((place) => place.id == raw['id']);
        final width = math.max(rect[2], rect[3]) * unit;
        await save(
          '${place.id}_$language',
          () => painter.sponsor(
            place.nameFor(language),
            width: width * .94 - .04,
            height: math.min(1, width * .51) - .04,
          ),
        );
      }
    }
    final entrance = navigation.places.firstWhere((place) => place.id == 'entrance_hall_lounge');
    final y = entrance.polygon.map((p) => p.y).reduce(math.max) - 12;
    final wallXs = navigation.walls
        .where(
          (wall) => wall.$1.x == wall.$2.x && math.min(wall.$1.y, wall.$2.y) < y && math.max(wall.$1.y, wall.$2.y) > y,
        )
        .map((wall) => wall.$1.x);
    final left = wallXs.where((x) => x < entrance.anchor.x).reduce(math.max);
    final right = wallXs.where((x) => x > entrance.anchor.x).reduce(math.min);
    await save(
      'main_entrance',
      () => painter.sign('FlutterKaigi 2026', '5F  /  WELCOME', green, width: (right - left) * unit - .22, height: .54),
    );
    await save('tread', painter.tread);
    await save('backdrop', painter.backdrop);
    await save('podium', painter.podium);
    File('${directory.path}/manifest.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
        'inputs': venueArtworkInputHashes(),
        'entranceCaptions': entranceCaptions,
        'images': images,
      })}\n',
    );
    // Remove only obsolete generated PNGs, leaving other files untouched.
    for (final file in directory.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (name.endsWith('.png') && !images.containsKey(name)) {
        file.deleteSync();
      }
    }
  });
}
