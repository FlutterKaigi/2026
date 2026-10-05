import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/qr_scanner_view.dart';
import 'package:app/feature/exchange/data/provider/exchange_link_configuration.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans the attendance QR code shown at the venue and pops with its
/// registration code.
///
/// The page never registers by itself. The camera reports the same QR code
/// many times a second, and every wrong code counts toward the attendee's
/// attempt limit, so the caller submits the returned code exactly once.
class SupportLtScanPage extends HookConsumerWidget {
  const SupportLtScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final origin = ref.watch(exchangeLinkConfigurationProvider.select((configuration) => configuration.origin));
    final controller = useMemoized(MobileScannerController.new);
    useEffect(
      () =>
          () => unawaited(controller.dispose()),
      [controller],
    );
    final route = ModalRoute.of(context);
    final isCompleted = useRef(false);

    void handleDetect(BarcodeCapture capture) {
      // The camera still reports codes while this route is leaving; popping
      // then would close the page underneath instead.
      if (isCompleted.value || !(route?.isCurrent ?? false)) {
        return;
      }
      final raw = capture.barcodes.firstOrNull?.rawValue;
      if (raw == null) {
        return;
      }
      final code = parseSupportLtQrPayload(raw, allowedOrigins: {?origin});
      if (code == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(t.supportLt.scanInvalid)));
        return;
      }
      isCompleted.value = true;
      unawaited(controller.stop());
      Navigator.of(context).pop(code);
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.supportLt.scanTitle)),
      body: QrScannerView(
        controller: controller,
        onDetect: handleDetect,
        hint: t.supportLt.scanHint,
        cameraErrorMessage: t.supportLt.scanCameraError,
      ),
    );
  }
}
