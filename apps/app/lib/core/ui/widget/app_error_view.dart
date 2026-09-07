import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Shared Firebase-aware error state based on the FlutterKaigi 2025 screen.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return AppScrollbar(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'res/assets/dashumaru_magao.webp',
                  height: 180,
                  fit: BoxFit.contain,
                  semanticLabel: t.error.imageSemanticLabel,
                ),
                const SizedBox(height: 24),
                Text(
                  t.error.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _messageFor(t),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(t.error.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _messageFor(Translations t) {
    if (error case FirebaseException(:final code)) {
      return switch (code) {
        'permission-denied' || 'unauthenticated' => t.error.permissionDenied,
        'unavailable' || 'network-request-failed' => t.error.unavailable,
        'deadline-exceeded' => t.error.timeout,
        _ => t.error.message,
      };
    }
    return t.error.message;
  }
}
