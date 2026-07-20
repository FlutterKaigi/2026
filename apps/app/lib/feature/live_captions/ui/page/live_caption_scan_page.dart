import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/live_captions/util/caption_target_parser.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans a venue QR code (or takes a manual room id) and opens its captions.
class LiveCaptionScanPage extends StatefulWidget {
  const LiveCaptionScanPage({super.key});

  @override
  State<LiveCaptionScanPage> createState() => _LiveCaptionScanPageState();
}

class _LiveCaptionScanPageState extends State<LiveCaptionScanPage> {
  final _manualController = TextEditingController();
  var _handled = false;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  void _open(String venueId) {
    if (_handled) {
      return;
    }
    _handled = true;
    LiveCaptionRoomRoute(venueId: venueId).pushReplacement(context);
  }

  void _showInvalidPayloadMessage() {
    final t = Translations.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(t.liveCaptions.scan.invalid)));
  }

  void _onDetect(BarcodeCapture capture) {
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null) {
      return;
    }
    final venueId = parseCaptionTarget(rawValue);
    if (venueId == null) {
      _showInvalidPayloadMessage();
      return;
    }
    _open(venueId);
  }

  void _submitManualInput() {
    final venueId = parseCaptionTarget(_manualController.text);
    if (venueId == null) {
      _showInvalidPayloadMessage();
      return;
    }
    _open(venueId);
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.liveCaptions.scan.title)),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    t.liveCaptions.scan.cameraError,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.liveCaptions.scan.instruction),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _manualController,
                    decoration: InputDecoration(
                      labelText: t.liveCaptions.scan.manualLabel,
                      hintText: t.liveCaptions.scan.manualHint,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        tooltip: t.liveCaptions.scan.open,
                        onPressed: _submitManualInput,
                      ),
                    ),
                    autocorrect: false,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _submitManualInput(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
