import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/exchange_scan_outcome.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository_provider.dart';
import 'package:app/feature/exchange/ui/widget/exchange_enter_code_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// `/account/exchange/scan` — scans another attendee's exchange QR code.
///
/// Pops with an [ExchangeScanOutcome] once a definitive result is reached
/// (success, self-scan, duplicate, or an unexpected error); a malformed
/// barcode (e.g. an unrelated QR code) shows an inline message and keeps
/// scanning instead, since it is likely just a stray scan.
class ExchangeScanPage extends HookConsumerWidget {
  const ExchangeScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final controller = useMemoized(MobileScannerController.new);
    useEffect(() => controller.dispose, const []);
    final isProcessing = useState(false);

    Future<void> handleEnterCodeInstead() async {
      final outcome = await showExchangeEnterCodeSheet(context);
      if (outcome != null && context.mounted) {
        context.pop(outcome);
      }
    }

    Future<void> onDetect(BarcodeCapture capture) async {
      if (isProcessing.value || uid == null || capture.barcodes.isEmpty) {
        return;
      }
      final raw = capture.barcodes.first.rawValue;
      if (raw == null) {
        return;
      }

      isProcessing.value = true;
      final outcome = await handleScannedExchangeToken(
        raw: raw,
        currentUid: uid,
        repository: ref.read(profileExchangeRepositoryProvider),
      );
      if (!context.mounted) {
        return;
      }
      if (outcome.kind == ExchangeScanOutcomeKind.malformed) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(exchangeScanOutcomeMessage(t, outcome))));
        isProcessing.value = false;
        return;
      }
      context.pop(outcome);
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.exchange.scan.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
            errorBuilder: (context, error) => _CameraErrorView(
              error: error,
              onEnterCodeInstead: handleEnterCodeInstead,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      t.exchange.scan.hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: handleEnterCodeInstead,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: Text(t.exchange.scan.enterCodeInstead),
                ),
              ],
            ),
          ),
          if (isProcessing.value)
            const ColoredBox(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

/// Shown by [MobileScanner] when the camera cannot be used (most commonly a
/// denied permission), with a fallback to the 6-digit code entry sheet.
class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.error, required this.onEnterCodeInstead});

  final MobileScannerException error;
  final VoidCallback onEnterCodeInstead;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                t.exchange.scan.permissionDeniedTitle,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                t.exchange.scan.permissionDeniedBody,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onEnterCodeInstead, child: Text(t.exchange.scan.enterCodeInstead)),
            ],
          ),
        ),
      ),
    );
  }
}
