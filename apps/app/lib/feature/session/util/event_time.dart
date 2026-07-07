/// The conference timetable is displayed in Japan Standard Time (UTC+9), the
/// event venue's local time. JST does not observe daylight saving time.
const eventTimeZoneOffset = Duration(hours: 9);

/// Converts a timestamp to the event-local wall clock time.
DateTime toEventTime(DateTime value) => value.toUtc().add(eventTimeZoneOffset);

/// Returns the event-local calendar day for grouping timetable items.
DateTime eventDateOnly(DateTime value) {
  final eventTime = toEventTime(value);
  return DateTime(eventTime.year, eventTime.month, eventTime.day);
}
