import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/session_timetable_day_content_widget.dart';
import 'package:app/feature/session/ui/widget/session_timetable_filter_bar_widget.dart';
import 'package:flutter/material.dart';

class SessionTimetableListWidget extends StatelessWidget {
  const SessionTimetableListWidget({
    required this.data,
    required this.scrollController,
    required this.onRefresh,
    super.key,
  });

  final SessionTimetableData data;
  final ScrollController scrollController;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final selectedDay = data.selectedDay;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (data.availableDates.isNotEmpty)
            SliverToBoxAdapter(
              child: SessionTimetableDaySelectorBarWidget(
                dates: data.availableDates,
                selectedDate: data.selectedDate,
              ),
            ),
          if (data.venues.isNotEmpty)
            SliverToBoxAdapter(
              child: SessionTimetableVenueFilterBarWidget(
                venues: data.venues,
                selectedVenueId: data.selectedVenueId,
              ),
            ),
          const SliverToBoxAdapter(child: SessionTimetableTimeFormatSelectorWidget()),
          if (selectedDay != null)
            SliverToBoxAdapter(
              child: SessionTimetableDayContentWidget(
                day: selectedDay,
                key: ValueKey(selectedDay.date),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
