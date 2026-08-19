import 'dart:math' as math;

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/session_card_widget.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:flutter/material.dart';

const _entryContentGap = 12.0;
const _entryBottomSpacing = 16.0;
const _timeLabelTopPadding = 4.0;
const _timelineGapAfterTimeLabel = 6.0;
const _timeColumnSafetyMargin = 4.0;

class SessionTimetableDayContentWidget extends StatelessWidget {
  const SessionTimetableDayContentWidget({
    required this.day,
    super.key,
  });

  final SessionTimetableDay day;

  @override
  Widget build(BuildContext context) {
    final entryGroups = day.entryGroups;
    const timeFormat = EventTimeFormat.twentyFourHour;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final textDirection = Directionality.of(context);
    final timeLabelStyle = _timeLabelTextStyle(context);
    final timeLabels = [
      for (final entries in entryGroups)
        formatEventTime(
          entries.first.startsAt,
          timeFormat,
          locale: locale,
        ),
    ];
    final timeColumnWidth =
        _measureWidestTimeLabelWidth(
          context: context,
          labels: timeLabels.toSet(),
          style: timeLabelStyle,
          textDirection: textDirection,
        ) +
        _timeColumnSafetyMargin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: Theme.of(context).colorScheme.outlineVariant,
          thickness: 1,
          height: 1,
          indent: 0,
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < entryGroups.length; index++)
          _TimetableEntryGroupTileWidget(
            entries: entryGroups[index],
            isLast: index == entryGroups.length - 1,
            timeLabel: timeLabels[index],
            timeFormat: timeFormat,
            timeColumnWidth: timeColumnWidth,
          ),
      ],
    );
  }
}

class _TimetableEntryGroupTileWidget extends StatelessWidget {
  const _TimetableEntryGroupTileWidget({
    required this.entries,
    required this.isLast,
    required this.timeLabel,
    required this.timeFormat,
    required this.timeColumnWidth,
  });

  final List<SessionTimetableEntry> entries;
  final bool isLast;
  final String timeLabel;
  final EventTimeFormat timeFormat;
  final double timeColumnWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final firstEntry = entries.first;
    final textDirection = Directionality.of(context);
    final timeLabelStyle = _timeLabelTextStyle(context);
    final lineStartY =
        _timeLabelTopPadding +
        _measureTextHeight(
          context: context,
          text: timeLabel,
          style: timeLabelStyle,
          maxWidth: timeColumnWidth,
          textDirection: textDirection,
        ) +
        _timelineGapAfterTimeLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomPaint(
        painter: _TimelineConnectorPainterWidget(
          color: colorScheme.outlineVariant,
          showConnector: !isLast,
          textDirection: textDirection,
          timeColumnWidth: timeColumnWidth,
          lineStartY: lineStartY,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: timeColumnWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: _timeLabelTopPadding),
                child: Text(
                  timeLabel,
                  textAlign: TextAlign.center,
                  style: timeLabelStyle,
                ),
              ),
            ),
            const SizedBox(width: _entryContentGap),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: _entryBottomSpacing),
                child: entries.length == 1
                    ? _TimetableEntryCardWidget(
                        entry: firstEntry,
                        timeFormat: timeFormat,
                      )
                    : _ParallelTimetableEntriesColumnWidget(
                        entries: entries,
                        timeFormat: timeFormat,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineConnectorPainterWidget extends CustomPainter {
  const _TimelineConnectorPainterWidget({
    required this.color,
    required this.showConnector,
    required this.textDirection,
    required this.timeColumnWidth,
    required this.lineStartY,
  });

  final Color color;
  final bool showConnector;
  final TextDirection textDirection;
  final double timeColumnWidth;
  final double lineStartY;

  @override
  void paint(Canvas canvas, Size size) {
    if (!showConnector) {
      return;
    }

    final x = switch (textDirection) {
      TextDirection.ltr => timeColumnWidth / 2,
      TextDirection.rtl => size.width - (timeColumnWidth / 2),
    };

    if (size.height <= lineStartY) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x, lineStartY),
      Offset(x, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TimelineConnectorPainterWidget oldDelegate) {
    return color != oldDelegate.color ||
        showConnector != oldDelegate.showConnector ||
        textDirection != oldDelegate.textDirection ||
        timeColumnWidth != oldDelegate.timeColumnWidth ||
        lineStartY != oldDelegate.lineStartY;
  }
}

class _TimetableEntryCardWidget extends StatelessWidget {
  const _TimetableEntryCardWidget({
    required this.entry,
    required this.timeFormat,
  });

  final SessionTimetableEntry entry;
  final EventTimeFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    return entry.isSession
        ? SessionCardWidget(
            entry: entry,
            timeFormat: timeFormat,
            compact: true,
          )
        : _TimelineEventCardWidget(
            entry: entry,
            timeFormat: timeFormat,
          );
  }
}

class _ParallelTimetableEntriesColumnWidget extends StatelessWidget {
  const _ParallelTimetableEntriesColumnWidget({
    required this.entries,
    required this.timeFormat,
  });

  final List<SessionTimetableEntry> entries;
  final EventTimeFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          _TimetableEntryCardWidget(
            entry: entries[index],
            timeFormat: timeFormat,
          ),
          if (index < entries.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TimelineEventCardWidget extends StatelessWidget {
  const _TimelineEventCardWidget({
    required this.entry,
    required this.timeFormat,
  });

  final SessionTimetableEntry entry;
  final EventTimeFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final timelineEvent = entry.timelineEvent!;

    return _TimetableCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.event_available_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timelineEvent.title.resolve(locale),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChipWidget(
                icon: Icons.sell_outlined,
                label: t.sessionTimetable.type.event,
              ),
              if (entry.venue != null)
                _InfoChipWidget(
                  icon: Icons.meeting_room_outlined,
                  label: entry.venue!.name.resolve(locale),
                ),
              _InfoChipWidget(
                icon: Icons.schedule,
                label: formatEventTimeRange(
                  entry.startsAt,
                  entry.endsAt,
                  timeFormat,
                  locale: locale.toLanguageTag(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimetableCardWidget extends StatelessWidget {
  const _TimetableCardWidget({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class _InfoChipWidget extends StatelessWidget {
  const _InfoChipWidget({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      side: BorderSide(color: colorScheme.outlineVariant),
      visualDensity: VisualDensity.compact,
    );
  }
}

double _measureTextHeight({
  required BuildContext context,
  required String text,
  required TextStyle? style,
  required double maxWidth,
  required TextDirection textDirection,
}) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: style ?? DefaultTextStyle.of(context).style,
    ),
    textAlign: TextAlign.center,
    textDirection: textDirection,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: maxWidth);

  return textPainter.height;
}

double _measureWidestTimeLabelWidth({
  required BuildContext context,
  required Iterable<String> labels,
  required TextStyle? style,
  required TextDirection textDirection,
}) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: labels.join('\n'),
      style: style ?? DefaultTextStyle.of(context).style,
    ),
    textAlign: TextAlign.center,
    textDirection: textDirection,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();

  return textPainter.computeLineMetrics().fold<double>(
    0,
    (width, line) => math.max(width, line.width),
  );
}

TextStyle? _timeLabelTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelLarge?.copyWith(
    fontWeight: FontWeight.w700,
  );
}
