import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/exchange_scan_outcome.dart';
import 'package:app/feature/exchange/data/provider/exchange_token_service.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Opens a bottom sheet where the signed-in user can enter the other
/// attendee's 6-digit fallback code. Returns the resulting
/// [ExchangeScanOutcome], or `null` if dismissed without submitting
/// successfully.
Future<ExchangeScanOutcome?> showExchangeEnterCodeSheet(BuildContext context) =>
    showModalBottomSheet<ExchangeScanOutcome>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ExchangeEnterCodeSheet(),
    );

class _ExchangeEnterCodeSheet extends HookConsumerWidget {
  const _ExchangeEnterCodeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final controller = useTextEditingController();
    final isSubmitting = useState(false);
    final errorText = useState<String?>(null);

    Future<void> submit() async {
      final uid = ref.read(authStateChangesProvider).value?.uid;
      final code = controller.text.trim();
      if (uid == null || isSubmitting.value) {
        return;
      }
      if (!RegExp(r'^\d{6}$').hasMatch(code)) {
        errorText.value = t.exchange.code.enterInvalidFormat;
        return;
      }

      isSubmitting.value = true;
      errorText.value = null;
      try {
        final redeemed = await ref.read(exchangeTokenServiceProvider).redeemCode(code);
        final outcome = await handleScannedExchangeToken(
          raw: redeemed.token,
          currentUid: uid,
          repository: ref.read(profileExchangeRepositoryProvider),
        );
        if (context.mounted) {
          Navigator.of(context).pop(outcome);
        }
      } on FirebaseException catch (exception) {
        errorText.value = switch (exception.code) {
          'not-found' => t.exchange.code.notFound,
          'deadline-exceeded' => t.exchange.code.expiredCode,
          'failed-precondition' => t.exchange.code.selfCode,
          'resource-exhausted' => t.exchange.code.rateLimited,
          _ => t.exchange.code.genericError,
        };
      } on Object {
        errorText.value = t.exchange.code.genericError;
      } finally {
        if (context.mounted) {
          isSubmitting.value = false;
        }
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.exchange.code.enterTitle, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            t.exchange.code.enterDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            enabled: !isSubmitting.value,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 4),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              counterText: '',
              errorText: errorText.value,
            ),
            onSubmitted: (_) => submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isSubmitting.value ? null : submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: isSubmitting.value
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t.exchange.code.submit),
          ),
        ],
      ),
    );
  }
}
