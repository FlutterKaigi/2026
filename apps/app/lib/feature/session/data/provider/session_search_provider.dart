import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:data/data.dart';

enum SessionSearchTypeFilter {
  all,
  regular,
  lightningTalk,
  beginnersLightningTalk,
}

enum SessionSearchLanguageFilter {
  all,
  ja,
  en,
}

final class SessionSearchCriteria {
  const SessionSearchCriteria({
    this.query = '',
    this.date,
    this.type = SessionSearchTypeFilter.all,
    this.language = SessionSearchLanguageFilter.all,
  });

  final String query;
  final DateTime? date;
  final SessionSearchTypeFilter type;
  final SessionSearchLanguageFilter language;

  bool get hasCriteria =>
      query.trim().isNotEmpty ||
      date != null ||
      type != SessionSearchTypeFilter.all ||
      language != SessionSearchLanguageFilter.all;
}

List<SessionTimetableEntry> buildSessionSearchResults({
  required SessionTimetableData data,
  required SessionSearchCriteria criteria,
}) {
  if (!criteria.hasCriteria) {
    return const [];
  }

  final normalizedQuery = criteria.query.trim().toLowerCase();
  return [
    for (final day in data.days)
      for (final entry in day.entries)
        if (entry.session case final session?)
          if (_matchesDate(entry, criteria.date) &&
              _matchesType(session, criteria.type) &&
              _matchesLanguage(session, criteria.language) &&
              _matchesQuery(entry, normalizedQuery))
            entry,
  ];
}

bool _matchesLanguage(
  Session session,
  SessionSearchLanguageFilter selectedLanguage,
) {
  if (selectedLanguage == SessionSearchLanguageFilter.all) {
    return true;
  }

  final primaryLanguage = session.primaryLocale.trim().split(RegExp('[-_]')).first.toLowerCase();
  return primaryLanguage == selectedLanguage.name;
}

bool _matchesDate(SessionTimetableEntry entry, DateTime? selectedDate) {
  if (selectedDate == null) {
    return true;
  }

  final date = eventDateOnly(entry.startsAt);
  return date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
}

bool _matchesType(Session session, SessionSearchTypeFilter selectedType) {
  if (selectedType == SessionSearchTypeFilter.all) {
    return true;
  }

  return _typeOf(session) == selectedType;
}

SessionSearchTypeFilter _typeOf(Session session) {
  if (session.isBeginnersLightningTalk) {
    return SessionSearchTypeFilter.beginnersLightningTalk;
  }
  if (session.isLightningTalk) {
    return SessionSearchTypeFilter.lightningTalk;
  }
  return SessionSearchTypeFilter.regular;
}

bool _matchesQuery(SessionTimetableEntry entry, String normalizedQuery) {
  if (normalizedQuery.isEmpty) {
    return true;
  }

  final session = entry.session!;
  final searchableText = [
    session.title.ja,
    session.title.en,
    session.description.ja,
    session.description.en,
    for (final speaker in entry.speakers) speaker.name,
  ].join('\n').toLowerCase();

  return searchableText.contains(normalizedQuery);
}
