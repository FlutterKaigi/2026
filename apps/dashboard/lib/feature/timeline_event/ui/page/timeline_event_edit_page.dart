import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/ui/date_time_field.dart';
import 'package:dashboard/core/ui/form_action_bar.dart';
import 'package:dashboard/core/ui/locale_map_field.dart';
import 'package:dashboard/feature/timeline_event/data/provider/timeline_event_repository.dart';
import 'package:dashboard/feature/venue/data/provider/venue_list_state.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TimelineEventEditPage extends HookConsumerWidget {
  const TimelineEventEditPage({super.key, this.timelineEvent});

  final TimelineEvent? timelineEvent;

  bool get _isNew => timelineEvent == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(venueListProvider);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final titleJaController = useTextEditingController(text: timelineEvent?.title.ja ?? '');
    final titleEnController = useTextEditingController(text: timelineEvent?.title.en ?? '');
    final startsAt = useState<DateTime>(timelineEvent?.startsAt ?? DateTime.now());
    final endsAt = useState<DateTime?>(timelineEvent?.endsAt);
    final venueId = useState<String?>(timelineEvent?.venueId);
    final isSaving = useState(false);

    Future<void> pickStartsAt() async {
      final picked = await context.pickDateTime(initial: startsAt.value);
      if (picked == null) return;
      startsAt.value = picked;
    }

    Future<void> pickEndsAt() async {
      final picked = await context.pickDateTime(initial: endsAt.value ?? startsAt.value);
      if (picked == null) return;
      endsAt.value = picked;
    }

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;
      isSaving.value = true;
      try {
        final eventToSave = TimelineEvent(
          id: timelineEvent?.id ?? '',
          title: LocaleMap(ja: titleJaController.text.trim(), en: titleEnController.text.trim()),
          startsAt: startsAt.value,
          endsAt: endsAt.value,
          venueId: venueId.value,
          createdAt: timelineEvent?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(timelineEventRepositoryProvider).save(eventToSave);
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
              Text(
                _isNew ? 'タイムラインイベント新規作成' : 'タイムラインイベント編集',
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
                      label: 'タイトル *',
                      jaController: titleJaController,
                      enController: titleEnController,
                      jaValidator: (v) => (v == null || v.trim().isEmpty) ? '日本語タイトルを入力してください' : null,
                      enValidator: (v) => (v == null || v.trim().isEmpty) ? 'English title is required' : null,
                    ),
                    const SizedBox(height: 24),
                    DateTimeField(label: '開始日時 *', value: startsAt.value, onTap: pickStartsAt),
                    const SizedBox(height: 16),
                    DateTimeField(
                      label: '終了日時',
                      value: endsAt.value,
                      onTap: pickEndsAt,
                      onClear: () => endsAt.value = null,
                    ),
                    const SizedBox(height: 24),
                    venues.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('会場の読み込みに失敗: $e'),
                      data: (venueList) => DropdownButtonFormField<String?>(
                        initialValue: venueId.value,
                        decoration: const InputDecoration(labelText: '会場', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('なし')),
                          for (final v in venueList) DropdownMenuItem(value: v.id, child: Text(v.name.ja)),
                        ],
                        onChanged: (v) => venueId.value = v,
                      ),
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
