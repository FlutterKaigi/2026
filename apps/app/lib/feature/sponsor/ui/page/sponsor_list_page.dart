import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/settings_icon_button.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/sponsor/ui/widget/sponsor_message_state_widget.dart';
import 'package:app/feature/sponsor/ui/widget/sponsor_wall_widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Shows the conference sponsor logo wall.
class SponsorListPage extends ConsumerWidget {
  const SponsorListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final sponsorWall = ref.watch(sponsorWallProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.sponsors.title),
        actions: const [SettingsIconButton()],
      ),
      body: switch (sponsorWall) {
        AsyncData(:final value) when value.isEmpty => SponsorMessageStateWidget(
          icon: Icons.business_outlined,
          title: t.sponsors.empty,
        ),
        AsyncData(:final value) => SponsorWallWidget(data: value),
        AsyncError(:final error) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(sponsorListProvider),
        ),
        AsyncLoading() => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      },
    );
  }
}
