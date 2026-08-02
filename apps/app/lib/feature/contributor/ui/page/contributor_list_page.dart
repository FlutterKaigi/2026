import 'dart:async';

import 'package:app/core/constants/app_links.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_network_image.dart';
import 'package:app/core/ui/widget/settings_icon_button.dart';
import 'package:app/feature/contributor/data/provider/contributor_list_provider.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Lists GitHub contributors to the FlutterKaigi 2026 repository.
class ContributorListPage extends ConsumerWidget {
  const ContributorListPage({super.key});

  static const _repositoryName = 'FlutterKaigi/2026';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final contributors = ref.watch(contributorListProvider);
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
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.contributors.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Semantics(
              button: true,
              label: t.contributors.openRepository,
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => unawaited(
                  launchExternalUrl(
                    context,
                    uri: Uri.parse(AppLinks.repository),
                    failureMessage: t.links.openError,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _repositoryName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.open_in_new,
                        size: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
              onRefresh: () async => ref.invalidate(contributorListProvider),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: value.length,
                itemBuilder: (context, index) => _ContributorTile(
                  contributor: value[index],
                ),
              ),
            ),
            AsyncError(:final error) => AppErrorView(
              error: error,
              onRetry: () => ref.invalidate(contributorListProvider),
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

class _ContributorTile extends StatelessWidget {
  const _ContributorTile({required this.contributor});

  final Contributor contributor;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final uri = Uri.tryParse(contributor.htmlUrl);
    return ListTile(
      dense: true,
      minTileHeight: 56,
      leading: AppNetworkAvatar(
        radius: 20,
        imageUrl: contributor.avatarUrl,
        fallback: const Icon(Icons.person_outline),
      ),
      title: Text(
        contributor.login,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        t.contributors.contributionsCount(n: contributor.contributions),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: uri == null
          ? null
          : () => unawaited(
              launchExternalUrl(
                context,
                uri: uri,
                failureMessage: t.links.openError,
              ),
            ),
    );
  }
}
