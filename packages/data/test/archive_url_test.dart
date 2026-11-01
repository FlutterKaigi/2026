import 'package:data/data.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('youtubeArchiveUri', () {
    for (final value in [
      'https://www.youtube.com/watch?v=video&t=30',
      'https://youtube.com/live/video',
      'https://m.youtube.com/shorts/video',
      'https://music.youtube.com/watch?v=video',
      'https://youtu.be/video?t=30',
      'https://www.youtube-nocookie.com/embed/video',
    ]) {
      test('accepts $value', () => expect(youtubeArchiveUri(' $value '), Uri.parse(value)));
    }
    for (final value in <String?>[
      null,
      '',
      '  ',
      'not a URL',
      'http://youtu.be/video',
      'javascript:alert(1)',
      'https://youtube.com.example.com/watch?v=x',
      'https://example.com/?url=https://youtube.com/watch?v=x',
      'https://user@youtube.com/watch?v=x',
      'https://youtube.com:8443/watch?v=x',
      'https://unknown.youtube.com/watch?v=x',
      'https://youtu.be/video with spaces',
    ]) {
      test('rejects $value', () => expect(youtubeArchiveUri(value), isNull));
    }
  });

  final now = DateTime.utc(2026, 10, 29);
  final session = Session(
    id: 'session',
    title: const LocaleMap(ja: 'セッション', en: 'Session'),
    description: const LocaleMap(ja: '説明', en: 'Description'),
    primaryLocale: 'ja',
    startsAt: now,
    endsAt: now.add(const Duration(hours: 1)),
    venueId: 'venue',
    createdAt: now,
    updatedAt: now,
  );
  final event = TimelineEvent(
    id: 'event',
    title: const LocaleMap(ja: 'イベント', en: 'Event'),
    startsAt: now,
    createdAt: now,
    updatedAt: now,
  );

  test('legacy documents without archiveUrl deserialize', () {
    expect(Session.fromJson({...session.toJson()}..remove('archiveUrl')).archiveUrl, isNull);
    expect(TimelineEvent.fromJson({...event.toJson()}..remove('archiveUrl')).archiveUrl, isNull);
    expect(Session.fromJson({...session.toJson(), 'archiveUrl': null}).archiveUrl, isNull);
    expect(TimelineEvent.fromJson({...event.toJson(), 'archiveUrl': null}).archiveUrl, isNull);
  });

  test('session archive URL survives save/read and can be cleared', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreSessionRepository(firestore: firestore);
    const url = 'https://youtu.be/session';
    await repository.save(session.copyWith(id: '', archiveUrl: url));
    final saved = (await repository.watchAll().first).single;
    expect(saved.archiveUrl, url);
    await repository.save(saved.copyWith(archiveUrl: null));
    expect((await repository.watchAll().first).single.archiveUrl, isNull);
    expect((await firestore.collection('sessions').doc(saved.id).get()).data()!['archiveUrl'], isNull);
  });

  test('timeline event archive URL survives save/read and can be cleared', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreTimelineEventRepository(firestore: firestore);
    const url = 'https://youtube.com/live/event';
    await repository.save(event.copyWith(id: '', archiveUrl: url));
    final saved = (await repository.watchAll().first).single;
    expect(saved.archiveUrl, url);
    await repository.save(saved.copyWith(archiveUrl: null));
    expect((await repository.watchAll().first).single.archiveUrl, isNull);
    expect((await firestore.collection('timelineEvents').doc(saved.id).get()).data()!['archiveUrl'], isNull);
  });
}
