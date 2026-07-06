import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/news/data/provider/news_list_provider.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lists published news items.
class NewsListPage extends ConsumerWidget {
  const NewsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final newsList = ref.watch(newsListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.news.title)),
      body: switch (newsList) {
        AsyncData(:final value) when value.isEmpty => Center(
          child: Text(t.news.empty),
        ),
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(newsListProvider),
          child: ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _NewsTile(news: value[index]),
          ),
        ),
        AsyncError() => Center(child: Text(t.news.error)),
        AsyncLoading() => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      },
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.news});

  final News news;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final rawUrl = news.url.resolve(locale);
    final uri = rawUrl.isEmpty ? null : Uri.tryParse(rawUrl);
    return ListTile(
      title: Text(news.title.resolve(locale)),
      subtitle: Text(DateFormat('yyyy/MM/dd').format(news.publishedAt)),
      trailing: uri == null ? null : const Icon(Icons.open_in_new),
      onTap: uri == null
          ? null
          : () => unawaited(
              launchUrl(uri, mode: LaunchMode.externalApplication),
            ),
    );
  }
}
