import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/digit_code_field.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/component/quiz_progress_steps.dart';
import 'package:app/feature/quiz/ui/page/quiz_check_in_scan_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// An account and the check-in link code that was submitted for it without a tap.
typedef QuizCheckInAutoSubmission = (String uid, String code);

/// Checks a registered attendee in with the venue's QR code or its 6-digit
/// code. Team selection follows once the server records the check-in.
class QuizCheckInView extends StatelessWidget {
  const QuizCheckInView({
    required this.event,
    required this.uid,
    required this.linkCode,
    required this.autoSubmissions,
    super.key,
  });

  final QuizEvent event;
  final String uid;

  /// Code from the check-in QR code's link, submitted once without a tap.
  final String? linkCode;

  /// Owned by the page so that sign-in and state changes rebuilding this view
  /// never resubmit a link: one wrong link must not exhaust the attempt limit.
  final Set<QuizCheckInAutoSubmission> autoSubmissions;

  @override
  Widget build(BuildContext context) {
    if (event.teamSelectionStatus != QuizTeamSelectionStatus.open) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            Translations.of(context).quiz.checkIn.closed,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
    }
    return _CheckInForm(
      key: ValueKey((uid, linkCode)),
      eventId: event.id,
      uid: uid,
      linkCode: linkCode,
      autoSubmissions: autoSubmissions,
    );
  }
}

class _CheckInForm extends HookConsumerWidget {
  const _CheckInForm({
    required this.eventId,
    required this.uid,
    required this.linkCode,
    required this.autoSubmissions,
    super.key,
  });

  final String eventId;
  final String uid;
  final String? linkCode;
  final Set<QuizCheckInAutoSubmission> autoSubmissions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context).quiz.checkIn;
    final accountUnavailable = Translations.of(context).quiz.registration.accountUnavailable;
    final theme = Theme.of(context);
    final linkCode = this.linkCode;
    final hasValidLinkCode = linkCode != null && isQuizCheckInCode(linkCode);
    final controller = useTextEditingController(text: hasValidLinkCode ? linkCode : null);
    final submitting = useState(false);
    // コードそのものの誤りのときだけ、メッセージに加えてマス目もエラー表示にする。
    final error = useState<({String message, bool highlightsCode})?>(
      linkCode != null && !hasValidLinkCode ? (message: t.linkInvalid, highlightsCode: false) : null,
    );

    Future<void> submit() async {
      if (submitting.value) {
        return;
      }
      final code = controller.text.trim();
      if (!isQuizCheckInCode(code)) {
        error.value = (message: t.invalidFormat, highlightsCode: true);
        return;
      }
      submitting.value = true;
      error.value = null;
      try {
        await ref.read(quizParticipantRepositoryProvider).checkIn(eventId, code);
      } on FirebaseFunctionsException catch (failure) {
        if (!context.mounted) {
          return;
        }
        final details = failure.details;
        final reason = details is Map ? details['reason'] : null;
        error.value = switch ((failure.code, reason)) {
          (_, 'wrong-code') => (message: t.wrongCode, highlightsCode: true),
          (_, 'rate-limited') => (message: t.rateLimited, highlightsCode: false),
          // 無効化されたアカウントなど、コード以外の理由で拒否された場合は、
          // 更新やサインインし直しでは解決しないので運営への問い合わせを案内する。
          (_, 'disabled-account') || ('permission-denied', _) => (message: accountUnavailable, highlightsCode: false),
          ('invalid-argument', _) => (message: t.invalidFormat, highlightsCode: true),
          // 参加登録が取り消された場合は、受付終了と区別してスタッフへ案内する。
          ('failed-precondition', 'not-registered') => (message: t.notRegistered, highlightsCode: false),
          ('failed-precondition', _) => (message: t.closed, highlightsCode: false),
          ('unavailable' || 'deadline-exceeded' || 'aborted', _) => (message: t.unavailable, highlightsCode: false),
          _ => (message: t.failed, highlightsCode: false),
        };
      } on Exception {
        if (context.mounted) {
          error.value = (message: t.unavailable, highlightsCode: false);
        }
      } finally {
        if (context.mounted) {
          submitting.value = false;
        }
      }
    }

    Future<void> scan() async {
      // タブを切り替えてもカメラが動き続けないよう、ナビゲーションごと覆う。
      final code = await Navigator.of(context, rootNavigator: true).push<String>(
        MaterialPageRoute(builder: (_) => QuizCheckInScanPage(eventId: eventId)),
      );
      // 読み取り中に別のアカウントへ切り替わっていたら、そのアカウントでは送信しない。
      if (code == null || !context.mounted || ref.read(quizUserProvider).value?.uid != uid) {
        return;
      }
      controller.text = code;
      await submit();
    }

    useEffect(() {
      // 送信前に記録するので、失敗しても自動では送り直さない。
      if (!hasValidLinkCode || !autoSubmissions.add((uid, linkCode))) {
        return null;
      }
      // 送信は状態を書き換えるため、最初のビルドが終わってから始める。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          unawaited(submit());
        }
      });
      return null;
    }, const []);

    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const QuizProgressSteps(current: QuizProgressStep.checkIn),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(t.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(t.instructions, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          // 読み取りが基本の手段なので、コード入力より目立たせる。
          Card.outlined(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(Icons.qr_code_scanner, size: 48, color: scheme.onPrimaryContainer),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: submitting.value ? null : scan,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(t.scanButton),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 区切り線の中央に見出しを置く。大きな文字でも線が残るよう、見出しの幅は抑えて折り返す。
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                const Expanded(child: Divider()),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.7),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      t.codeSectionTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DigitCodeField(
            label: t.codeLabel,
            controller: controller,
            enabled: !submitting.value,
            errorText: error.value?.message,
            highlightsError: error.value?.highlightsCode ?? false,
            onChanged: (_) => error.value = null,
            onSubmitted: (_) => submit(),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: submitting.value ? null : submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: submitting.value
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: Text(submitting.value ? t.submitting : t.submit),
          ),
        ],
      ),
    );
  }
}
