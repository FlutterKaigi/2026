import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final quizClockRepositoryProvider = Provider<QuizClockRepository>((_) => FirebaseQuizClockRepository());
final quizClockProvider = FutureProvider<QuizClock>((ref) => ref.watch(quizClockRepositoryProvider).synchronize());

/// 端末の時計ではなく、サーバー同期後の単調時計で残り時間を表示する。
class QuizCountdown extends HookConsumerWidget {
  const QuizCountdown({super.key, required this.closesAt, this.large = false});

  final DateTime closesAt;
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = ref.watch(quizClockProvider);
    final tick = useState(0);
    useEffect(() {
      final lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(quizClockProvider));
      final ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick.value++);
      final synchronizer = Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidate(quizClockProvider));
      return () {
        lifecycle.dispose();
        ticker.cancel();
        synchronizer.cancel();
      };
    }, const []);
    final synchronized = clock.isLoading || clock.hasError ? null : clock.value;
    final remaining = synchronized != null && synchronized.isFresh
        ? closesAt.difference(synchronized.now).inSeconds
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
