import 'package:app/feature/session/util/event_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats event times in JST with the selected format', () {
    final startsAt = DateTime.utc(2026, 10, 31);
    final endsAt = DateTime.utc(2026, 10, 31, 1, 15);

    expect(
      formatEventTime(startsAt, EventTimeFormat.twentyFourHour),
      '09:00',
    );
    expect(
      formatEventTime(startsAt, EventTimeFormat.amPm, locale: 'en'),
      '9:00 AM',
    );
    expect(
      formatEventTime(endsAt, EventTimeFormat.amPm, locale: 'ja'),
      '午前10:15',
    );
    expect(
      formatEventTimeRange(
        startsAt,
        endsAt,
        EventTimeFormat.twentyFourHour,
      ),
      '09:00-10:15',
    );
  });
}
