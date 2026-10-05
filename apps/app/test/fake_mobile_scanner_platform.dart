import 'package:mobile_scanner/mobile_scanner.dart';

/// Fails every `start()` the way an unavailable camera would, so
/// [MobileScannerController] surfaces it through `value.error` (and the
/// widget's `errorBuilder`) rather than a raw platform-channel exception.
///
/// mobile_scanner talks to the platform over a method channel that has no
/// implementation in widget tests. Faking the platform (rather than stubbing a
/// channel) keeps `MobileScannerController.start()` inside its own documented
/// error handling instead of throwing an unhandled `MissingPluginException`
/// from `initState()`'s fire-and-forget `_initializeController()`. `onDetect`
/// is a plain callback stored on the `MobileScanner` widget, so tests can
/// still invoke it directly without a real camera preview.
final class FakeMobileScannerPlatform extends MobileScannerPlatform {
  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) {
    throw const MobileScannerException(
      errorCode: MobileScannerErrorCode.genericError,
      errorDetails: MobileScannerErrorDetails(message: 'No platform camera in widget tests.'),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
