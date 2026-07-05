import 'package:dashboard/core/extension/date_time_extension.dart';
import 'package:dashboard/feature/sponsor/model/sponsor_column.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// 編集中セルの識別子。
typedef SponsorCellRef = ({String sponsorId, SponsorColumn column});

/// ソート状態。null の場合はデフォルト（作成日時の降順）。
typedef SponsorSort = ({SponsorColumn column, bool ascending});

/// スポンサー一覧の Excel 風テーブル。
///
/// - ヘッダー行と先頭列（表示名 ja）を固定
/// - セルをダブルクリックするとインライン編集モードに切り替わる
/// - ヘッダークリックでソート（昇順 → 降順 → 解除）
/// - 縦横のスクロールバーを常時表示
class SponsorTable extends HookWidget {
  const SponsorTable({
    super.key,
    required this.sponsors,
    required this.editingCell,
    required this.sort,
    required this.onSortRequested,
    required this.onEditStarted,
    required this.onEditCancelled,
    required this.onTextSubmitted,
    required this.onEditPagePressed,
    required this.onDeletePressed,
  });

  final List<Sponsor> sponsors;
  final SponsorCellRef? editingCell;
  final SponsorSort? sort;
  final ValueChanged<SponsorColumn> onSortRequested;
  final void Function(Sponsor sponsor, SponsorColumn column) onEditStarted;
  final VoidCallback onEditCancelled;
  final void Function(Sponsor sponsor, SponsorColumn column, String text) onTextSubmitted;
  final ValueChanged<Sponsor> onEditPagePressed;
  final ValueChanged<Sponsor> onDeletePressed;

  static const _headerHeight = 44.0;
  static const _rowHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gridLine = BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5));
    final verticalController = useScrollController();
    final horizontalController = useScrollController();

    // ブラウザやウィンドウサイズによらずスクロール位置がわかるよう、
    // 縦横ともにスクロールバーを常時表示する。
    final table = TableView.builder(
      verticalDetails: ScrollableDetails.vertical(controller: verticalController),
      horizontalDetails: ScrollableDetails.horizontal(controller: horizontalController),
      columnCount: SponsorColumn.values.length,
      rowCount: sponsors.length + 1,
      pinnedRowCount: 1,
      pinnedColumnCount: 1,
      columnBuilder: (index) => TableSpan(
        extent: FixedTableSpanExtent(SponsorColumn.values[index].width),
        foregroundDecoration: TableSpanDecoration(border: TableSpanBorder(trailing: gridLine)),
      ),
      rowBuilder: (index) => TableSpan(
        extent: FixedTableSpanExtent(index == 0 ? _headerHeight : _rowHeight),
        backgroundDecoration: TableSpanDecoration(
          color: switch (index) {
            0 => theme.colorScheme.surfaceContainerHigh,
            _ when index.isEven => theme.colorScheme.surfaceContainerLowest,
            _ => theme.colorScheme.surface,
          },
        ),
        foregroundDecoration: TableSpanDecoration(border: TableSpanBorder(trailing: gridLine)),
      ),
      cellBuilder: (context, vicinity) {
        final column = SponsorColumn.values[vicinity.column];
        if (vicinity.row == 0) {
          return TableViewCell(
            child: _HeaderCell(column: column, sort: sort, onSortRequested: onSortRequested),
          );
        }
        final sponsor = sponsors[vicinity.row - 1];
        return TableViewCell(child: _buildDataCell(context, sponsor, column));
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

  Widget _buildDataCell(BuildContext context, Sponsor sponsor, SponsorColumn column) {
    final isEditing = editingCell != null && editingCell!.sponsorId == sponsor.id && editingCell!.column == column;

    if (isEditing) {
      return _TextEditingCell(
        key: ValueKey('edit-${sponsor.id}-${column.name}'),
        initialValue: column.valueOf(sponsor) ?? '',
        onSubmitted: (text) => onTextSubmitted(sponsor, column, text),
        onCancelled: onEditCancelled,
      );
    }

    final theme = Theme.of(context);
    final value = column.valueOf(sponsor);
    final missing = value == null && column.warnsWhenMissing;

    final content = switch (column) {
      SponsorColumn.tier => Align(
        alignment: Alignment.centerLeft,
        child: _TierBadge(tier: sponsor.tier),
      ),
      SponsorColumn.updatedAt => Text(
        sponsor.updatedAt.formatDateTime(),
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      SponsorColumn.actions => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: '詳細フォームで編集',
            onPressed: () => onEditPagePressed(sponsor),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: '削除',
            color: Colors.red,
            onPressed: () => onDeletePressed(sponsor),
          ),
        ],
      ),
      _ when value == null => Text(
        '未設定',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: missing ? theme.colorScheme.error : theme.colorScheme.outline,
          fontStyle: FontStyle.italic,
        ),
      ),
      _ when column.isLogo => Row(
        children: [
          Image.network(
            value,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, _, _) =>
                Icon(Icons.broken_image_outlined, size: 20, color: theme.colorScheme.outline),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
      _ => Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
    };

    return GestureDetector(
      onDoubleTap: column.isEditable ? () => onEditStarted(sponsor, column) : null,
      // 空セルでもダブルクリックを拾えるように背景色を透過で塗る。
      child: Container(
        color: missing ? theme.colorScheme.errorContainer.withValues(alpha: 0.25) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: content,
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.column, required this.sort, required this.onSortRequested});

  final SponsorColumn column;
  final SponsorSort? sort;
  final ValueChanged<SponsorColumn> onSortRequested;

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
        // 編集可能列（ロゴ・slug）にはヘッダーに編集アイコンを表示する。
        if (column.isEditable) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: 'ダブルクリックで編集可能',
            child: Icon(Icons.edit_outlined, size: 14, color: theme.colorScheme.primary),
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

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final SponsorTier tier;

  static const _colors = <SponsorTier, Color>{
    SponsorTier.platinum: Color(0xFF607D8B),
    SponsorTier.gold: Color(0xFFB8860B),
    SponsorTier.silver: Color(0xFF757575),
    SponsorTier.bronze: Color(0xFF8D6E63),
    SponsorTier.tool: Color(0xFF00897B),
    SponsorTier.community: Color(0xFF43A047),
    SponsorTier.individual: Color(0xFF7B1FA2),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[tier]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tier.name,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// テキストセルのインライン編集。Enter または他のセルへのフォーカス移動で確定、Esc でキャンセル。
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
        // フォーカスが外れたら Excel と同様に編集内容を確定する。
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
