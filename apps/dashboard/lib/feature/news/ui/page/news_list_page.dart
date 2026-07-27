import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/ui/confirm_delete_dialog.dart' show ConfirmDeleteDialog;
import 'package:dashboard/feature/news/data/provider/news_list_repository.dart';
import 'package:dashboard/feature/news/data/provider/news_list_state.dart';
import 'package:dashboard/feature/news/model/news_column.dart';
import 'package:dashboard/feature/news/ui/widget/news_table.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// News はこのダッシュボードが編集元（原本）のため、行ごとに都度保存する Sponsor 方式ではなく、
/// テーブル上で自由に編集・追加してから「保存」ボタンで一括コミットするワークフローにしている。
class NewsListPage extends HookConsumerWidget {
  const NewsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsListProvider);
    final newsList = newsAsync.maybeWhen(data: (news) => news, orElse: () => const <News>[]);
    final baseById = {for (final news in newsList) news.id: news};

    final edits = useState<Map<String, NewsDraft>>(const {});
    final newRows = useState<List<({String tempKey, NewsDraft draft})>>(const []);
    final newRowCounter = useState<int>(0);
    final editingCell = useState<NewsCellRef?>(null);
    final sort = useState<NewsSort?>(null);
    final invalidCells = useState<Map<String, Set<NewsColumn>>>(const {});
    final isSaving = useState(false);

    // 他の管理者の操作等で既存行が Firestore 上から無くなった場合、その行への
    // 下書き・バリデーションエラーが残り続けて「保存」件数が解消できなくなるのを防ぐ。
    useEffect(() {
      final currentIds = newsList.map((news) => news.id).toSet();
      if (edits.value.keys.any((id) => !currentIds.contains(id))) {
        final next = {...edits.value}..removeWhere((id, _) => !currentIds.contains(id));
        edits.value = next;
      }
      final currentTempKeys = newRows.value.map((entry) => entry.tempKey).toSet();
      final validKeys = {...currentIds, ...currentTempKeys};
      if (invalidCells.value.keys.any((key) => !validKeys.contains(key))) {
        final next = {...invalidCells.value}..removeWhere((key, _) => !validKeys.contains(key));
        invalidCells.value = next;
      }
      return null;
    }, [newsList]);

    NewsDraft draftOf(News news) => (
      titleJa: news.title.ja,
      titleEn: news.title.en,
      urlJa: news.url.ja,
      urlEn: news.url.en,
      publishedAt: news.publishedAt,
    );

    bool draftEquals(NewsDraft a, NewsDraft b) =>
        a.titleJa == b.titleJa &&
        a.titleEn == b.titleEn &&
        a.urlJa == b.urlJa &&
        a.urlEn == b.urlEn &&
        a.publishedAt.isAtSameMomentAs(b.publishedAt);

    void clearInvalid(String rowKey, NewsColumn column) {
      final current = invalidCells.value[rowKey];
      if (current == null || !current.contains(column)) return;
      final updatedSet = {...current}..remove(column);
      final next = {...invalidCells.value};
      if (updatedSet.isEmpty) {
        next.remove(rowKey);
      } else {
        next[rowKey] = updatedSet;
      }
      invalidCells.value = next;
    }

    void updateDraft(NewsRow row, NewsDraft nextDraft) {
      if (row.isNew) {
        newRows.value = [
          for (final entry in newRows.value)
            entry.tempKey == row.rowKey ? (tempKey: entry.tempKey, draft: nextDraft) : entry,
        ];
        return;
      }
      final newsId = row.newsId!;
      final base = baseById[newsId];
      final next = {...edits.value};
      if (base != null && draftEquals(draftOf(base), nextDraft)) {
        next.remove(newsId);
      } else {
        next[newsId] = nextDraft;
      }
      edits.value = next;
    }

    List<NewsRow> buildRows() {
      final newRowEntries = <NewsRow>[
        for (final entry in newRows.value)
          (rowKey: entry.tempKey, newsId: null, isNew: true, draft: entry.draft, updatedAt: null, isDirty: true),
      ];

      final existingRows = <NewsRow>[
        for (final news in newsList)
          (
            rowKey: news.id,
            newsId: news.id,
            isNew: false,
            draft: edits.value[news.id] ?? draftOf(news),
            updatedAt: news.updatedAt,
            isDirty: edits.value.containsKey(news.id),
          ),
      ];

      final currentSort = sort.value;
      if (currentSort != null) {
        existingRows.sort(
          (a, b) => currentSort.ascending ? currentSort.column.compare(a, b) : currentSort.column.compare(b, a),
        );
      }

      return [...newRowEntries, ...existingRows];
    }

    void toggleSort(NewsColumn column) {
      final current = sort.value;
      if (current?.column != column) {
        sort.value = (column: column, ascending: true);
      } else if (current!.ascending) {
        sort.value = (column: column, ascending: false);
      } else {
        sort.value = null; // 3 回目のクリックでデフォルト（公開日時の降順）に戻す
      }
    }

    void addRow() {
      final tempKey = 'new-${newRowCounter.value}';
      newRowCounter.value++;
      newRows.value = [
        ...newRows.value,
        (
          tempKey: tempKey,
          draft: (titleJa: '', titleEn: '', urlJa: '', urlEn: '', publishedAt: DateTime.now()),
        ),
      ];
    }

    void discardNew(NewsRow row) {
      newRows.value = newRows.value.where((entry) => entry.tempKey != row.rowKey).toList();
      if (invalidCells.value.containsKey(row.rowKey)) {
        final next = {...invalidCells.value}..remove(row.rowKey);
        invalidCells.value = next;
      }
    }

    void submitText(NewsRow row, NewsColumn column, String text) {
      editingCell.value = null;
      clearInvalid(row.rowKey, column);
      updateDraft(row, column.applyText(row.draft, text.trim()));
    }

    Future<void> pickPublishedAt(NewsRow row) async {
      final picked = await context.pickDateTime(initial: row.draft.publishedAt);
      if (picked == null) return;
      if (!context.mounted) return;
      updateDraft(row, NewsColumn.publishedAt.applyPublishedAt(row.draft, picked));
    }

    Future<void> deleteExisting(NewsRow row) async {
      final newsId = row.newsId!;
      await ConfirmDeleteDialog.show(
        context: context,
        name: row.draft.titleJa,
        onConfirm: () async {
          try {
            await ref.read(newsListRepositoryProvider).delete(newsId);
            if (edits.value.containsKey(newsId)) {
              final next = {...edits.value}..remove(newsId);
              edits.value = next;
            }
            if (context.mounted) context.showSnackBar('削除しました');
          } catch (e) {
            if (context.mounted) context.showSnackBar('削除に失敗しました: $e');
          }
        },
      );
    }

    Future<void> save() async {
      final dirtyExisting = [
        for (final entry in edits.value.entries)
          if (baseById[entry.key] != null) (newsId: entry.key, createdAt: baseById[entry.key]!.createdAt, draft: entry.value),
      ];
      final pendingNew = newRows.value;

      final nextInvalid = <String, Set<NewsColumn>>{};
      final validExisting = <({String newsId, DateTime createdAt, NewsDraft draft})>[];
      for (final item in dirtyExisting) {
        final invalid = NewsColumn.validate(item.draft);
        if (invalid.isEmpty) {
          validExisting.add(item);
        } else {
          nextInvalid[item.newsId] = invalid;
        }
      }
      final validNew = <({String tempKey, NewsDraft draft})>[];
      for (final item in pendingNew) {
        final invalid = NewsColumn.validate(item.draft);
        if (invalid.isEmpty) {
          validNew.add(item);
        } else {
          nextInvalid[item.tempKey] = invalid;
        }
      }
      invalidCells.value = nextInvalid;

      if (validExisting.isEmpty && validNew.isEmpty) {
        if (nextInvalid.isNotEmpty && context.mounted) {
          context.showSnackBar('入力エラーがあるため保存できません');
        }
        return;
      }

      isSaving.value = true;
      var successCount = 0;
      var failureCount = 0;
      final repository = ref.read(newsListRepositoryProvider);

      for (final item in validExisting) {
        try {
          await repository.save(
            News(
              id: item.newsId,
              title: LocaleMap(ja: item.draft.titleJa.trim(), en: item.draft.titleEn.trim()),
              url: LocaleMap(ja: item.draft.urlJa.trim(), en: item.draft.urlEn.trim()),
              publishedAt: item.draft.publishedAt,
              createdAt: item.createdAt,
              updatedAt: DateTime.now(),
            ),
          );
          successCount++;
          final next = {...edits.value}..remove(item.newsId);
          edits.value = next;
        } catch (_) {
          failureCount++;
        }
      }

      final savedTempKeys = <String>{};
      for (final item in validNew) {
        try {
          await repository.save(
            News(
              id: '',
              title: LocaleMap(ja: item.draft.titleJa.trim(), en: item.draft.titleEn.trim()),
              url: LocaleMap(ja: item.draft.urlJa.trim(), en: item.draft.urlEn.trim()),
              publishedAt: item.draft.publishedAt,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          successCount++;
          savedTempKeys.add(item.tempKey);
        } catch (_) {
          failureCount++;
        }
      }
      if (savedTempKeys.isNotEmpty) {
        newRows.value = newRows.value.where((entry) => !savedTempKeys.contains(entry.tempKey)).toList();
      }

      isSaving.value = false;
      if (!context.mounted) return;

      final skippedCount = nextInvalid.length;
      final parts = <String>[
        if (successCount > 0) '$successCount件保存しました',
        if (failureCount > 0) '$failureCount件の保存に失敗しました',
        if (skippedCount > 0) '$skippedCount件は入力エラーのため未保存です',
      ];
      context.showSnackBar(parts.isEmpty ? '変更はありません' : parts.join('、'));
    }

    final dirtyCount = edits.value.length + newRows.value.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(onPressed: addRow, icon: const Icon(Icons.add), label: const Text('行を追加')),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  '保存するまで変更は反映されません。ページを再読み込みすると未保存の変更は失われます。',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              FilledButton.icon(
                onPressed: dirtyCount == 0 || isSaving.value ? null : save,
                icon: isSaving.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text('保存 ($dirtyCount件)'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: newsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('エラー: $e')),
            data: (_) {
              final rows = buildRows();
              if (rows.isEmpty) {
                return const Center(child: Text('ニュースがありません'));
              }
              return SelectionArea(
                child: NewsTable(
                  rows: rows,
                  editingCell: editingCell.value,
                  sort: sort.value,
                  invalidCells: invalidCells.value,
                  isReadOnly: isSaving.value,
                  onSortRequested: toggleSort,
                  onEditStarted: (row, column) => editingCell.value = (rowKey: row.rowKey, column: column),
                  onEditCancelled: () => editingCell.value = null,
                  onTextSubmitted: submitText,
                  onPickPublishedAt: pickPublishedAt,
                  onDeleteExisting: deleteExisting,
                  onDiscardNew: discardNew,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
