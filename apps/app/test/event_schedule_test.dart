import 'package:app/core/constants/event_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('switches the conference day at JST midnight', () {
    const justBefore = Duration(milliseconds: 1);
    for (final (now, day) in <(DateTime, EventDay?)>[
      (DateTime.utc(2026, 10, 28, 15).subtract(justBefore), null),
      (DateTime.utc(2026, 10, 28, 15), EventDay.day1),
      (DateTime.utc(2026, 10, 29, 15).subtract(justBefore), EventDay.day1),
      (DateTime.utc(2026, 10, 29, 15), EventDay.day2),
      (DateTime.utc(2026, 10, 30, 15).subtract(justBefore), EventDay.day2),
      (DateTime.utc(2026, 10, 30, 15), null),
    ]) {
      expect(eventDayAt(now), day, reason: '$now');
    }
  });

  test('follows the instant, not the wall clock of the device time zone', () {
    // 10/29 00:30 JST is still 10/28 on a UTC device clock.
    expect(eventDayAt(DateTime.utc(2026, 10, 28, 15, 30).toLocal()), EventDay.day1);
    // 10/31 00:30 JST is still 10/30 on a UTC device clock, but the conference is over.
    expect(eventDayAt(DateTime.utc(2026, 10, 30, 15, 30).toLocal()), isNull);
  });
}
