import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/package_info.dart';
import 'package:app/core/provider/theme_mode.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Shows event/app information and basic app settings.
class EventInfoPage extends ConsumerWidget {
  const EventInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final packageInfo = ref.watch(packageInfoProvider);
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.eventInfo.title)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t.app.title),
            subtitle: Text(t.eventInfo.version),
            trailing: Text(
              switch (packageInfo) {
                AsyncData(:final value) => '${value.version} (${value.buildNumber})',
                AsyncError() => '—',
                AsyncLoading() => '…',
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              t.eventInfo.themeMode.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(t.eventInfo.themeMode.system),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(t.eventInfo.themeMode.light),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(t.eventInfo.themeMode.dark),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) => unawaited(
                ref.read(themeModeProvider.notifier).set(selection.first),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
