/// The conference timetable is displayed in Japan Standard Time (UTC+9), the
/// event venue's local time. JST does not observe daylight saving time.
const eventTimeZoneOffset = Duration(hours: 9);

/// Available display formats for event-local timetable times.
enum EventTimeFormat {
  twentyFourHour,
  amPm,
}

/// Converts a timestamp to the event-local wall clock time.
DateTime toEventTime(DateTime value) => value.toUtc().add(eventTimeZoneOffset);

/// Returns the event-local calendar day for grouping timetable items.
DateTime eventDateOnly(DateTime value) {
  final eventTime = toEventTime(value);
  return DateTime(eventTime.year, eventTime.month, eventTime.day);
}

/// Formats an event-local time using the selected display format.
String formatEventTime(
  DateTime value,
  EventTimeFormat format, {
  String? locale,
}) {
  final eventTime = toEventTime(value);
  return switch (format) {
    EventTimeFormat.twentyFourHour => _formatTwentyFourHour(eventTime),
    EventTimeFormat.amPm => _formatAmPm(eventTime, locale),
  };
}

/// Formats an event-local time range using the selected display format.
String formatEventTimeRange(
  DateTime startsAt,
  DateTime? endsAt,
  EventTimeFormat format, {
  String? locale,
}) {
  final formattedStart = formatEventTime(startsAt, format, locale: locale);
  if (endsAt == null) {
    return formattedStart;
  }

  return '$formattedStart-${formatEventTime(endsAt, format, locale: locale)}';
}

String _formatTwentyFourHour(DateTime value) {
  return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
}

String _formatAmPm(DateTime value, String? locale) {
  final languageCode = locale?.split(RegExp('[-_]')).first;
  final hour = _twelveHour(value.hour);
  final minute = _twoDigits(value.minute);
  final isAm = value.hour < 12;

  if (languageCode == 'ja') {
    final period = isAm ? '午前' : '午後';
    return '$period$hour:$minute';
  }

  final period = isAm ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

int _twelveHour(int hour) {
  final value = hour % 12;
  return value == 0 ? 12 : value;
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}
