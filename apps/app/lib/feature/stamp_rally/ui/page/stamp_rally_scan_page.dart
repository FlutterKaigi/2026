import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/qr_scanner_view.dart';
import 'package:app/feature/auth/ui/widget/authenticated_body.dart';
import 'package:app/feature/auth/ui/widget/centered_sign_in_card.dart';
import 'package:app/feature/stamp_rally/data/stamp_rally_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Reads a stamp rally QR code and hands it to `StampRallyLinkPage`, the same
/// screen the OS camera opens, so both paths share one result flow.
class StampRallyScanPage extends StatelessWidget {
  const StampRallyScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.stampRally.scanTitle)),
      body: AuthenticatedBody(
        signedOut: CenteredSignInCard(title: t.auth.signIn.required, description: t.stampRally.signInRequired),
        builder: (_) => const _ScannerBody(),
      ),
    );
  }
}

class _ScannerBody extends HookWidget {
  const _ScannerBody();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final controller = useMemoized(MobileScannerController.new);
    useEffect(
      () =>
          () => unawaited(controller.dispose()),
      [controller],
    );
    final handled = useRef(false);
    final route = ModalRoute.of(context);

    void handleDetect(BarcodeCapture capture) {
      final raw = capture.barcodes.firstOrNull?.rawValue;
      if (handled.value || !(route?.isCurrent ?? false) || raw == null) {
        return;
      }
      final token = parseStampRallyUrl(raw);
      if (token == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(t.stampRally.scanInvalid)));
        return;
      }
      handled.value = true;
      unawaited(controller.stop());
      StampRallyLinkRoute(token: token).pushReplacement(context);
    }

    return QrScannerView(
      controller: controller,
      onDetect: handleDetect,
      canScan: () => !handled.value,
      hint: t.stampRally.scanHint,
      cameraErrorMessage: t.stampRally.scanCameraError,
    );
  }
}
