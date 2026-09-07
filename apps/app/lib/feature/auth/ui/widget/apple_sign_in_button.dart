import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/ui/widget/sign_in_method_button_style.dart';
import 'package:flutter/material.dart';

/// Apple の Human Interface Guidelines に沿ったサインインボタン。
///
/// Apple のロゴ、公式の黒・白スタイルを維持しつつ、他の認証手段と同じ
/// タイポグラフィとアイコン位置で表示する。
/// https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({required this.onPressed, super.key});

  /// 押下時の処理。`null` のときは非活性表示になる。
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Translations.of(context);
    final backgroundColor = isDark ? Colors.white : Colors.black;
    final foregroundColor = isDark ? Colors.black : Colors.white;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: t.auth.signIn.withApple,
      child: SizedBox(
        width: double.infinity,
        height: signInMethodButtonHeight,
        child: Opacity(
          opacity: onPressed == null ? 0.38 : 1,
          child: Material(
            color: backgroundColor,
            borderRadius: signInMethodButtonBorderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PositionedDirectional(
                    start: signInMethodButtonIconInset,
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.apple,
                        size: signInMethodAppleIconSize,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Text(
                      t.auth.signIn.withApple,
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
