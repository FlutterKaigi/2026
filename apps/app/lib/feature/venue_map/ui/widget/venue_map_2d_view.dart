import 'dart:math' as math;

import 'package:app/feature/venue_map/data/venue_floor_plan.dart';
import 'package:app/feature/venue_map/ui/widget/venue_map_2d_controller.dart';
import 'package:app/feature/venue_map/ui/widget/venue_map_label_layout.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class VenueMap2DView extends StatefulWidget {
  const VenueMap2DView({
    required this.plan,
    required this.controller,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final VenueFloorPlan plan;
  final VenueMap2DController controller;
  final VenuePlace? selected;
  final ValueChanged<VenuePlace> onSelected;

  @override
  State<VenueMap2DView> createState() => _VenueMap2DViewState();
}

class _VenueMap2DViewState extends State<VenueMap2DView> {
  final _labelOffsets = <String, Offset>{};
  double _startScale = 1;
  Offset _anchor = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final camera = widget.controller;
    return ColoredBox(
      color: colors.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          camera.layout(constraints.biggest, widget.plan);
          return ListenableBuilder(
            listenable: camera,
            builder: (context, _) {
              final matrix = Matrix4.identity();
              if (camera.rotated) {
                matrix
                  ..setEntry(0, 0, 0)
                  ..setEntry(1, 0, camera.scale)
                  ..setEntry(0, 1, -camera.scale)
                  ..setEntry(1, 1, 0)
                  ..setEntry(0, 3, camera.offset.dx + widget.plan.size.height * camera.scale);
              } else {
                matrix
                  ..setEntry(0, 0, camera.scale)
                  ..setEntry(1, 1, camera.scale)
                  ..setEntry(0, 3, camera.offset.dx);
              }
              matrix.setEntry(1, 3, camera.offset.dy);
              return Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
                      camera.zoom(math.exp(-event.scrollDelta.dy * .002), focalPoint: event.localPosition);
                    });
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (details) {
                    _startScale = camera.scale;
                    _anchor = camera.unproject(details.localFocalPoint);
                  },
                  onScaleUpdate: (details) => camera.transform(
                    nextScale: _startScale * details.scale,
                    focalPoint: details.localFocalPoint,
                    worldAnchor: _anchor,
                  ),
                  onTapUp: (details) {
                    final point = camera.unproject(details.localPosition);
                    for (final place in widget.plan.places.reversed) {
                      if (place.path.contains(point)) {
                        widget.onSelected(place);
                        break;
                      }
                    }
                  },
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          width: widget.plan.size.width,
                          height: widget.plan.size.height,
                          child: IgnorePointer(
                            child: Transform(
                              transform: matrix,
                              child: Stack(
                                children: [
                                  Positioned.fromRect(
                                    rect: widget.plan.artBox,
                                    child: _floorArt(colors),
                                  ),
                                  if (colors.brightness == Brightness.dark)
                                    Positioned.fill(child: CustomPaint(painter: _RoomTintPainter(widget.plan, colors))),
                                  if (widget.selected case final place?)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _SelectionPainter(place, colors.primary, camera.scale),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ..._labels(context),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _floorArt(ColorScheme colors) {
    final image = Image.asset('assets/venue_map/floor_map.png', fit: BoxFit.fill, excludeFromSemantics: true);
    if (colors.brightness != Brightness.dark) {
      return image;
    }
    // Map the drawing's luminance onto theme paper/ink, preserving readable walls in dark mode.
    final paper = colors.surfaceContainerHighest;
    final ink = colors.onSurfaceVariant;
    final matrix = <double>[];
    for (final (background, foreground) in [(paper.r, ink.r), (paper.g, ink.g), (paper.b, ink.b)]) {
      final difference = background - foreground;
      matrix.addAll([difference * .2126, difference * .7152, difference * .0722, 0, foreground * 255]);
    }
    matrix.addAll([0, 0, 0, 1, 0]);
    return ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: image);
  }

  List<Widget> _labels(BuildContext context) {
    final camera = widget.controller;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final items = <VenueMapLabelAnchor>[];
    final style = theme.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700);
    for (final place in widget.plan.places) {
      final point = camera.project(place.anchor);
      if (!(Offset.zero & camera.viewport).contains(point)) {
        continue;
      }
      final facility = place.type == VenuePlaceType.facility;
      final restroom = place.icon == 'wc';
      final label = facility ? place.mapLabel(language) : place.name(language).replaceFirst(' HALL', '\nHALL');
      final painter = TextPainter(
        text: TextSpan(text: label, style: facility ? theme.textTheme.labelSmall : style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final size = facility
          ? Size(math.max(48, painter.width + 12), label.isNotEmpty ? math.max(48, painter.height + 30) : 48)
          : Size(math.max(48, painter.width + 12), math.max(48, painter.height + 8));
      painter.dispose();
      items.add(
        VenueMapLabelAnchor(
          id: place.id,
          anchor: point,
          size: size,
          priority: restroom
              ? 0
              : place.id == widget.selected?.id
              ? 1
              : place.type == VenuePlaceType.hall
              ? 2
              : place.type == VenuePlaceType.foyer
              ? 3
              : 4,
          previousOffset: _labelOffsets[place.id] ?? Offset.zero,
        ),
      );
    }
    final placements = layoutVenueMapLabels(items, camera.viewport);
    final result = <Widget>[
      Positioned.fill(
        child: IgnorePointer(child: CustomPaint(painter: _LabelConnectorPainter(placements, colors.onSurfaceVariant))),
      ),
    ];
    // Draw the higher-priority labels last, so restroom buttons remain tappable even in a tiny viewport.
    for (final placement in placements.reversed) {
      final place = widget.plan.find(placement.item.id)!;
      final selected = place.id == widget.selected?.id;
      final facility = place.type == VenuePlaceType.facility;
      final caption = place.mapLabel(language);
      final label = place.name(language).replaceFirst(' HALL', '\nHALL');
      final box = placement.rect;
      _labelOffsets[place.id] = box.center - placement.item.anchor;
      result.add(
        Positioned.fromRect(
          rect: box,
          child: Semantics(
            button: true,
            selected: selected,
            label: place.name(language),
            child: Tooltip(
              message: place.name(language),
              excludeFromSemantics: true,
              child: Material(
                color: selected ? colors.primaryContainer : colors.surface.withValues(alpha: .9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: selected ? colors.primary : colors.outlineVariant),
                ),
                child: InkWell(
                  onTap: () => widget.onSelected(place),
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: ExcludeSemantics(
                      child: facility
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(place.iconData, color: selected ? colors.onPrimaryContainer : place.color(colors)),
                                if (caption.isNotEmpty)
                                  Text(
                                    caption,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelSmall!.copyWith(
                                      color: selected ? colors.onPrimaryContainer : place.color(colors),
                                    ),
                                  ),
                              ],
                            )
                          : Text(
                              label,
                              textAlign: TextAlign.center,
                              style: style.copyWith(color: selected ? colors.onPrimaryContainer : place.color(colors)),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return result;
  }
}

class _SelectionPainter extends CustomPainter {
  const _SelectionPainter(this.place, this.color, this.scale);

  final VenuePlace place;
  final Color color;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawPath(place.path, Paint()..color = color.withValues(alpha: .2))
      ..drawPath(
        place.path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / scale,
      );
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) =>
      oldDelegate.place != place || oldDelegate.color != color || oldDelegate.scale != scale;
}

class _RoomTintPainter extends CustomPainter {
  const _RoomTintPainter(this.plan, this.colors);
  final VenueFloorPlan plan;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    for (final place in plan.places) {
      if (place.type != VenuePlaceType.facility) {
        canvas.drawPath(place.path, Paint()..color = place.color(colors).withValues(alpha: .16));
      }
    }
  }

  @override
  bool shouldRepaint(_RoomTintPainter oldDelegate) => oldDelegate.plan != plan || oldDelegate.colors != colors;
}

class _LabelConnectorPainter extends CustomPainter {
  const _LabelConnectorPainter(this.placements, this.color);
  final List<VenueMapLabelPlacement> placements;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (final placement in placements) {
      final anchor = placement.item.anchor;
      final box = placement.rect;
      final end = Offset(anchor.dx.clamp(box.left, box.right), anchor.dy.clamp(box.top, box.bottom));
      if ((anchor - end).distance > 3) {
        canvas
          ..drawLine(anchor, end, paint)
          ..drawCircle(anchor, 2.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_LabelConnectorPainter oldDelegate) =>
      oldDelegate.placements != placements || oldDelegate.color != color;
}
