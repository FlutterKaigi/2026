import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_page_content.dart';
import 'package:app/core/ui/widget/brand_header_card.dart';
import 'package:app/feature/auth/ui/widget/authenticated_body.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/sns_post/data/sns_post_provider.dart';
import 'package:app/feature/sns_post/ui/sns_post_companion_label.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class SnsPostPage extends StatelessWidget {
  const SnsPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.snsPost.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: AuthenticatedBody(
        signedOut: AppPageContent(
          maxWidth: 560,
          child: SignInCard(title: t.auth.signIn.required, description: t.snsPost.signInRequired),
        ),
        builder: (uid) => _RegistrationBody(uid: uid),
      ),
    );
  }
}

class _RegistrationBody extends HookConsumerWidget {
  const _RegistrationBody({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registration = ref.watch(snsPostRegistrationProvider(uid));
    final editing = useState(false);
    return switch (registration) {
      AsyncData(:final value) => AppPageContent(
        maxWidth: 560,
        child: BrandHeaderCard(
          child: value == null || editing.value
              ? _RegistrationForm(
                  uid: uid,
                  initial: value,
                  onSaved: () => editing.value = false,
                  onCancel: value == null ? null : () => editing.value = false,
                )
              : _RegisteredContent(registration: value, onEdit: () => editing.value = true),
        ),
      ),
      AsyncError(error: FormatException()) => AppPageContent(
        maxWidth: 560,
        child: BrandHeaderCard(
          child: _RegistrationForm(
            uid: uid,
            initial: null,
            notice: Translations.of(context).snsPost.invalidRegistration,
            onSaved: () => ref.invalidate(snsPostRegistrationProvider(uid)),
            onCancel: null,
          ),
        ),
      ),
      AsyncError(:final error) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(snsPostRegistrationProvider(uid)),
      ),
      _ => const Center(child: CircularProgressIndicator.adaptive()),
    };
  }
}

class _RegistrationForm extends HookConsumerWidget {
  const _RegistrationForm({
    required this.uid,
    required this.initial,
    required this.onSaved,
    required this.onCancel,
    this.notice,
  });

  final String uid;
  final SnsPostRegistration? initial;
  final VoidCallback onSaved;
  final VoidCallback? onCancel;
  final String? notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final controller = useTextEditingController(text: initial?.url);
    final companionKey = useMemoized(GlobalKey<FormFieldState<SnsPostCompanion>>.new);
    final submitting = useState(false);
    final error = useState<String?>(null);

    Future<void> submit() async {
      if (submitting.value || !formKey.currentState!.validate()) {
        return;
      }
      submitting.value = true;
      error.value = null;
      FocusScope.of(context).unfocus();
      try {
        await ref
            .read(snsPostRepositoryProvider)
            .save(
              uid: uid,
              url: controller.text.trim(),
              companion: companionKey.currentState!.value!,
            );
        if (context.mounted) {
          onSaved();
        }
      } on Exception catch (exception, stackTrace) {
        if (context.mounted) {
          ref.read(talkerProvider).handle(exception, stackTrace);
          error.value = t.snsPost.saveFailed;
        }
      } finally {
        if (context.mounted) {
          submitting.value = false;
        }
      }
    }

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notice != null) ...[
            Text(notice!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            const SizedBox(height: 16),
          ],
          Text(
            t.snsPost.heading,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            t.snsPost.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          Text(t.snsPost.companionLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(t.snsPost.companionHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          FormField<SnsPostCompanion>(
            key: companionKey,
            initialValue: initial?.companion,
            validator: (value) => value == null ? t.snsPost.companionRequired : null,
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final option in SnsPostCompanion.values)
                      ChoiceChip(
                        label: Text(snsPostCompanionLabel(t, option)),
                        selected: field.value == option,
                        onSelected: submitting.value ? null : (_) => field.didChange(option),
                      ),
                  ],
                ),
                if (field.errorText case final message?)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(message, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: controller,
            enabled: !submitting.value,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: SnsPostRegistration.urlMaxLength,
            decoration: InputDecoration(
              labelText: t.snsPost.urlLabel,
              hintText: 'https://x.com/…/status/…',
              helperText: t.snsPost.urlHint,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.link),
              counterText: '',
            ),
            validator: (value) => SnsPostRegistration.isValidUrl(value?.trim() ?? '') ? null : t.snsPost.invalidUrl,
            onFieldSubmitted: (_) => submit(),
          ),
          if (error.value case final message?) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: theme.colorScheme.error),
              semanticsLabel: message,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: submitting.value ? null : submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: submitting.value
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: Text(
              submitting.value
                  ? t.snsPost.saving
                  : initial == null
                  ? t.snsPost.register
                  : t.snsPost.update,
            ),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: submitting.value ? null : onCancel, child: Text(t.snsPost.cancel)),
          ],
        ],
      ),
    );
  }
}

class _RegisteredContent extends StatelessWidget {
  const _RegisteredContent({required this.registration, required this.onEdit});

  final SnsPostRegistration registration;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final date = DateFormat.yMd(t.$meta.locale.languageCode).add_Hm().format(registration.updatedAt.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 32, color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t.snsPost.registeredTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(t.snsPost.registeredBody, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Card.outlined(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  avatar: Icon(Icons.people_outline, size: 18, color: theme.colorScheme.onTertiaryContainer),
                  label: Text(snsPostCompanionLabel(t, registration.companion)),
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  labelStyle: TextStyle(color: theme.colorScheme.onTertiaryContainer),
                  side: BorderSide.none,
                ),
                const SizedBox(height: 8),
                SelectableText(registration.url, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(t.snsPost.updatedAt(date: date), style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => launchExternalUrl(
                    context,
                    uri: Uri.parse(registration.url),
                    failureMessage: t.snsPost.openFailed,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(t.snsPost.openPost),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => const MissionRoute().go(context),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(t.snsPost.viewMissions),
        ),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined), label: Text(t.snsPost.edit)),
      ],
    );
  }
}
