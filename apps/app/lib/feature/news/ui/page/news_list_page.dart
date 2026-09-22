import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/core/ui/widget/settings_icon_button.dart';
import 'package:app/feature/news/data/provider/news_list_provider.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

/// Lists published news items.
class NewsListPage extends ConsumerWidget {
  const NewsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final newsList = ref.watch(newsListProvider);
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
          t.news.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [SettingsIconButton()],
      ),
      body: AppScrollbar(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: switch (newsList) {
              AsyncData(:final value) when value.isEmpty => Center(
                child: Text(t.news.empty),
              ),
              AsyncData(:final value) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(newsListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _NewsTile(news: value[index]),
                ),
              ),
              AsyncError(:final error) => AppErrorView(
                error: error,
                onRetry: () => ref.invalidate(newsListProvider),
              ),
              AsyncLoading() => const Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.news});

  final News news;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final rawUrl = news.url.resolve(locale);
    final uri = rawUrl.isEmpty ? null : Uri.tryParse(rawUrl);
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        news.title.resolve(locale),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        DateFormat.yMMMMd(locale.toLanguageTag()).format(news.publishedAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: uri == null ? null : const Icon(Icons.open_in_new, size: 20),
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
