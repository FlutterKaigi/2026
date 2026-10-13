import 'dart:math' as math;

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/session/data/provider/bookmarked_sessions_provider.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/session_speaker_widget.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:app/feature/session/util/session_language.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _sidePadding = 8.0;
const _timeColumnWidth = 64.0;
const _minimumRoomColumnWidth = 216.0;
// The cell and card paddings on both sides of a band's label.
const _bandLabelInset = 2 * (6 + 8);

/// A room-oriented schedule grid.
///
/// Every start and end time of the day is a row boundary, as on the website
/// timetable (`tool/generate_sessions.dart`), and each entry spans the rows
/// from its start to its end. A 30-minute talk therefore runs alongside the
/// three 10-minute LTs next to it instead of ending where the first LT does.
/// Rows size themselves to their content rather than to a pixel-per-minute
/// scale, which keeps every title and speaker readable without letting short
/// or overlapping sessions paint over each other.
///
/// The widget scrolls the day itself so the hall names stay pinned above the
/// grid, while the time column stays pinned as the rooms scroll sideways.
class SessionTimetableRoomTimelineWidget extends HookWidget {
  const SessionTimetableRoomTimelineWidget({
    required this.day,
    this.scrollStorageKey,
    super.key,
  });

  final SessionTimetableDay day;

  /// Keys the vertical scroll view, so its position comes back when the
  /// attendee returns to this day.
  final Key? scrollStorageKey;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final scrollOffset = useValueNotifier<double>(0);
    final headerDrag = useRef<Drag?>(null);
    useEffect(
      () {
        void updateScrollOffset() => scrollOffset.value = scrollController.offset;
        scrollController.addListener(updateScrollOffset);
        return () => scrollController.removeListener(updateScrollOffset);
      },
      [scrollController, scrollOffset],
    );
    if (day.entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final columns = _buildRoomColumns(context, day.entries);
    final schedule = _buildRoomSchedule(day.entries, columns);
    final colorScheme = Theme.of(context).colorScheme;

    // Measured outside the vertical scroll view, so scrolling the day does not
    // rebuild the grid.
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableRoomWidth = constraints.maxWidth.isFinite
            ? math.max<double>(0, constraints.maxWidth - 2 * _sidePadding - _timeColumnWidth)
            : _minimumRoomColumnWidth * columns.length;
        final roomColumnWidth = math.max<double>(
          _minimumRoomColumnWidth,
          availableRoomWidth / columns.length,
        );
        final visibleRoomWidth = math.min(availableRoomWidth, roomColumnWidth * columns.length);
        final columnWidths = [
          _timeColumnWidth,
          for (var index = 0; index < columns.length; index++) roomColumnWidth,
        ];

        return CustomScrollView(
          key: scrollStorageKey,
          slivers: [
            PinnedHeaderSliver(
              child: ColoredBox(
                color: colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
                  // The hall names sit outside the rooms' horizontal scroll
                  // view, so they follow its offset and hand sideways drags to
                  // it.
                  child: GestureDetector(
                    onHorizontalDragStart: (details) {
                      if (scrollController.hasClients) {
                        headerDrag.value = scrollController.position.drag(details, () => headerDrag.value = null);
                      }
                    },
                    onHorizontalDragUpdate: (details) => headerDrag.value?.update(details),
                    onHorizontalDragEnd: (details) => headerDrag.value?.end(details),
                    onHorizontalDragCancel: () => headerDrag.value?.cancel(),
                    child: _ScrollMirrorWidget(
                      scrollOffset: scrollOffset,
                      width: _sum(columnWidths),
                      child: _RowSpanGrid(
                        columnWidths: columnWidths,
                        rowCount: 1,
                        children: [
                          _RowSpanGridCell(
                            key: const ValueKey('room-schedule-time-header'),
                            column: 0,
                            startRow: 0,
                            endRow: 1,
                            child: _PinnedTimeCellWidget(
                              scrollOffset: scrollOffset,
                              backgroundColor: colorScheme.surfaceContainerHigh,
                              isHeader: true,
                              child: const _TimeHeaderCellWidget(),
                            ),
                          ),
                          for (var index = 0; index < columns.length; index++)
                            _RowSpanGridCell(
                              key: ValueKey(('room-schedule-room-header', index)),
                              column: index + 1,
                              startRow: 0,
                              endRow: 1,
                              child: _ClippedRoomCellWidget(
                                scrollOffset: scrollOffset,
                                roomOffset: index * roomColumnWidth,
                                backgroundColor: colorScheme.surfaceContainerHigh,
                                isHeader: true,
                                child: _RoomHeaderCellWidget(label: columns[index].label),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(_sidePadding, 0, _sidePadding, 48),
              sliver: SliverToBoxAdapter(
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (notification) {
                    // Resizing can clamp the offset without notifying the controller.
                    scrollOffset.value = notification.metrics.pixels;
                    return false;
                  },
                  child: SingleChildScrollView(
                    key: ValueKey(('room-schedule-scroll', day.date)),
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: _RowSpanGrid(
                      columnWidths: columnWidths,
                      rowCount: schedule.rowStarts.length,
                      children: [
                        // Bands go before the rooms: an entry overlapping a band
                        // from its very start, which the band cannot stop short
                        // of, is then drawn on top of it, as on the website.
                        for (final band in schedule.bands)
                          _RowSpanGridCell(
                            key: ValueKey(('room-schedule-band', band.startRow)),
                            column: 1,
                            columnSpan: columns.length,
                            startRow: band.startRow,
                            endRow: band.endRow,
                            child: _ClippedRoomCellWidget(
                              scrollOffset: scrollOffset,
                              roomOffset: 0,
                              child: _ScheduleCellWidget(
                                entries: band.entries,
                                followScrollOffset: scrollOffset,
                                visibleWidth: visibleRoomWidth,
                              ),
                            ),
                          ),
                        for (var row = 0; row < schedule.rowStarts.length; row++)
                          _RowSpanGridCell(
                            key: ValueKey(('room-schedule-time', row)),
                            column: 0,
                            startRow: row,
                            endRow: row + 1,
                            child: _PinnedTimeCellWidget(
                              scrollOffset: scrollOffset,
                              backgroundColor: colorScheme.surface,
                              child: _TimeCellWidget(startsAt: schedule.rowStarts[row]),
                            ),
                          ),
                        for (var roomIndex = 0; roomIndex < columns.length; roomIndex++)
                          for (final block in schedule.roomBlocks[roomIndex])
                            _RowSpanGridCell(
                              key: ValueKey(('room-schedule-cell', roomIndex, block.startRow)),
                              column: roomIndex + 1,
                              startRow: block.startRow,
                              endRow: block.endRow,
                              child: _ClippedRoomCellWidget(
                                scrollOffset: scrollOffset,
                                roomOffset: roomIndex * roomColumnWidth,
                                child: _ScheduleCellWidget(entries: block.entries),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shows [child], laid out [width] wide, scrolled sideways by [scrollOffset]
/// in step with the rooms' scroll view below it.
class _ScrollMirrorWidget extends StatelessWidget {
  const _ScrollMirrorWidget({
    required this.scrollOffset,
    required this.width,
    required this.child,
  });

  final ValueListenable<double> scrollOffset;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: width,
        maxWidth: width,
        fit: OverflowBoxFit.deferToChild,
        child: AnimatedBuilder(
          animation: scrollOffset,
          builder: (context, child) => Transform.translate(
            offset: Offset(-scrollOffset.value, 0),
            child: child,
          ),
          child: child,
        ),
      ),
    );
  }
}

// Keep one grid so time labels and room cells share content-driven row heights.
// Counter the horizontal scroll for the time cells and clip rooms at that edge.
class _PinnedTimeCellWidget extends StatelessWidget {
  const _PinnedTimeCellWidget({
    required this.scrollOffset,
    required this.backgroundColor,
    required this.child,
    this.isHeader = false,
  });

  final ValueListenable<double> scrollOffset;
  final Color backgroundColor;
  final Widget child;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(color: Theme.of(context).colorScheme.outlineVariant);
    return AnimatedBuilder(
      animation: scrollOffset,
      builder: (context, child) => Transform.translate(
        offset: Offset(scrollOffset.value, 0),
        child: child,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: isHeader ? borderSide : BorderSide.none,
            left: borderSide,
            right: borderSide,
            bottom: borderSide,
          ),
        ),
        child: Align(alignment: Alignment.topCenter, child: child),
      ),
    );
  }
}

// Room cells fill every row they span, so a session's card covers its time.
class _ClippedRoomCellWidget extends StatelessWidget {
  const _ClippedRoomCellWidget({
    required this.scrollOffset,
    required this.roomOffset,
    required this.child,
    this.backgroundColor,
    this.isHeader = false,
  });

  final ValueListenable<double> scrollOffset;
  final double roomOffset;
  final Widget child;
  final Color? backgroundColor;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(color: Theme.of(context).colorScheme.outlineVariant);
    return ClipRect(
      clipper: _RoomCellClipper(
        scrollOffset: scrollOffset,
        roomOffset: roomOffset,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: isHeader ? borderSide : BorderSide.none,
            right: borderSide,
            bottom: borderSide,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _RoomCellClipper extends CustomClipper<Rect> {
  _RoomCellClipper({
    required this.scrollOffset,
    required this.roomOffset,
  }) : super(reclip: scrollOffset);

  final ValueListenable<double> scrollOffset;
  final double roomOffset;

  @override
  Rect getClip(Size size) {
    final left = (scrollOffset.value - roomOffset).clamp(0.0, size.width);
    return Rect.fromLTRB(left, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(_RoomCellClipper oldClipper) {
    return scrollOffset != oldClipper.scrollOffset || roomOffset != oldClipper.roomOffset;
  }
}

class _TimeHeaderCellWidget extends StatelessWidget {
  const _TimeHeaderCellWidget();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 9),
      child: Icon(Icons.schedule, size: 18),
    );
  }
}

class _RoomHeaderCellWidget extends StatelessWidget {
  const _RoomHeaderCellWidget({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimeCellWidget extends StatelessWidget {
  const _TimeCellWidget({required this.startsAt});

  final DateTime startsAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        _formatWallClock(startsAt),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ScheduleCellWidget extends StatelessWidget {
  const _ScheduleCellWidget({
    required this.entries,
    this.followScrollOffset,
    this.visibleWidth = double.infinity,
  });

  final List<SessionTimetableEntry> entries;

  /// Set for a band, to keep each card's details within the [visibleWidth] of
  /// the rooms on screen however far they are scrolled.
  final ValueListenable<double>? followScrollOffset;
  final double visibleWidth;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final locale = Localizations.localeOf(context);
    final maxContentWidth = math.max<double>(0, visibleWidth - _bandLabelInset);
    return Padding(
      padding: const EdgeInsets.all(6),
      // A lone entry stretches over the rows it spans. Entries overlapping in
      // one room cannot share its timeline, so they stack at the top instead.
      child: entries.length == 1
          ? _RoomScheduleEntryWidget(
              entry: entries.single,
              locale: locale,
              followScrollOffset: followScrollOffset,
              maxContentWidth: maxContentWidth,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  _RoomScheduleEntryWidget(
                    entry: entries[index],
                    locale: locale,
                    followScrollOffset: followScrollOffset,
                    maxContentWidth: maxContentWidth,
                  ),
                  if (index < entries.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _RoomScheduleEntryWidget extends ConsumerWidget {
  const _RoomScheduleEntryWidget({
    required this.entry,
    required this.locale,
    this.followScrollOffset,
    this.maxContentWidth = double.infinity,
  });

  final SessionTimetableEntry entry;
  final Locale locale;
  final ValueListenable<double>? followScrollOffset;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final session = entry.session;
    final title = _entryTitle(entry, locale);
    final languageLabel = session == null ? null : sessionLanguageLabel(session.primaryLocale);
    final bookmarked = switch (ref.watch(bookmarkedSessionIdsProvider)) {
      AsyncData(:final value) when session != null => value.contains(session.id),
      _ => false,
    };
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 4),
        Text(
          key: ValueKey('room-session-title-${entry.id}'),
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (entry.speakers.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (var index = 0; index < entry.speakers.length; index++) ...[
            SessionSpeakerLabelWidget(
              speaker: entry.speakers[index],
              textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (index < entry.speakers.length - 1) const SizedBox(height: 6),
          ],
        ],
      ],
    );

    return Material(
      key: ValueKey('room-timeline-entry-${entry.id}'),
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
          padding: const EdgeInsets.all(8),
          child: switch (followScrollOffset) {
            final scrollOffset? => _ScrollFollowingWidget(
              scrollOffset: scrollOffset,
              maxWidth: maxContentWidth,
              child: details,
            ),
            null => details,
          },
        ),
      ),
    );
  }
}

/// Keeps [child] at the left edge of the rooms on screen while a band wider
/// than the screen scrolls past, so the band's label stays readable.
class _ScrollFollowingWidget extends StatelessWidget {
  const _ScrollFollowingWidget({
    required this.scrollOffset,
    required this.maxWidth,
    required this.child,
  });

  final ValueListenable<double> scrollOffset;
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: AnimatedBuilder(
        animation: scrollOffset,
        builder: (context, child) => Transform.translate(
          offset: Offset(scrollOffset.value, 0),
          child: child,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
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

final class _RoomColumn {
  const _RoomColumn({
    required this.venueId,
    required this.label,
  });

  final String? venueId;
  final String label;
}

/// A day's schedule on a grid whose rows run between consecutive start and end
/// times.
final class _RoomSchedule {
  const _RoomSchedule({
    required this.rowStarts,
    required this.roomBlocks,
    required this.bands,
  });

  /// The event-local time each row starts at. A row ends where the next one
  /// starts; the last row ends with the day's last entry.
  final List<DateTime> rowStarts;

  /// Each room's column split into blocks. Together they cover every row of
  /// the room that no band covers.
  final List<List<_ScheduleBlock>> roomBlocks;

  /// Entries without a room (the lunch break, the party), each drawn across
  /// every room column as on the website.
  final List<_ScheduleBlock> bands;
}

/// Rows [startRow] up to but not including [endRow] of a column, with the
/// entries scheduled there, or none for an empty slot.
final class _ScheduleBlock {
  const _ScheduleBlock({
    required this.startRow,
    required this.endRow,
    this.entries = const [],
  });

  final int startRow;
  final int endRow;
  final List<SessionTimetableEntry> entries;
}

/// Where an entry sits on the grid; `roomIndex` is null for a band.
typedef _EntryPlacement = ({int order, int? roomIndex, int startRow, int endRow, SessionTimetableEntry entry});

List<_RoomColumn> _buildRoomColumns(
  BuildContext context,
  List<SessionTimetableEntry> entries,
) {
  final t = Translations.of(context);
  final locale = Localizations.localeOf(context);
  final entriesByVenueId = <String, List<SessionTimetableEntry>>{};

  for (final entry in entries) {
    if (entry.venueId case final venueId?) {
      entriesByVenueId.putIfAbsent(venueId, () => []).add(entry);
    }
  }
  // Entries without a room run across the room columns, so a day with no room
  // at all still needs one column for them.
  if (entriesByVenueId.isEmpty) {
    return [_RoomColumn(venueId: null, label: t.sessionTimetable.view.shared)];
  }
  final venueGroups = entriesByVenueId.entries.toList()..sort(_compareVenueGroups);

  return [
    for (final venueGroup in venueGroups)
      _RoomColumn(
        venueId: venueGroup.key,
        label: switch (venueGroup.value.first.venue) {
          final venue? => venue.name.resolve(locale),
          null => t.sessionTimetable.venue.unknown,
        },
      ),
  ];
}

int _compareVenueGroups(
  MapEntry<String, List<SessionTimetableEntry>> a,
  MapEntry<String, List<SessionTimetableEntry>> b,
) {
  final orderCompare = (a.value.first.venue?.order ?? 1 << 30).compareTo(
    b.value.first.venue?.order ?? 1 << 30,
  );
  return orderCompare != 0 ? orderCompare : a.key.compareTo(b.key);
}

_RoomSchedule _buildRoomSchedule(
  List<SessionTimetableEntry> entries,
  List<_RoomColumn> columns,
) {
  final roomIndexByVenueId = {for (final (index, column) in columns.indexed) column.venueId: index};
  final roomStarts = [
    for (final entry in entries)
      if (roomIndexByVenueId.containsKey(entry.venueId)) toEventTime(entry.startsAt),
  ];
  final spans = [
    for (final (order, entry) in entries.indexed)
      (
        order: order,
        entry: entry,
        // Entries without a column of their own become bands across every room.
        roomIndex: roomIndexByVenueId[entry.venueId],
        startsAt: toEventTime(entry.startsAt),
        endsAt: _layoutEnd(
          entry,
          isBand: !roomIndexByVenueId.containsKey(entry.venueId),
          roomStarts: roomStarts,
        ),
      ),
  ];
  // Every start and end is a row boundary, so entries share a time axis
  // without having to share a row.
  final ticks = {
    for (final span in spans) ...[span.startsAt, ?span.endsAt],
  }.toList()..sort();
  // The last tick only closes the final row, unless an entry without a usable
  // end starts there and needs a row of its own.
  final rowStarts = [
    for (final tick in ticks)
      if (tick != ticks.last || spans.any((span) => span.startsAt == tick)) tick,
  ];
  final rowByStart = {for (final (row, startsAt) in rowStarts.indexed) startsAt: row};

  final placements = <_EntryPlacement>[
    for (final span in spans)
      (
        order: span.order,
        roomIndex: span.roomIndex,
        startRow: rowByStart[span.startsAt]!,
        endRow: _endRow(rowStarts, rowByStart[span.startsAt]!, span.endsAt),
        entry: span.entry,
      ),
  ];
  List<_ScheduleBlock> blocksOf(int? roomIndex) => _mergeOverlapping(
    [
      for (final placement in placements)
        if (placement.roomIndex == roomIndex) placement,
    ]..sort(_comparePlacements),
  );

  final bands = blocksOf(null);
  final bandRows = {
    for (final band in bands)
      for (var row = band.startRow; row < band.endRow; row++) row,
  };
  return _RoomSchedule(
    rowStarts: rowStarts,
    roomBlocks: [
      for (var roomIndex = 0; roomIndex < columns.length; roomIndex++)
        _withEmptyRows(blocksOf(roomIndex), rowCount: rowStarts.length, bandRows: bandRows),
    ],
    bands: bands,
  );
}

/// Where an entry stops on the grid: its end, or none for an end at or before
/// its start.
///
/// A band is one block across every room, so where a room entry starts during
/// it (the lunch stage opens before the lunch break is over) it stops there, as
/// on the website. Its card still shows the real end time.
DateTime? _layoutEnd(
  SessionTimetableEntry entry, {
  required bool isBand,
  required List<DateTime> roomStarts,
}) {
  final startsAt = toEventTime(entry.startsAt);
  final endsAt = switch (entry.endsAt) {
    final endsAt? when endsAt.isAfter(entry.startsAt) => toEventTime(endsAt),
    _ => null,
  };
  if (!isBand || endsAt == null) {
    return endsAt;
  }
  return roomStarts.fold<DateTime>(
    endsAt,
    (end, roomStart) => roomStart.isAfter(startsAt) && roomStart.isBefore(end) ? roomStart : end,
  );
}

/// The row an entry stops before: the first one starting at or after its end.
/// An entry without a usable end still takes the row it starts in.
int _endRow(List<DateTime> rowStarts, int startRow, DateTime? endsAt) {
  if (endsAt == null) {
    return startRow + 1;
  }
  final endRow = rowStarts.indexWhere((startsAt) => !startsAt.isBefore(endsAt), startRow + 1);
  return endRow < 0 ? rowStarts.length : endRow;
}

int _comparePlacements(_EntryPlacement a, _EntryPlacement b) {
  final startCompare = a.startRow.compareTo(b.startRow);
  return startCompare != 0 ? startCompare : a.order.compareTo(b.order);
}

/// Turns one column's placements, in row order, into blocks spanning their
/// rows. A column cannot show two entries at once, so entries overlapping there
/// share one block spanning all of them instead of painting over each other.
List<_ScheduleBlock> _mergeOverlapping(List<_EntryPlacement> placements) {
  final blocks = <_ScheduleBlock>[];
  var index = 0;
  while (index < placements.length) {
    final startRow = placements[index].startRow;
    var endRow = startRow + 1;
    final entries = <SessionTimetableEntry>[];
    while (index < placements.length && placements[index].startRow < endRow) {
      entries.add(placements[index].entry);
      endRow = math.max(endRow, placements[index].endRow);
      index++;
    }
    blocks.add(_ScheduleBlock(startRow: startRow, endRow: endRow, entries: entries));
  }
  return blocks;
}

/// Adds a single-row empty block for every row of a room that neither its
/// entries nor a band cover, so the grid keeps a line between all rows.
List<_ScheduleBlock> _withEmptyRows(
  List<_ScheduleBlock> blocks, {
  required int rowCount,
  required Set<int> bandRows,
}) {
  final coveredRows = {
    ...bandRows,
    for (final block in blocks)
      for (var row = block.startRow; row < block.endRow; row++) row,
  };
  return [
    ...blocks,
    for (var row = 0; row < rowCount; row++)
      if (!coveredRows.contains(row)) _ScheduleBlock(startRow: row, endRow: row + 1),
  ];
}

/// Lays cells out on a grid whose rows size to their content, like [Table],
/// but lets a cell span several rows, which [Table] cannot.
class _RowSpanGrid extends MultiChildRenderObjectWidget {
  const _RowSpanGrid({
    required this.columnWidths,
    required this.rowCount,
    required super.children,
  });

  final List<double> columnWidths;
  final int rowCount;

  @override
  _RenderRowSpanGrid createRenderObject(BuildContext context) {
    return _RenderRowSpanGrid(columnWidths: columnWidths, rowCount: rowCount);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderRowSpanGrid renderObject) {
    renderObject
      ..columnWidths = columnWidths
      ..rowCount = rowCount;
  }
}

/// Places [child] in the enclosing [_RowSpanGrid], covering [columnSpan]
/// columns from [column] and rows [startRow] up to but not including [endRow].
class _RowSpanGridCell extends ParentDataWidget<_RowSpanGridParentData> {
  const _RowSpanGridCell({
    required this.column,
    required this.startRow,
    required this.endRow,
    required super.child,
    this.columnSpan = 1,
    super.key,
  });

  final int column;
  final int columnSpan;
  final int startRow;
  final int endRow;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData! as _RowSpanGridParentData;
    if (parentData.column == column &&
        parentData.columnSpan == columnSpan &&
        parentData.startRow == startRow &&
        parentData.endRow == endRow) {
      return;
    }
    parentData
      ..column = column
      ..columnSpan = columnSpan
      ..startRow = startRow
      ..endRow = endRow;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _RowSpanGrid;
}

class _RowSpanGridParentData extends ContainerBoxParentData<RenderBox> {
  int column = 0;
  int columnSpan = 1;
  int startRow = 0;
  int endRow = 1;
}

class _RenderRowSpanGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowSpanGridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowSpanGridParentData> {
  _RenderRowSpanGrid({
    required this._columnWidths,
    required this._rowCount,
  });

  List<double> get columnWidths => _columnWidths;
  List<double> _columnWidths;
  set columnWidths(List<double> value) {
    if (listEquals(_columnWidths, value)) {
      return;
    }
    _columnWidths = value;
    markNeedsLayout();
  }

  int get rowCount => _rowCount;
  int _rowCount;
  set rowCount(int value) {
    if (_rowCount == value) {
      return;
    }
    _rowCount = value;
    markNeedsLayout();
  }

  double get _width => _sum(_columnWidths);

  double _cellWidth(_RowSpanGridParentData parentData) {
    return _sum(_columnWidths.getRange(parentData.column, parentData.column + parentData.columnSpan));
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowSpanGridParentData) {
      child.parentData = _RowSpanGridParentData();
    }
  }

  /// Sizes every row so each cell fits in the rows it spans.
  ///
  /// Single-row cells size their row first. A spanning cell then adds only the
  /// height its rows still lack, spread evenly over them. Shorter spans go
  /// first, so a long one (a two-hour workshop) stretches only the rows the
  /// entries beside it left short.
  List<double> _rowHeights(double Function(RenderBox child, double width) measure) {
    final heights = List<double>.filled(_rowCount, 0);
    final spanningCells = <({int startRow, int endRow, double height})>[];
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _RowSpanGridParentData;
      final height = measure(child, _cellWidth(parentData));
      if (parentData.endRow - parentData.startRow == 1) {
        heights[parentData.startRow] = math.max(heights[parentData.startRow], height);
      } else {
        spanningCells.add((startRow: parentData.startRow, endRow: parentData.endRow, height: height));
      }
      child = parentData.nextSibling;
    }
    spanningCells.sort((a, b) {
      final spanCompare = (a.endRow - a.startRow).compareTo(b.endRow - b.startRow);
      return spanCompare != 0 ? spanCompare : a.startRow.compareTo(b.startRow);
    });
    for (final cell in spanningCells) {
      final missingHeight = cell.height - _sum(heights.getRange(cell.startRow, cell.endRow));
      if (missingHeight <= 0) {
        continue;
      }
      for (var row = cell.startRow; row < cell.endRow; row++) {
        heights[row] += missingHeight / (cell.endRow - cell.startRow);
      }
    }
    return heights;
  }

  @override
  double computeMinIntrinsicWidth(double height) => _width;

  @override
  double computeMaxIntrinsicWidth(double height) => _width;

  @override
  double computeMinIntrinsicHeight(double width) {
    return _sum(_rowHeights((child, columnWidth) => child.getMinIntrinsicHeight(columnWidth)));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _sum(_rowHeights((child, columnWidth) => child.getMaxIntrinsicHeight(columnWidth)));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final heights = _rowHeights(
      (child, width) => child.getDryLayout(BoxConstraints.tightFor(width: width)).height,
    );
    return constraints.constrain(Size(_width, _sum(heights)));
  }

  @override
  void performLayout() {
    // Measure every cell at its natural height first, as [RenderTable] does for
    // intrinsic-height cells, then stretch it over the rows it spans.
    final heights = _rowHeights((child, width) {
      child.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      return child.size.height;
    });
    final rowTops = <double>[0];
    for (final height in heights) {
      rowTops.add(rowTops.last + height);
    }
    final columnLefts = <double>[0];
    for (final width in _columnWidths) {
      columnLefts.add(columnLefts.last + width);
    }

    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _RowSpanGridParentData;
      // A minimum height instead of a tight one keeps the cell from becoming a
      // relayout boundary, so content that grows later (a larger text scale)
      // runs this layout again and resizes the rows.
      final width = _cellWidth(parentData);
      child.layout(
        BoxConstraints(
          minWidth: width,
          maxWidth: width,
          minHeight: rowTops[parentData.endRow] - rowTops[parentData.startRow],
        ),
        parentUsesSize: true,
      );
      parentData.offset = Offset(columnLefts[parentData.column], rowTops[parentData.startRow]);
      child = parentData.nextSibling;
    }
    size = constraints.constrain(Size(columnLefts.last, rowTops.last));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

double _sum(Iterable<double> values) => values.fold(0, (total, value) => total + value);

String _entryTitle(SessionTimetableEntry entry, Locale locale) {
  return entry.session?.title.resolve(locale) ?? entry.timelineEvent!.title.resolve(locale);
}

String _formatWallClock(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
