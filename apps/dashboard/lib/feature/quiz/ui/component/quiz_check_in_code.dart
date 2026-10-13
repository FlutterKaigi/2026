import 'package:dashboard/core/attendee_app_origin.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 会場で配るチェックイン用の QR コードと6桁の参加コード。
class QuizCheckInCode extends ConsumerWidget {
  const QuizCheckInCode({required this.eventId, required this.qrSize, this.codeStyle, super.key});

  final String eventId;
  final double qrSize;
  final TextStyle? codeStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final origin = ref.watch(attendeeAppOriginProvider);
    return ref
        .watch(quizCheckInCodeProvider(eventId))
        .when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('参加コードを読み込めませんでした: $error'),
          data: (code) => code == null
              ? const Text('参加コードはまだ発行されていません。「コードを再発行」で発行してください。')
              : Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // QR readers expect dark modules on a light background, so
                    // the code stays on white whatever the dashboard theme is.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: QrImageView(
                        data: quizCheckInQrPayload(eventId, code, origin: origin),
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
                ),
        );
  }
}
