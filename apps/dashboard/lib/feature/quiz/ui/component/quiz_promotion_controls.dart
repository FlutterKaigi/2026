import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/event_environment/event_admin_client.dart';
import 'package:dashboard/core/event_environment/event_environment.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Promotion copies only this event's definition; publication remains a
/// separate production action. The request always uses the current login.
class QuizPromotionControls extends HookConsumerWidget {
  const QuizPromotionControls({super.key, required this.event, required this.busy});
  final QuizEvent event;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(eventAdminClientProvider);
    final withdrawing = useState(false);
    if (client == null || client.environment == Flavor.dev) return const SizedBox.shrink();
    if (client.environment == Flavor.stg) {
      return OutlinedButton.icon(
        onPressed: busy
            ? null
            : () async {
                final eventId = await showDialog<String>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => _PromotionDialog(client: client, eventId: event.id),
                );
                if (eventId != null && context.mounted) {
                  context.go(eventLocation(QuizConsoleRoute(eventId).location, Flavor.prod));
                }
              },
        icon: const Icon(Icons.upload_outlined),
        label: const Text('本番へ反映'),
      );
    }
    final snapshot = ref.watch(eventAdminSnapshotProvider).asData?.value;
    final rawEvent = snapshot?['event'] as Map?;
    if (rawEvent?['promotion'] == null) return const SizedBox.shrink();
    final canWithdraw =
        [QuizEventStatus.draft, QuizEventStatus.published].contains(event.status) &&
        rawEvent?['admissionSlotsReady'] != true;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: !canWithdraw || busy || withdrawing.value
              ? null
              : () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('本番への反映を取り消す'),
                      content: Text(
                        '「${event.title.ja}」を本番の一覧・参加者アプリから非表示にします。\n'
                        '内容と操作履歴は保存されます。STG の元イベントと他の本番イベントは変更しません。',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('反映を取り消す')),
                      ],
                    ),
                  );
                  if (ok != true || !context.mounted) return;
                  withdrawing.value = true;
                  try {
                    await client.mutate('withdrawQuizPromotion', {'eventId': event.id});
                    if (context.mounted) context.go(eventLocation(const QuizEventListRoute().location, Flavor.prod));
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('反映を取り消せませんでした: $error')));
                    }
                  } finally {
                    if (context.mounted) withdrawing.value = false;
                  }
                },
          icon: const Icon(Icons.undo),
          label: Text(withdrawing.value ? '取り消し中…' : '反映を取り消す'),
        ),
        Text(canWithdraw ? 'STG から反映したイベントです。参加受付の開始前なら取り消せます。' : '参加受付開始後は反映を取り消せません。'),
      ],
    );
  }
}

class _PromotionDialog extends StatefulWidget {
  const _PromotionDialog({required this.client, required this.eventId});
  final EventAdminClient client;
  final String eventId;

  @override
  State<_PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<_PromotionDialog> {
  late Future<Map<String, dynamic>> _preview;
  final _operationId = newEventOperationId();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _preview = widget.client.call('previewQuizPromotion', {'eventId': widget.eventId});
  }

  Future<void> _promote(Map<String, dynamic> preview) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.client.mutate('promoteQuizEvent', {
        'eventId': widget.eventId,
        'revision': preview['revision'],
        'operationId': _operationId,
      });
      if (mounted) Navigator.pop(context, result['eventId'] as String);
    } catch (error) {
      if (mounted) setState(() => _error = '反映の完了を確認できませんでした: $error\n通信エラー後はこの画面で再試行できます。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: FutureBuilder<Map<String, dynamic>>(
      future: _preview,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final existing = data?['existingEventId'] as String?;
        final missing = data?['missingSponsorIds'] as List? ?? [];
        return AlertDialog(
          title: const Text('STG → 本番への反映を確認'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (snapshot.connectionState != ConnectionState.done)
                    const Center(child: CircularProgressIndicator()),
                  if (snapshot.hasError) Text('反映内容を確認できませんでした: ${snapshot.error}'),
                  if (data != null) ...[
                    Text((data['title'] as Map)['ja'] as String, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('問題 ${data['questionCount']} 問 ・ スポンサー ${data['sponsorCount']} 社 ・ 定員 ${data['capacity']} 人'),
                    Text('STG のイベント ID: ${widget.eventId}'),
                    const SizedBox(height: 16),
                    for (final question in data['questions'] as List)
                      Text('${question['order']}. ${(question['title'] as Map)['ja']}'),
                    const SizedBox(height: 16),
                    const Text(
                      'このイベントの設定・問題・正解・解説を本番に下書きとして作成します。\n'
                      '参加者・回答・得点・受付コード・進行状態は引き継ぎません。\n'
                      '反映後に本番側で内容を確認し、受付コードの発行と公開を行ってください。',
                    ),
                    if (existing != null) ...[
                      const SizedBox(height: 12),
                      const Text('既に本番へ反映されています。内容を上書きせず、既存の本番イベントを開きます。'),
                    ] else if (missing.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('本番に存在しないスポンサー: ${missing.join(', ')}\nスポンサーを先に本番へ反映してください。'),
                    ],
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('キャンセル')),
            if (existing != null)
              FilledButton(onPressed: () => Navigator.pop(context, existing), child: const Text('本番のイベントを開く'))
            else
              FilledButton(
                onPressed: data == null || missing.isNotEmpty || _busy ? null : () => _promote(data),
                child: Text(_busy ? '反映中…' : '本番に下書きを作成'),
              ),
          ],
        );
      },
    ),
  );
}
