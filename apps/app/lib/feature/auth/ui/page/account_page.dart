import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/core/ui/widget/settings_icon_button.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/auth/ui/auth_error_message.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/profile/data/provider/user_profile_provider.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:app/feature/profile/ui/widget/profile_summary_card_widget.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The account tab: sign-in options while signed out, account info while
/// signed in.
class AccountPage extends HookConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final authState = ref.watch(authStateChangesProvider);
    final profileState = ref.watch(userProfileProvider);
    final isProcessing = useState(false);

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
        (repository) => repository.deleteAccount(
          password: password,
          // 再認証が通ってから、トークンが失効する前にプロフィールを消す。
          beforeDelete: () async {
            await ref.read(userProfileRepositoryProvider).delete(user.uid);
            await ref.read(exchangeTokenCacheRepositoryProvider).clear(user.uid);
            await ref.read(exchangeCodeCacheRepositoryProvider).clear(user.uid);
          },
        ),
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
          child: value == null
              ? const _SignedOutView()
              : _SignedInView(
                  user: value,
                  profileState: profileState,
                  isProcessing: isProcessing.value,
                  onRetryProfile: () => ref.invalidate(userProfileProvider),
                  onSignOut: () => runAuthAction((repository) async {
                    await ref.read(exchangeTokenCacheRepositoryProvider).clear(value.uid);
                    await ref.read(exchangeCodeCacheRepositoryProvider).clear(value.uid);
                    await repository.signOut();
                  }),
                  onDeleteAccount: () => deleteAccount(value),
                  onComingSoon: () => showMessage(t.auth.account.comingSoon),
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

/// Centered sign-in card shown while signed out.
class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SignInCard(
          title: t.auth.signIn.required,
          description: t.auth.signIn.description,
        ),
      ),
    );
  }
}

/// Signed-in account tab: profile card, missions, event entry points and
/// account actions as a top-aligned scrolling list.
class _SignedInView extends StatelessWidget {
  const _SignedInView({
    required this.user,
    required this.profileState,
    required this.isProcessing,
    required this.onRetryProfile,
    required this.onSignOut,
    required this.onDeleteAccount,
    required this.onComingSoon,
  });

  final User user;
  final AsyncValue<UserProfile?> profileState;
  final bool isProcessing;
  final VoidCallback onRetryProfile;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onDeleteAccount;

  /// Tapped an event entry point whose screen is not implemented yet.
  final VoidCallback onComingSoon;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final profile = profileState.value;
    final title = profile?.displayName ?? user.displayName ?? user.email ?? t.auth.account.noEmail;
    final subtitle = title != user.email ? user.email : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                switch (profileState) {
                  AsyncData(:final value) => ProfileCard(
                    title: title,
                    subtitle: subtitle,
                    avatarUrl: value?.avatarUrl ?? user.photoURL,
                    profile: value,
                    onEdit: () => const ProfileEditRoute().push<void>(context),
                    onCreate: () => const ProfileEditRoute().push<void>(context),
                  ),
                  AsyncError(:final error) => _ProfileLoadError(error: error, onRetry: onRetryProfile),
                  AsyncLoading() => const Card.outlined(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    ),
                  ),
                },
                const SizedBox(height: 8),
                Card.outlined(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  semanticContainer: false,
                  child: ListTile(
                    minTileHeight: 56,
                    leading: const Icon(Icons.track_changes_outlined, size: 22),
                    title: Text(t.auth.account.mission, style: theme.textTheme.bodyMedium),
                    subtitle: Text(t.auth.account.missionDescription, style: theme.textTheme.bodySmall),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: onComingSoon,
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeading(title: t.auth.account.joinEvent),
                const SizedBox(height: 8),
                Card.outlined(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  semanticContainer: false,
                  child: Column(
                    children: [
                      _NavigationTile(
                        icon: Icons.quiz_outlined,
                        title: t.auth.account.quiz,
                        onTap: onComingSoon,
                      ),
                      const Divider(height: 1),
                      _SupportLtNavigationTile(uid: user.uid),
                      const Divider(height: 1),
                      _NavigationTile(
                        icon: Icons.qr_code_2_outlined,
                        title: t.auth.account.profileExchange,
                        onTap: () => const ExchangeHomeRoute().push<void>(context),
                      ),
                      const Divider(height: 1),
                      _NavigationTile(
                        icon: Icons.image_outlined,
                        title: t.auth.account.snsPost,
                        onTap: onComingSoon,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeading(title: t.auth.account.title),
                const SizedBox(height: 8),
                Card.outlined(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  semanticContainer: false,
                  child: Column(
                    children: [
                      _NavigationTile(
                        icon: Icons.logout,
                        title: t.auth.account.signOut,
                        onTap: isProcessing ? null : () => unawaited(onSignOut()),
                      ),
                      const Divider(height: 1),
                      _NavigationTile(
                        icon: Icons.delete_outline,
                        title: t.auth.account.delete,
                        color: theme.colorScheme.error,
                        showsChevron: false,
                        onTap: isProcessing ? null : () => unawaited(onDeleteAccount()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _SupportLtNavigationTile extends ConsumerWidget {
  const _SupportLtNavigationTile({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    ref.listen(supportLtRegistrationProvider(uid), (_, next) {
      // The tile has no room for an error view; the Support LT page offers a
      // retry. Record the failure so a permission or network problem is visible.
      if (next case AsyncError(:final error, :final stackTrace)) {
        ref.read(talkerProvider).handle(error, stackTrace);
      }
    });
    // `value` keeps the last registration through reloads so the badge does
    // not flicker while the stream resubscribes.
    final isRegistered = ref.watch(supportLtRegistrationProvider(uid)).value != null;
    return _NavigationTile(
      icon: Icons.mic_none_outlined,
      title: t.auth.account.lightningTalks,
      badge: isRegistered ? _RegisteredBadge(label: t.supportLt.registeredStatus) : null,
      onTap: () => const SupportLtRoute().push<void>(context),
    );
  }
}

/// Compact tonal badge marking a completed Support LT registration.
class _RegisteredBadge extends StatelessWidget {
  const _RegisteredBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      // プロフィール編集ボタンと同じく、アカウントタブの強調は primary 系で揃える。
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 8, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}

/// Dense in-app navigation row, matching the link tiles on the event tab.
class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.showsChevron = true,
    this.badge,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  /// Overrides the icon and label color (e.g. the error color for delete).
  final Color? color;
  final bool showsChevron;

  /// Shown before the chevron, e.g. a status badge.
  final Widget? badge;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    minTileHeight: 48,
    enabled: onTap != null,
    iconColor: color,
    textColor: color,
    leading: Icon(icon, size: 22),
    title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
    trailing: badge == null && !showsChevron
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge case final badge?) ...[badge, const SizedBox(width: 4)],
              if (showsChevron) const Icon(Icons.chevron_right, size: 20),
            ],
          ),
    onTap: onTap,
  );
}

/// Compact inline error for the profile section so the rest of the account
/// tab (sign-out, delete) stays usable.
class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.error.title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(t.error.message, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(t.error.retry)),
          ],
        ),
      ),
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
