import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/core/event_environment/event_admin_client.dart';
import 'package:dashboard/core/event_environment/event_environment.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';

class QuizEventDeleteDialog extends StatefulWidget {
  const QuizEventDeleteDialog._({required this.client, required this.event});

  static Future<bool> show({
    required BuildContext context,
    required EventAdminClient client,
    required QuizEvent event,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => QuizEventDeleteDialog._(client: client, event: event),
      ) ??
      false;

  final EventAdminClient client;
  final QuizEvent event;

  @override
  State<QuizEventDeleteDialog> createState() => _QuizEventDeleteDialogState();
}

class _QuizEventDeleteDialogState extends State<QuizEventDeleteDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _delete() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.client.mutate('deleteEvent', {'eventId': widget.event.id});
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        final message = error is FirebaseFunctionsException ? error.message ?? error.code : error.toString();
        setState(() => _error = '削除できませんでした: $message\n状態を確認し、この画面から再試行できます。');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.event.title.ja.isEmpty ? '(タイトル未設定)' : widget.event.title.ja;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('イベントを削除'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.client.environment.label}の「$title」を削除します。\n参加者・チーム・問題・正解・回答など、このイベントの関連データもすべて削除され、元に戻せません。',
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('キャンセル')),
          FilledButton(
            onPressed: _busy ? null : _delete,
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(_busy ? '削除中…' : '削除する'),
          ),
        ],
      ),
    );
  }
}
