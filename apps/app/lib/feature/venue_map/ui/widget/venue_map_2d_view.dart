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
      color: colors.brightness == Brightness.dark ? const Color(0xFF18232E) : const Color(0xFFFCFDFE),
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
                    GestureBinding.instance.pointerSignalResolver.register(
                      event,
                      (_) => camera.zoom(math.exp(-event.scrollDelta.dy * .002), focalPoint: event.localPosition),
                    );
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
                    final place = widget.plan.placeAt(camera.unproject(details.localPosition));
                    if (place != null) {
                      widget.onSelected(place);
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
                                    child: Image.asset(
                                      colors.brightness == Brightness.dark
                                          ? widget.plan.artAssetDark
                                          : widget.plan.artAsset,
                                      fit: BoxFit.fill,
                                      excludeFromSemantics: true,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                  if (widget.selected case final place?)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _SelectionPainter(place, place.color(colors), camera.scale),
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

  List<Widget> _labels(BuildContext context) {
    final camera = widget.controller;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final items = <VenueMapLabelAnchor>[];
    final captions = <String, String>{};
    final detailed = camera.scale >= .5;
    for (final place in widget.plan.places) {
      final point = camera.project(place.anchor);
      if (!(Offset.zero & camera.viewport).contains(point)) {
        continue;
      }
      final selected = place.id == widget.selected?.id;
      // Table footprints always remain on the floor. Numbers appear when there
      // is enough room; every sponsor is also available in the searchable list.
      if (place.type == VenuePlaceType.sponsor && !detailed && !selected) {
        continue;
      }
      final facility = place.type == VenuePlaceType.facility;
      final sponsor = place.type == VenuePlaceType.sponsor;
      final caption = sponsor
          ? '${place.boothNumber}'
          : facility
          ? (detailed || selected || place.id.startsWith('ask_') ? place.mapLabel(language) : '')
          : place.name(language).replaceFirst(' HALL', '\nHALL');
      captions[place.id] = caption;
      final painter = TextPainter(
        text: TextSpan(
          text: caption,
          style: theme.textTheme.labelSmall!.copyWith(
            fontSize: facility ? 10 : 12,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: math.max(60, camera.viewport.width - 32));
      final size = sponsor
          ? Size(24 * textScale, 24 * textScale)
          : facility
          ? Size(math.max(32, painter.width + 14), caption.isEmpty ? 32 : 34 + painter.height)
          : Size(math.max(48, painter.width + 12), math.max(36, painter.height + 8));
      painter.dispose();
      items.add(
        VenueMapLabelAnchor(
          id: place.id,
          anchor: point,
          size: size,
          priority: selected
              ? 0
              : place.icon == 'wc'
              ? 1
              : place.type == VenuePlaceType.hall
              ? 2
              : sponsor
              ? 5
              : 3,
          previousOffset: _labelOffsets[place.id] ?? Offset.zero,
        ),
      );
    }
    final placements = layoutVenueMapLabels(items, camera.viewport);
    return [
      Positioned.fill(
        child: IgnorePointer(child: CustomPaint(painter: _LabelConnectorPainter(placements, colors.onSurfaceVariant))),
      ),
      for (final placement in placements.reversed) _label(context, placement, captions[placement.item.id]!, textScale),
    ];
  }

  Widget _label(BuildContext context, VenueMapLabelPlacement placement, String caption, double textScale) {
    final place = widget.plan.find(placement.item.id)!;
    final selected = place.id == widget.selected?.id;
    final colors = Theme.of(context).colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final sponsor = place.type == VenuePlaceType.sponsor;
    final facility = place.type == VenuePlaceType.facility;
    final color = place.color(colors);
    _labelOffsets[place.id] = placement.rect.center - placement.item.anchor;
    return Positioned.fromRect(
      rect: placement.rect,
      child: Semantics(
        button: true,
        selected: selected,
        label: place.semanticsLabel(language),
        child: Tooltip(
          message: place.semanticsLabel(language),
          excludeFromSemantics: true,
          child: Material(
            color: sponsor
                ? (selected ? place.markerColor : colors.surface)
                : selected
                ? colors.primaryContainer
                : colors.surface.withValues(alpha: .88),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(sponsor ? 20 : 8),
              side: BorderSide(
                color: sponsor
                    ? color
                    : selected
                    ? colors.primary
                    : Colors.transparent,
                width: selected ? 2 : 1.5,
              ),
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
                            Icon(place.iconData, size: 22, color: selected ? colors.onPrimaryContainer : color),
                            if (caption.isNotEmpty)
                              Text(
                                caption,
                                textAlign: TextAlign.center,
                                softWrap: false,
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                  fontSize: 10,
                                  height: 1.25,
                                  color: selected ? colors.onPrimaryContainer : color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        )
                      : Text(
                          caption,
                          textAlign: TextAlign.center,
                          softWrap: false,
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: sponsor && selected
                                ? place.markerTextColor
                                : selected
                                ? colors.onPrimaryContainer
                                : sponsor
                                ? colors.onSurface
                                : color,
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
          ..strokeWidth = 3 / scale,
      );
    if (place.type == VenuePlaceType.sponsor) {
      canvas.drawCircle(
        place.anchor,
        23 / scale,
        Paint()
          ..color = color.withValues(alpha: .25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 / scale,
      );
    }
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) =>
      oldDelegate.place != place || oldDelegate.color != color || oldDelegate.scale != scale;
}

class _LabelConnectorPainter extends CustomPainter {
  const _LabelConnectorPainter(this.placements, this.color);
  final List<VenueMapLabelPlacement> placements;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .55)
      ..strokeWidth = 1;
    for (final placement in placements) {
      final anchor = placement.item.anchor;
      final box = placement.rect;
      final end = Offset(anchor.dx.clamp(box.left, box.right), anchor.dy.clamp(box.top, box.bottom));
      if ((anchor - end).distance > 4) {
        canvas
          ..drawLine(anchor, end, paint)
          ..drawCircle(anchor, 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_LabelConnectorPainter oldDelegate) =>
      oldDelegate.placements != placements || oldDelegate.color != color;
}
