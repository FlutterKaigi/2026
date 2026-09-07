import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/app_locale.dart';
import 'package:app/core/provider/package_info.dart';
import 'package:app/core/provider/theme_mode.dart';
import 'package:app/core/router/router.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Lets the user change appearance and language preferences.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final appLocale = ref.watch(appLocaleProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appVersion = switch (packageInfo) {
      AsyncData(:final value) => '${value.version} (${value.buildNumber})',
      AsyncError() => '—',
      AsyncLoading() => '…',
    };

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              const EventInfoRoute().go(context);
            }
          },
          icon: const BackButtonIcon(),
        ),
        title: Text(
          t.settings.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeading(title: t.settings.appearance),
                  const SizedBox(height: 8),
                  _SettingsSelectionCard<ThemeMode>(
                    icon: Icons.palette_outlined,
                    title: t.settings.themeMode.title,
                    selected: themeMode,
                    failureMessage: t.settings.saveError,
                    items: [
                      (
                        value: ThemeMode.system,
                        label: t.settings.themeMode.system,
                      ),
                      (
                        value: ThemeMode.light,
                        label: t.settings.themeMode.light,
                      ),
                      (
                        value: ThemeMode.dark,
                        label: t.settings.themeMode.dark,
                      ),
                    ],
                    onSelected: ref.read(themeModeProvider.notifier).set,
                  ),
                  const SizedBox(height: 8),
                  _SettingsSelectionCard<AppLocale>(
                    icon: Icons.language_outlined,
                    title: t.settings.language.title,
                    selected: appLocale,
                    failureMessage: t.settings.saveError,
                    items: [
                      (
                        value: AppLocale.ja,
                        label: t.settings.language.japanese,
                      ),
                      (
                        value: AppLocale.en,
                        label: t.settings.language.english,
                      ),
                    ],
                    onSelected: ref.read(appLocaleProvider.notifier).set,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeading(title: t.settings.appInfo),
                  const SizedBox(height: 8),
                  Card.outlined(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      minTileHeight: 48,
                      leading: const Icon(Icons.info_outline, size: 22),
                      title: Text(t.app.title),
                      subtitle: Text(t.settings.version),
                      trailing: Text(appVersion),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    ),
  );
}

class _SettingsSelectionCard<T> extends StatelessWidget {
  const _SettingsSelectionCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.failureMessage,
    required this.items,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final T selected;
  final String failureMessage;
  final List<({T value, String label})> items;
  final Future<void> Function(T value) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RadioGroup<T>(
              groupValue: selected,
              onChanged: (value) async {
                if (value != null) {
                  try {
                    await onSelected(value);
                  } on Object {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(failureMessage)),
                      );
                    }
                  }
                }
              },
              child: Column(
                children: [
                  for (final item in items)
                    RadioListTile<T>(
                      value: item.value,
                      title: Text(item.label),
                      dense: true,
                      minTileHeight: 48,
                      contentPadding: EdgeInsets.zero,
                      selected: item.value == selected,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
