import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

String supportLtErrorMessage(Object error, {required String fallback}) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => '管理者権限が必要です。確認済みの flutterkaigi.jp アカウントと管理者登録を確認してください。',
      'unauthenticated' => 'セッションの有効期限が切れています。再度サインインしてください。',
      'resource-exhausted' => '操作が集中しています。少し時間をおいて再試行してください。',
      _ => fallback,
    };
  }
  return fallback;
}

class SupportLtLoadError extends StatelessWidget {
  const SupportLtLoadError({super.key, required this.message, required this.retryKey, required this.onRetry});

  final String message;
  final Key retryKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: retryKey,
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('再読み込み'),
        ),
      ],
    );
  }
}
