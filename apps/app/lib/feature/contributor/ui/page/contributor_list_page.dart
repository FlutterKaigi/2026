import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_network_image.dart';
import 'package:app/core/ui/widget/settings_icon_button.dart';
import 'package:app/feature/contributor/data/contributor_provider.dart';
import 'package:app/feature/contributor/data/model/contributor.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Lists GitHub contributors to the FlutterKaigi 2026 repository.
class ContributorListPage extends ConsumerWidget {
  const ContributorListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final contributors = ref.watch(contributorsProvider);
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
          t.contributors.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [SettingsIconButton()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: switch (contributors) {
            AsyncData(:final value) when value.isEmpty => Center(
              child: Text(t.contributors.empty),
            ),
            AsyncData(:final value) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(contributorsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    t.contributors.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 12,
                    children: [
                      for (final contributor in value) _ContributorCell(contributor: contributor),
                    ],
                  ),
                ],
              ),
            ),
            AsyncError(:final error) => AppErrorView(
              error: error,
              onRetry: () => ref.invalidate(contributorsProvider),
            ),
            AsyncLoading() => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
          },
        ),
      ),
    );
  }
}

class _ContributorCell extends StatelessWidget {
  const _ContributorCell({required this.contributor});

  final Contributor contributor;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final uri = Uri.tryParse(contributor.htmlUrl);
    return SizedBox(
      width: 104,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: uri == null
            ? null
            : () => unawaited(
                launchExternalUrl(
                  context,
                  uri: uri,
                  failureMessage: t.links.openError,
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppNetworkAvatar(
                radius: 28,
                imageUrl: contributor.avatarUrl,
                fallback: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 8),
              Text(
                contributor.login,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.contributors.contributionsCount(n: contributor.contributions),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
