import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/digit_code_field.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
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
          ('invalid-argument', _) => (message: t.invalidFormat, highlightsCode: true),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(t.instructions),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: submitting.value ? null : scan,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(t.scanButton),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(t.codeSectionTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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
