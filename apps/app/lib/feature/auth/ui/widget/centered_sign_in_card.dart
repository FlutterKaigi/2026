import 'package:app/core/ui/widget/app_page_content.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:flutter/material.dart';

/// [SignInCard] as the whole body of a signed-out page: centered vertically,
/// and scrollable when it doesn't fit on a short screen or at a large text
/// size.
class CenteredSignInCard extends StatelessWidget {
  const CenteredSignInCard({required this.title, required this.description, this.returnTo, super.key});

  final String title;
  final String description;
  final String? returnTo;

  @override
  Widget build(BuildContext context) => AppPageContent(
    maxWidth: signInCardMaxWidth,
    padding: const EdgeInsets.all(24),
    centerVertically: true,
    child: SignInCard(title: title, description: description, returnTo: returnTo),
  );
}
