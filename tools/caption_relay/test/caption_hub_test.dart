import 'package:caption_protocol/caption_protocol.dart';
import 'package:caption_relay/caption_relay.dart';
import 'package:test/test.dart';

void main() {
  final key = const CaptionStreamKey(roomId: 'main', sessionId: 'opening');
  final otherKey = const CaptionStreamKey(roomId: 'sub', sessionId: 'talk');
  final initialTime = DateTime.utc(2026, 11, 7, 1);
  late DateTime now;
  late CaptionHub hub;

  CaptionIngestRequest request({
    CaptionStreamKey? streamKey,
    String utteranceId = 'opening-1',
    int utteranceSequence = 1,
    int revision = 0,
    String translatedText = 'Welcome',
    bool isFinal = true,
    DateTime? sourceStartedAt,
    Duration clearAfter = const Duration(seconds: 8),
  }) {
    final selectedKey = streamKey ?? key;
    return CaptionIngestRequest(
      roomId: selectedKey.roomId,
      sessionId: selectedKey.sessionId,
      utteranceId: utteranceId,
      utteranceSequence: utteranceSequence,
      revision: revision,
      translatedText: translatedText,
      isFinal: isFinal,
      sourceStartedAt: sourceStartedAt ?? now.subtract(const Duration(seconds: 1)),
      clearAfter: clearAfter,
    );
  }

  setUp(() {
    now = initialTime;
    hub = CaptionHub(clock: () => now);
  });

  tearDown(() => hub.close());

  test('publishes monotonically sequenced captions and clear events', () async {
    final events = hub.subscribe(key).take(2).toList();
    final first = hub.publishCaption(request());
    final clear = hub.publishClear(CaptionClearRequest(roomId: key.roomId, sessionId: key.sessionId));

    expect((await events).map((event) => event.type), [CaptionEventType.caption, CaptionEventType.clear]);
    expect(first.sequence, 1);
    expect(first.utteranceId, 'opening-1');
    expect(first.revision, 0);
    expect(clear.sequence, 2);
  });

  test('replays the latest unexpired caption to a new subscriber', () async {
    hub.publishCaption(request(translatedText: 'Still current'));

    expect((await hub.subscribe(key).first).translatedText, 'Still current');
  });

  test('does not replay an expired caption after reconnect', () async {
    hub.publishCaption(request(translatedText: 'Expired', clearAfter: const Duration(seconds: 2)));
    now = now.add(const Duration(seconds: 3));

    final nextEvent = hub
        .subscribe(key)
        .first
        .timeout(const Duration(milliseconds: 10), onTimeout: () => hub.heartbeat(key));

    expect((await nextEvent).type, CaptionEventType.heartbeat);
  });

  test('rejects stale and duplicate revisions for an utterance', () {
    hub.publishCaption(request(revision: 2, isFinal: false));

    expect(() => hub.publishCaption(request(revision: 2, isFinal: false)), throwsFormatException);
    expect(() => hub.publishCaption(request(revision: 1, isFinal: false)), throwsFormatException);

    final next = hub.publishCaption(request(revision: 3, isFinal: false));
    expect(next.revision, 3);
    expect(next.sequence, 2);
  });

  test('never lets a late partial overwrite a final caption', () async {
    final events = <CaptionEvent>[];
    final subscription = hub.subscribe(key).listen(events.add);
    addTearDown(subscription.cancel);
    hub.publishCaption(request(revision: 2));

    expect(() => hub.publishCaption(request(revision: 3, isFinal: false)), throwsFormatException);
    final correctedFinal = hub.publishCaption(
      request(revision: 3, translatedText: 'Corrected final'),
    );

    expect(correctedFinal.translatedText, 'Corrected final');
    expect(events.map((event) => event.translatedText), ['Welcome', 'Corrected final']);
    expect(hub.finalCaptionLatency.count, 1);
  });

  test('requires a stable source start across revisions', () {
    hub.publishCaption(request(isFinal: false));

    expect(
      () => hub.publishCaption(
        request(
          revision: 1,
          sourceStartedAt: now.subtract(const Duration(seconds: 2)),
        ),
      ),
      throwsFormatException,
    );
    expect(hub.finalCaptionLatency.count, 0);
  });

  test('never lets an older utterance overwrite a newer utterance', () {
    hub.publishCaption(
      request(
        utteranceId: 'opening-2',
        utteranceSequence: 2,
        isFinal: false,
      ),
    );

    expect(
      () => hub.publishCaption(
        request(
          utteranceId: 'opening-1',
          utteranceSequence: 1,
          revision: 10,
        ),
      ),
      throwsFormatException,
    );
  });

  test('rejects two utterance IDs claiming the same producer sequence', () {
    hub.publishCaption(request(isFinal: false));

    expect(
      () => hub.publishCaption(
        request(
          utteranceId: 'opening-conflict',
          utteranceSequence: 1,
          revision: 1,
        ),
      ),
      throwsFormatException,
    );
  });

  test('clear makes the displayed utterance terminal while its stream is active', () async {
    final subscription = hub.subscribe(key).listen((_) {});
    addTearDown(subscription.cancel);
    hub.publishCaption(request(isFinal: false));
    hub.publishClear(CaptionClearRequest(roomId: key.roomId, sessionId: key.sessionId));

    expect(() => hub.publishCaption(request(revision: 1, isFinal: false)), throwsFormatException);
    expect(() => hub.publishCaption(request(revision: 1)), throwsFormatException);
    expect(
      hub
          .publishCaption(
            request(utteranceId: 'opening-2', utteranceSequence: 2),
          )
          .utteranceId,
      'opening-2',
    );
  });

  test('caps allocated streams and releases an idle stream after its last subscriber', () async {
    await hub.close();
    hub = CaptionHub(clock: () => now, maximumStreams: 1);
    final subscription = hub.subscribe(key).listen((_) {});

    expect(hub.activeStreamCount, 1);
    expect(() => hub.subscribe(otherKey), throwsFormatException);

    await subscription.cancel();
    expect(hub.activeStreamCount, 0);
    final otherSubscription = hub.subscribe(otherKey).listen((_) {});
    expect(hub.activeStreamCount, 1);
    await otherSubscription.cancel();
  });

  test('prunes an expired idle caption before enforcing the stream cap', () async {
    await hub.close();
    hub = CaptionHub(clock: () => now, maximumStreams: 1);
    hub.publishCaption(request(clearAfter: const Duration(seconds: 1)));
    expect(hub.activeStreamCount, 1);
    now = now.add(const Duration(seconds: 2));

    hub.publishCaption(
      request(streamKey: otherKey, utteranceId: 'talk-1'),
    );

    expect(hub.activeStreamCount, 1);
    expect(hub.pruneExpired(), 0);
  });

  test('drops sequence and revision state when a cleared stream becomes idle', () async {
    final subscription = hub.subscribe(key).listen((_) {});
    hub.publishCaption(request(isFinal: false));
    hub.publishClear(CaptionClearRequest(roomId: key.roomId, sessionId: key.sessionId));
    await subscription.cancel();

    expect(hub.activeStreamCount, 0);
    expect(() => hub.publishCaption(request(revision: 1, isFinal: false)), throwsFormatException);
    now = now.add(CaptionEvent.maximumDisplayDuration);
    final restarted = hub.publishCaption(request(isFinal: false));
    expect(restarted.sequence, 1);
    expect(restarted.revision, 0);
  });

  test('keeps a clear tombstone when no audience is connected', () {
    hub.publishCaption(request(isFinal: false));
    hub.publishClear(CaptionClearRequest(roomId: key.roomId, sessionId: key.sessionId));

    expect(hub.activeStreamCount, 0);
    expect(() => hub.publishCaption(request(revision: 1, isFinal: false)), throwsFormatException);
  });

  test('counts retained clear tombstones toward the stream bound', () async {
    await hub.close();
    hub = CaptionHub(clock: () => now, maximumStreams: 1);
    hub.publishCaption(request(isFinal: false));
    hub.publishClear(CaptionClearRequest(roomId: key.roomId, sessionId: key.sessionId));

    expect(hub.activeStreamCount, 0);
    expect(
      () => hub.publishCaption(
        request(streamKey: otherKey, utteranceId: 'talk-1'),
      ),
      throwsFormatException,
    );

    now = now.add(CaptionEvent.maximumDisplayDuration);
    expect(
      hub
          .publishCaption(
            request(streamKey: otherKey, utteranceId: 'talk-1'),
          )
          .streamKey,
      otherKey,
    );
  });

  test('summarizes only accepted final-caption latency with exact nearest rank', () {
    hub.publishCaption(
      request(
        utteranceId: 'opening-1',
        utteranceSequence: 1,
        sourceStartedAt: now.subtract(const Duration(milliseconds: 100)),
        isFinal: false,
      ),
    );
    for (final (index, latencyMs) in <int>[100, 200, 300, 400].indexed) {
      hub.publishCaption(
        request(
          utteranceId: 'opening-${index + 2}',
          utteranceSequence: index + 2,
          sourceStartedAt: now.subtract(Duration(milliseconds: latencyMs)),
        ),
      );
    }

    final snapshot = hub.finalCaptionLatency;
    expect(snapshot.count, 4);
    expect(snapshot.p50, 200);
    expect(snapshot.p95, 400);
    expect(snapshot.max, 400);
  });

  test('bounds latency samples and reports only the newest window', () async {
    await hub.close();
    hub = CaptionHub(clock: () => now, latencySampleCapacity: 3);
    for (var index = 1; index <= 4; index++) {
      hub.publishCaption(
        request(
          utteranceId: 'opening-$index',
          utteranceSequence: index,
          sourceStartedAt: now.subtract(Duration(seconds: index)),
        ),
      );
    }

    final snapshot = hub.finalCaptionLatency;
    expect(snapshot.count, 3);
    expect(snapshot.p50, 3000);
    expect(snapshot.p95, 4000);
    expect(snapshot.max, 4000);
  });

  test('rejects unreasonably future and old source timestamps without recording them', () {
    expect(
      () => hub.publishCaption(
        request(sourceStartedAt: now.add(CaptionEvent.maximumClockSkew).add(const Duration(milliseconds: 1))),
      ),
      throwsFormatException,
    );
    expect(
      () => hub.publishCaption(
        request(sourceStartedAt: now.subtract(CaptionEvent.maximumSourceAge).subtract(const Duration(milliseconds: 1))),
      ),
      throwsFormatException,
    );

    expect(hub.finalCaptionLatency.count, 0);
  });

  test('clamps accepted producer clock skew to zero milliseconds', () {
    hub.publishCaption(request(sourceStartedAt: now.add(const Duration(seconds: 1))));

    expect(hub.finalCaptionLatency.toJson(), {'count': 1, 'p50': 0, 'p95': 0, 'max': 0});
  });
}
