import 'dart:math' as math;

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/session/data/provider/bookmarked_sessions_provider.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:app/feature/session/util/session_language.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _timeRailWidth = 58.0;
const _roomHeaderHeight = 48.0;
const _roomColumnWidth = 216.0;
const _roomLaneWidth = 184.0;
const _minuteHeight = 2.0;
const _minimumEntryHeight = 28.0;
const _entryGap = 4.0;

class SessionTimetableRoomTimelineWidget extends StatelessWidget {
  const SessionTimetableRoomTimelineWidget({
    required this.day,
    super.key,
  });

  final SessionTimetableDay day;

  @override
  Widget build(BuildContext context) {
    if (day.entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final locale = Localizations.localeOf(context);
    final columns = _buildColumns(context, day.entries);
    final range = _TimelineRange.fromEntries(day.entries);
    final gridHeight = range.durationMinutes * _minuteHeight;
    final hourMarkers = range.hourMarkers;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 0, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableColumnWidth = math.max<double>(
            0,
            constraints.maxWidth - _timeRailWidth,
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _timeRailWidth,
                child: Column(
                  children: [
                    const SizedBox(height: _roomHeaderHeight),
                    SizedBox(
                      height: gridHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final marker in hourMarkers)
                            Positioned(
                              top: range.offsetFor(marker) - 9,
                              right: 8,
                              child: Text(
                                _formatWallClock(marker),
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final column in columns)
                        SizedBox(
                          width: _columnWidth(
                            column,
                            minimumWidth: columns.length == 1 ? availableColumnWidth : _roomColumnWidth,
                          ),
                          child: _RoomColumnWidget(
                            column: column,
                            columnWidth: _columnWidth(
                              column,
                              minimumWidth: columns.length == 1 ? availableColumnWidth : _roomColumnWidth,
                            ),
                            range: range,
                            gridHeight: gridHeight,
                            hourMarkers: hourMarkers,
                            locale: locale,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoomColumnWidget extends StatelessWidget {
  const _RoomColumnWidget({
    required this.column,
    required this.columnWidth,
    required this.range,
    required this.gridHeight,
    required this.hourMarkers,
    required this.locale,
  });

  final _RoomColumn column;
  final double columnWidth;
  final _TimelineRange range;
  final double gridHeight;
  final List<DateTime> hourMarkers;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          height: _roomHeaderHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            border: Border(
              left: BorderSide(color: colorScheme.outlineVariant),
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Text(
            column.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: gridHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoomGridPainter(
                    lineOffsets: [
                      for (final marker in hourMarkers) range.offsetFor(marker),
                    ],
                    color: colorScheme.outlineVariant,
                  ),
                ),
              ),
              for (final positionedEntry in column.entries)
                Positioned(
                  top:
                      range.offsetFor(
                        toEventTime(positionedEntry.entry.startsAt),
                      ) +
                      (_entryGap / 2),
                  left: _entryLeft(positionedEntry, columnWidth),
                  right: _entryRight(positionedEntry, columnWidth),
                  height: _entryHeight(positionedEntry.entry),
                  child: _RoomTimelineEntryWidget(
                    entry: positionedEntry.entry,
                    locale: locale,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoomTimelineEntryWidget extends ConsumerWidget {
  const _RoomTimelineEntryWidget({
    required this.entry,
    required this.locale,
  });

  final SessionTimetableEntry entry;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final session = entry.session;
    final title = session?.title.resolve(locale) ?? entry.timelineEvent!.title.resolve(locale);
    final languageLabel = session == null ? null : sessionLanguageLabel(session.primaryLocale);
    final bookmarked = switch (ref.watch(bookmarkedSessionIdsProvider)) {
      AsyncData(:final value) when session != null => value.contains(session.id),
      _ => false,
    };

    return Material(
      color: entry.isSession ? colorScheme.surfaceContainerLow : colorScheme.tertiaryContainer,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: entry.isSession ? colorScheme.primary : colorScheme.tertiary,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: session == null ? null : () => SessionDetailsRoute(sessionId: session.id).push<void>(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showMetadata = constraints.maxHeight >= 50;
              final showSpeaker = constraints.maxHeight >= 96 && entry.speakers.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showMetadata)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatEventTimeRange(
                              entry.startsAt,
                              entry.endsAt,
                              EventTimeFormat.twentyFourHour,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        if (languageLabel != null) _TinyLanguageTagWidget(label: languageLabel),
                        if (bookmarked) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.bookmark,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  if (showMetadata) const SizedBox(height: 3),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: showSpeaker ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (showSpeaker)
                    Text(
                      entry.speakers.first.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TinyLanguageTagWidget extends StatelessWidget {
  const _TinyLanguageTagWidget({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RoomGridPainter extends CustomPainter {
  const _RoomGridPainter({
    required this.lineOffsets,
    required this.color,
  });

  final List<double> lineOffsets;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
    for (final offset in lineOffsets) {
      canvas.drawLine(Offset(0, offset), Offset(size.width, offset), paint);
    }
  }

  @override
  bool shouldRepaint(_RoomGridPainter oldDelegate) {
    return color != oldDelegate.color || lineOffsets != oldDelegate.lineOffsets;
  }
}

final class _RoomColumn {
  const _RoomColumn({
    required this.label,
    required this.entries,
  });

  final String label;
  final List<_PositionedRoomEntry> entries;

  int get maximumLaneCount => entries.fold(
    1,
    (maximum, positionedEntry) => math.max(
      maximum,
      positionedEntry.laneCount,
    ),
  );
}

final class _PositionedRoomEntry {
  const _PositionedRoomEntry({
    required this.entry,
    required this.lane,
    required this.laneCount,
  });

  final SessionTimetableEntry entry;
  final int lane;
  final int laneCount;
}

final class _TimelineRange {
  const _TimelineRange({
    required this.start,
    required this.end,
  });

  factory _TimelineRange.fromEntries(List<SessionTimetableEntry> entries) {
    final localStarts = [for (final entry in entries) toEventTime(entry.startsAt)]..sort();
    final localEnds = [
      for (final entry in entries) toEventTime(entry.endsAt ?? entry.startsAt.add(const Duration(minutes: 30))),
    ]..sort();
    final earliest = localStarts.first;
    final latest = localEnds.last;
    final start = DateTime.utc(
      earliest.year,
      earliest.month,
      earliest.day,
      earliest.hour,
    );
    final end = latest.minute == 0 && latest.second == 0
        ? latest
        : DateTime.utc(
            latest.year,
            latest.month,
            latest.day,
            latest.hour + 1,
          );

    return _TimelineRange(start: start, end: end);
  }

  final DateTime start;
  final DateTime end;

  int get durationMinutes => math.max(60, end.difference(start).inMinutes);

  List<DateTime> get hourMarkers => [
    for (var marker = start; !marker.isAfter(end); marker = marker.add(const Duration(hours: 1))) marker,
  ];

  double offsetFor(DateTime value) => value.difference(start).inMinutes * _minuteHeight;
}

List<_RoomColumn> _buildColumns(
  BuildContext context,
  List<SessionTimetableEntry> entries,
) {
  final t = Translations.of(context);
  final locale = Localizations.localeOf(context);
  final entriesByVenueId = <String?, List<SessionTimetableEntry>>{};

  for (final entry in entries) {
    entriesByVenueId.putIfAbsent(entry.venueId, () => []).add(entry);
  }
  final venueGroups = entriesByVenueId.entries.toList()..sort(_compareVenueGroups);

  return [
    for (final venueGroup in venueGroups)
      _RoomColumn(
        label: switch ((
          venueGroup.value.first.venueId,
          venueGroup.value.first.venue,
        )) {
          (null, _) => t.sessionTimetable.view.shared,
          (_, final venue?) => venue.name.resolve(locale),
          _ => t.sessionTimetable.venue.unknown,
        },
        entries: _positionEntries(venueGroup.value),
      ),
  ];
}

int _compareVenueGroups(
  MapEntry<String?, List<SessionTimetableEntry>> a,
  MapEntry<String?, List<SessionTimetableEntry>> b,
) {
  if (a.key == null) {
    return b.key == null ? 0 : -1;
  }
  if (b.key == null) {
    return 1;
  }

  final aVenueOrder = a.value.first.venue?.order ?? 1 << 30;
  final bVenueOrder = b.value.first.venue?.order ?? 1 << 30;
  final orderCompare = aVenueOrder.compareTo(bVenueOrder);
  if (orderCompare != 0) {
    return orderCompare;
  }

  return a.key!.compareTo(b.key!);
}

List<_PositionedRoomEntry> _positionEntries(
  List<SessionTimetableEntry> entries,
) {
  final sortedEntries = [...entries]
    ..sort((a, b) {
      final startCompare = a.startsAt.compareTo(b.startsAt);
      if (startCompare != 0) {
        return startCompare;
      }
      return _entryEnd(a).compareTo(_entryEnd(b));
    });
  final groups = <List<SessionTimetableEntry>>[];
  var groupEnd = DateTime.fromMillisecondsSinceEpoch(0);

  for (final entry in sortedEntries) {
    if (groups.isEmpty || !entry.startsAt.isBefore(groupEnd)) {
      groups.add([entry]);
      groupEnd = _entryEnd(entry);
      continue;
    }

    groups.last.add(entry);
    final entryEnd = _entryEnd(entry);
    if (entryEnd.isAfter(groupEnd)) {
      groupEnd = entryEnd;
    }
  }

  return [
    for (final group in groups) ..._positionGroup(group),
  ];
}

List<_PositionedRoomEntry> _positionGroup(
  List<SessionTimetableEntry> entries,
) {
  final laneEnds = <DateTime>[];
  final assignments = <({SessionTimetableEntry entry, int lane})>[];

  for (final entry in entries) {
    final reusableLane = laneEnds.indexWhere(
      (laneEnd) => !laneEnd.isAfter(entry.startsAt),
    );
    final lane = reusableLane < 0 ? laneEnds.length : reusableLane;
    if (reusableLane < 0) {
      laneEnds.add(_entryEnd(entry));
    } else {
      laneEnds[lane] = _entryEnd(entry);
    }
    assignments.add((entry: entry, lane: lane));
  }

  return [
    for (final assignment in assignments)
      _PositionedRoomEntry(
        entry: assignment.entry,
        lane: assignment.lane,
        laneCount: laneEnds.length,
      ),
  ];
}

double _entryHeight(SessionTimetableEntry entry) {
  final durationMinutes = _entryEnd(entry).difference(entry.startsAt).inMinutes;
  return math.max(_minimumEntryHeight, durationMinutes * _minuteHeight - _entryGap);
}

DateTime _entryEnd(SessionTimetableEntry entry) {
  return entry.endsAt ?? entry.startsAt.add(const Duration(minutes: 30));
}

double _columnWidth(
  _RoomColumn column, {
  required double minimumWidth,
}) {
  return math.max<double>(
    minimumWidth,
    column.maximumLaneCount * _roomLaneWidth,
  );
}

double _entryLeft(
  _PositionedRoomEntry entry,
  double columnWidth,
) {
  final laneWidth = columnWidth / entry.laneCount;
  return entry.lane * laneWidth + _entryGap;
}

double _entryRight(
  _PositionedRoomEntry entry,
  double columnWidth,
) {
  final laneWidth = columnWidth / entry.laneCount;
  return columnWidth - ((entry.lane + 1) * laneWidth) + _entryGap;
}

String _formatWallClock(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
