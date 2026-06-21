import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/ui/form_action_bar.dart';
import 'package:dashboard/core/ui/locale_map_field.dart';
import 'package:dashboard/core/ui/outlined_text_form_field.dart';
import 'package:dashboard/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SponsorEditPage extends HookConsumerWidget {
  const SponsorEditPage({super.key, this.sponsor});

  final Sponsor? sponsor;

  bool get _isNew => sponsor == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameJaController = useTextEditingController(text: sponsor?.name.ja ?? '');
    final nameEnController = useTextEditingController(text: sponsor?.name.en ?? '');
    final nameKanaController = useTextEditingController(text: sponsor?.nameKana ?? '');
    final descJaController = useTextEditingController(text: sponsor?.description.ja ?? '');
    final descEnController = useTextEditingController(text: sponsor?.description.en ?? '');
    final logoUrlController = useTextEditingController(text: sponsor?.logoUrl ?? '');
    final xUrlController = useTextEditingController(text: sponsor?.xUrl ?? '');
    final websiteUrlController = useTextEditingController(text: sponsor?.websiteUrl ?? '');
    final recruitUrlController = useTextEditingController(text: sponsor?.recruitUrl ?? '');
    final jobBoardUrlController = useTextEditingController(text: sponsor?.jobBoardUrl ?? '');
    final isSaving = useState(false);

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;
      isSaving.value = true;
      try {
        final sponsorToSave = Sponsor(
          id: sponsor?.id ?? '',
          name: LocaleMap(ja: nameJaController.text.trim(), en: nameEnController.text.trim()),
          nameKana: nameKanaController.text.trim().isEmpty ? null : nameKanaController.text.trim(),
          description: LocaleMap(ja: descJaController.text.trim(), en: descEnController.text.trim()),
          logoUrl: logoUrlController.text.trim(),
          xUrl: xUrlController.text.trim().isEmpty ? null : xUrlController.text.trim(),
          websiteUrl: websiteUrlController.text.trim().isEmpty ? null : websiteUrlController.text.trim(),
          recruitUrl: recruitUrlController.text.trim().isEmpty ? null : recruitUrlController.text.trim(),
          jobBoardUrl: jobBoardUrlController.text.trim().isEmpty ? null : jobBoardUrlController.text.trim(),
          createdAt: sponsor?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(sponsorRepositoryProvider).save(sponsorToSave);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) context.showSnackBar('保存に失敗しました: $e');
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
              Text(
                _isNew ? 'スポンサー新規作成' : 'スポンサー編集',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
                    LocaleMapField(
                      label: '表示名 *',
                      jaController: nameJaController,
                      enController: nameEnController,
                      jaValidator: (v) => (v == null || v.trim().isEmpty) ? '日本語表示名を入力してください' : null,
                      enValidator: (v) => (v == null || v.trim().isEmpty) ? 'English name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    OutlinedTextFormField(
                      controller: nameKanaController,
                      labelText: '読み仮名',
                    ),
                    const SizedBox(height: 24),
                    Text('PR文', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descJaController,
                      decoration: const InputDecoration(labelText: '日本語', border: OutlineInputBorder()),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descEnController,
                      decoration: const InputDecoration(labelText: 'English', border: OutlineInputBorder()),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    OutlinedTextFormField(
                      controller: logoUrlController,
                      labelText: '企業ロゴ URL *',
                      hintText: 'https://example.com/logo.png',
                      validator: (v) => (v == null || v.trim().isEmpty) ? '企業ロゴ URL を入力してください' : null,
                    ),
                    const SizedBox(height: 24),
                    Text('リンク', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    OutlinedTextFormField(
                      controller: websiteUrlController,
                      labelText: '公式サイト URL',
                      hintText: 'https://example.com',
                    ),
                    const SizedBox(height: 8),
                    OutlinedTextFormField(
                      controller: xUrlController,
                      labelText: 'X (Twitter) URL',
                      hintText: 'https://x.com/...',
                    ),
                    const SizedBox(height: 8),
                    OutlinedTextFormField(
                      controller: recruitUrlController,
                      labelText: '採用ページ URL',
                      hintText: 'https://example.com/recruit',
                    ),
                    const SizedBox(height: 8),
                    OutlinedTextFormField(
                      controller: jobBoardUrlController,
                      labelText: 'ジョブボード掲載 URL',
                      hintText: 'https://...',
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
