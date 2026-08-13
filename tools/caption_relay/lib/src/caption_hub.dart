import 'dart:async';
import 'dart:collection';

import 'package:caption_protocol/caption_protocol.dart';

typedef CaptionClock = DateTime Function();

final class CaptionHub {
  CaptionHub({
    CaptionClock? clock,
    this.maximumStreams = 32,
    this.latencySampleCapacity = 1000,
  }) : _clock = clock ?? _utcNow {
    if (maximumStreams < 1) {
      throw ArgumentError.value(maximumStreams, 'maximumStreams', 'must be positive');
    }
    if (latencySampleCapacity < 1 || latencySampleCapacity > 1000) {
      throw ArgumentError.value(
        latencySampleCapacity,
        'latencySampleCapacity',
        'must be between 1 and 1000',
      );
    }
  }

  final CaptionClock _clock;
  final int maximumStreams;
  final int latencySampleCapacity;
  final Map<CaptionStreamKey, StreamController<CaptionEvent>> _controllers = {};
  final Map<CaptionStreamKey, CaptionEvent> _latest = {};
  final Map<CaptionStreamKey, int> _lastSequences = {};
  final Map<CaptionStreamKey, _UtteranceState> _utteranceStates = {};
  final Map<CaptionStreamKey, int> _streamSubscriberCounts = {};
  final Queue<int> _finalCaptionLatencyMs = Queue<int>();
  var _subscriberCount = 0;
  var _isClosing = false;

  int get subscriberCount => _subscriberCount;
  int get activeStreamCount => _controllers.length;

  CaptionLatencySnapshot get finalCaptionLatency {
    if (_finalCaptionLatencyMs.isEmpty) {
      return const CaptionLatencySnapshot.empty();
    }
    final sorted = _finalCaptionLatencyMs.toList()..sort();
    return CaptionLatencySnapshot(
      count: sorted.length,
      p50: _nearestRank(sorted, 50),
      p95: _nearestRank(sorted, 95),
      max: sorted.last,
    );
  }

  CaptionEvent publishCaption(CaptionIngestRequest request) {
    final now = _clock().toUtc();
    _validateSourceStartedAt(request.sourceStartedAt, now);
    pruneExpired();
    final key = CaptionStreamKey(roomId: request.roomId, sessionId: request.sessionId);
    final previous = _utteranceStates[key];
    var shouldRecordFinalLatency = request.isFinal;
    if (previous != null) {
      if (request.utteranceSequence < previous.utteranceSequence) {
        throw const FormatException(
          'utteranceSequence must not be older than the displayed utterance.',
        );
      }
      if (request.utteranceSequence == previous.utteranceSequence) {
        if (request.utteranceId != previous.utteranceId) {
          throw const FormatException(
            'An utteranceSequence cannot identify two different utterances.',
          );
        }
        if (previous.isCleared) {
          throw const FormatException('The utterance has already been cleared.');
        }
        if (!request.sourceStartedAt.isAtSameMomentAs(previous.sourceStartedAt)) {
          throw const FormatException(
            'sourceStartedAt must remain unchanged across revisions of an utterance.',
          );
        }
        if (request.revision <= previous.revision) {
          throw const FormatException(
            'revision must be greater than the last accepted revision.',
          );
        }
        if (previous.isFinal && !request.isFinal) {
          throw const FormatException('A partial caption cannot replace a final caption.');
        }
        shouldRecordFinalLatency = request.isFinal && !previous.isFinal;
      }
    }
    final controller = _controllerFor(key);
    final event = CaptionEvent.caption(
      roomId: request.roomId,
      sessionId: request.sessionId,
      sequence: _nextSequence(key),
      utteranceId: request.utteranceId,
      utteranceSequence: request.utteranceSequence,
      revision: request.revision,
      sourceText: request.sourceText,
      translatedText: request.translatedText,
      isFinal: request.isFinal,
      sourceStartedAt: request.sourceStartedAt,
      producedAt: now,
      clearAt: now.add(request.clearAfter),
    );
    _utteranceStates[key] = _UtteranceState(
      utteranceId: request.utteranceId,
      utteranceSequence: request.utteranceSequence,
      revision: request.revision,
      isFinal: request.isFinal,
      sourceStartedAt: request.sourceStartedAt,
    );
    _latest[key] = event;
    controller.add(event);
    if (shouldRecordFinalLatency) {
      _recordFinalCaptionLatency(now.difference(request.sourceStartedAt).inMilliseconds);
    }
    return event;
  }

  CaptionEvent publishClear(CaptionClearRequest request) {
    final key = CaptionStreamKey(roomId: request.roomId, sessionId: request.sessionId);
    final controller = _controllerFor(key);
    final event = CaptionEvent.clear(
      roomId: request.roomId,
      sessionId: request.sessionId,
      sequence: _nextSequence(key),
      producedAt: _clock().toUtc(),
    );
    _latest.remove(key);
    final previous = _utteranceStates[key];
    if (previous != null) {
      _utteranceStates[key] = previous.markClearedUntil(
        _clock().toUtc().add(CaptionEvent.maximumDisplayDuration),
      );
    }
    controller.add(event);
    _pruneIfIdle(key);
    return event;
  }

  CaptionEvent heartbeat(CaptionStreamKey key) => CaptionEvent.heartbeat(
    roomId: key.roomId,
    sessionId: key.sessionId,
    sequence: _lastSequences[key] ?? 0,
    producedAt: _clock().toUtc(),
  );

  Stream<CaptionEvent> subscribe(CaptionStreamKey key) {
    final source = _controllerFor(key);
    StreamSubscription<CaptionEvent>? sourceSubscription;
    late final StreamController<CaptionEvent> output;
    output = StreamController<CaptionEvent>(
      sync: true,
      onListen: () {
        _subscriberCount++;
        _streamSubscriberCounts[key] = (_streamSubscriberCounts[key] ?? 0) + 1;
        sourceSubscription = source.stream.listen(
          output.add,
          onError: output.addError,
          onDone: output.close,
        );
        final latest = _latest[key];
        if (latest == null) {
          return;
        }
        if (latest.isExpiredAt(_clock())) {
          _latest.remove(key);
        } else {
          output.add(latest);
        }
      },
      onPause: () => sourceSubscription?.pause(),
      onResume: () => sourceSubscription?.resume(),
      onCancel: () async {
        _subscriberCount--;
        final remaining = (_streamSubscriberCounts[key] ?? 1) - 1;
        if (remaining == 0) {
          _streamSubscriberCounts.remove(key);
        } else {
          _streamSubscriberCounts[key] = remaining;
        }
        await sourceSubscription?.cancel();
        _pruneIfIdle(key);
      },
    );
    return output.stream;
  }

  Future<void> close() async {
    _isClosing = true;
    await Future.wait(_controllers.values.toList().map((controller) => controller.close()));
    _controllers.clear();
    _latest.clear();
    _lastSequences.clear();
    _utteranceStates.clear();
    _streamSubscriberCounts.clear();
    _finalCaptionLatencyMs.clear();
    _subscriberCount = 0;
  }

  int pruneExpired() {
    final now = _clock().toUtc();
    final expiredCaptionKeys = _latest.entries
        .where((entry) => entry.value.isExpiredAt(now))
        .map((entry) => entry.key)
        .toList();
    final expiredTombstoneKeys = _utteranceStates.entries
        .where((entry) => entry.value.isCleared && entry.value.clearedUntil?.isAfter(now) != true)
        .map((entry) => entry.key)
        .toList();
    for (final key in expiredCaptionKeys) {
      _latest.remove(key);
      _pruneIfIdle(key);
    }
    for (final key in expiredTombstoneKeys) {
      _utteranceStates.remove(key);
      _pruneIfIdle(key);
    }
    return {...expiredCaptionKeys, ...expiredTombstoneKeys}.length;
  }

  int _nextSequence(CaptionStreamKey key) {
    final next = (_lastSequences[key] ?? 0) + 1;
    _lastSequences[key] = next;
    return next;
  }

  void _validateSourceStartedAt(DateTime sourceStartedAt, DateTime now) {
    if (sourceStartedAt.isAfter(now.add(CaptionEvent.maximumClockSkew))) {
      throw const FormatException('sourceStartedAt is unreasonably far in the future.');
    }
    if (now.difference(sourceStartedAt) > CaptionEvent.maximumSourceAge) {
      throw const FormatException('sourceStartedAt is unreasonably old.');
    }
  }

  void _recordFinalCaptionLatency(int latencyMs) {
    // A producer clock may be slightly ahead within the accepted skew. Clamping
    // keeps the reported duration numeric and non-negative.
    _finalCaptionLatencyMs.addLast(latencyMs < 0 ? 0 : latencyMs);
    while (_finalCaptionLatencyMs.length > latencySampleCapacity) {
      _finalCaptionLatencyMs.removeFirst();
    }
  }

  StreamController<CaptionEvent> _controllerFor(CaptionStreamKey key) {
    final existing = _controllers[key];
    if (existing != null) {
      return existing;
    }
    pruneExpired();
    final trackedKeys = <CaptionStreamKey>{
      ..._controllers.keys,
      ..._latest.keys,
      ..._utteranceStates.keys,
    };
    if (!trackedKeys.contains(key) && trackedKeys.length >= maximumStreams) {
      throw FormatException('The relay supports at most $maximumStreams active caption streams.');
    }
    return _controllers[key] = StreamController<CaptionEvent>.broadcast(sync: true);
  }

  void _pruneIfIdle(CaptionStreamKey key) {
    if (_isClosing || _latest.containsKey(key) || (_streamSubscriberCounts[key] ?? 0) > 0) {
      return;
    }
    final state = _utteranceStates[key];
    final retainClearTombstone = state?.isCleared == true && state!.clearedUntil?.isAfter(_clock().toUtc()) == true;
    final controller = _controllers.remove(key);
    _lastSequences.remove(key);
    if (!retainClearTombstone) {
      _utteranceStates.remove(key);
    }
    _streamSubscriberCounts.remove(key);
    if (controller != null) {
      unawaited(controller.close());
    }
  }
}

/// A bounded-window latency summary for accepted final captions.
///
/// Percentiles use the exact nearest-rank method over the retained samples.
final class CaptionLatencySnapshot {
  const CaptionLatencySnapshot({
    required this.count,
    required this.p50,
    required this.p95,
    required this.max,
  });

  const CaptionLatencySnapshot.empty() : count = 0, p50 = null, p95 = null, max = null;

  final int count;
  final int? p50;
  final int? p95;
  final int? max;

  Map<String, Object?> toJson() => {
    'count': count,
    'p50': p50,
    'p95': p95,
    'max': max,
  };
}

final class _UtteranceState {
  const _UtteranceState({
    required this.utteranceId,
    required this.utteranceSequence,
    required this.revision,
    required this.isFinal,
    required this.sourceStartedAt,
    this.isCleared = false,
    this.clearedUntil,
  });

  final String utteranceId;
  final int utteranceSequence;
  final int revision;
  final bool isFinal;
  final DateTime sourceStartedAt;
  final bool isCleared;
  final DateTime? clearedUntil;

  _UtteranceState markClearedUntil(DateTime deadline) => _UtteranceState(
    utteranceId: utteranceId,
    utteranceSequence: utteranceSequence,
    revision: revision,
    isFinal: true,
    sourceStartedAt: sourceStartedAt,
    isCleared: true,
    clearedUntil: deadline,
  );
}

DateTime _utcNow() => DateTime.now().toUtc();

int _nearestRank(List<int> sortedSamples, int percentile) {
  final rank = (percentile * sortedSamples.length + 99) ~/ 100;
  return sortedSamples[rank - 1];
}
