import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/core/ui/widget/brand_header_card.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:app/feature/support_lt/ui/support_lt_error_message.dart';
import 'package:app/feature/support_lt/ui/widget/support_lt_code_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Registers attendance with the shared code supplied by event organizers.
class SupportLtPage extends ConsumerWidget {
  const SupportLtPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final auth = ref.watch(authStateChangesProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.supportLt.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: switch (auth) {
        // 共有リンクから開いた参加者も、アカウントタブへ移らずにこの場でサインインできる。
        AsyncData(value: null) => _PageContent(
          child: SignInCard(
            title: t.auth.signIn.required,
            description: t.supportLt.signInRequired,
          ),
        ),
        AsyncData(:final value?) => _RegistrationBody(key: ValueKey(value.uid), uid: value.uid),
        AsyncError(:final error) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(authStateChangesProvider),
        ),
        _ => const Center(child: CircularProgressIndicator.adaptive()),
      },
    );
  }
}

class _RegistrationBody extends ConsumerWidget {
  const _RegistrationBody({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registration = ref.watch(supportLtRegistrationProvider(uid));

    return switch (registration) {
      AsyncData(value: null) => const _RegistrationForm(),
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
  const _RegistrationForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final controller = useTextEditingController();
    final isSubmitting = useState(false);
    // コードそのものの誤りのときだけ、メッセージに加えてマス目もエラー表示にする。
    final error = useState<({String message, bool highlightsCode})?>(null);

    Future<void> submit() async {
      if (isSubmitting.value) {
        return;
      }
      final code = controller.text.trim();
      if (!RegExp(r'^\d{6}$').hasMatch(code)) {
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

    return _PageContent(
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
            SupportLtCodeField(
              controller: controller,
              enabled: !isSubmitting.value,
              errorText: error.value?.message,
              highlightsError: error.value?.highlightsCode ?? false,
              onChanged: (_) => error.value = null,
              onSubmitted: (_) => submit(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
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
    return _PageContent(
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

class _PageContent extends StatelessWidget {
  const _PageContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AppScrollbar(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        // どの状態もサインインカードと同じ幅にそろえる。
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: signInCardMaxWidth),
          child: child,
        ),
      ),
    ),
  );
}
