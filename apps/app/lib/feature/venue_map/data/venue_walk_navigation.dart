import 'dart:math' as math;

import 'package:collection/collection.dart';

/// All navigation remains in the reviewed floor plan's pixel coordinates.
/// The renderer alone converts these to scene units.
typedef MapPoint = math.Point<double>;

MapPoint readPoint(Object? value) {
  final coordinates = value! as List;
  return MapPoint((coordinates[0] as num).toDouble(), (coordinates[1] as num).toDouble());
}

class MapPlace {
  MapPlace(Map<String, Object?> json)
    : id = json['id']! as String,
      name = (json['name']! as Map)['ja']! as String,
      type = json['type']! as String,
      number = json['boothNumber'] as int?,
      anchor = readPoint(json['anchor']),
      polygon = (json['polygon']! as List).map(readPoint).toList();

  final String id;
  final String name;
  final String type;
  final int? number;
  final MapPoint anchor;
  final List<MapPoint> polygon;
}

bool insidePolygon(MapPoint p, List<MapPoint> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final a = polygon[i];
    final b = polygon[j];
    if ((a.y > p.y) != (b.y > p.y) && p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) {
      inside = !inside;
    }
  }
  return inside;
}

double distanceToSegment(MapPoint p, MapPoint a, MapPoint b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  final length2 = dx * dx + dy * dy;
  final t = length2 == 0 ? 0.0 : (((p.x - a.x) * dx + (p.y - a.y) * dy) / length2).clamp(0.0, 1.0);
  return p.distanceTo(MapPoint(a.x + t * dx, a.y + t * dy));
}

class VenueNavigation {
  VenueNavigation(this.data) {
    outline = (data['outline']! as List).map(readPoint).toList();
    walls = (data['walls']! as List).cast<List<Object?>>().map((w) => (readPoint(w[0]), readPoint(w[1]))).toList();
    blocked = (data['restrictedAreas']! as List).map((p) => (p as List).map(readPoint).toList()).toList();
    for (final booth in (data['booths']! as List).cast<Map<String, Object?>>()) {
      final r = (booth['rect']! as List).cast<num>();
      blocked.add(_rect(r[0], r[1], r[2], r[3]));
    }
    // Escalator runs are not walking surfaces in this single-floor demo.
    for (final raw in (data['escalators']! as List).cast<Map<String, Object?>>()) {
      final e = Map<String, Object?>.from(raw);
      final x0 = e['x0']! as num;
      final y0 = e['y0']! as num;
      blocked.add(_rect(x0, y0, (e['x1']! as num) - x0, (e['y1']! as num) - y0));
    }
    places = (data['places']! as List).map((p) => MapPlace(Map<String, Object?>.from(p as Map))).toList();
  }

  final Map<String, Object?> data;
  late final List<MapPoint> outline;
  late final List<(MapPoint, MapPoint)> walls;
  late final List<List<MapPoint>> blocked;
  late final List<MapPlace> places;
  static const radius = 7.0;
  static const grid = 6.0;
  static const spawn = MapPoint(903, 525);
  final _walkableCells = <(int, int), bool>{};

  static List<MapPoint> _rect(num x, num y, num w, num h) => [
    MapPoint(x.toDouble(), y.toDouble()),
    MapPoint((x + w).toDouble(), y.toDouble()),
    MapPoint((x + w).toDouble(), (y + h).toDouble()),
    MapPoint(x.toDouble(), (y + h).toDouble()),
  ];

  bool canStand(MapPoint p) {
    if (!insidePolygon(p, outline)) {
      return false;
    }
    for (var i = 0; i < outline.length; i++) {
      if (distanceToSegment(p, outline[i], outline[(i + 1) % outline.length]) < radius) {
        return false;
      }
    }
    for (final (a, b) in walls) {
      if (distanceToSegment(p, a, b) < radius + 1) {
        return false;
      }
    }
    for (final polygon in blocked) {
      if (insidePolygon(p, polygon)) {
        return false;
      }
      for (var i = 0; i < polygon.length; i++) {
        if (distanceToSegment(p, polygon[i], polygon[(i + 1) % polygon.length]) < radius) {
          return false;
        }
      }
    }
    return true;
  }

  bool canTravel(MapPoint from, MapPoint to) {
    final steps = math.max(1, (from.distanceTo(to) / (radius / 2)).ceil());
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      if (!canStand(MapPoint(from.x + (to.x - from.x) * t, from.y + (to.y - from.y) * t))) {
        return false;
      }
    }
    return true;
  }

  /// Substeps prevent tunnelling even when a long frame crosses a thin wall.
  /// Axis sliding lets manual input move along a wall without crossing it.
  MapPoint move(MapPoint from, MapPoint delta) {
    final steps = math.max(1, (delta.magnitude / (radius / 2)).ceil());
    final dx = delta.x / steps;
    final dy = delta.y / steps;
    var p = from;
    for (var i = 0; i < steps; i++) {
      final both = MapPoint(p.x + dx, p.y + dy);
      if (canStand(both)) {
        p = both;
      } else {
        final x = MapPoint(p.x + dx, p.y);
        if (canStand(x)) {
          p = x;
        }
        final y = MapPoint(p.x, p.y + dy);
        if (canStand(y)) {
          p = y;
        }
      }
    }
    return p;
  }

  MapPoint _point((int, int) c) => MapPoint(c.$1 * grid, c.$2 * grid);
  bool _cellFree((int, int) c) => _walkableCells.putIfAbsent(c, () => canStand(_point(c)));

  (int, int)? _nearCell(MapPoint p) {
    final x = (p.x / grid).round();
    final y = (p.y / grid).round();
    final candidates = <(int, int)>[
      for (var dx = -2; dx <= 2; dx++)
        for (var dy = -2; dy <= 2; dy++) (x + dx, y + dy),
    ]..sort((a, b) => p.distanceTo(_point(a)).compareTo(p.distanceTo(_point(b))));
    for (final cell in candidates) {
      if (_cellFree(cell) && canTravel(p, _point(cell))) {
        return cell;
      }
    }
    return null;
  }

  /// A* over a cached grid, followed by collision-checked line-of-sight smoothing.
  /// A missing route is reported to the UI; it never teleports through walls.
  List<MapPoint> route(MapPoint from, MapPoint to) {
    if (!canStand(from) || !canStand(to)) {
      return [];
    }
    if (canTravel(from, to)) {
      return [to];
    }
    final start = _nearCell(from);
    final end = _nearCell(to);
    if (start == null || end == null) {
      return [];
    }
    final queue = HeapPriorityQueue<({(int, int) cell, double score})>(
      (a, b) => a.score.compareTo(b.score),
    )..add((cell: start, score: 0));
    final cameFrom = <(int, int), (int, int)>{};
    final costs = <(int, int), double>{start: 0};
    final closed = <(int, int)>{};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst().cell;
      if (!closed.add(current)) {
        continue;
      }
      if (current == end) {
        final raw = <MapPoint>[to, _point(end)];
        var c = end;
        while (c != start) {
          c = cameFrom[c]!;
          raw.add(_point(c));
        }
        raw.add(from);
        final points = raw.reversed.toList();
        final result = <MapPoint>[];
        var i = 0;
        while (i < points.length - 1) {
          var next = points.length - 1;
          while (next > i + 1 && !canTravel(points[i], points[next])) {
            next--;
          }
          result.add(points[next]);
          i = next;
        }
        return result;
      }
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) {
            continue;
          }
          final next = (current.$1 + dx, current.$2 + dy);
          if (closed.contains(next) || !_cellFree(next)) {
            continue;
          }
          if (!canTravel(_point(current), _point(next))) {
            continue;
          }
          final cost = costs[current]! + (dx != 0 && dy != 0 ? math.sqrt2 : 1);
          if (cost >= (costs[next] ?? double.infinity)) {
            continue;
          }
          costs[next] = cost;
          cameFrom[next] = current;
          queue.add((cell: next, score: cost + _point(next).distanceTo(_point(end)) / grid));
        }
      }
    }
    return [];
  }

  MapPlace? hallAt(MapPoint p) =>
      places.where((v) => v.type == 'hall').firstWhereOrNull((v) => insidePolygon(p, v.polygon));
}
