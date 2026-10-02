import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_page_content.dart';
import 'package:app/feature/auth/ui/widget/authenticated_body.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
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
        signedOut: AppPageContent(
          maxWidth: signInCardMaxWidth,
          padding: const EdgeInsets.all(24),
          centerVertically: true,
          child: SignInCard(title: t.auth.signIn.required, description: t.stampRally.signInRequired),
        ),
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

    void handleDetect(BarcodeCapture capture) {
      final raw = capture.barcodes.firstOrNull?.rawValue;
      if (handled.value || raw == null) {
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

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: controller,
          onDetect: handleDetect,
          errorBuilder: (context, error) => ColoredBox(
            color: Colors.black,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  t.stampRally.scanCameraError,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: Text(
                t.stampRally.scanHint,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
