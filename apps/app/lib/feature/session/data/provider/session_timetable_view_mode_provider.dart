import 'package:app/core/provider/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// How the timetable lays out a day.
enum SessionTimetableViewMode {
  /// Entries listed in time order.
  list,

  /// A grid with a column per room.
  rooms,
}

/// Remembers the timetable layout on this device, so the next launch opens the
/// one the attendee chose last.
class SessionTimetableViewModeNotifier extends Notifier<SessionTimetableViewMode> {
  static const preferencesKey = 'session_timetable_view_mode';

  @override
  SessionTimetableViewMode build() {
    final value = ref.watch(sharedPreferencesProvider).getString(preferencesKey);
    return SessionTimetableViewMode.values.asNameMap()[value] ?? SessionTimetableViewMode.list;
  }

  /// Persists [mode] and switches the timetable to it.
  Future<void> set(SessionTimetableViewMode mode) async {
    final saved = await ref.read(sharedPreferencesProvider).setString(preferencesKey, mode.name);
    if (!saved) {
      throw StateError('Could not persist the timetable view.');
    }
    state = mode;
  }
}

/// Exposes the persisted timetable layout and a setter to change it.
final sessionTimetableViewModeProvider = NotifierProvider<SessionTimetableViewModeNotifier, SessionTimetableViewMode>(
  SessionTimetableViewModeNotifier.new,
);
