import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/extension/date_time_extension.dart';
import 'package:dashboard/feature/support_lt/data/provider/support_lt_state.dart';
import 'package:dashboard/feature/support_lt/ui/widget/support_lt_load_error.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SupportLtCodeCard extends ConsumerStatefulWidget {
  const SupportLtCodeCard({super.key});

  @override
  ConsumerState<SupportLtCodeCard> createState() => _SupportLtCodeCardState();
}

class _SupportLtCodeCardState extends ConsumerState<SupportLtCodeCard> {
  bool _isIssuing = false;
  String? _issueError;

  Future<void> _issueCode({required bool rotate}) async {
    if (_isIssuing) return;
    if (rotate) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('登録コードを再発行しますか？'),
          content: const Text('現在のコードは使えなくなります。新しいコードを参加者に案内してください。登録済みの参加者には影響しません。'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('再発行する')),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }
    setState(() {
      _isIssuing = true;
      _issueError = null;
    });
    try {
      await ref.read(supportLtRepositoryProvider).issueCode(rotate: rotate);
      if (mounted) context.showSnackBar(rotate ? '登録コードを再発行しました' : '登録コードを発行しました');
    } catch (error) {
      if (mounted) {
        setState(() {
          _issueError = supportLtErrorMessage(error, fallback: 'コードを発行できませんでした。通信状況を確認して再試行してください。');
        });
      }
    } finally {
      if (mounted) setState(() => _isIssuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(supportLtCodeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('参加登録コード', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('6桁の共通コードです。再発行するまで有効で、何人でも利用できます。'),
            const SizedBox(height: 16),
            code.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SupportLtLoadError(
                message: supportLtErrorMessage(error, fallback: '登録コードを読み込めませんでした。通信状況を確認して再試行してください。'),
                retryKey: const Key('retry-support-lt-code'),
                onRetry: () => ref.invalidate(supportLtCodeProvider),
              ),
              data: _buildCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCode(SupportLtCode? code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (code == null) const Text('登録コードはまだ発行されていません') else _CodeDetails(code: code, isIssuing: _isIssuing),
        const SizedBox(height: 16),
        if (_issueError case final error?) ...[
          Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: _isIssuing ? null : () => _issueCode(rotate: code != null),
          icon: _isIssuing
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(code == null ? Icons.key : Icons.refresh),
          label: Text(_isIssuing ? '発行中…' : (code == null ? '登録コードを発行' : 'コードを再発行')),
        ),
      ],
    );
  }
}

class _CodeDetails extends StatelessWidget {
  const _CodeDetails({required this.code, required this.isIssuing});

  final SupportLtCode code;
  final bool isIssuing;

  Future<void> _copy(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: code.code));
      if (context.mounted) context.showSnackBar('コードをコピーしました');
    } catch (_) {
      if (context.mounted) context.showSnackBar('コピーできませんでした。コードを選択してコピーしてください。');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SelectableText(
              code.code,
              style: theme.textTheme.headlineLarge?.copyWith(fontFamily: 'monospace', letterSpacing: 4),
            ),
            IconButton(
              tooltip: 'コードをコピー',
              onPressed: isIssuing ? null : () => _copy(context),
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('発行日時: ${code.issuedAt.toLocal().formatDateTime()}'),
      ],
    );
  }
}
