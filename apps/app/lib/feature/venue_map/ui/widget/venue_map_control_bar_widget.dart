import 'package:app/core/i18n/strings.g.dart';
import 'package:flutter/material.dart';

class VenueMapControlBarWidget extends StatelessWidget {
  const VenueMapControlBarWidget({
    required this.enabled,
    required this.onCommand,
    super.key,
  });

  final bool enabled;
  final ValueChanged<String> onCommand;

  @override
  Widget build(BuildContext context) {
    final groups = _controlGroups(context.t);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final group in groups) ...[
                _VenueMapControlGroupWidget(
                  group: group,
                  enabled: enabled,
                  onCommand: onCommand,
                ),
                if (group != groups.last) const SizedBox(width: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_VenueMapControlGroup> _controlGroups(Translations t) {
    final controls = t.venueMap.controls;
    return [
      _VenueMapControlGroup(
        label: controls.view.title,
        controls: [
          _VenueMapControl(
            label: controls.view.threeD,
            icon: Icons.view_in_ar_outlined,
            javaScript: 'window.FloorPlan3D.view3D()',
          ),
          _VenueMapControl(
            label: controls.view.top,
            icon: Icons.vertical_align_top,
            javaScript: 'window.FloorPlan3D.topView()',
          ),
        ],
      ),
      _VenueMapControlGroup(
        label: controls.highlight.title,
        controls: [
          _VenueMapControl(
            label: controls.highlight.mainHalls,
            icon: Icons.event_seat_outlined,
            javaScript: 'window.FloorPlan3D.highlightMainHalls()',
          ),
          _VenueMapControl(
            label: controls.highlight.exhibitionHalls,
            icon: Icons.storefront_outlined,
            javaScript: 'window.FloorPlan3D.highlightExhibitionHalls()',
          ),
          _VenueMapControl(
            label: controls.highlight.grandHalls,
            icon: Icons.meeting_room_outlined,
            javaScript: 'window.FloorPlan3D.highlightGrandHalls()',
          ),
          _VenueMapControl(
            label: controls.highlight.toilets,
            icon: Icons.wc,
            javaScript: 'window.FloorPlan3D.highlightToilets()',
          ),
          _VenueMapControl(
            label: controls.highlight.elevators,
            icon: Icons.elevator_outlined,
            javaScript: 'window.FloorPlan3D.highlightElevators()',
          ),
          _VenueMapControl(
            label: controls.highlight.entrance,
            icon: Icons.login,
            javaScript: 'window.FloorPlan3D.highlightEntranceArea()',
          ),
        ],
      ),
      _VenueMapControlGroup(
        label: controls.labels.title,
        controls: [
          _VenueMapControl(
            label: controls.labels.hide,
            icon: Icons.label_off_outlined,
            javaScript: 'window.FloorPlan3D.hideAllLabels()',
          ),
          _VenueMapControl(
            label: controls.labels.show,
            icon: Icons.label_outline,
            javaScript: 'window.FloorPlan3D.showAllLabels()',
          ),
          _VenueMapControl(
            label: controls.labels.decreaseSize,
            icon: Icons.text_decrease,
            javaScript: 'void window.FloorPlan3D.decreaseLabelSize()',
          ),
          _VenueMapControl(
            label: controls.labels.increaseSize,
            icon: Icons.text_increase,
            javaScript: 'void window.FloorPlan3D.increaseLabelSize()',
          ),
        ],
      ),
    ];
  }
}

class _VenueMapControlGroupWidget extends StatelessWidget {
  const _VenueMapControlGroupWidget({
    required this.group,
    required this.enabled,
    required this.onCommand,
  });

  final _VenueMapControlGroup group;
  final bool enabled;
  final ValueChanged<String> onCommand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          group.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final control in group.controls) ...[
              _VenueMapControlButtonWidget(
                control: control,
                enabled: enabled,
                onCommand: onCommand,
              ),
              if (control != group.controls.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _VenueMapControlButtonWidget extends StatelessWidget {
  const _VenueMapControlButtonWidget({
    required this.control,
    required this.enabled,
    required this.onCommand,
  });

  final _VenueMapControl control;
  final bool enabled;
  final ValueChanged<String> onCommand;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: enabled
          ? () async {
              await _ensureFullyVisible(context);
              if (!context.mounted) {
                return;
              }
              onCommand(control.javaScript);
            }
          : null,
      icon: Icon(control.icon, size: 18),
      label: Text(
        control.label,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _ensureFullyVisible(BuildContext context) async {
    const duration = Duration(milliseconds: 180);
    const curve = Curves.easeOutCubic;

    await Scrollable.ensureVisible(
      context,
      duration: duration,
      curve: curve,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
    if (!context.mounted) {
      return;
    }
    await Scrollable.ensureVisible(
      context,
      duration: duration,
      curve: curve,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }
}

class _VenueMapControlGroup {
  const _VenueMapControlGroup({
    required this.label,
    required this.controls,
  });

  final String label;
  final List<_VenueMapControl> controls;
}

class _VenueMapControl {
  const _VenueMapControl({
    required this.label,
    required this.icon,
    required this.javaScript,
  });

  final String label;
  final IconData icon;
  final String javaScript;
}
