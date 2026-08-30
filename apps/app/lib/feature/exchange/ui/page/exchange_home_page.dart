import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/exchange_code.dart';
import 'package:app/feature/exchange/data/exchange_code_redeem_handler.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/exchange/ui/widget/exchange_access_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Own QR code and the entry points to scan another attendee's QR code or
/// view previously exchanged profiles.
class ExchangeHomePage extends ConsumerWidget {
  const ExchangeHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.exchange.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ExchangeAccessGate(builder: (context) => const _ExchangeHomeBody()),
    );
  }
}

class _ExchangeHomeBody extends ConsumerWidget {
  const _ExchangeHomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final tokenState = ref.watch(myExchangeTokenProvider);

    return AppScrollbar(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.exchange.qrDescription,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                switch (tokenState) {
                  AsyncData(:final value) => _QrCard(qrPayload: value.qrPayload, expiresAt: value.expiresAt),
                  AsyncError(:final error) => AppErrorView(
                    error: error,
                    onRetry: () => ref.read(myExchangeTokenProvider.notifier).refresh(),
                  ),
                  AsyncLoading() => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                },
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => const ExchangeScanRoute().push<void>(context),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(t.exchange.scanButton),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => const ExchangeListRoute().push<void>(context),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.people_outline),
                  label: Text(t.exchange.listButton),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  t.exchange.codeSectionTitle,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  t.exchange.codeSectionDescription,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                const _MyCodeCard(),
                const SizedBox(height: 16),
                const _RedeemCodeForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.qrPayload, required this.expiresAt});

  final String qrPayload;
  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // A QR reader binarizes the image assuming dark modules on a
            // light background, so the code must stay white/black no matter
            // which app theme is active — following Card.outlined's dark
            // surface here would make the code fail to scan, not just be
            // hard to see. Module color and the quiet-zone padding are left
            // at qr_flutter's own black-on-transparent defaults (only the
            // background is overridden below) and pinned by a widget test
            // instead, so a future default change in the package surfaces
            // as a test failure rather than a silent regression. The
            // rounded clip keeps the white square from reading as a stray
            // rectangle against the card's rounded corners.
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: QrImageView(
                data: qrPayload,
                size: 220,
                backgroundColor: Colors.white,
                semanticsLabel: t.exchange.qrSemanticLabel,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.exchange.qrExpiresAt(date: DateFormat.yMd(locale.toString()).add_Hm().format(expiresAt.toLocal())),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// The signed-in user's own 6-digit code, with its expiry time (short-lived
/// by design — see [ExchangeCode]) and a manual refresh action.
///
/// The expiry is shown as a fixed timestamp — the same style [_QrCard] uses
/// for its 24-hour token — rather than a live-ticking countdown, so the
/// widget never needs a repeating timer just to stay visually accurate.
class _MyCodeCard extends ConsumerWidget {
  const _MyCodeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeState = ref.watch(myExchangeCodeProvider);

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: switch (codeState) {
          AsyncData(:final value) => _CodeDisplay(code: value),
          AsyncError(:final error) => AppErrorView(
            error: error,
            onRetry: () => ref.read(myExchangeCodeProvider.notifier).refresh(),
          ),
          AsyncLoading() => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator.adaptive()),
          ),
        },
      ),
    );
  }
}

class _CodeDisplay extends ConsumerWidget {
  const _CodeDisplay({required this.code});

  final ExchangeCode code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    return Column(
      children: [
        Text(
          _formatGrouped(code.value),
          semanticsLabel: t.exchange.myCodeSemanticLabel,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 4),
        ),
        const SizedBox(height: 8),
        Text(
          code.isExpired
              ? t.exchange.myCodeExpired
              : t.exchange.myCodeExpiresAt(date: DateFormat.Hms(locale.toString()).format(code.expiresAt.toLocal())),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => ref.read(myExchangeCodeProvider.notifier).refresh(),
          child: Text(t.exchange.myCodeRefresh),
        ),
      ],
    );
  }
}

/// Splits a 6-digit code into two groups of three for readability
/// (e.g. `123456` -> `123 456`).
String _formatGrouped(String code) => code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;

/// Form for entering another attendee's 6-digit code.
class _RedeemCodeForm extends HookConsumerWidget {
  const _RedeemCodeForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final controller = useTextEditingController();
    final isSubmitting = useState(false);
    final myUid = ref.watch(authStateChangesProvider).value?.uid;

    void showMessage(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> submit() async {
      final uid = myUid;
      if (uid == null || isSubmitting.value) {
        return;
      }
      final code = controller.text.trim();
      if (!RegExp(r'^\d{6}$').hasMatch(code)) {
        showMessage(t.exchange.enterCodeInvalidFormat);
        return;
      }

      isSubmitting.value = true;
      final outcome = await ExchangeCodeRedeemHandler(
        myUid: uid,
        redeemer: ref.read(exchangeCodeRedeemerProvider),
        repository: ref.read(profileExchangeRepositoryProvider),
      ).redeem(code);
      if (context.mounted) {
        isSubmitting.value = false;
      }

      switch (outcome) {
        case RedeemExchangeCodeSucceeded():
          if (context.mounted) {
            controller.clear();
            showMessage(t.exchange.scanSucceeded);
          }
        case RedeemExchangeCodeAlreadyExists():
          if (context.mounted) {
            controller.clear();
            showMessage(t.exchange.scanAlreadyExists);
          }
        case RedeemExchangeCodeInvalid():
          if (context.mounted) {
            showMessage(t.exchange.redeemInvalid);
          }
        case RedeemExchangeCodeSelf():
          if (context.mounted) {
            showMessage(t.exchange.redeemSelf);
          }
        case RedeemExchangeCodeRateLimited():
          if (context.mounted) {
            showMessage(t.exchange.redeemRateLimited);
          }
        case RedeemExchangeCodeFailed(:final error, :final stackTrace):
          ref.read(talkerProvider).handle(error, stackTrace);
          if (context.mounted) {
            showMessage(t.exchange.scanFailed);
          }
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !isSubmitting.value,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            onSubmitted: (_) => unawaited(submit()),
            decoration: InputDecoration(
              labelText: t.exchange.enterCodeLabel,
              hintText: t.exchange.enterCodeHint,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: FilledButton(
            onPressed: isSubmitting.value ? null : () => unawaited(submit()),
            child: isSubmitting.value
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t.exchange.enterCodeButton),
          ),
        ),
      ],
    );
  }
}
