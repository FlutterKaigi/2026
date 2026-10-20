import 'package:dashboard/core/attendee_app_origin.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 会場で配るチェックイン用の QR コードと6桁の参加コード。
class QuizCheckInCode extends ConsumerWidget {
  const QuizCheckInCode({
    required this.eventId,
    required this.qrSize,
    this.codeStyle,
    this.projection = false,
    super.key,
  });

  final String eventId;
  final double qrSize;
  final TextStyle? codeStyle;

  /// 会場の投影画面向けに、白いカードの大きな QR コードと参加コードを縦に並べる。
  /// 運営向けの案内やエラーの中身は会場に映さない。
  final bool projection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final origin = ref.watch(attendeeAppOriginProvider);
    final messageStyle = projection ? Theme.of(context).textTheme.headlineMedium : null;
    return ref
        .watch(quizCheckInCodeProvider(eventId))
        .when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text(
            projection ? '参加コードを読み込めませんでした。' : '参加コードを読み込めませんでした: $error',
            style: messageStyle,
          ),
          data: (code) {
            if (code == null) {
              return Text(
                projection ? '参加コードの表示までお待ちください。' : '参加コードはまだ発行されていません。「コードを再発行」で発行してください。',
                style: messageStyle,
              );
            }
            final payload = quizCheckInQrPayload(eventId, code, origin: origin);
            return projection ? _projectionCode(context, payload, code) : _consoleCode(context, payload, code);
          },
        );
  }

  Widget _consoleCode(BuildContext context, String payload, String code) => Wrap(
    spacing: 32,
    runSpacing: 16,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      // QR readers expect dark modules on a light background, so
      // the code stays on white whatever the dashboard theme is.
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: QrImageView(
          data: payload,
          size: qrSize,
          backgroundColor: Colors.white,
          semanticsLabel: 'クイズ大会のチェックイン用 QR コード',
        ),
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('参加コード'),
          SelectableText(
            code,
            style: (codeStyle ?? Theme.of(context).textTheme.headlineLarge)?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _projectionCode(BuildContext context, String payload, String code) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 投影画面はダーク配色だが、QR リーダーは明るい背景の暗いモジュールを前提にするため白いカードに載せる。
        DecoratedBox(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            // QrImageView は LayoutBuilder で組まれているため、大きさを固定して投影画面のレイアウト計算に載せる。
            child: SizedBox.square(
              dimension: qrSize,
              child: QrImageView(
                data: payload,
                size: qrSize,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                semanticsLabel: 'クイズ大会のチェックイン用 QR コード',
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '参加コード',
          style: TextStyle(
            fontSize: 26,
            height: 34 / 26,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          code,
          style: (codeStyle ?? theme.textTheme.displayLarge)?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
