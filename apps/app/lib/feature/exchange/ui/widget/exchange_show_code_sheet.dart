import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/exchange/data/provider/exchange_token_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Opens a bottom sheet showing a freshly-issued 6-digit fallback code for
/// the signed-in user to read out to the other attendee.
Future<void> showExchangeCodeSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const _ExchangeShowCodeSheet(),
);

class _ExchangeShowCodeSheet extends HookConsumerWidget {
  const _ExchangeShowCodeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final codeState = useState<AsyncValue<IssuedExchangeCode>>(const AsyncLoading());
    final secondsLeft = useState<int>(0);

    Future<void> issue() async {
      codeState.value = const AsyncLoading();
      try {
        final issued = await ref.read(exchangeTokenServiceProvider).issueCode();
        codeState.value = AsyncData(issued);
        secondsLeft.value = issued.expiresInSeconds;
      } on Object catch (error, stackTrace) {
        codeState.value = AsyncError(error, stackTrace);
      }
    }

    // 発行直後に一度だけ取得する。
    useEffect(() {
      unawaited(issue());
      return null;
    }, const []);

    // 発行済みコードがある間だけ、1秒ごとに残り時間を減らす。
    useEffect(() {
      if (codeState.value is! AsyncData) {
        return null;
      }
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (secondsLeft.value > 0) {
          secondsLeft.value -= 1;
        }
      });
      return timer.cancel;
    }, [codeState.value]);

    final isExpired = codeState.value is AsyncData && secondsLeft.value <= 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.exchange.code.showTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            t.exchange.code.showDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          switch (codeState.value) {
            AsyncData(:final value) when !isExpired => Column(
              children: [
                Text(
                  _spacedCode(value.code),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.exchange.code.expiresIn(seconds: secondsLeft.value),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            AsyncData() => Column(
              children: [
                Text(t.exchange.code.expired, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                FilledButton(onPressed: issue, child: Text(t.exchange.code.reissue)),
              ],
            ),
            AsyncError() => Column(
              children: [
                Text(t.exchange.code.issueFailed, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: issue, child: Text(t.error.retry)),
              ],
            ),
            _ => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator.adaptive(),
            ),
          },
        ],
      ),
    );
  }

  String _spacedCode(String code) => code.split('').join(' ');
}
