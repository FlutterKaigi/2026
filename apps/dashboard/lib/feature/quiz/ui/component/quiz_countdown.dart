import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final quizClockRepositoryProvider = Provider<QuizClockRepository>((_) => FirebaseQuizClockRepository());
final quizClockProvider = AsyncNotifierProvider.autoDispose<QuizClockController, QuizClock?>(
  QuizClockController.new,
);

class QuizClockController extends AsyncNotifier<QuizClock?> {
  @override
  Future<QuizClock> build() => ref.watch(quizClockRepositoryProvider).synchronize();

  void resynchronizeAfterInterruption() {
    state = const AsyncData(null);
    ref.invalidateSelf();
  }
}

/// 端末の時計ではなく、サーバー同期後の単調時計で残り時間を表示する。
class QuizCountdown extends HookConsumerWidget {
  const QuizCountdown({super.key, required this.closesAt, this.large = false});

  final DateTime? closesAt;
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = ref.watch(quizClockProvider);
    final tick = useState(0);
    useEffect(() {
      final lifecycle = AppLifecycleListener(
        onResume: () => ref.read(quizClockProvider.notifier).resynchronizeAfterInterruption(),
      );
      final ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick.value++);
      final synchronizer = Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidate(quizClockProvider));
      return () {
        lifecycle.dispose();
        ticker.cancel();
        synchronizer.cancel();
      };
    }, const []);
    final deadline = closesAt;
    if (deadline == null) {
      return const SizedBox.shrink();
    }
    final synchronized = clock.value;
    final remaining = synchronized != null && synchronized.isFresh
        ? (deadline.difference(synchronized.now).inMilliseconds / 1000).ceil()
        : null;
    final seconds = remaining?.clamp(0, 86400);
    final label = seconds == null
        ? (clock.hasError ? '時刻同期に失敗しました（再接続待ち）' : '時刻を同期中…')
        : seconds == 0
        ? '回答時間終了'
        : '残り ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Text(
      label,
      style: large ? Theme.of(context).textTheme.displaySmall : Theme.of(context).textTheme.titleMedium,
    );
  }
}
