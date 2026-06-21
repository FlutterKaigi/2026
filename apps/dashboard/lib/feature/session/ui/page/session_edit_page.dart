import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/ui/date_time_field.dart';
import 'package:dashboard/core/ui/form_action_bar.dart';
import 'package:dashboard/core/ui/locale_map_field.dart';
import 'package:dashboard/core/ui/outlined_text_form_field.dart';
import 'package:dashboard/feature/session/data/provider/session_repository.dart';
import 'package:dashboard/feature/speaker/data/provider/speaker_list_state.dart';
import 'package:dashboard/feature/venue/data/provider/venue_list_state.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SessionEditPage extends HookConsumerWidget {
  const SessionEditPage({super.key, this.session});

  final Session? session;

  bool get _isNew => session == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(venueListProvider);
    final speakers = ref.watch(speakerListProvider);

    final formKey = useMemoized(GlobalKey<FormState>.new);
    final titleJaController = useTextEditingController(text: session?.title.ja ?? '');
    final titleEnController = useTextEditingController(text: session?.title.en ?? '');
    final descJaController = useTextEditingController(text: session?.description.ja ?? '');
    final descEnController = useTextEditingController(text: session?.description.en ?? '');
    final sessionizeUrlController = useTextEditingController(text: session?.sessionizeUrl ?? '');
    final primaryLocale = useState(session?.primaryLocale ?? 'ja');
    final startsAt = useState<DateTime>(session?.startsAt ?? DateTime.now());
    final endsAt = useState<DateTime>(session?.endsAt ?? DateTime.now().add(const Duration(minutes: 40)));
    final venueId = useState<String?>(session?.venueId.isEmpty == true ? null : session?.venueId);
    final selectedSpeakerIds = useState<List<String>>(session?.speakerIds ?? const []);
    final isLightningTalk = useState(session?.isLightningTalk ?? false);
    final isBeginnersLightningTalk = useState(session?.isBeginnersLightningTalk ?? false);
    final isHandsOn = useState(session?.isHandsOn ?? false);
    final isSaving = useState(false);

    Future<void> pickStartsAt() async {
      final picked = await context.pickDateTime(initial: startsAt.value);
      if (picked == null) return;
      startsAt.value = picked;
    }

    Future<void> pickEndsAt() async {
      final picked = await context.pickDateTime(initial: endsAt.value);
      if (picked == null) return;
      endsAt.value = picked;
    }

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;
      if (venueId.value == null) {
        context.showSnackBar('会場を選択してください');
        return;
      }
      isSaving.value = true;
      try {
        final sessionToSave = Session(
          id: session?.id ?? '',
          title: LocaleMap(ja: titleJaController.text.trim(), en: titleEnController.text.trim()),
          description: LocaleMap(ja: descJaController.text.trim(), en: descEnController.text.trim()),
          primaryLocale: primaryLocale.value,
          startsAt: startsAt.value,
          endsAt: endsAt.value,
          venueId: venueId.value!,
          speakerIds: selectedSpeakerIds.value,
          isLightningTalk: isLightningTalk.value,
          isBeginnersLightningTalk: isBeginnersLightningTalk.value,
          isHandsOn: isHandsOn.value,
          sessionizeUrl: sessionizeUrlController.text.trim().isEmpty ? null : sessionizeUrlController.text.trim(),
          createdAt: session?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(sessionRepositoryProvider).save(sessionToSave);
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
                _isNew ? 'セッション新規作成' : 'セッション編集',
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
                    _SectionLabel('原文言語'),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ja', label: Text('日本語')),
                        ButtonSegment(value: 'en', label: Text('English')),
                      ],
                      selected: {primaryLocale.value},
                      onSelectionChanged: (set) => primaryLocale.value = set.first,
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel('説明'),
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
                    DateTimeField(label: '開始日時 *', value: startsAt.value, onTap: pickStartsAt),
                    const SizedBox(height: 16),
                    DateTimeField(label: '終了日時 *', value: endsAt.value, onTap: pickEndsAt),
                    const SizedBox(height: 24),
                    venues.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('会場の読み込みに失敗: $e'),
                      data: (venueList) => DropdownButtonFormField<String>(
                        initialValue: venueId.value,
                        decoration: const InputDecoration(labelText: '会場 *', border: OutlineInputBorder()),
                        items: [
                          for (final v in venueList) DropdownMenuItem(value: v.id, child: Text(v.name.ja)),
                        ],
                        onChanged: (v) => venueId.value = v,
                        validator: (v) => (v == null || v.isEmpty) ? '会場を選択してください' : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel('スピーカー'),
                    const SizedBox(height: 8),
                    speakers.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('スピーカーの読み込みに失敗: $e'),
                      data: (speakerList) => speakerList.isEmpty
                          ? const Text('スピーカーがいません', style: TextStyle(color: Colors.grey))
                          : Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final speaker in speakerList)
                                  FilterChip(
                                    label: Text(speaker.name),
                                    selected: selectedSpeakerIds.value.contains(speaker.id),
                                    onSelected: (selected) {
                                      final ids = [...selectedSpeakerIds.value];
                                      if (selected) {
                                        ids.add(speaker.id);
                                      } else {
                                        ids.remove(speaker.id);
                                      }
                                      selectedSpeakerIds.value = ids;
                                    },
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel('フラグ'),
                    SwitchListTile.adaptive(
                      title: const Text('ライトニングトーク'),
                      value: isLightningTalk.value,
                      onChanged: (v) => isLightningTalk.value = v,
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('初心者向けライトニングトーク'),
                      value: isBeginnersLightningTalk.value,
                      onChanged: (v) => isBeginnersLightningTalk.value = v,
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('ハンズオン'),
                      value: isHandsOn.value,
                      onChanged: (v) => isHandsOn.value = v,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    OutlinedTextFormField(
                      controller: sessionizeUrlController,
                      labelText: 'Sessionize URL',
                      hintText: 'https://sessionize.com/...',
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}
