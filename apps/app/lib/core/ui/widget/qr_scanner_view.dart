import 'dart:async';

import 'package:app/core/log/talker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Camera preview that reports detected QR codes, with [hint] over the preview
/// and [cameraErrorMessage] in its place when the camera is unavailable.
class QrScannerView extends ConsumerStatefulWidget {
  const QrScannerView({
    required this.controller,
    required this.onDetect,
    required this.hint,
    required this.cameraErrorMessage,
    this.canScan,
    super.key,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;
  final String hint;
  final String cameraErrorMessage;

  /// False as soon as a result is accepted, including during route transitions.
  final bool Function()? canScan;

  @override
  ConsumerState<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends ConsumerState<QrScannerView> with WidgetsBindingObserver {
  Future<void>? _stopping;
  bool _resuming = false;
  bool _hasRoute = false;
  bool _permissionDenied = false;
  bool _permissionRetryAllowed = false;
  AppLifecycleState? _lastLifecycleState;
  late final void Function(Object, StackTrace) _reportError;

  bool get _isForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  bool get _canScan => mounted && (ModalRoute.of(context)?.isCurrent ?? true) && (widget.canScan?.call() ?? true);

  @override
  void initState() {
    super.initState();
    // MobileScanner observes app lifecycle only when it owns the controller.
    WidgetsBinding.instance.addObserver(this);
    _lastLifecycleState = WidgetsBinding.instance.lifecycleState;
    _reportError = ref.read(talkerProvider).handle;
    _permissionDenied = widget.controller.value.error?.errorCode == MobileScannerErrorCode.permissionDenied;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The child performs its own initial autoStart after attaching the controller.
    if (_hasRoute) {
      if (_canScan) {
        unawaited(_resume());
      } else {
        _stop();
      }
    }
    _hasRoute = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasBackgrounded =
        _lastLifecycleState == AppLifecycleState.hidden || _lastLifecycleState == AppLifecycleState.paused;
    _lastLifecycleState = state;
    // Flutter also synthesizes hidden while returning from paused. A denial
    // received in the background must wait for a new departure, not that return.
    if (_permissionDenied &&
        !wasBackgrounded &&
        (state == AppLifecycleState.hidden || state == AppLifecycleState.paused)) {
      _permissionRetryAllowed = true;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_resume());
    } else {
      _stop();
    }
  }

  void _onControllerChanged() {
    final denied = widget.controller.value.error?.errorCode == MobileScannerErrorCode.permissionDenied;
    if (denied && !_permissionDenied) {
      _permissionRetryAllowed = false;
    }
    _permissionDenied = denied;
    // autoStart can finish after a permission prompt or a route/lifecycle change.
    if (!_canScan || !_isForeground) {
      _stop();
    }
  }

  void _stop() {
    // Permission prompts can change lifecycle while start() is still pending.
    if (widget.controller.value.isStarting || !widget.controller.value.isRunning) {
      return;
    }
    _stopping = _stopController();
  }

  Future<void> _stopController() async {
    try {
      await widget.controller.stop();
    } on Exception catch (error, stackTrace) {
      // The plugin translates start failures into controller.value.error, but
      // stop forwards platform exceptions. Consume and log this async boundary.
      _reportError(error, stackTrace);
    }
  }

  Future<void> _resume() async {
    if (_resuming) {
      return;
    }
    _resuming = true;
    try {
      await _stopping;
      if (!_canScan || !_isForeground) {
        return;
      }
      if (widget.controller.value.isStarting || widget.controller.value.isRunning) {
        return;
      }
      // Dismissing Android's permission prompt can itself resume the app.
      // Retry a denial only after leaving the app (for example, for Settings),
      // not on a focus change or when uncovering this route.
      if (_permissionDenied && !_permissionRetryAllowed) {
        return;
      }
      _permissionRetryAllowed = false;
      await widget.controller.start();
    } on Exception catch (error, stackTrace) {
      _reportError(error, stackTrace);
    } finally {
      _resuming = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      MobileScanner(
        controller: widget.controller,
        onDetect: (capture) {
          if (_canScan && _isForeground) {
            widget.onDetect(capture);
          }
        },
        errorBuilder: (context, error) => _CameraError(message: widget.cameraErrorMessage),
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
              widget.hint,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ],
  );
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
