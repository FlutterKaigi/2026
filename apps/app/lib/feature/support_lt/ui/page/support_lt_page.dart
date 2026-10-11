import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_page_content.dart';
import 'package:app/core/ui/widget/brand_header_card.dart';
import 'package:app/core/ui/widget/digit_code_field.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/widget/authenticated_body.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:app/feature/support_lt/ui/page/support_lt_scan_page.dart';
import 'package:app/feature/support_lt/ui/support_lt_error_message.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// An account and the link code that was submitted for it without a tap.
typedef _AutoSubmission = (String uid, String code);

/// Registers attendance with the venue's QR code, or with the shared code it
/// carries when the attendee cannot scan.
class SupportLtPage extends HookWidget {
  const SupportLtPage({this.linkCode, super.key});

  /// Code from the attendance QR code's link (`supportLtQrPayload`), submitted
  /// once the attendee is signed in. `null` when the page is opened in the app.
  final String? linkCode;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    // 自動送信の記録は、サインイン状態や登録状況の切り替わりで作り直される
    // フォームではなくページで持つ。フォームが戻るたびに送信し直すと、誤った
    // コードのリンク 1 つで試行回数の上限に達してしまう。
    final autoSubmissions = useRef(<_AutoSubmission>{});

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.supportLt.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: AuthenticatedBody(
        signedOut: AppPageContent(
          maxWidth: signInCardMaxWidth,
          padding: const EdgeInsets.all(24),
          centerVertically: true,
          child: SignInCard(
            title: t.auth.signIn.required,
            description: t.supportLt.signInRequired,
          ),
        ),
        // 別のリンクを続けて開いても同じルートが使い回されるため、コードごとに
        // 状態を作り直して、前のコードの入力や結果を引き継がない。
        builder: (uid) => _RegistrationBody(
          key: ValueKey(linkCode),
          uid: uid,
          linkCode: linkCode,
          autoSubmissions: autoSubmissions.value,
        ),
      ),
    );
  }
}

class _RegistrationBody extends ConsumerWidget {
  const _RegistrationBody({required this.uid, required this.linkCode, required this.autoSubmissions, super.key});

  final String uid;
  final String? linkCode;
  final Set<_AutoSubmission> autoSubmissions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registration = ref.watch(supportLtRegistrationProvider(uid));

    return switch (registration) {
      AsyncData(value: null) => _RegistrationForm(uid: uid, linkCode: linkCode, autoSubmissions: autoSubmissions),
      AsyncData() => const _RegisteredContent(),
      AsyncError(:final error) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(supportLtRegistrationProvider(uid)),
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
    };
  }
}

class _RegistrationForm extends HookConsumerWidget {
  const _RegistrationForm({required this.uid, required this.linkCode, required this.autoSubmissions});

  final String uid;
  final String? linkCode;
  final Set<_AutoSubmission> autoSubmissions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final linkCode = this.linkCode;
    final hasValidLinkCode = linkCode != null && isSupportLtCode(linkCode);
    final controller = useTextEditingController(text: hasValidLinkCode ? linkCode : null);
    final isSubmitting = useState(false);
    // コードそのものの誤りのときだけ、メッセージに加えてマス目もエラー表示にする。
    final error = useState<({String message, bool highlightsCode})?>(
      linkCode != null && !hasValidLinkCode ? (message: t.supportLt.linkInvalid, highlightsCode: false) : null,
    );

    Future<void> submit() async {
      if (isSubmitting.value) {
        return;
      }
      final code = controller.text.trim();
      if (!isSupportLtCode(code)) {
        error.value = (message: t.supportLt.invalidFormat, highlightsCode: true);
        return;
      }
      isSubmitting.value = true;
      error.value = null;
      try {
        await ref.read(supportLtRepositoryProvider).register(code);
      } on Exception catch (exception, stackTrace) {
        if (context.mounted) {
          ref.read(talkerProvider).handle(exception, stackTrace);
          error.value = (
            message: supportLtErrorMessage(t, exception),
            highlightsCode: isSupportLtCodeError(exception),
          );
        }
      } finally {
        if (context.mounted) {
          isSubmitting.value = false;
        }
      }
    }

    Future<void> scan() async {
      // タブを切り替えてもカメラが動き続けないよう、ナビゲーションごと覆う。
      final code = await Navigator.of(context, rootNavigator: true).push<String>(
        MaterialPageRoute(builder: (_) => const SupportLtScanPage()),
      );
      // 読み取り中に別のアカウントへ切り替わっていたら、そのアカウントでは登録しない。
      if (code == null || !context.mounted || ref.read(authRepositoryProvider).currentUser?.uid != uid) {
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

    return AppPageContent(
      maxWidth: signInCardMaxWidth,
      padding: const EdgeInsets.all(24),
      centerVertically: true,
      child: BrandHeaderCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.supportLt.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: isSubmitting.value ? null : scan,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(t.supportLt.scanButton),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              t.supportLt.codeSectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              t.supportLt.codeSectionDescription,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            DigitCodeField(
              label: t.supportLt.codeLabel,
              controller: controller,
              enabled: !isSubmitting.value,
              errorText: error.value?.message,
              highlightsError: error.value?.highlightsCode ?? false,
              onChanged: (_) => error.value = null,
              onSubmitted: (_) => submit(),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: isSubmitting.value ? null : submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: isSubmitting.value
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(isSubmitting.value ? t.supportLt.submitting : t.supportLt.register),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisteredContent extends StatelessWidget {
  const _RegisteredContent();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return AppPageContent(
      maxWidth: signInCardMaxWidth,
      padding: const EdgeInsets.all(24),
      centerVertically: true,
      child: BrandHeaderCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_outline, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              t.supportLt.registeredTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              t.supportLt.registeredBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => const AccountRoute().go(context),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: Text(t.supportLt.backToAccount),
            ),
          ],
        ),
      ),
    );
  }
}
