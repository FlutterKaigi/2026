import 'dart:math' as math;

import 'package:app/feature/venue_map/data/venue_floor_plan.dart';
import 'package:app/feature/venue_map/ui/widget/venue_map_2d_controller.dart';
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
    final occupied = <Rect>[];
    final result = <Widget>[];
    final ordered = [...widget.plan.places]
      ..sort((a, b) {
        int priority(VenuePlace p) => p.id == widget.selected?.id ? -1 : p.type.index;
        return priority(a).compareTo(priority(b));
      });
    for (final place in ordered) {
      final selected = place.id == widget.selected?.id;
      final facility = place.type == VenuePlaceType.facility;
      if (place.id == 'ask_speaker' && !selected && camera.scale < camera.fitScale * 1.4) {
        continue;
      }
      final point = camera.project(place.anchor);
      final label = place.name(language).replaceFirst(' HALL', '\nHALL');
      final style = theme.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700);
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final size = facility
          ? const Size(48, 48)
          : Size(math.max(48, painter.width + 12), math.max(48, painter.height + 8));
      painter.dispose();
      final box = Rect.fromCenter(center: point, width: size.width, height: size.height);
      if (!box.overlaps(Offset.zero & camera.viewport)) {
        continue;
      }
      if (!selected && occupied.any((other) => other.inflate(2).overlaps(box))) {
        continue;
      }
      occupied.add(box);
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
                          ? Icon(place.iconData, color: selected ? colors.onPrimaryContainer : place.color(colors))
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
