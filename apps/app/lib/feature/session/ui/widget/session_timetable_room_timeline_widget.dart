import 'dart:math' as math;

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/session/data/provider/bookmarked_sessions_provider.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/session_speaker_widget.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:app/feature/session/util/session_language.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _timeColumnWidth = 64.0;
const _minimumRoomColumnWidth = 216.0;

/// A room-oriented schedule table.
///
/// Rows are grouped by start time and size themselves to their content. Unlike
/// a pixel-per-minute timeline, this keeps every title and speaker readable
/// without letting short or overlapping sessions paint over each other.
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

    final columns = _buildRoomColumns(context, day.entries);
    final rows = _buildScheduleRows(day.entries);
    final colorScheme = Theme.of(context).colorScheme;
    final borderSide = BorderSide(color: colorScheme.outlineVariant);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableRoomWidth = constraints.maxWidth.isFinite
              ? math.max<double>(0, constraints.maxWidth - _timeColumnWidth)
              : _minimumRoomColumnWidth * columns.length;
          final roomColumnWidth = math.max<double>(
            _minimumRoomColumnWidth,
            availableRoomWidth / columns.length,
          );
          final tableWidth = _timeColumnWidth + roomColumnWidth * columns.length;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Table(
                columnWidths: {
                  0: const FixedColumnWidth(_timeColumnWidth),
                  for (var index = 0; index < columns.length; index++) index + 1: FixedColumnWidth(roomColumnWidth),
                },
                border: TableBorder(
                  top: borderSide,
                  bottom: borderSide,
                  left: borderSide,
                  right: borderSide,
                  horizontalInside: borderSide,
                  verticalInside: borderSide,
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh),
                    children: [
                      const _TimeHeaderCellWidget(),
                      for (final column in columns) _RoomHeaderCellWidget(label: column.label),
                    ],
                  ),
                  for (final row in rows)
                    TableRow(
                      key: ValueKey('room-schedule-row-${row.startsAt.toIso8601String()}'),
                      children: [
                        _TimeCellWidget(startsAt: row.startsAt),
                        for (final column in columns)
                          _ScheduleCellWidget(
                            entries: [
                              for (final entry in row.entries)
                                if (entry.venueId == column.venueId) entry,
                            ],
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeHeaderCellWidget extends StatelessWidget {
  const _TimeHeaderCellWidget();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
  const _ScheduleCellWidget({required this.entries});

  final List<SessionTimetableEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final locale = Localizations.localeOf(context);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            _RoomScheduleEntryWidget(
              entry: entries[index],
              locale: locale,
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
  });

  final SessionTimetableEntry entry;
  final Locale locale;

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
          child: Column(
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

final class _RoomColumn {
  const _RoomColumn({
    required this.venueId,
    required this.label,
  });

  final String? venueId;
  final String label;
}

final class _ScheduleRow {
  const _ScheduleRow({
    required this.startsAt,
    required this.entries,
  });

  final DateTime startsAt;
  final List<SessionTimetableEntry> entries;
}

List<_RoomColumn> _buildRoomColumns(
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
        venueId: venueGroup.key,
        label: switch ((venueGroup.value.first.venueId, venueGroup.value.first.venue)) {
          (null, _) => t.sessionTimetable.view.shared,
          (_, final venue?) => venue.name.resolve(locale),
          _ => t.sessionTimetable.venue.unknown,
        },
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

  final orderCompare = (a.value.first.venue?.order ?? 1 << 30).compareTo(
    b.value.first.venue?.order ?? 1 << 30,
  );
  return orderCompare != 0 ? orderCompare : a.key!.compareTo(b.key!);
}

List<_ScheduleRow> _buildScheduleRows(List<SessionTimetableEntry> entries) {
  final entriesByStart = <DateTime, List<SessionTimetableEntry>>{};
  for (final entry in entries) {
    final startsAt = toEventTime(entry.startsAt);
    entriesByStart.putIfAbsent(startsAt, () => []).add(entry);
  }
  final startsAtValues = entriesByStart.keys.toList()..sort();

  return [
    for (final startsAt in startsAtValues)
      _ScheduleRow(
        startsAt: startsAt,
        entries: entriesByStart[startsAt]!,
      ),
  ];
}

String _entryTitle(SessionTimetableEntry entry, Locale locale) {
  return entry.session?.title.resolve(locale) ?? entry.timelineEvent!.title.resolve(locale);
}

String _formatWallClock(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
