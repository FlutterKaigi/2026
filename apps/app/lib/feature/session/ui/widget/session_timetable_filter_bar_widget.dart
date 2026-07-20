import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/session/data/provider/session_time_format.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SessionTimetableDaySelectorBarWidget extends ConsumerWidget {
  const SessionTimetableDaySelectorBarWidget({
    required this.dates,
    required this.selectedDate,
    super.key,
  });

  final List<DateTime> dates;
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < dates.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            _AutoScrollingChoiceChipWidget(
              label: Text(_formatDayButtonLabel(t, index, dates[index])),
              selected: selectedDate != null && _isSameDate(dates[index], selectedDate!),
              onSelected: (_) => ref.read(sessionTimetableDayFilterProvider.notifier).select(dates[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class SessionTimetableVenueFilterBarWidget extends ConsumerWidget {
  const SessionTimetableVenueFilterBarWidget({
    required this.venues,
    required this.selectedVenueId,
    super.key,
  });

  final List<Venue> venues;
  final String? selectedVenueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AutoScrollingChoiceChipWidget(
            label: Text(t.sessionTimetable.venue.all),
            selected: selectedVenueId == null,
            onSelected: (_) => ref.read(sessionTimetableVenueFilterProvider.notifier).select(null),
          ),
          for (final venue in venues) ...[
            const SizedBox(width: 8),
            _AutoScrollingChoiceChipWidget(
              label: Text(venue.name.resolve(locale)),
              selected: selectedVenueId == venue.id,
              onSelected: (_) => ref.read(sessionTimetableVenueFilterProvider.notifier).select(venue.id),
            ),
          ],
        ],
      ),
    );
  }
}

class SessionTimetableTimeFormatSelectorWidget extends ConsumerWidget {
  const SessionTimetableTimeFormatSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final timeFormat = ref.watch(sessionTimeFormatProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AutoScrollingChoiceChipWidget(
            label: Text(t.sessionTimetable.timeFormat.twentyFourHour),
            selected: timeFormat == EventTimeFormat.twentyFourHour,
            onSelected: (_) => unawaited(
              ref.read(sessionTimeFormatProvider.notifier).set(EventTimeFormat.twentyFourHour),
            ),
          ),
          const SizedBox(width: 8),
          _AutoScrollingChoiceChipWidget(
            label: Text(t.sessionTimetable.timeFormat.amPm),
            selected: timeFormat == EventTimeFormat.amPm,
            onSelected: (_) => unawaited(
              ref.read(sessionTimeFormatProvider.notifier).set(EventTimeFormat.amPm),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoScrollingChoiceChipWidget extends StatefulWidget {
  const _AutoScrollingChoiceChipWidget({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  State<_AutoScrollingChoiceChipWidget> createState() => _AutoScrollingChoiceChipWidgetStateWidget();
}

class _AutoScrollingChoiceChipWidgetStateWidget extends State<_AutoScrollingChoiceChipWidget> {
  final _chipKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _chipKey,
      child: ChoiceChip(
        label: widget.label,
        selected: widget.selected,
        onSelected: (selected) {
          widget.onSelected(selected);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }

            final context = _chipKey.currentContext;
            if (context == null) {
              return;
            }

            unawaited(_scrollChipIntoView(context));
          });
        },
      ),
    );
  }
}

String _formatDayButtonLabel(Translations t, int dayIndex, DateTime date) {
  return t.sessionTimetable.dayButtonLabel(
    day: dayIndex + 1,
    date: '${date.month}/${date.day}',
  );
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Future<void> _scrollChipIntoView(BuildContext context) async {
  final scrollable = Scrollable.maybeOf(context);
  if (scrollable == null) {
    return;
  }

  final position = scrollable.position;
  if (position.axisDirection != AxisDirection.left && position.axisDirection != AxisDirection.right) {
    return;
  }

  final chipRenderObject = context.findRenderObject();
  final viewportRenderObject = scrollable.context.findRenderObject();
  if (chipRenderObject is! RenderBox || viewportRenderObject is! RenderBox) {
    return;
  }

  final chipOffset = chipRenderObject.localToGlobal(Offset.zero);
  final viewportOffset = viewportRenderObject.localToGlobal(Offset.zero);
  final chipStart = chipOffset.dx - viewportOffset.dx;
  final chipEnd = chipStart + chipRenderObject.size.width;
  final viewportWidth = viewportRenderObject.size.width;

  var targetOffset = position.pixels;
  if (chipStart < 0) {
    targetOffset += chipStart;
  } else if (chipEnd > viewportWidth) {
    targetOffset += chipEnd - viewportWidth;
  } else {
    return;
  }

  final clampedOffset = targetOffset.clamp(position.minScrollExtent, position.maxScrollExtent);
  if ((clampedOffset - position.pixels).abs() < 0.5) {
    return;
  }

  await position.animateTo(
    clampedOffset,
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
  );
}
