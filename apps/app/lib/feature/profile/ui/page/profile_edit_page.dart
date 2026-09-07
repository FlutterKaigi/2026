import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/profile/data/provider/user_profile_provider.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:app/feature/profile/data/sns_platform.dart';
import 'package:app/feature/profile/ui/widget/country_flag_widget.dart';
import 'package:app/feature/profile/ui/widget/country_picker_sheet.dart';
import 'package:app/feature/profile/ui/widget/profile_avatar_widget.dart';
import 'package:app/feature/profile/ui/widget/sns_link_icon_widget.dart';
import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Maximum content width so the form stays readable on tablets and web.
const _formMaxWidth = 560.0;

/// One editable SNS link row. [id] keeps the row's text field stable while
/// rows are inserted and removed around it.
class SnsLinkDraft {
  const SnsLinkDraft({required this.id, required this.platform, required this.value});

  /// Creates a draft with a fresh identity.
  SnsLinkDraft.create({required this.platform, required this.value}) : id = Object();

  final Object id;
  final SnsPlatform platform;
  final String value;

  SnsLinkDraft copyWith({SnsPlatform? platform, String? value}) =>
      SnsLinkDraft(id: id, platform: platform ?? this.platform, value: value ?? this.value);

  /// Converts to a persisted [SnsLink], or `null` when the URL is blank.
  SnsLink? toSnsLink() {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return SnsLink(type: platform.key, value: trimmed);
  }
}

/// Creates or edits the signed-in user's [UserProfile].
///
/// Mirrors the FlutterKaigi 2025 profile edit screen: a display name, the
/// attendee's country or region (required, picked from a searchable sheet),
/// optional SNS links and a short bio. The avatar is taken from the sign-in
/// provider; in-app photo upload is not supported yet.
class ProfileEditPage extends HookConsumerWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final user = ref.watch(authStateChangesProvider).value;
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          profileState.value == null ? t.profile.createTitle : t.profile.editTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: switch (profileState) {
        // フォームは最初に読み込んだプロフィールから初期化する。保存直後の
        // ストリーム更新でフォームを作り直すと、入力中の状態が消えるうえに
        // 保存完了後の pop が古い context で止まるので、キーは uid だけに依存させる。
        AsyncData(:final value) when user != null => _ProfileForm(
          key: ValueKey(user.uid),
          user: user,
          profile: value,
        ),
        AsyncData() => Center(child: Text(t.auth.signIn.description)),
        AsyncError(:final error) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
      },
    );
  }
}

class _ProfileForm extends HookConsumerWidget {
  const _ProfileForm({required this.user, required this.profile, super.key});

  final User user;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    final formKey = useMemoized(GlobalKey<FormState>.new);
    final displayNameController = useTextEditingController(text: profile?.displayName ?? user.displayName ?? '');
    final bioController = useTextEditingController(text: profile?.bio ?? '');
    final country = useState<Country?>(
      profile == null ? null : findCountry(profile!.countryOrRegion),
    );
    final countryError = useState<String?>(null);
    final snsLinks = useState<List<SnsLinkDraft>>([
      for (final link in profile?.snsLinks ?? const <SnsLink>[])
        SnsLinkDraft.create(platform: SnsPlatform.fromKey(link.type), value: link.value),
    ]);
    final isSaving = useState(false);
    final isDirty = useState(false);

    // 入力の変更を追跡して、未保存のまま離脱しようとしたときに確認する。
    useEffect(() {
      void markDirty() => isDirty.value = true;
      displayNameController.addListener(markDirty);
      bioController.addListener(markDirty);
      return () {
        displayNameController.removeListener(markDirty);
        bioController.removeListener(markDirty);
      };
    }, [displayNameController, bioController]);

    final avatarUrl = profile?.avatarUrl ?? user.photoURL;

    Future<void> pickCountry() async {
      final picked = await showCountryPickerSheet(context, selected: country.value);
      if (picked != null) {
        country.value = picked;
        countryError.value = null;
        isDirty.value = true;
      }
    }

    Future<void> save() async {
      final selectedCountry = country.value;
      final isFormValid = formKey.currentState?.validate() ?? false;
      countryError.value = selectedCountry == null ? t.profile.countryRequired : null;
      if (!isFormValid || selectedCountry == null || isSaving.value) {
        return;
      }

      final now = DateTime.now();
      final bio = bioController.text.trim();
      final updated = UserProfile(
        id: user.uid,
        displayName: displayNameController.text.trim(),
        avatarUrl: avatarUrl,
        countryOrRegion: selectedCountry.code,
        snsLinks: [
          for (final draft in snsLinks.value)
            if (draft.toSnsLink() case final link?) link,
        ],
        bio: bio.isEmpty ? null : bio,
        createdAt: profile?.createdAt ?? now,
        updatedAt: now,
      );

      isSaving.value = true;
      try {
        await ref.read(userProfileRepositoryProvider).save(updated);
        if (!context.mounted) {
          return;
        }
        isDirty.value = false;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(t.profile.saved)));
        context.pop();
      } on Exception catch (exception, stackTrace) {
        ref.read(talkerProvider).handle(exception, stackTrace);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(t.profile.saveFailed)));
        }
      } finally {
        if (context.mounted) {
          isSaving.value = false;
        }
      }
    }

    Future<bool> confirmDiscard() async {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.profile.discardTitle),
          content: Text(t.profile.discardBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.profile.keepEditing),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.profile.discardAction),
            ),
          ],
        ),
      );
      return discard ?? false;
    }

    return PopScope(
      canPop: !isDirty.value || isSaving.value,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        if (await confirmDiscard() && context.mounted) {
          isDirty.value = false;
          context.pop();
        }
      },
      child: AppScrollbar(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _formMaxWidth),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: ProfileAvatar(imageUrl: avatarUrl, radius: 44)),
                    const SizedBox(height: 8),
                    Text(
                      t.profile.visibilityNote,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: displayNameController,
                      enabled: !isSaving.value,
                      maxLength: UserProfile.displayNameMaxLength,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(
                        labelText: '${t.profile.displayNameLabel} *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? t.profile.displayNameRequired : null,
                    ),
                    const SizedBox(height: 8),
                    _CountryField(
                      country: country.value,
                      errorText: countryError.value,
                      enabled: !isSaving.value,
                      locale: locale,
                      onTap: pickCountry,
                    ),
                    const SizedBox(height: 24),
                    _SnsLinksSection(
                      links: snsLinks.value,
                      enabled: !isSaving.value,
                      // 常に最新の state を読んでから更新する（ビルド時点のリストを
                      // 閉じ込めると、連続した入力と削除で変更が取りこぼされる）。
                      onAdd: () {
                        snsLinks.value = [...snsLinks.value, SnsLinkDraft.create(platform: SnsPlatform.x, value: '')];
                        isDirty.value = true;
                      },
                      onChanged: (updated) {
                        snsLinks.value = [
                          for (final draft in snsLinks.value) draft.id == updated.id ? updated : draft,
                        ];
                        isDirty.value = true;
                      },
                      onRemove: (id) {
                        snsLinks.value = [
                          for (final draft in snsLinks.value)
                            if (draft.id != id) draft,
                        ];
                        isDirty.value = true;
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: bioController,
                      enabled: !isSaving.value,
                      maxLength: UserProfile.bioMaxLength,
                      maxLines: 5,
                      minLines: 3,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: t.profile.bioLabel,
                        hintText: t.profile.bioHint,
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isSaving.value ? null : () => unawaited(save()),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: isSaving.value
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(t.profile.save),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only outlined field that opens the country picker.
class _CountryField extends StatelessWidget {
  const _CountryField({
    required this.country,
    required this.errorText,
    required this.enabled,
    required this.locale,
    required this.onTap,
  });

  final Country? country;
  final String? errorText;
  final bool enabled;
  final Locale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final selected = country;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: selected == null,
        decoration: InputDecoration(
          labelText: '${t.profile.countryLabel} *',
          // 未選択時はプレースホルダーを子として描くので、ラベルは常に上に逃がす
          // （そうしないとラベルとプレースホルダーが同じ位置に重なる）。
          floatingLabelBehavior: FloatingLabelBehavior.always,
          errorText: errorText,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          enabled: enabled,
        ),
        child: selected == null
            ? Text(
                t.profile.countryPlaceholder,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            : Row(
                children: [
                  CountryFlagIcon(country: selected),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selected.name.resolve(locale),
                      style: theme.textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SnsLinksSection extends StatelessWidget {
  const _SnsLinksSection({
    required this.links,
    required this.enabled,
    required this.onAdd,
    required this.onChanged,
    required this.onRemove,
  });

  final List<SnsLinkDraft> links;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<SnsLinkDraft> onChanged;
  final ValueChanged<Object> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final canAdd = links.length < UserProfile.snsLinksMaxCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.profile.snsLinksLabel,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: enabled && canAdd ? onAdd : null,
              icon: const Icon(Icons.add),
              label: Text(t.profile.addSnsLink),
            ),
          ],
        ),
        if (links.isEmpty)
          Text(
            t.profile.snsLinksEmpty,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          for (final link in links)
            Padding(
              key: ValueKey(link.id),
              padding: const EdgeInsets.only(top: 12),
              child: _SnsLinkRow(
                draft: link,
                enabled: enabled,
                onChanged: onChanged,
                onRemove: () => onRemove(link.id),
              ),
            ),
        if (!canAdd)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              t.profile.snsLinksMax(n: UserProfile.snsLinksMaxCount),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

/// Platform selector plus URL field for one SNS link.
///
/// Owns its [TextEditingController] so the text survives parent rebuilds
/// caused by sibling rows changing.
class _SnsLinkRow extends HookWidget {
  const _SnsLinkRow({
    required this.draft,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  final SnsLinkDraft draft;
  final bool enabled;
  final ValueChanged<SnsLinkDraft> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final controller = useTextEditingController(text: draft.value);

    String platformLabel(SnsPlatform platform) => platform.label ?? t.profile.snsPlatformOther;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 148,
          child: DropdownButtonFormField<SnsPlatform>(
            initialValue: draft.platform,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t.profile.snsPlatformLabel,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            items: [
              for (final platform in SnsPlatform.values)
                DropdownMenuItem(
                  value: platform,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SnsLinkIcon(platform: platform, size: 16),
                      const SizedBox(width: 8),
                      Flexible(child: Text(platformLabel(platform), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
            ],
            onChanged: enabled ? (platform) => onChanged(draft.copyWith(platform: platform)) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: t.profile.snsUrlLabel,
              hintText: 'https://',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => onChanged(draft.copyWith(value: value)),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return t.profile.snsUrlRequired;
              }
              return isValidSnsLinkUrl(text) ? null : t.profile.snsUrlInvalid;
            },
          ),
        ),
        IconButton(
          tooltip: t.profile.removeSnsLink,
          onPressed: enabled ? onRemove : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ],
    );
  }
}
