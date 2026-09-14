import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/provider/environment.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/brand_header_card.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
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

/// Maximum width of [SignInCard]: the shared sign-in button width plus the card
/// padding on both sides.
const signInCardMaxWidth = signInMethodButtonMaxWidth + brandHeaderCardPadding * 2;

/// Brand card offering one button per available sign-in method.
///
/// Shown on the signed-out account tab and on pages that need a signed-in
/// attendee (such as Support LT registration opened from a shared link), so
/// attendees can sign in where they are.
class SignInCard extends HookConsumerWidget {
  const SignInCard({required this.title, required this.description, super.key});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final isProcessing = useState(false);
    final showsAppleSignIn = ref.watch(appleSignInAvailabilityProvider);

    Future<void> signIn(Future<void> Function(AuthRepository repository) action) async {
      if (isProcessing.value) {
        return;
      }
      isProcessing.value = true;
      try {
        await action(ref.read(authRepositoryProvider));
      } on FirebaseAuthException catch (exception, stackTrace) {
        ref.read(talkerProvider).handle(exception, stackTrace);
        final message = authErrorMessage(t, exception);
        if (message != null && context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      } finally {
        // サインインに成功するとカードごと置き換わるため、残っているときだけ戻す。
        if (context.mounted) {
          isProcessing.value = false;
        }
      }
    }

    return ConstrainedBox(
      // 認証方法が変わっても操作領域が揃うよう、ボタン列の共通の最大幅に
      // カードの余白を足した幅で制限する(枠線は内側に描かれる)。
      constraints: const BoxConstraints(maxWidth: signInCardMaxWidth),
      child: BrandHeaderCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            GoogleSignInButton(
              onPressed: isProcessing.value ? null : () async => signIn((repository) => repository.signInWithGoogle()),
            ),
            const SizedBox(height: 8),
            if (showsAppleSignIn) ...[
              AppleSignInButton(
                onPressed: isProcessing.value ? null : () async => signIn((repository) => repository.signInWithApple()),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton(
              onPressed: isProcessing.value ? null : () async => const EmailSignInRoute().push<void>(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(signInMethodButtonHeight),
                maximumSize: const Size.fromHeight(signInMethodButtonHeight),
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(borderRadius: signInMethodButtonBorderRadius),
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
            if (isProcessing.value) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
