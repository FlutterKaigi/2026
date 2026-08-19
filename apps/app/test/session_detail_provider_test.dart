import 'package:app/feature/session/data/provider/session_detail_provider.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects a session by ID without throwing when missing', () {
    expect(selectSessionById(_sessions, 'session-a'), _sessions.first);
    expect(selectSessionById(_sessions, 'missing'), isNull);
  });

  test('resolves venue and speakers from existing Firestore-backed lists', () {
    final data = buildSessionDetailData(
      session: _sessions.first,
      venues: _venues,
      speakers: _speakers,
    );

    expect(data.session.id, 'session-a');
    expect(data.venue?.id, 'hall-a');
    expect(data.speakers.map((speaker) => speaker.id), ['speaker-a']);
  });
}

final _sessions = [
  Session(
    id: 'session-a',
    title: const LocaleMap(ja: 'セッション A', en: 'Session A'),
    description: const LocaleMap(ja: '説明', en: 'Description'),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 29),
    endsAt: DateTime.utc(2026, 10, 29, 1),
    venueId: 'hall-a',
    speakerIds: const ['speaker-a', 'missing-speaker'],
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

final _venues = [
  Venue(
    id: 'hall-a',
    name: const LocaleMap(ja: 'ホール A', en: 'Hall A'),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

final _speakers = [
  Speaker(
    id: 'speaker-a',
    name: 'Speaker A',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];
