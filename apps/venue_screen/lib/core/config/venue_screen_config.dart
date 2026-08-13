enum VenueScreenView { overlay, preview }

final class VenueScreenConfig {
  const VenueScreenConfig({
    required this.webSocketUri,
    required this.roomId,
    required this.sessionId,
    required this.view,
    required this.maxLines,
    required this.fontSize,
    required this.lineHeight,
    required this.horizontalMargin,
    required this.bottomMargin,
    required this.backgroundOpacity,
    required this.staleAfter,
    this.configurationError,
  });

  factory VenueScreenConfig.fromUri(Uri uri) {
    final parameters = uri.queryParameters;
    final roomParameter = parameters['room'];
    final sessionParameter = parameters['session'];
    final roomId = roomParameter ?? 'main';
    final sessionId = sessionParameter ?? 'rehearsal';
    final configurationErrors = <String>[
      if (!_isSafeIdentifier(roomId)) 'room must be a safe identifier',
      if (!_isSafeIdentifier(sessionId)) 'session must be a safe identifier',
      if (parameters.containsKey('token')) 'credentials must not be placed in URL query parameters',
    ];

    final explicitWebSocketParameter = parameters['ws'];
    final explicitWebSocketUri = explicitWebSocketParameter == null ? null : Uri.tryParse(explicitWebSocketParameter);
    if (explicitWebSocketParameter != null &&
        (explicitWebSocketUri == null ||
            !explicitWebSocketUri.hasAuthority ||
            explicitWebSocketUri.userInfo.isNotEmpty ||
            (explicitWebSocketUri.scheme != 'ws' && explicitWebSocketUri.scheme != 'wss'))) {
      configurationErrors.add('ws must be an absolute ws:// or wss:// URL without credentials');
    }
    if (explicitWebSocketUri != null && explicitWebSocketUri.queryParameters.containsKey('token')) {
      configurationErrors.add('credentials must not be placed in the ws URL query parameters');
    }
    final baseWebSocketUri =
        explicitWebSocketUri != null &&
            explicitWebSocketUri.hasAuthority &&
            (explicitWebSocketUri.scheme == 'ws' || explicitWebSocketUri.scheme == 'wss')
        ? explicitWebSocketUri
        : Uri(
            scheme: uri.scheme == 'https' ? 'wss' : 'ws',
            host: uri.host.isEmpty ? '127.0.0.1' : uri.host,
            port: uri.hasPort ? uri.port : null,
            path: '/ws',
          );
    if (!_isLoopbackHost(baseWebSocketUri.host)) {
      configurationErrors.add('ws host must be loopback because the caption relay is local-only');
    }
    final webSocketUri = baseWebSocketUri.replace(
      queryParameters: {
        'room': roomId,
        'session': sessionId,
      },
    );

    return VenueScreenConfig(
      webSocketUri: webSocketUri,
      roomId: roomId,
      sessionId: sessionId,
      view: parameters['view'] == 'preview' ? VenueScreenView.preview : VenueScreenView.overlay,
      maxLines: _intParameter(parameters['maxLines'], fallback: 1, minimum: 1, maximum: 2),
      fontSize: _doubleParameter(parameters['fontSize'], fallback: 64, minimum: 36, maximum: 96),
      lineHeight: _doubleParameter(parameters['lineHeight'], fallback: 1.25, minimum: 1, maximum: 1.6),
      horizontalMargin: _doubleParameter(parameters['horizontal'], fallback: 72, minimum: 24, maximum: 200),
      bottomMargin: _doubleParameter(parameters['bottom'], fallback: 54, minimum: 16, maximum: 240),
      backgroundOpacity: _doubleParameter(parameters['opacity'], fallback: 0.88, minimum: 0.65, maximum: 1),
      staleAfter: Duration(
        seconds: _intParameter(parameters['staleAfter'], fallback: 12, minimum: 6, maximum: 60),
      ),
      configurationError: configurationErrors.isEmpty ? null : configurationErrors.join('; '),
    );
  }

  final Uri webSocketUri;
  final String roomId;
  final String sessionId;
  final VenueScreenView view;
  final int maxLines;
  final double fontSize;
  final double lineHeight;
  final double horizontalMargin;
  final double bottomMargin;
  final double backgroundOpacity;
  final Duration staleAfter;
  final String? configurationError;

  bool get isValid => configurationError == null;
}

bool _isSafeIdentifier(String value) => RegExp(r'^[A-Za-z0-9._:-]{1,128}$').hasMatch(value);

bool _isLoopbackHost(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'localhost' ||
      normalized == '::1' ||
      normalized == '0:0:0:0:0:0:0:1' ||
      RegExp(r'^127(?:\.[0-9]{1,3}){3}$').hasMatch(normalized);
}

int _intParameter(String? source, {required int fallback, required int minimum, required int maximum}) {
  final value = int.tryParse(source ?? '');
  return value == null ? fallback : value.clamp(minimum, maximum);
}

double _doubleParameter(String? source, {required double fallback, required double minimum, required double maximum}) {
  final value = double.tryParse(source ?? '');
  return value == null || !value.isFinite ? fallback : value.clamp(minimum, maximum);
}
