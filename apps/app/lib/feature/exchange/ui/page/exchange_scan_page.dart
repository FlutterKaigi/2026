import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/ui/widget/qr_scanner_view.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/exchange_scan_handler.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:app/feature/exchange/data/provider/exchange_link_configuration.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/exchange/ui/widget/exchange_access_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans another attendee's profile-exchange QR code and creates the
/// exchange in the signed-in user's list.
class ExchangeScanPage extends ConsumerWidget {
  const ExchangeScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.exchange.scanTitle)),
      body: ExchangeAccessGate(builder: (context) => const _ScannerBody()),
    );
  }
}

/// Writing straight to Firestore (rather than round-tripping through a
/// Cloud Function) keeps a scan usable offline: the write queues locally and
/// the caller's exchange list reflects it immediately, then propagates to the
/// other attendee once connectivity returns.
class _ScannerBody extends HookConsumerWidget {
  const _ScannerBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final myUid = ref.watch(authStateChangesProvider).value?.uid;
    final linkConfiguration = ref.watch(exchangeLinkConfigurationProvider);
    final controller = useMemoized(MobileScannerController.new);
    useEffect(
      () =>
          () => unawaited(controller.dispose()),
      [controller],
    );
    final isProcessing = useState(false);
    final route = ModalRoute.of(context);
    // The camera still reports codes, and a started exchange still completes,
    // while this route is leaving after a back navigation.
    bool isCurrentRoute() => route?.isCurrent ?? false;

    void showMessage(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> handleDetect(BarcodeCapture capture) async {
      if (isProcessing.value || myUid == null || !isCurrentRoute()) {
        return;
      }
      final barcodes = capture.barcodes;
      final raw = barcodes.isEmpty ? null : barcodes.first.rawValue;
      if (raw == null) {
        return;
      }
      final scanned = parseScannedExchangeToken(raw, allowedOrigins: linkConfiguration.allowedOrigins);
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
      final outcome = await ExchangeScanHandler(
        myUid: myUid,
        repository: ref.read(profileExchangeRepositoryProvider),
      ).createExchange(otherUid: scanned.otherUid, token: scanned.token);

      switch (outcome) {
        case ExchangeCreated():
          if (context.mounted) {
            showMessage(t.exchange.scanSucceeded);
            // Popping a leaving route would close the page underneath instead.
            if (isCurrentRoute()) {
              Navigator.of(context).pop();
            }
            return;
          }
        case ExchangeAlreadyExists():
          if (context.mounted) {
            showMessage(t.exchange.scanAlreadyExists);
          }
        case ExchangeCreateFailed(:final error, :final stackTrace):
          ref.read(talkerProvider).handle(error, stackTrace);
          if (context.mounted) {
            showMessage(t.exchange.scanFailed);
          }
      }
      if (context.mounted) {
        isProcessing.value = false;
        await controller.start();
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        QrScannerView(
          controller: controller,
          onDetect: (capture) => unawaited(handleDetect(capture)),
          hint: t.exchange.scanHint,
          cameraErrorMessage: t.exchange.scanCameraError,
        ),
        if (isProcessing.value)
          const ColoredBox(
            color: Colors.black45,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
