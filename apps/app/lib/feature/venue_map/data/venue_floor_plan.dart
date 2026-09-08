import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum VenuePlaceType { hall, foyer, facility }

class VenuePlace {
  VenuePlace.fromJson(Map<String, Object?> json)
    : id = json['id']! as String,
      names = Map<String, String>.from(json['name']! as Map),
      subtitles = Map<String, String>.from(json['subtitle']! as Map),
      type = VenuePlaceType.values.byName(json['type']! as String),
      palette = json['palette']! as String,
      polygon = (json['polygon']! as List).map(_point).toList(),
      anchor = _point(json['anchor']),
      icon = json['icon'] as String?;

  final String id;
  final Map<String, String> names;
  final Map<String, String> subtitles;
  final VenuePlaceType type;
  final String palette;
  final List<Offset> polygon;
  final Offset anchor;
  final String? icon;

  String name(String languageCode) => names[languageCode] ?? names['ja']!;
  String subtitle(String languageCode) => subtitles[languageCode] ?? subtitles['ja']!;

  Path get path => Path()..addPolygon(polygon, true);

  IconData get iconData => switch (icon) {
    'info' => Icons.info_outline,
    'wc' => id == 'mens_wc' ? Icons.man : Icons.woman,
    'lift' => Icons.elevator_outlined,
    'entry' => Icons.login,
    'person' => Icons.record_voice_over_outlined,
    _ => type == VenuePlaceType.foyer ? Icons.storefront_outlined : Icons.meeting_room_outlined,
  };

  Color color(ColorScheme colors) => switch (palette) {
    'purple' => colors.primary,
    'blue' => colors.tertiary,
    'rose' => colors.secondary,
    'teal' => colors.onTertiaryContainer,
    'gold' => colors.onSecondaryContainer,
    _ => colors.onSurfaceVariant,
  };

  bool matches(String query) {
    final normalized = query.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return [...names.values, ...subtitles.values].any(
      (value) => value.toLowerCase().replaceAll(RegExp(r'\s+'), '').contains(normalized),
    );
  }
}

class VenueFloorPlan {
  VenueFloorPlan.fromJson(Map<String, Object?> json)
    : size = Size((json['width']! as num).toDouble(), (json['height']! as num).toDouble()),
      bounds = _rect(json['bounds']),
      artBox = _rect(json['artBox']),
      places = (json['places']! as List)
          .map((value) => VenuePlace.fromJson(Map<String, Object?>.from(value as Map)))
          .toList();

  final Size size;
  final Rect bounds;
  final Rect artBox;
  final List<VenuePlace> places;

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
