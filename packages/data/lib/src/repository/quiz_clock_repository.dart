import 'package:cloud_functions/cloud_functions.dart';

/// Calibrates quiz countdowns against the same server that enforces deadlines.
abstract interface class QuizClockRepository {
  Future<QuizClock> synchronize();
}

/// A server time anchor advanced by monotonic elapsed time, never the device clock.
final class QuizClock {
  QuizClock({
    required DateTime serverNow,
    this.uncertainty = Duration.zero,
    Duration Function()? elapsed,
  }) : _serverNow = serverNow,
       _elapsed = elapsed ?? _startStopwatch();

  final DateTime _serverNow;
  final Duration Function() _elapsed;
  final Duration uncertainty;

  DateTime get now => _serverNow.add(_elapsed());

  /// Recalibrate periodically and after returning from the background.
  bool get isFresh => _elapsed() < const Duration(minutes: 1);

  static Duration Function() _startStopwatch() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }
}

final class FirebaseQuizClockRepository implements QuizClockRepository {
  FirebaseQuizClockRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFunctions _functions;

  @override
  Future<QuizClock> synchronize() async {
    final roundTrip = Stopwatch()..start();
    final result = await _functions
        .httpsCallable(
          'getQuizServerTime',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 10)),
        )
        .call<Map<String, dynamic>>();
    roundTrip.stop();
    final halfRoundTrip = Duration(microseconds: roundTrip.elapsedMicroseconds ~/ 2);
    final serverNowMs = result.data['serverNowMs'];
    if (serverNowMs is! num) {
      throw const FormatException('Invalid quiz server time');
    }
    return QuizClock(
      serverNow: DateTime.fromMillisecondsSinceEpoch(serverNowMs.toInt(), isUtc: true).add(halfRoundTrip),
      uncertainty: halfRoundTrip,
    );
  }
}
