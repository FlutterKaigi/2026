import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/provider/environment.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/core/ui/widget/settings_icon_button.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/auth/ui/auth_error_message.dart';
import 'package:app/feature/auth/ui/widget/apple_sign_in_button.dart';
import 'package:app/feature/auth/ui/widget/google_sign_in_button.dart';
import 'package:app/feature/auth/ui/widget/sign_in_method_button_style.dart';
import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Whether the current build may expose native Sign in with Apple.
bool isAppleSignInAvailable({
  required Flavor flavor,
  required bool isWeb,
  required TargetPlatform platform,
}) => flavor == Flavor.production && !isWeb && platform == TargetPlatform.iOS;

final appleSignInAvailabilityProvider = Provider<bool>((ref) {
  final environment = ref.watch(environmentProvider);
  return isAppleSignInAvailable(
    flavor: environment.flavor,
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
  );
});

/// The account tab: sign-in options while signed out, account info while
/// signed in.
class AccountPage extends HookConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final authState = ref.watch(authStateChangesProvider);
    final isProcessing = useState(false);
    final showsAppleSignIn = ref.watch(appleSignInAvailabilityProvider);

    void showMessage(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> runAuthAction(
      Future<void> Function(AuthRepository repository) action, {
      String? successMessage,
    }) async {
      if (isProcessing.value) {
        return;
      }
      isProcessing.value = true;
      try {
        await action(ref.read(authRepositoryProvider));
        if (successMessage != null && context.mounted) {
          showMessage(successMessage);
        }
      } on FirebaseAuthException catch (exception, stackTrace) {
        ref.read(talkerProvider).handle(exception, stackTrace);
        final message = authErrorMessage(t, exception);
        if (message != null && context.mounted) {
          showMessage(message);
        }
      } finally {
        isProcessing.value = false;
      }
    }

    Future<void> deleteAccount(User user) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.auth.account.deleteConfirmTitle),
          content: Text(t.auth.account.deleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.auth.account.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.auth.account.deleteConfirmAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) {
        return;
      }

      // メール+パスワードのユーザーは再認証に現在のパスワードが必要
      // (providerId は EmailAuthProvider.PROVIDER_ID の 'password')。
      String? password;
      final usesPassword = user.providerData.any((info) => info.providerId == 'password');
      if (usesPassword) {
        password = await showDialog<String>(
          context: context,
          builder: (_) => const _PasswordPromptDialog(),
        );
        if (password == null || !context.mounted) {
          return;
        }
      }

      await runAuthAction(
        (repository) => repository.deleteAccount(password: password),
        successMessage: t.auth.account.deleted,
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.auth.account.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [SettingsIconButton()],
      ),
      body: switch (authState) {
        AsyncData(:final value) => AppScrollbar(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                // 認証方法が変わっても操作領域が揃うよう、共通の最大幅にする。
                constraints: const BoxConstraints(maxWidth: signInMethodButtonMaxWidth),
                child: value == null
                    ? _SignedOutView(
                        isProcessing: isProcessing.value,
                        showsAppleSignIn: showsAppleSignIn,
                        onSignIn: runAuthAction,
                      )
                    : _SignedInView(
                        user: value,
                        isProcessing: isProcessing.value,
                        onSignOut: () => runAuthAction((repository) => repository.signOut()),
                        onDeleteAccount: () => deleteAccount(value),
                      ),
              ),
            ),
          ),
        ),
        AsyncError(:final error) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(authStateChangesProvider),
        ),
        AsyncLoading() => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      },
    );
  }
}

/// Sign-in method buttons shown while signed out.
class _SignedOutView extends StatelessWidget {
  const _SignedOutView({
    required this.isProcessing,
    required this.showsAppleSignIn,
    required this.onSignIn,
  });

  final bool isProcessing;
  final bool showsAppleSignIn;
  final Future<void> Function(Future<void> Function(AuthRepository repository) action) onSignIn;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.account_circle_outlined,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          t.auth.signIn.description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        GoogleSignInButton(
          onPressed: isProcessing ? null : () async => onSignIn((repository) => repository.signInWithGoogle()),
        ),
        const SizedBox(height: 12),
        if (showsAppleSignIn) ...[
          AppleSignInButton(
            onPressed: isProcessing ? null : () async => onSignIn((repository) => repository.signInWithApple()),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          onPressed: isProcessing ? null : () async => const EmailSignInRoute().push<void>(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(signInMethodButtonHeight),
            maximumSize: const Size.fromHeight(signInMethodButtonHeight),
            padding: EdgeInsets.zero,
            textStyle: signInMethodButtonLabelStyle,
          ),
          child: SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [
                const PositionedDirectional(
                  start: signInMethodButtonIconInset,
                  child: Icon(Icons.mail_outline, size: signInMethodButtonIconSize),
                ),
                Text(t.auth.signIn.withEmail),
              ],
            ),
          ),
        ),
        if (isProcessing) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

/// Account summary and sign-out shown while signed in.
class _SignedInView extends StatelessWidget {
  const _SignedInView({
    required this.user,
    required this.isProcessing,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  final User user;
  final bool isProcessing;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final title = user.displayName ?? user.email ?? t.auth.account.noEmail;
    final subtitle = user.displayName != null ? user.email : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CircleAvatar(
          radius: 32,
          child: Icon(Icons.person, size: 32, semanticLabel: t.auth.account.title),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          t.auth.account.signedIn,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        // サインイン中だけ見えるアプリ機能への導線。クイズ大会は参加と回答の
        // 記録をアカウントに紐づけるため、ここが唯一の入口になる。
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            t.auth.account.features,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        Card.outlined(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const Icon(Icons.quiz_outlined),
            title: Text(t.quiz.title),
            subtitle: Text(t.quiz.entrySubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => unawaited(const QuizListRoute().push<void>(context)),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: isProcessing ? null : () async => onSignOut(),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.logout),
          label: Text(t.auth.account.signOut),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: isProcessing ? null : () async => onDeleteAccount(),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.delete_outline),
          label: Text(t.auth.account.delete),
        ),
      ],
    );
  }
}

/// アカウント削除の再認証に使う現在のパスワードを入力させるダイアログ。
///
/// 入力されたパスワードを `Navigator.pop` の結果として返す。キャンセル時は
/// `null` を返す。
class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog();

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 入力の有無で決定ボタンの活性を切り替える。
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.isEmpty) {
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return AlertDialog(
      title: Text(t.auth.account.deletePasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.auth.account.deletePasswordBody),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: t.auth.email.passwordLabel,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.auth.account.cancel),
        ),
        FilledButton(
          onPressed: _controller.text.isEmpty ? null : _submit,
          child: Text(t.auth.account.deleteConfirmAction),
        ),
      ],
    );
  }
}
