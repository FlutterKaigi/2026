import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/auth_error_message.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Whether the form signs in to an existing account or creates a new one.
enum _EmailAuthMode { signIn, createAccount }

/// Email/password sign-in, account creation, and password reset.
class EmailSignInPage extends HookConsumerWidget {
  const EmailSignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final mode = useState(_EmailAuthMode.signIn);
    final obscurePassword = useState(true);
    final isProcessing = useState(false);

    void showMessage(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> run(Future<void> Function() action, {required void Function() onSuccess}) async {
      if (isProcessing.value) {
        return;
      }
      isProcessing.value = true;
      try {
        await action();
        if (context.mounted) {
          onSuccess();
        }
      } on FirebaseAuthException catch (exception) {
        final message = authErrorMessage(t, exception);
        if (message != null && context.mounted) {
          showMessage(message);
        }
      } finally {
        isProcessing.value = false;
      }
    }

    // アカウントタブへ戻る。push で開いたときは pop し、ディープリンクで
    // 直接開いたときは宣言的スタックの親 `/account` へ戻す。
    void backToAccount() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        const AccountRoute().go(context);
      }
    }

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }
      final repository = ref.read(authRepositoryProvider);
      final email = emailController.text.trim();
      final password = passwordController.text;
      await run(
        () => switch (mode.value) {
          _EmailAuthMode.signIn => repository.signInWithEmailAndPassword(email: email, password: password),
          _EmailAuthMode.createAccount => repository.createUserWithEmailAndPassword(email: email, password: password),
        },
        onSuccess: backToAccount,
      );
    }

    Future<void> resetPassword() async {
      final email = emailController.text.trim();
      if (email.isEmpty) {
        showMessage(t.auth.email.emailRequired);
        return;
      }
      await run(
        () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email: email),
        onSuccess: () => showMessage(t.auth.email.resetEmailSent),
      );
    }

    final submitLabel = switch (mode.value) {
      _EmailAuthMode.signIn => t.auth.email.signInButton,
      _EmailAuthMode.createAccount => t.auth.email.createAccountButton,
    };

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: backToAccount,
          icon: const BackButtonIcon(),
        ),
        title: Text(
          t.auth.email.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: AppScrollbar(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: formKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: emailController,
                        enabled: !isProcessing.value,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: t.auth.email.emailLabel,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? t.auth.email.emailRequired : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        enabled: !isProcessing.value,
                        obscureText: obscurePassword.value,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) async => submit(),
                        decoration: InputDecoration(
                          labelText: t.auth.email.passwordLabel,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: obscurePassword.value ? t.auth.email.showPassword : t.auth.email.hidePassword,
                            onPressed: () => obscurePassword.value = !obscurePassword.value,
                            icon: Icon(
                              obscurePassword.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? t.auth.email.passwordRequired : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: isProcessing.value ? null : () async => submit(),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        child: isProcessing.value
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(submitLabel),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: isProcessing.value
                            ? null
                            : () => mode.value = switch (mode.value) {
                                _EmailAuthMode.signIn => _EmailAuthMode.createAccount,
                                _EmailAuthMode.createAccount => _EmailAuthMode.signIn,
                              },
                        child: Text(
                          switch (mode.value) {
                            _EmailAuthMode.signIn => t.auth.email.switchToCreateAccount,
                            _EmailAuthMode.createAccount => t.auth.email.switchToSignIn,
                          },
                        ),
                      ),
                      if (mode.value == _EmailAuthMode.signIn)
                        TextButton(
                          onPressed: isProcessing.value ? null : () async => resetPassword(),
                          child: Text(t.auth.email.forgotPassword),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
