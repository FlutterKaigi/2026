import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension TimelineEventDetailsX on TimelineEvent {
  /// The description in [locale], or null when it is blank in both locales.
  String? resolveDescription(Locale locale) {
    final description = this.description?.resolve(locale).trim();
    return description == null || description.isEmpty ? null : description;
  }
}

Future<void> showTimelineEventDetailsDialog(
  BuildContext context, {
  required SessionTimetableEntry entry,
  required String description,
}) {
  final locale = Localizations.localeOf(context);
  final venue = entry.venue;
  final theme = Theme.of(context);

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('timeline-event-details-dialog'),
      scrollable: true,
      title: Text(entry.timelineEvent!.title.resolve(locale)),
      contentTextStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRowWidget(
            icon: Icons.calendar_today_outlined,
            label: DateFormat('yyyy/MM/dd').format(toEventTime(entry.startsAt)),
          ),
          const SizedBox(height: 10),
          _InfoRowWidget(
            icon: Icons.schedule,
            label: formatEventTimeRange(
              entry.startsAt,
              entry.endsAt,
              EventTimeFormat.twentyFourHour,
              locale: locale.toLanguageTag(),
            ),
          ),
          if (venue != null) ...[
            const SizedBox(height: 10),
            _InfoRowWidget(
              icon: Icons.meeting_room_outlined,
              label: venue.name.resolve(locale),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(description),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    ),
  );
}

class _InfoRowWidget extends StatelessWidget {
  const _InfoRowWidget({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    );
  }
}
