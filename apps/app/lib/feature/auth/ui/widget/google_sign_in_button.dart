import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/ui/widget/sign_in_method_button_style.dart';
import 'package:flutter/material.dart';

/// Google のブランドガイドラインに沿ったサインインボタン。
///
/// 公式の G ロゴ、配色、枠線、余白を使い、Apple・メールのボタンと同じ幅で
/// 表示する。ラベルは Google が推奨するローカライズ済み文言を使う。
/// https://developers.google.com/identity/branding-guidelines
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({required this.onPressed, super.key});

  /// 押下時の処理。`null` のときは非活性表示になる。
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF131314) : Colors.white;
    final borderColor = isDark ? const Color(0xFF8E918F) : const Color(0xFF747775);
    final foregroundColor = isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: t.auth.signIn.withGoogle,
      child: SizedBox(
        height: signInMethodButtonHeight,
        width: double.infinity,
        child: Opacity(
          opacity: onPressed == null ? 0.38 : 1,
          child: Material(
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: signInMethodButtonBorderRadius,
              side: BorderSide(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PositionedDirectional(
                    start: signInMethodButtonIconInset,
                    child: Image.asset(
                      'res/assets/google_sign_in/g-logo.png',
                      width: signInMethodButtonIconSize,
                      height: signInMethodButtonIconSize,
                      excludeFromSemantics: true,
                    ),
                  ),
                  ExcludeSemantics(
                    child: Text(
                      t.auth.signIn.withGoogle,
                      textAlign: TextAlign.center,
                      style: signInMethodButtonLabelStyle.copyWith(color: foregroundColor),
                    ),
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
