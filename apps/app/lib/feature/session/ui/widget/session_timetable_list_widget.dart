import 'dart:async';

import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/session_timetable_day_content_widget.dart';
import 'package:app/feature/session/ui/widget/session_timetable_filter_bar_widget.dart';
import 'package:app/feature/session/ui/widget/session_timetable_room_timeline_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum SessionTimetableViewMode {
  list,
  rooms,
}

class SessionTimetableListWidget extends HookConsumerWidget {
  const SessionTimetableListWidget({
    required this.data,
    required this.viewMode,
    super.key,
  });

  final SessionTimetableData data;
  final SessionTimetableViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedDayIndex(data);
    final currentPageIndex = useState(selectedIndex);
    final pageController = usePageController(
      initialPage: selectedIndex,
    );
    final visiblePageIndex = currentPageIndex.value >= 0 && currentPageIndex.value < data.days.length
        ? currentPageIndex.value
        : selectedIndex;

    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!pageController.hasClients) {
            return;
          }
          currentPageIndex.value = selectedIndex;
          final currentPage = pageController.page?.round();
          if (currentPage == selectedIndex) {
            return;
          }
          unawaited(
            pageController.animateToPage(
              selectedIndex,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            ),
          );
        });
        return null;
      },
      [selectedIndex, data.days.length],
    );

    void selectDay(DateTime date) {
      final index = data.days.indexWhere(
        (day) => _isSameDate(day.date, date),
      );
      if (index < 0) {
        return;
      }
      currentPageIndex.value = index;
      unawaited(
        pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        ),
      );
      ref.read(sessionTimetableDayFilterProvider.notifier).select(date);
    }

    return Column(
      children: [
        SessionTimetableFilterBarWidget(
          dates: data.availableDates,
          selectedDate: data.days[visiblePageIndex].date,
          onDaySelected: selectDay,
        ),
        Expanded(
          child: PageView.builder(
            controller: pageController,
            physics: viewMode == SessionTimetableViewMode.rooms ? const NeverScrollableScrollPhysics() : null,
            itemCount: data.days.length,
            onPageChanged: (index) {
              currentPageIndex.value = index;
              ref.read(sessionTimetableDayFilterProvider.notifier).select(data.days[index].date);
            },
            itemBuilder: (context, index) {
              final day = data.days[index];
              final content = switch (viewMode) {
                SessionTimetableViewMode.list => SessionTimetableDayContentWidget(
                  day: day,
                  key: ValueKey(('list', day.date)),
                ),
                SessionTimetableViewMode.rooms => SessionTimetableRoomTimelineWidget(
                  day: day,
                  key: ValueKey(('rooms', day.date)),
                ),
              };

              return CustomScrollView(
                key: PageStorageKey(('timetable-day', viewMode, day.date)),
                slivers: [
                  SliverToBoxAdapter(child: content),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

int _selectedDayIndex(SessionTimetableData data) {
  final selectedDate = data.selectedDate;
  if (selectedDate == null) {
    return 0;
  }

  final index = data.days.indexWhere(
    (day) =>
        day.date.year == selectedDate.year && day.date.month == selectedDate.month && day.date.day == selectedDate.day,
  );
  return index < 0 ? 0 : index;
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
