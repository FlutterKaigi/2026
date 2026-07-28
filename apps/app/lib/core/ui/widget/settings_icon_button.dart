import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:flutter/material.dart';

/// Opens the app settings screen from a page app bar.
class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return IconButton(
      tooltip: t.settings.title,
      onPressed: () => const SettingsRoute().push<void>(context),
      icon: const Icon(Icons.settings_outlined),
    );
  }
}
