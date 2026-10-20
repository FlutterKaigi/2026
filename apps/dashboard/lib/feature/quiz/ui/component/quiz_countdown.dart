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

/// 残り時間。[seconds] はサーバー同期後の締切までの秒数（0 は締切済み）で、
/// 締切がないときや同期できていない間は `null`。[failed] は時刻の同期に失敗したかどうか。
typedef QuizRemaining = ({int? seconds, bool failed});

/// 端末の時計ではなく、サーバー同期後の単調時計で残り時間を表示する。
class QuizCountdown extends HookConsumerWidget {
  const QuizCountdown({super.key, required this.closesAt}) : builder = null;

  /// 残り時間に応じた表示を [builder] で組み立てる（投影画面用）。
  ///
  /// 読み上げ中（[closesAt] が `null`）も時刻の同期を続けるため、回答開始と同時に残り時間を出せる。
  const QuizCountdown.builder({
    super.key,
    required this.closesAt,
    required Widget Function(BuildContext context, QuizRemaining remaining) this.builder,
  });

  final DateTime? closesAt;
  final Widget Function(BuildContext context, QuizRemaining remaining)? builder;

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
    final synchronized = clock.value;
    final remaining = deadline != null && synchronized != null && synchronized.isFresh
        ? (deadline.difference(synchronized.now).inMilliseconds / 1000).ceil()
        : null;
    final seconds = remaining?.clamp(0, 86400);
    if (builder case final builder?) {
      return builder(context, (seconds: seconds, failed: clock.hasError));
    }
    if (deadline == null) {
      return const SizedBox.shrink();
    }
    final label = seconds == null
        ? (clock.hasError ? '時刻同期に失敗しました（再接続待ち）' : '時刻を同期中…')
        : seconds == 0
        ? '回答時間終了'
        : '残り ${quizRemainingText(seconds)}';
    return Text(label, style: Theme.of(context).textTheme.titleMedium);
  }
}

/// 残り秒数を m:ss にする。
String quizRemainingText(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// 投影画面で、残り時間を出せない間の文言。管理画面の文言とは分け、会場向けの言い方にする。
String quizProjectionClockMessage(QuizRemaining remaining) => remaining.failed ? '残り時間を表示できません' : '残り時間を確認中…';
