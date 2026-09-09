import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum VenuePlaceType { hall, foyer, facility, sponsor }

class VenuePlace {
  VenuePlace.fromJson(Map<String, Object?> json)
    : id = json['id']! as String,
      names = Map<String, String>.from(json['name']! as Map),
      subtitles = Map<String, String>.from(json['subtitle']! as Map),
      type = VenuePlaceType.values.byName(json['type']! as String),
      palette = json['palette']! as String,
      polygon = (json['polygon']! as List).map(_point).toList(),
      anchor = _point(json['anchor']),
      icon = json['icon'] as String?,
      materialIcon = json['materialIcon'] as String?,
      boothNumber = json['boothNumber'] as int?,
      relatedHallId = json['relatedHallId'] as String?,
      keywords = List<String>.from(json['keywords'] as List? ?? const []),
      mapLabels = Map<String, String>.from(json['mapLabel'] as Map? ?? const {});

  final String id;
  final Map<String, String> names;
  final Map<String, String> subtitles;
  final VenuePlaceType type;
  final String palette;
  final List<Offset> polygon;
  final Offset anchor;
  final String? icon;
  final String? materialIcon;
  final int? boothNumber;
  final String? relatedHallId;
  final List<String> keywords;
  final Map<String, String> mapLabels;

  String name(String languageCode) => names[languageCode] ?? names['ja']!;
  String subtitle(String languageCode) => subtitles[languageCode] ?? subtitles['ja']!;
  String mapLabel(String languageCode) => mapLabels[languageCode] ?? '';
  String semanticsLabel(String languageCode) =>
      boothNumber == null ? name(languageCode) : '$boothNumber · ${name(languageCode)}';

  Path get path => Path()..addPolygon(polygon, true);

  IconData get iconData => switch (materialIcon) {
    'info_outline' => Icons.info_outline,
    'man' => Icons.man,
    'woman' => Icons.woman,
    'accessible' => Icons.accessible,
    'delete_outline' => Icons.delete_outline,
    'palette_outlined' => Icons.palette_outlined,
    'login' => Icons.login,
    'escalator' => Icons.escalator,
    'record_voice_over_outlined' => Icons.record_voice_over_outlined,
    _ =>
      type == VenuePlaceType.foyer || type == VenuePlaceType.sponsor
          ? Icons.storefront_outlined
          : Icons.meeting_room_outlined,
  };

  Color get markerColor => switch (palette) {
    'booth' => const Color(0xFF54788A),
    'purple' => const Color(0xFF8061BD),
    'blue' => const Color(0xFF408FC3),
    'rose' => const Color(0xFF945838),
    'teal' => const Color(0xFF326E58),
    'gold' => const Color(0xFFB98227),
    'pink' => const Color(0xFFCE6BA5),
    _ => const Color(0xFF375666),
  };

  Color color(ColorScheme colors) =>
      colors.brightness == Brightness.dark ? Color.lerp(markerColor, Colors.white, .4)! : markerColor;

  Color get markerTextColor => markerColor.computeLuminance() > .179 ? Colors.black : Colors.white;

  bool matches(String query) {
    final normalized = query.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final number = int.tryParse(normalized.replaceFirst('#', ''));
    if (number != null) {
      return boothNumber == number;
    }
    return [...names.values, ...subtitles.values, ...keywords].any(
      (value) => value.toLowerCase().replaceAll(RegExp(r'\s+'), '').contains(normalized),
    );
  }
}

class VenueEntrance {
  VenueEntrance.fromJson(Map<String, Object?> json)
    : placeId = json['placeId']! as String,
      path = Path()..addPolygon((json['polygon']! as List).map(_point).toList(), true);

  final String placeId;
  final Path path;
}

class VenueFloorPlan {
  VenueFloorPlan.fromJson(Map<String, Object?> json)
    : size = Size((json['width']! as num).toDouble(), (json['height']! as num).toDouble()),
      bounds = _rect(json['bounds']),
      artAsset = json['artAsset']! as String,
      artAssetDark = json['artAssetDark']! as String,
      artBox = _rect(json['artBox']),
      publicEntrances = (json['publicEntrances'] as List? ?? const [])
          .map((value) => VenueEntrance.fromJson(Map<String, Object?>.from(value as Map)))
          .toList(),
      restrictedAreas = (json['restrictedAreas'] as List? ?? const [])
          .map((value) => Path()..addPolygon((value as List).map(_point).toList(), true))
          .toList(),
      places = (json['places']! as List)
          .map((value) => VenuePlace.fromJson(Map<String, Object?>.from(value as Map)))
          .toList();

  final Size size;
  final Rect bounds;
  final String artAsset;
  final String artAssetDark;
  final Rect artBox;
  final List<VenueEntrance> publicEntrances;
  final List<Path> restrictedAreas;
  final List<VenuePlace> places;

  bool isRestricted(Offset point) => restrictedAreas.any((area) => area.contains(point));

  VenuePlace? placeAt(Offset point) {
    if (isRestricted(point)) {
      return null;
    }
    for (final entrance in publicEntrances.reversed) {
      if (entrance.path.contains(point)) {
        return find(entrance.placeId);
      }
    }
    for (final place in places.reversed) {
      if (place.path.contains(point)) {
        return place;
      }
    }
    return null;
  }

  VenuePlace? find(String id) {
    for (final place in places) {
      if (place.id == id) {
        return place;
      }
    }
    return null;
  }
}

Offset _point(Object? value) {
  final coordinates = value! as List;
  return Offset((coordinates[0] as num).toDouble(), (coordinates[1] as num).toDouble());
}

Rect _rect(Object? value) {
  final rect = Map<String, Object?>.from(value! as Map);
  return Rect.fromLTWH(
    (rect['x']! as num).toDouble(),
    (rect['y']! as num).toDouble(),
    (rect['w']! as num).toDouble(),
    (rect['h']! as num).toDouble(),
  );
}

final venueFloorPlanProvider = FutureProvider<VenueFloorPlan>((ref) async {
  final source = await rootBundle.loadString('assets/venue_map/floor_plan.json');
  return VenueFloorPlan.fromJson(Map<String, Object?>.from(jsonDecode(source) as Map));
});
