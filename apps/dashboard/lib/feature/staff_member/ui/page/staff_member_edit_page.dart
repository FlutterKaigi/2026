import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/ui/form_action_bar.dart';
import 'package:dashboard/core/ui/outlined_text_form_field.dart';
import 'package:dashboard/feature/staff_member/data/provider/staff_member_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StaffMemberEditPage extends HookConsumerWidget {
  const StaffMemberEditPage({super.key, this.staffMember});

  final StaffMember? staffMember;

  bool get _isNew => staffMember == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final snsLinksKey = useMemoized(GlobalKey<_SnsLinksFieldState>.new);
    final nameController = useTextEditingController(text: staffMember?.name ?? '');
    final iconUrlController = useTextEditingController(text: staffMember?.iconUrl ?? '');
    final greetingController = useTextEditingController(text: staffMember?.greeting ?? '');
    final orderController = useTextEditingController(text: staffMember?.order.toString() ?? '0');
    final isSaving = useState(false);

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;
      isSaving.value = true;
      try {
        final staffMemberToSave = StaffMember(
          id: staffMember?.id ?? '',
          name: nameController.text.trim(),
          iconUrl: iconUrlController.text.trim(),
          greeting: greetingController.text.trim().isEmpty ? null : greetingController.text.trim(),
          snsLinks: snsLinksKey.currentState?.currentLinks ?? [],
          order: int.parse(orderController.text.trim()),
          createdAt: staffMember?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(staffMemberRepositoryProvider).save(staffMemberToSave);
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
              Text(_isNew ? 'スタッフ新規作成' : 'スタッフ編集', style: Theme.of(context).textTheme.titleLarge),
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
                      controller: iconUrlController,
                      labelText: 'アイコン画像 URL *',
                      hintText: 'https://example.com/icon.png',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'アイコン画像 URL を入力してください';
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null || !uri.hasScheme) return '有効なURLを入力してください';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: greetingController,
                      decoration: const InputDecoration(labelText: 'ひとこと', border: OutlineInputBorder()),
                      maxLines: 3,
                      minLines: 2,
                    ),
                    const SizedBox(height: 16),
                    OutlinedTextFormField(
                      controller: orderController,
                      labelText: '表示順 *',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '表示順を入力してください';
                        if (int.tryParse(v.trim()) == null) return '整数を入力してください';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _SnsLinksField(key: snsLinksKey, initialLinks: staffMember?.snsLinks ?? const []),
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

class _SnsLinksField extends StatefulWidget {
  const _SnsLinksField({super.key, required this.initialLinks});

  final List<SnsLink> initialLinks;

  @override
  State<_SnsLinksField> createState() => _SnsLinksFieldState();
}

class _SnsLinksFieldState extends State<_SnsLinksField> {
  static const _platforms = <String, String>{
    'x': 'X',
    'bluesky': 'Bluesky',
    'mixi2': 'mixi2',
    'medium': 'Medium',
    'qiita': 'Qiita',
    'zenn': 'Zenn',
    'note': 'note',
  };

  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final byType = {for (final l in widget.initialLinks) l.type: l.value};
    _controllers = {for (final type in _platforms.keys) type: TextEditingController(text: byType[type] ?? '')};
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<SnsLink> get currentLinks => [
    for (final type in _platforms.keys)
      if (_controllers[type]!.text.trim().isNotEmpty) SnsLink(type: type, value: _controllers[type]!.text.trim()),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SNS リンク', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        for (final MapEntry(:key, :value) in _platforms.entries) ...[
          OutlinedTextFormField(controller: _controllers[key]!, labelText: value),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
