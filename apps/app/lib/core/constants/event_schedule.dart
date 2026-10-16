/// A conference day on the venue's calendar (JST).
enum EventDay { day1, day2 }

// JST midnights as UTC instants, so a device set to another time zone still
// agrees with the venue on which day it is.
final _day1StartsAt = DateTime.utc(2026, 10, 28, 15);
final _day2StartsAt = DateTime.utc(2026, 10, 29, 15);
final _day2EndsAt = DateTime.utc(2026, 10, 30, 15);
final _guideStartsAt = _day1StartsAt.add(const Duration(hours: 6));

/// The conference day at [now], or `null` before and after the conference.
EventDay? eventDayAt(DateTime now) {
  if (now.isBefore(_day1StartsAt) || !now.isBefore(_day2EndsAt)) {
    return null;
  }
  return now.isBefore(_day2StartsAt) ? EventDay.day1 : EventDay.day2;
}

bool isEventGuideWindow(DateTime now) => !now.isBefore(_guideStartsAt) && now.isBefore(_day2EndsAt);
