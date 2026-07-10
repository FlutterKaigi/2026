import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Reads and persists the user's preferred session timetable time format.
class SessionTimeFormatNotifier extends Notifier<EventTimeFormat> {
  static const _prefsKey = 'session_time_format';

  @override
  EventTimeFormat build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(_prefsKey);
    return EventTimeFormat.values.asNameMap()[stored] ?? EventTimeFormat.twentyFourHour;
  }

  /// Updates the active [EventTimeFormat] and persists the choice.
  Future<void> set(EventTimeFormat format) async {
    await ref.read(sharedPreferencesProvider).setString(_prefsKey, format.name);
    state = format;
  }
}

/// Exposes the persisted session timetable time format.
final sessionTimeFormatProvider = NotifierProvider<SessionTimeFormatNotifier, EventTimeFormat>(
  SessionTimeFormatNotifier.new,
);
