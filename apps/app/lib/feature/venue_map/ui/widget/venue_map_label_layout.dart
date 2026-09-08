import 'dart:math' as math;

import 'package:flutter/material.dart';

class VenueMapLabelAnchor {
  const VenueMapLabelAnchor({
    required this.id,
    required this.anchor,
    required this.size,
    required this.priority,
    this.previousOffset = Offset.zero,
  });
  final String id;
  final Offset anchor;
  final Size size;
  final int priority;
  final Offset previousOffset;
}

class VenueMapLabelPlacement {
  const VenueMapLabelPlacement(this.item, this.rect);
  final VenueMapLabelAnchor item;
  final Rect rect;
}

/// Keeps on-screen labels visible, moving collisions to the nearest available space.
/// The same placement rule is used by the 3D asset's label-layout.js.
List<VenueMapLabelPlacement> layoutVenueMapLabels(List<VenueMapLabelAnchor> items, Size viewport) {
  const margin = 4.0;
  const gap = 6.0;
  final placed = <VenueMapLabelPlacement>[];
  final ordered = items.indexed.toList()
    ..sort((a, b) {
      final essential = (a.$2.priority == 0 ? 0 : 1).compareTo(b.$2.priority == 0 ? 0 : 1);
      if (essential != 0) {
        return essential;
      }
      // Reserve space for larger translated labels before smaller ones fill the gaps.
      final area = (b.$2.size.width * b.$2.size.height).compareTo(a.$2.size.width * a.$2.size.height);
      if (area != 0) {
        return area;
      }
      final priority = a.$2.priority.compareTo(b.$2.priority);
      return priority == 0 ? a.$1.compareTo(b.$1) : priority;
    });
  for (final (_, item) in ordered) {
    final minX = margin + item.size.width / 2;
    final maxX = math.max(minX, viewport.width - minX);
    final minY = margin + item.size.height / 2;
    final maxY = math.max(minY, viewport.height - minY);
    double clampX(double value) => value.clamp(minX, maxX);
    double clampY(double value) => value.clamp(minY, maxY);
    final previous = item.anchor + item.previousOffset;
    final previousX = clampX(previous.dx);
    final previousY = clampY(previous.dy);
    final xs = {clampX(item.anchor.dx), previousX, minX, maxX};
    final ys = {clampY(item.anchor.dy), previousY, minY, maxY};
    for (final other in placed) {
      xs
        ..add(clampX(other.rect.left - gap - item.size.width / 2))
        ..add(clampX(other.rect.right + gap + item.size.width / 2));
      ys
        ..add(clampY(other.rect.top - gap - item.size.height / 2))
        ..add(clampY(other.rect.bottom + gap + item.size.height / 2));
    }
    Rect? best;
    var bestScore = double.infinity;
    for (final x in xs) {
      for (final y in ys) {
        final center = Offset(x, y);
        final box = Rect.fromCenter(center: center, width: item.size.width, height: item.size.height);
        final overlap = placed.fold<double>(0, (sum, other) {
          final intersect = box.inflate(gap).intersect(other.rect);
          return sum + math.max(0, intersect.width) * math.max(0, intersect.height);
        });
        final score =
            overlap * 1e6 +
            (center - item.anchor).distanceSquared +
            .15 * (center - Offset(previousX, previousY)).distanceSquared;
        if (score < bestScore) {
          bestScore = score;
          best = box;
        }
      }
    }
    placed.add(VenueMapLabelPlacement(item, best!));
  }
  return placed;
}
