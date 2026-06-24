import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/ui/form_action_bar.dart';
import 'package:dashboard/core/ui/outlined_text_form_field.dart';
import 'package:dashboard/feature/speaker/data/provider/speaker_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SpeakerEditPage extends HookConsumerWidget {
  const SpeakerEditPage({super.key, this.speaker});

  final Speaker? speaker;

  bool get _isNew => speaker == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameController = useTextEditingController(text: speaker?.name ?? '');
    final avatarUrlController = useTextEditingController(text: speaker?.avatarUrl ?? '');
    final xIdController = useTextEditingController(text: speaker?.xId ?? '');
    final bioController = useTextEditingController(text: speaker?.bio ?? '');
    final isSaving = useState(false);

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;
      isSaving.value = true;
      try {
        final speakerToSave = Speaker(
          id: speaker?.id ?? '',
          name: nameController.text.trim(),
          avatarUrl: avatarUrlController.text.trim().isEmpty ? null : avatarUrlController.text.trim(),
          xId: xIdController.text.trim().isEmpty ? null : xIdController.text.trim(),
          bio: bioController.text.trim().isEmpty ? null : bioController.text.trim(),
          createdAt: speaker?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(speakerRepositoryProvider).save(speakerToSave);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          context.showSnackBar('保存に失敗しました: $e');
        }
      } finally {
        isSaving.value = false;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              BackButton(onPressed: () => context.pop()),
              Text(_isNew ? 'スピーカー新規作成' : 'スピーカー編集', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedTextFormField(
                      controller: nameController,
                      labelText: '名前 *',
                      validator: (v) => (v == null || v.trim().isEmpty) ? '名前を入力してください' : null,
                    ),
                    const SizedBox(height: 16),
                    OutlinedTextFormField(
                      controller: avatarUrlController,
                      labelText: 'アバター画像 URL',
                      hintText: 'https://example.com/avatar.png',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null || !uri.hasScheme) return '有効なURLを入力してください';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedTextFormField(
                      controller: xIdController,
                      labelText: 'X ID（@ なし）',
                      hintText: 'username',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: bioController,
                      decoration: const InputDecoration(labelText: 'プロフィール', border: OutlineInputBorder()),
                      maxLines: 5,
                      minLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        FormActionBar(onSave: save, isSaving: isSaving.value, isNew: _isNew),
      ],
    );
  }
}
