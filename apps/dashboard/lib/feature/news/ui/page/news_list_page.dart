import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/extension/date_time_extension.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/core/ui/confirm_delete_dialog.dart' show ConfirmDeleteDialog;
import 'package:dashboard/feature/news/data/provider/news_list_state.dart';
import 'package:dashboard/feature/news/data/provider/news_list_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NewsListPage extends ConsumerWidget {
  const NewsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsList = ref.watch(newsListProvider);

    Future<void> deleteNews(News news) async {
      await ConfirmDeleteDialog.show(
        context: context,
        name: news.title.ja,
        onConfirm: () async {
          try {
            await ref.read(newsListRepositoryProvider).delete(news.id);
            if (context.mounted) {
              context.showSnackBar('削除しました');
            }
          } catch (e) {
            if (context.mounted) {
              context.showSnackBar('削除に失敗しました: $e');
            }
          }
        },
      );
    }

    return Stack(
      children: [
        newsList.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (news) => news.isEmpty
              ? const Center(child: Text('ニュースがありません'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: news.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _NewsListItem(
                    news: news[index],
                    onEdit: () => NewsEditRoute($extra: news[index]).push(context),
                    onDelete: () => deleteNews(news[index]),
                  ),
                ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => const NewsEditRoute().push(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _NewsListItem extends StatelessWidget {
  const _NewsListItem({required this.news, required this.onEdit, required this.onDelete});

  final News news;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(news.title.ja),
      subtitle: Text('${news.publishedAt.formatDate()}  EN: ${news.title.en}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: '編集', onPressed: onEdit),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '削除',
            color: Colors.red,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
