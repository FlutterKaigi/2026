import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/ui/form_action_bar.dart';
import 'package:dashboard/core/ui/locale_map_field.dart';
import 'package:dashboard/core/ui/outlined_text_form_field.dart';
import 'package:dashboard/feature/venue/data/provider/venue_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class VenueEditPage extends HookConsumerWidget {
  const VenueEditPage({super.key, this.venue});

  final Venue? venue;

  bool get _isNew => venue == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameJaController = useTextEditingController(text: venue?.name.ja ?? '');
    final nameEnController = useTextEditingController(text: venue?.name.en ?? '');
    final orderController = useTextEditingController(text: venue?.order?.toString() ?? '');
    final isSaving = useState(false);

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;
      isSaving.value = true;
      try {
        final orderText = orderController.text.trim();
        final venueToSave = Venue(
          id: venue?.id ?? '',
          name: LocaleMap(ja: nameJaController.text.trim(), en: nameEnController.text.trim()),
          order: orderText.isEmpty ? null : int.tryParse(orderText),
          createdAt: venue?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(venueRepositoryProvider).save(venueToSave);
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
              Text(_isNew ? '会場新規作成' : '会場編集', style: Theme.of(context).textTheme.titleLarge),
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
                      label: '会場名 *',
                      jaController: nameJaController,
                      enController: nameEnController,
                      jaValidator: (v) => (v == null || v.trim().isEmpty) ? '日本語名を入力してください' : null,
                      enValidator: (v) => (v == null || v.trim().isEmpty) ? 'English name is required' : null,
                    ),
                    const SizedBox(height: 24),
                    OutlinedTextFormField(
                      controller: orderController,
                      labelText: '表示順',
                      hintText: '未入力の場合は自動',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (int.tryParse(v.trim()) == null) return '整数を入力してください';
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
