import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:flutter/material.dart';

/// 未ログイン時にクイズ画面の代わりに出す案内。
///
/// クイズは参加・回答の記録を本人のアカウントに紐づけるため、匿名では参加でき
/// ない。導線はアカウントタブに置いてあるので、そこへ戻して各サインイン方法を
/// 選んでもらう。
class QuizSignInRequiredView extends StatelessWidget {
  const QuizSignInRequiredView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t.quiz.signInRequired.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.quiz.signInRequired.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => const AccountRoute().go(context),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    icon: const Icon(Icons.login),
                    label: Text(t.quiz.signInRequired.button),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
