import 'dart:math' as math;

import 'package:app/feature/venue_map/data/venue_floor_plan.dart';
import 'package:flutter/material.dart';

/// The camera has no selected-place state. Selection can move it once through [focus].
class VenueMap2DController extends ChangeNotifier {
  Size viewport = Size.zero;
  Offset offset = Offset.zero;
  double scale = 1;
  double fitScale = 1;
  bool rotated = false;
  VenueFloorPlan? _plan;

  Offset orient(Offset point) => rotated ? Offset(_plan!.size.height - point.dy, point.dx) : point;
  Offset project(Offset point) => orient(point) * scale + offset;
  Offset unproject(Offset point) {
    final oriented = (point - offset) / scale;
    return rotated ? Offset(oriented.dy, _plan!.size.height - oriented.dx) : oriented;
  }

  void layout(Size size, VenueFloorPlan plan) {
    if (size.isEmpty || size == viewport) {
      return;
    }
    final previous = viewport;
    viewport = size;
    _plan = plan;
    if (previous.isEmpty) {
      rotated = size.width < size.height * .9;
      _fit();
    } else {
      // Keep the current camera through search, selection summaries, and resizes.
      offset += Offset((size.width - previous.width) / 2, (size.height - previous.height) / 2);
    }
  }

  void _fit() {
    final bounds = _plan!.bounds;
    final width = rotated ? bounds.height : bounds.width;
    final height = rotated ? bounds.width : bounds.height;
    fitScale = math.max(.05, math.min((viewport.width - 40) / width, (viewport.height - 80) / height));
    scale = fitScale;
    offset = viewport.center(Offset.zero) - orient(bounds.center) * scale;
  }

  void fit() {
    if (_plan == null) {
      return;
    }
    _fit();
    notifyListeners();
  }

  void rotate() {
    if (_plan == null) {
      return;
    }
    rotated = !rotated;
    fit();
  }

  void focus(VenuePlace place) {
    if (_plan == null) {
      return;
    }
    final center = orient(place.anchor);
    final points = place.polygon.map(orient);
    final radiusX = points.map((p) => (p.dx - center.dx).abs()).reduce(math.max) + 24;
    final radiusY = points.map((p) => (p.dy - center.dy).abs()).reduce(math.max) + 24;
    scale = math.max(
      fitScale,
      math.min(fitScale * 2.2, math.min((viewport.width - 64) / (radiusX * 2), (viewport.height - 64) / (radiusY * 2))),
    );
    offset = viewport.center(Offset.zero) - center * scale;
    notifyListeners();
  }

  void transform({required double nextScale, required Offset focalPoint, required Offset worldAnchor}) {
    scale = nextScale.clamp(fitScale * .7, fitScale * 6);
    offset = focalPoint - orient(worldAnchor) * scale;
    notifyListeners();
  }

  void zoom(double factor, {Offset? focalPoint}) {
    if (_plan == null) {
      return;
    }
    final focal = focalPoint ?? viewport.center(Offset.zero);
    transform(nextScale: scale * factor, focalPoint: focal, worldAnchor: unproject(focal));
  }
}
