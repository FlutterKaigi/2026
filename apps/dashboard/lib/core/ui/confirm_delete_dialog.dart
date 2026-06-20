import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog._({this.name, required this.onConfirm});

  final String? name;
  final VoidCallback onConfirm;

  static Future<void> show({
    required BuildContext context,
    String? name,
    required VoidCallback onConfirm,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ConfirmDeleteDialog._(name: name, onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = name != null ? '「$name」を削除しますか？この操作は元に戻せません。' : '削除しますか？この操作は元に戻せません。';
    return AlertDialog(
      title: const Text('削除の確認'),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () {
            context.pop();
            onConfirm();
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('削除'),
        ),
      ],
    );
  }
}
