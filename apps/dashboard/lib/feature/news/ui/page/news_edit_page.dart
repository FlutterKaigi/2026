import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/ui/date_time_field.dart';
import 'package:dashboard/core/ui/form_action_bar.dart';
import 'package:dashboard/core/ui/outlined_text_form_field.dart';
import 'package:dashboard/feature/news/data/provider/news_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NewsEditPage extends HookConsumerWidget {
  const NewsEditPage({super.key, this.news});

  final News? news;

  bool get _isNew => news == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final titleJaController = useTextEditingController(text: news?.title.ja ?? '');
    final titleEnController = useTextEditingController(text: news?.title.en ?? '');
    final urlJaController = useTextEditingController(text: news?.url.ja ?? '');
    final urlEnController = useTextEditingController(text: news?.url.en ?? '');
    final publishedAt = useState<DateTime>(news?.publishedAt ?? DateTime.now());
    final isSaving = useState(false);

    Future<void> pickPublishedAt() async {
      final picked = await context.pickDateTime(initial: publishedAt.value);
      if (picked == null) return;
      publishedAt.value = picked;
    }

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;
      isSaving.value = true;
      try {
        final newsToSave = News(
          id: news?.id ?? '',
          title: LocaleMap(ja: titleJaController.text.trim(), en: titleEnController.text.trim()),
          publishedAt: publishedAt.value,
          url: LocaleMap(ja: urlJaController.text.trim(), en: urlEnController.text.trim()),
          createdAt: news?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(newsRepositoryProvider).save(newsToSave);
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
              Text(_isNew ? 'ニュース新規作成' : 'ニュース編集', style: Theme.of(context).textTheme.titleLarge),
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
                    Text('タイトル *', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    OutlinedTextFormField(
                      controller: titleJaController,
                      labelText: '日本語',
                      validator: (v) => (v == null || v.trim().isEmpty) ? '日本語タイトルを入力してください' : null,
                    ),
                    const SizedBox(height: 8),
                    OutlinedTextFormField(
                      controller: titleEnController,
                      labelText: 'English',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'English title is required' : null,
                    ),
                    const SizedBox(height: 24),
                    DateTimeField(
                      label: '公開日時 *',
                      value: publishedAt.value,
                      onTap: pickPublishedAt,
                    ),
                    const SizedBox(height: 24),
                    Text('URL *', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    OutlinedTextFormField(
                      controller: urlJaController,
                      labelText: '日本語',
                      hintText: 'https://example.com/ja',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '日本語URLを入力してください';
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null || !uri.hasScheme) return '有効なURLを入力してください';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedTextFormField(
                      controller: urlEnController,
                      labelText: 'English',
                      hintText: 'https://example.com/en',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'English URL is required';
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null || !uri.hasScheme) return 'Please enter a valid URL';
                        return null;
                      },
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
