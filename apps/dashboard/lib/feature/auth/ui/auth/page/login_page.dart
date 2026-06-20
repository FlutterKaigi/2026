import 'package:dashboard/feature/auth/data/provider/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> signIn() async {
      isLoading.value = true;
      errorMessage.value = null;
      try {
        await ref.read(authRepositoryProvider).signInWithGoogle();
      } catch (e) {
        errorMessage.value = 'サインインに失敗しました';
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: isLoading.value ? null : signIn,
              icon: isLoading.value
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flutter_dash),
              label: const Text('Sign in with Google'),
            ),
            if (errorMessage.value != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage.value!,
                style: TextStyle(color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
