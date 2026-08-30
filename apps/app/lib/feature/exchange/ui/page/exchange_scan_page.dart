import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans another attendee's profile-exchange QR code and creates the
/// exchange in the signed-in user's list.
///
/// Writing straight to Firestore (rather than round-tripping through a
/// Cloud Function) keeps a scan usable offline: the write queues locally and
/// the caller's exchange list reflects it immediately, then propagates to the
/// other attendee once connectivity returns.
class ExchangeScanPage extends HookConsumerWidget {
  const ExchangeScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final myUid = ref.watch(authStateChangesProvider).value?.uid;
    final controller = useMemoized(MobileScannerController.new);
    useEffect(
      () =>
          () => unawaited(controller.dispose()),
      [controller],
    );
    final isProcessing = useState(false);

    void showMessage(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> handleDetect(BarcodeCapture capture) async {
      if (isProcessing.value || myUid == null) {
        return;
      }
      final barcodes = capture.barcodes;
      final raw = barcodes.isEmpty ? null : barcodes.first.rawValue;
      if (raw == null) {
        return;
      }
      final scanned = parseScannedExchangeToken(raw);
      if (scanned == null) {
        showMessage(t.exchange.scanInvalid);
        return;
      }
      if (scanned.otherUid == myUid) {
        showMessage(t.exchange.scanSelf);
        return;
      }

      isProcessing.value = true;
      await controller.stop();
      try {
        await ref
            .read(profileExchangeRepositoryProvider)
            .create(uid: myUid, otherUid: scanned.otherUid, token: scanned.token);
        if (context.mounted) {
          showMessage(t.exchange.scanSucceeded);
          Navigator.of(context).pop();
          return;
        }
      } on Exception catch (exception, stackTrace) {
        ref.read(talkerProvider).handle(exception, stackTrace);
        if (context.mounted) {
          showMessage(t.exchange.scanFailed);
        }
      }
      if (context.mounted) {
        isProcessing.value = false;
        await controller.start();
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.exchange.scanTitle)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) => unawaited(handleDetect(capture)),
            errorBuilder: (context, error) => _CameraError(message: t.exchange.scanCameraError),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t.exchange.scanHint,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
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

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
