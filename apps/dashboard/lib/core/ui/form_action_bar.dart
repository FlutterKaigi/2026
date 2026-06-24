import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FormActionBar extends StatelessWidget {
  const FormActionBar({super.key, required this.onSave, required this.isSaving, required this.isNew});

  final VoidCallback onSave;
  final bool isSaving;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: isSaving ? null : () => context.pop(),
                child: const Text('キャンセル'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isNew ? '作成' : '保存'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
