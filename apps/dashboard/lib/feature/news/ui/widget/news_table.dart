import 'package:dashboard/feature/news/model/news_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// News 一覧の Excel 風テーブル。
///
/// - ヘッダー行と先頭列（タイトル ja）を固定
/// - セルをダブルクリックするとインライン編集モードに切り替わる（title/url 列のみ）
/// - 公開日時列はタップで直接日時ピッカーを開く（テキスト入力ではないため）
/// - ヘッダークリックでソート（昇順 → 降順 → 解除）
/// - 編集内容はこのウィジェットの外側（呼び出し元の下書き状態）に反映されるのみで、
///   ここでは Firestore への保存は一切行わない
class NewsTable extends HookWidget {
  const NewsTable({
    super.key,
    required this.rows,
    required this.editingCell,
    required this.sort,
    required this.invalidCells,
    required this.isReadOnly,
    required this.onSortRequested,
    required this.onEditStarted,
    required this.onEditCancelled,
    required this.onTextSubmitted,
    required this.onPickPublishedAt,
    required this.onDeleteExisting,
    required this.onDiscardNew,
  });

  final List<NewsRow> rows;
  final NewsCellRef? editingCell;
  final NewsSort? sort;
  final Map<String, Set<NewsColumn>> invalidCells;

  /// 保存処理の実行中は true。保存対象のスナップショットとの不整合
  /// （保存中の行を削除・破棄・再編集することによるデータ不整合）を防ぐため、
  /// 行の編集・削除・破棄を一時的に無効化する。
  final bool isReadOnly;
  final ValueChanged<NewsColumn> onSortRequested;
  final void Function(NewsRow row, NewsColumn column) onEditStarted;
  final VoidCallback onEditCancelled;
  final void Function(NewsRow row, NewsColumn column, String text) onTextSubmitted;
  final ValueChanged<NewsRow> onPickPublishedAt;
  final ValueChanged<NewsRow> onDeleteExisting;
  final ValueChanged<NewsRow> onDiscardNew;

  static const _headerHeight = 44.0;
  static const _rowHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gridLine = BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5));
    final verticalController = useScrollController();
    final horizontalController = useScrollController();

    Color rowBackgroundColor(int index) {
      if (index == 0) return theme.colorScheme.surfaceContainerHigh;
      final row = rows[index - 1];
      if (row.isNew) return theme.colorScheme.tertiaryContainer.withValues(alpha: 0.25);
      if (row.isDirty) return theme.colorScheme.primaryContainer.withValues(alpha: 0.18);
      return index.isEven ? theme.colorScheme.surfaceContainerLowest : theme.colorScheme.surface;
    }

    final table = TableView.builder(
      verticalDetails: ScrollableDetails.vertical(controller: verticalController),
      horizontalDetails: ScrollableDetails.horizontal(controller: horizontalController),
      columnCount: NewsColumn.values.length,
      rowCount: rows.length + 1,
      pinnedRowCount: 1,
      pinnedColumnCount: 1,
      columnBuilder: (index) => TableSpan(
        extent: FixedTableSpanExtent(NewsColumn.values[index].width),
        foregroundDecoration: TableSpanDecoration(border: TableSpanBorder(trailing: gridLine)),
      ),
      rowBuilder: (index) => TableSpan(
        extent: FixedTableSpanExtent(index == 0 ? _headerHeight : _rowHeight),
        backgroundDecoration: TableSpanDecoration(color: rowBackgroundColor(index)),
        foregroundDecoration: TableSpanDecoration(border: TableSpanBorder(trailing: gridLine)),
      ),
      cellBuilder: (context, vicinity) {
        final column = NewsColumn.values[vicinity.column];
        if (vicinity.row == 0) {
          return TableViewCell(
            child: _HeaderCell(column: column, sort: sort, onSortRequested: onSortRequested),
          );
        }
        final row = rows[vicinity.row - 1];
        return TableViewCell(child: _buildDataCell(context, row, column));
      },
    );

    return Scrollbar(
      controller: verticalController,
      thumbVisibility: true,
      trackVisibility: true,
      notificationPredicate: (notification) => notification.metrics.axis == Axis.vertical,
      child: Scrollbar(
        controller: horizontalController,
        thumbVisibility: true,
        trackVisibility: true,
        notificationPredicate: (notification) => notification.metrics.axis == Axis.horizontal,
        child: table,
      ),
    );
  }

  Widget _buildDataCell(BuildContext context, NewsRow row, NewsColumn column) {
    final theme = Theme.of(context);
    final isInvalid = invalidCells[row.rowKey]?.contains(column) ?? false;
    final isEditing = editingCell != null && editingCell!.rowKey == row.rowKey && editingCell!.column == column;

    if (isEditing && column.isInlineTextEditable) {
      return _TextEditingCell(
        key: ValueKey('edit-${row.rowKey}-${column.name}'),
        initialValue: column.textValueOf(row),
        onSubmitted: (text) => onTextSubmitted(row, column, text),
        onCancelled: onEditCancelled,
      );
    }

    final content = switch (column) {
      NewsColumn.actions => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (row.isNew)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: '破棄',
              onPressed: isReadOnly ? null : () => onDiscardNew(row),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: '削除',
              color: Colors.red,
              onPressed: isReadOnly ? null : () => onDeleteExisting(row),
            ),
        ],
      ),
      NewsColumn.publishedAt => InkWell(
        onTap: isReadOnly ? null : () => onPickPublishedAt(row),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                column.textValueOf(row),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      NewsColumn.updatedAt => Text(
        column.textValueOf(row),
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      _ => Row(
        children: [
          if (column == NewsColumn.titleJa && row.isNew) ...[
            _NewBadge(),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              column.textValueOf(row),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    };

    final cell = GestureDetector(
      onDoubleTap: (!isReadOnly && column.isInlineTextEditable) ? () => onEditStarted(row, column) : null,
      child: Container(
        color: isInvalid ? theme.colorScheme.errorContainer.withValues(alpha: 0.4) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: content,
      ),
    );

    if (!isInvalid) return cell;
    return Tooltip(
      message: column.isUrl ? '有効なURLを入力してください' : '入力してください',
      child: cell,
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
        border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '新規',
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.tertiary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.column, required this.sort, required this.onSortRequested});

  final NewsColumn column;
  final NewsSort? sort;
  final ValueChanged<NewsColumn> onSortRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSorted = sort?.column == column;
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            column.label,
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (column.isInlineTextEditable || column.isDateTime) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: column.isDateTime ? 'クリックで編集可能' : 'ダブルクリックで編集可能',
            child: Icon(
              column.isDateTime ? Icons.calendar_today : Icons.edit_outlined,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );

    if (!column.isSortable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: label,
      );
    }

    return InkWell(
      onTap: () => onSortRequested(column),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Flexible(child: label),
            const SizedBox(width: 4),
            Icon(
              isSorted ? (sort!.ascending ? Icons.arrow_upward : Icons.arrow_downward) : Icons.unfold_more,
              size: 16,
              color: isSorted ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

/// テキストセルのインライン編集。Enter または他のセルへのフォーカス移動で確定、Esc でキャンセル。
///
/// 確定してもここでは何も永続化しない。呼び出し元がローカルの下書き状態を更新するのみで、
/// Firestore への書き込みは一覧ページの「保存」ボタン押下時にまとめて行われる。
class _TextEditingCell extends HookWidget {
  const _TextEditingCell({
    super.key,
    required this.initialValue,
    required this.onSubmitted,
    required this.onCancelled,
  });

  final String initialValue;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancelled;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialValue);
    final focusNode = useFocusNode();
    final settled = useRef(false);

    void submit() {
      if (settled.value) return;
      settled.value = true;
      onSubmitted(controller.text);
    }

    void cancel() {
      if (settled.value) return;
      settled.value = true;
      onCancelled();
    }

    useEffect(() {
      void onFocusChanged() {
        if (!focusNode.hasFocus) submit();
      }

      focusNode.addListener(onFocusChanged);
      return () => focusNode.removeListener(onFocusChanged);
    }, [focusNode]);

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): cancel},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(),
            filled: true,
          ),
          onSubmitted: (_) => submit(),
        ),
      ),
    );
  }
}
