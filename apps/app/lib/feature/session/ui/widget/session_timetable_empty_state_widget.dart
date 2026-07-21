import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/session_timetable_filter_bar_widget.dart';
import 'package:flutter/material.dart';

class SessionTimetableEmptyStateWidget extends StatelessWidget {
  const SessionTimetableEmptyStateWidget({
    required this.data,
    required this.scrollController,
    super.key,
  });

  final SessionTimetableData data;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final message = data.hasAnyEntries && data.selectedVenueId != null
        ? t.sessionTimetable.emptyFiltered
        : t.sessionTimetable.empty;

    return ListView(
      controller: scrollController,
      children: [
        if (data.availableDates.isNotEmpty)
          SessionTimetableDaySelectorBarWidget(
            dates: data.availableDates,
            selectedDate: data.selectedDate,
          ),
        if (data.venues.isNotEmpty)
          SessionTimetableVenueFilterBarWidget(
            venues: data.venues,
            selectedVenueId: data.selectedVenueId,
          ),
        const SessionTimetableTimeFormatSelectorWidget(),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
              Icon(
                Icons.event_busy_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
