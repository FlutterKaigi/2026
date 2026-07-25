import 'package:app/feature/session/data/provider/session_repository.dart';
import 'package:app/feature/session/data/provider/session_timetable_repository.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Streams the raw Firestore `sessions` collection as [Session] models.
final sessionListProvider = StreamProvider<List<Session>>(
  (ref) => ref.watch(sessionRepositoryProvider).watchAll(),
);

/// Streams timeline events sorted by start time.
final sessionTimelineEventListProvider = StreamProvider<List<TimelineEvent>>(
  (ref) => ref.watch(sessionTimetableTimelineEventRepositoryProvider).watchAll(),
);

/// Streams venues used to resolve timetable venue labels.
final sessionVenueListProvider = StreamProvider<List<Venue>>(
  (ref) => ref.watch(sessionTimetableVenueRepositoryProvider).watchAll(),
);

/// Streams speakers used to resolve session speaker labels.
final sessionSpeakerListProvider = StreamProvider<List<Speaker>>(
  (ref) => ref.watch(sessionTimetableSpeakerRepositoryProvider).watchAll(),
);

/// Holds the selected event date. `null` means the first available event day.
class SessionTimetableDayFilterNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  /// Selects an event-local calendar day.
  void select(DateTime date) => state = _dateOnly(date);
}

/// Exposes the selected event date for the timetable.
final sessionTimetableDayFilterProvider = NotifierProvider<SessionTimetableDayFilterNotifier, DateTime?>(
  SessionTimetableDayFilterNotifier.new,
);

/// Combines Firestore collections into the data needed by the timetable UI.
final sessionTimetableProvider = Provider<AsyncValue<SessionTimetableData>>(
  (ref) {
    final sessions = ref.watch(sessionListProvider);
    final timelineEvents = ref.watch(sessionTimelineEventListProvider);
    final venues = ref.watch(sessionVenueListProvider);
    final speakers = ref.watch(sessionSpeakerListProvider);

    return switch ((sessions, timelineEvents, venues, speakers)) {
      (AsyncError(:final error, :final stackTrace), _, _, _) => AsyncError(error, stackTrace),
      (_, AsyncError(:final error, :final stackTrace), _, _) => AsyncError(error, stackTrace),
      (_, _, AsyncError(:final error, :final stackTrace), _) => AsyncError(error, stackTrace),
      (_, _, _, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
      (
        AsyncData(value: final sessionList),
        AsyncData(value: final timelineEventList),
        AsyncData(value: final venueList),
        AsyncData(value: final speakerList),
      ) =>
        AsyncData(
          buildSessionTimetableData(
            sessions: sessionList,
            timelineEvents: timelineEventList,
            venues: venueList,
            speakers: speakerList,
            selectedDate: ref.watch(sessionTimetableDayFilterProvider),
          ),
        ),
      _ => const AsyncLoading(),
    };
  },
);

/// Builds timetable data from loaded Firestore collection snapshots.
SessionTimetableData buildSessionTimetableData({
  required List<Session> sessions,
  required List<TimelineEvent> timelineEvents,
  required List<Venue> venues,
  required List<Speaker> speakers,
  DateTime? selectedDate,
}) {
  final venueById = {for (final venue in venues) venue.id: venue};
  final speakerById = {for (final speaker in speakers) speaker.id: speaker};

  final entries = [
    for (final timelineEvent in timelineEvents)
      SessionTimetableEntry.timelineEvent(
        timelineEvent: timelineEvent,
        venue: venueById[timelineEvent.venueId],
      ),
    for (final session in sessions)
      SessionTimetableEntry.session(
        session: session,
        venue: venueById[session.venueId],
        speakers: [
          for (final speakerId in session.speakerIds)
            if (speakerById[speakerId] != null) speakerById[speakerId]!,
        ],
      ),
  ]..sort((a, b) => compareSessionTimetableEntries(a, b, venueById));

  final availableDates = _eventDates(entries);
  final effectiveSelectedDate = _resolveSelectedDate(
    selectedDate,
    availableDates,
  );
  final days = [
    for (final date in availableDates)
      SessionTimetableDay(
        date: date,
        entries: [
          for (final entry in entries)
            if (_isSameDate(eventDateOnly(entry.startsAt), date)) entry,
        ],
      ),
  ];
  final selectedDay = effectiveSelectedDate == null
      ? null
      : days.firstWhere(
          (day) => _isSameDate(day.date, effectiveSelectedDate),
        );

  return SessionTimetableData(
    days: days,
    availableDates: availableDates,
    selectedDate: effectiveSelectedDate,
    selectedDay: selectedDay,
    hasAnyEntries: entries.isNotEmpty,
  );
}

int compareSessionTimetableEntries(
  SessionTimetableEntry a,
  SessionTimetableEntry b,
  Map<String, Venue> venueById,
) {
  final startsAtCompare = a.startsAt.compareTo(b.startsAt);
  if (startsAtCompare != 0) {
    return startsAtCompare;
  }

  final aVenueOrder = venueById[a.venueId]?.order ?? 1 << 30;
  final bVenueOrder = venueById[b.venueId]?.order ?? 1 << 30;
  final venueCompare = aVenueOrder.compareTo(bVenueOrder);
  if (venueCompare != 0) {
    return venueCompare;
  }

  return a.id.compareTo(b.id);
}

List<DateTime> _eventDates(List<SessionTimetableEntry> entries) {
  final dates = <DateTime>[];

  for (final entry in entries) {
    final date = eventDateOnly(entry.startsAt);
    if (dates.isEmpty || !_isSameDate(dates.last, date)) {
      dates.add(date);
    }
  }

  return dates;
}

DateTime? _resolveSelectedDate(DateTime? selectedDate, List<DateTime> availableDates) {
  if (availableDates.isEmpty) {
    return null;
  }

  if (selectedDate != null) {
    final selectedDateOnly = _dateOnly(selectedDate);
    for (final availableDate in availableDates) {
      if (_isSameDate(availableDate, selectedDateOnly)) {
        return availableDate;
      }
    }
  }

  return availableDates.first;
}

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Data prepared for the session timetable page.
final class SessionTimetableData {
  const SessionTimetableData({
    required this.days,
    required this.availableDates,
    required this.selectedDate,
    required this.selectedDay,
    required this.hasAnyEntries,
  });

  final List<SessionTimetableDay> days;
  final List<DateTime> availableDates;
  final DateTime? selectedDate;
  final SessionTimetableDay? selectedDay;
  final bool hasAnyEntries;
}

/// Timetable entries grouped by event-local calendar day.
final class SessionTimetableDay {
  SessionTimetableDay({
    required this.date,
    required this.entries,
  });

  final DateTime date;
  final List<SessionTimetableEntry> entries;

  List<List<SessionTimetableEntry>> get entryGroups {
    final groups = <List<SessionTimetableEntry>>[];

    for (final entry in entries) {
      if (groups.isEmpty || !entry.startsAt.isAtSameMomentAs(groups.last.first.startsAt)) {
        groups.add([entry]);
      } else {
        groups.last.add(entry);
      }
    }

    return [
      for (final group in groups) List<SessionTimetableEntry>.unmodifiable(group),
    ];
  }
}

/// A single row in the timetable.
final class SessionTimetableEntry {
  const SessionTimetableEntry.session({
    required Session this.session,
    required this.venue,
    required this.speakers,
  }) : timelineEvent = null;

  const SessionTimetableEntry.timelineEvent({
    required TimelineEvent this.timelineEvent,
    required this.venue,
  }) : session = null,
       speakers = const [];

  final Session? session;
  final TimelineEvent? timelineEvent;
  final Venue? venue;
  final List<Speaker> speakers;

  String get id => session?.id ?? timelineEvent!.id;
  String? get venueId => session?.venueId ?? timelineEvent!.venueId;
  DateTime get startsAt => session?.startsAt ?? timelineEvent!.startsAt;
  DateTime? get endsAt => session?.endsAt ?? timelineEvent!.endsAt;
  bool get isSession => session != null;
}
