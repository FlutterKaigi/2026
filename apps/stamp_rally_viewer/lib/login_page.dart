import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (mounted) setState(() => _message = success);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _message = authErrorMessage(error));
    } catch (_) {
      if (mounted) setState(() => _message = 'ログイン処理に失敗しました。時間をおいて再試行してください。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _signIn() {
    if (_busy || !_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    _run(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmailAndPassword(
            email: _email.text.trim(),
            password: _password.text,
          ),
    );
  }

  void _resetPassword() {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _message = 'パスワード再設定の送信先メールアドレスを入力してください。');
      return;
    }
    _run(
      () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email: email),
      success: '再設定可能なアカウントの場合、メールを送信しました。受信トレイをご確認ください。',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Image.asset('assets/shuriken-logo.png', width: 64, height: 64)),
                  const SizedBox(height: 16),
                  Text('FlutterKaigi 2026', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'スタンプラリーの状況確認',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '獲得したスタンプのスポンサーと、景品の交換状況を確認できます。公式アプリと同じアカウントでログインしてください。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(ref.read(authRepositoryProvider).signInWithGoogle),
                    icon: Image.asset('assets/g-logo.png', width: 20, height: 20, excludeFromSemantics: true),
                    label: const Text('Google でログイン'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('または')),
                        Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _email,
                            enabled: !_busy,
                            decoration: const InputDecoration(labelText: 'メールアドレス'),
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            validator: (value) =>
                                value == null || !value.trim().contains('@') ? 'メールアドレスを入力してください。' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            enabled: !_busy,
                            obscureText: !_showPassword,
                            autofillHints: const [AutofillHints.password],
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signIn(),
                            decoration: InputDecoration(
                              labelText: 'パスワード',
                              suffixIcon: IconButton(
                                tooltip: _showPassword ? 'パスワードを隠す' : 'パスワードを表示',
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                                icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'パスワードを入力してください。' : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(onPressed: _busy ? null : _signIn, child: const Text('メールアドレスでログイン')),
                          ),
                          TextButton(
                            onPressed: _busy ? null : _resetPassword,
                            child: const Text('パスワードを忘れた方'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_busy) const LinearProgressIndicator(semanticsLabel: 'ログイン処理中'),
                  if (_message case final message?)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(liveRegion: true, child: Text(message)),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Apple でログインした方は、iOS の公式アプリでスタンプ数・景品の交換状況をご確認ください。\nこのページではスタンプの取得・景品の交換操作は行えません。',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

String? authErrorMessage(FirebaseAuthException error) => switch (error.code) {
  'popup-closed-by-user' || 'cancelled-popup-request' || 'canceled' => null,
  'invalid-email' => 'メールアドレスの形式を確認してください。',
  'invalid-credential' || 'user-not-found' || 'wrong-password' => 'メールアドレスまたはパスワードが正しくありません。',
  'user-disabled' => 'このアカウントは無効になっています。',
  'too-many-requests' => '操作が集中しています。しばらく待ってから再試行してください。',
  'network-request-failed' => '通信に失敗しました。ネットワーク接続を確認してください。',
  'popup-blocked' => 'ブラウザのポップアップを許可して、再度ログインしてください。',
  'account-exists-with-different-credential' => '公式アプリで使用したログイン方法でお試しください。',
  'unauthorized-domain' || 'operation-not-allowed' => 'このサイトのログイン設定が完了していません。運営にお問い合わせください。',
  _ => 'ログイン処理に失敗しました。時間をおいて再試行してください。',
};
