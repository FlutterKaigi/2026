import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/util/window_size.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/data/provider/session_timetable_view_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Keeps the event-day tabs and the layout switcher visible above the
/// swipeable timetable pages.
class SessionTimetableFilterBarWidget extends ConsumerWidget {
  const SessionTimetableFilterBarWidget({
    required this.dates,
    required this.selectedDate,
    this.onDaySelected,
    super.key,
  });

  final List<DateTime> dates;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDaySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dates.isEmpty) {
      return const SizedBox.shrink();
    }

    final t = Translations.of(context);
    final matchedIndex = selectedDate == null ? -1 : dates.indexWhere((date) => _isSameDate(date, selectedDate!));
    final selectedIndex = matchedIndex < 0 ? 0 : matchedIndex;
    // Phones keep the switcher to two icons so the day labels still fit; the
    // tooltips name each layout there.
    final showViewLabels = WindowSize.fromWidth(MediaQuery.sizeOf(context).width) != WindowSize.compact;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<int>(
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: [
                for (var index = 0; index < dates.length; index++)
                  ButtonSegment(
                    value: index,
                    label: Text(
                      t.sessionTimetable.dayButtonLabel(
                        day: index + 1,
                        date: '${dates[index].month}/${dates[index].day}',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              selected: {selectedIndex},
              onSelectionChanged: (selection) {
                final date = dates[selection.single];
                final callback = onDaySelected;
                if (callback != null) {
                  callback(date);
                  return;
                }
                ref.read(sessionTimetableDayFilterProvider.notifier).select(date);
              },
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size(0, 48)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<SessionTimetableViewMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: SessionTimetableViewMode.list,
                icon: const Icon(Icons.view_agenda_outlined),
                label: showViewLabels ? Text(t.sessionTimetable.view.list) : null,
                tooltip: t.sessionTimetable.view.list,
              ),
              ButtonSegment(
                value: SessionTimetableViewMode.rooms,
                icon: const Icon(Icons.view_week_outlined),
                label: showViewLabels ? Text(t.sessionTimetable.view.rooms) : null,
                tooltip: t.sessionTimetable.view.rooms,
              ),
            ],
            selected: {ref.watch(sessionTimetableViewModeProvider)},
            onSelectionChanged: (selection) => unawaited(_selectViewMode(context, ref, selection.single)),
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
              padding: showViewLabels ? null : const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectViewMode(
    BuildContext context,
    WidgetRef ref,
    SessionTimetableViewMode mode,
  ) async {
    try {
      await ref.read(sessionTimetableViewModeProvider.notifier).set(mode);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Translations.of(context).sessionTimetable.view.saveFailed)),
        );
      }
    }
  }
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
