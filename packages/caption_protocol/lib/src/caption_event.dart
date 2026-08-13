import 'dart:convert';

import 'package:caption_protocol/src/caption_stream_key.dart';

enum CaptionEventType {
  caption,
  clear,
  heartbeat,
}

final class CaptionEvent {
  CaptionEvent._({
    required this.protocolVersion,
    required this.type,
    required this.roomId,
    required this.sessionId,
    required this.sequence,
    required this.producedAt,
    this.utteranceId,
    this.utteranceSequence,
    this.revision,
    this.sourceText,
    this.translatedText,
    this.isFinal,
    this.sourceStartedAt,
    this.clearAt,
  }) {
    _validate();
  }

  factory CaptionEvent.caption({
    required String roomId,
    required String sessionId,
    required int sequence,
    required String utteranceId,
    required int utteranceSequence,
    required int revision,
    required String translatedText,
    required bool isFinal,
    required DateTime sourceStartedAt,
    required DateTime producedAt,
    required DateTime clearAt,
    String? sourceText,
  }) => CaptionEvent._(
    protocolVersion: currentProtocolVersion,
    type: CaptionEventType.caption,
    roomId: roomId,
    sessionId: sessionId,
    sequence: sequence,
    utteranceId: utteranceId,
    utteranceSequence: utteranceSequence,
    revision: revision,
    sourceText: sourceText,
    translatedText: translatedText,
    isFinal: isFinal,
    sourceStartedAt: sourceStartedAt.toUtc(),
    producedAt: producedAt.toUtc(),
    clearAt: clearAt.toUtc(),
  );

  factory CaptionEvent.clear({
    required String roomId,
    required String sessionId,
    required int sequence,
    required DateTime producedAt,
  }) => CaptionEvent._(
    protocolVersion: currentProtocolVersion,
    type: CaptionEventType.clear,
    roomId: roomId,
    sessionId: sessionId,
    sequence: sequence,
    producedAt: producedAt.toUtc(),
  );

  factory CaptionEvent.heartbeat({
    required String roomId,
    required String sessionId,
    required int sequence,
    required DateTime producedAt,
  }) => CaptionEvent._(
    protocolVersion: currentProtocolVersion,
    type: CaptionEventType.heartbeat,
    roomId: roomId,
    sessionId: sessionId,
    sequence: sequence,
    producedAt: producedAt.toUtc(),
  );

  factory CaptionEvent.fromJson(Map<String, Object?> json) {
    final unknownKeys = json.keys.toSet().difference(_knownJsonKeys);
    if (unknownKeys.isNotEmpty) {
      throw FormatException('Unknown caption event fields: ${unknownKeys.join(', ')}');
    }
    final protocolVersion = _readInt(json, 'protocolVersion');
    if (protocolVersion != currentProtocolVersion) {
      throw FormatException('Unsupported caption protocol version: $protocolVersion');
    }

    return CaptionEvent._(
      protocolVersion: protocolVersion,
      type: _parseEventType(json['type']),
      roomId: _readString(json, 'roomId'),
      sessionId: _readString(json, 'sessionId'),
      sequence: _readInt(json, 'sequence'),
      utteranceId: _readOptionalString(json, 'utteranceId'),
      utteranceSequence: _readOptionalInt(json, 'utteranceSequence'),
      revision: _readOptionalInt(json, 'revision'),
      sourceText: _readOptionalString(json, 'sourceText'),
      translatedText: _readOptionalString(json, 'translatedText'),
      isFinal: _readOptionalBool(json, 'isFinal'),
      sourceStartedAt: _readOptionalDateTime(json, 'sourceStartedAt'),
      producedAt: _readDateTime(json, 'producedAt'),
      clearAt: _readOptionalDateTime(json, 'clearAt'),
    );
  }

  factory CaptionEvent.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Caption event must be a JSON object.');
    }
    return CaptionEvent.fromJson(decoded);
  }

  static const currentProtocolVersion = 1;
  static const maximumTextLength = 1000;
  static const maximumDisplayDuration = Duration(minutes: 2);
  static const maximumSourceAge = Duration(minutes: 5);
  static const maximumClockSkew = Duration(seconds: 5);
  static const _knownJsonKeys = <String>{
    'protocolVersion',
    'type',
    'roomId',
    'sessionId',
    'sequence',
    'utteranceId',
    'utteranceSequence',
    'revision',
    'sourceText',
    'translatedText',
    'isFinal',
    'sourceStartedAt',
    'producedAt',
    'clearAt',
  };

  final int protocolVersion;
  final CaptionEventType type;
  final String roomId;
  final String sessionId;
  final int sequence;
  final String? utteranceId;
  final int? utteranceSequence;
  final int? revision;
  final String? sourceText;
  final String? translatedText;
  final bool? isFinal;
  final DateTime? sourceStartedAt;
  final DateTime producedAt;
  final DateTime? clearAt;

  CaptionStreamKey get streamKey => CaptionStreamKey(roomId: roomId, sessionId: sessionId);

  bool isExpiredAt(DateTime now) => clearAt != null && !clearAt!.isAfter(now.toUtc());

  bool isProducedTooFarInFutureAt(DateTime now) => producedAt.isAfter(now.toUtc().add(maximumClockSkew));

  Map<String, Object?> toJson() => <String, Object?>{
    'protocolVersion': protocolVersion,
    'type': type.name,
    'roomId': roomId,
    'sessionId': sessionId,
    'sequence': sequence,
    if (utteranceId != null) 'utteranceId': utteranceId,
    if (utteranceSequence != null) 'utteranceSequence': utteranceSequence,
    if (revision != null) 'revision': revision,
    if (sourceText != null) 'sourceText': sourceText,
    if (translatedText != null) 'translatedText': translatedText,
    if (isFinal != null) 'isFinal': isFinal,
    if (sourceStartedAt != null) 'sourceStartedAt': sourceStartedAt!.toUtc().toIso8601String(),
    'producedAt': producedAt.toUtc().toIso8601String(),
    if (clearAt != null) 'clearAt': clearAt!.toUtc().toIso8601String(),
  };

  String toJsonString() => jsonEncode(toJson());

  void _validate() {
    _validateIdentifier(roomId, 'roomId');
    _validateIdentifier(sessionId, 'sessionId');
    if (sequence < 0) {
      throw const FormatException('sequence must be zero or greater.');
    }
    if (!producedAt.isUtc) {
      throw const FormatException('producedAt must be UTC.');
    }

    switch (type) {
      case CaptionEventType.caption:
        final captionUtteranceId = utteranceId;
        if (captionUtteranceId == null) {
          throw const FormatException('utteranceId is required for caption events.');
        }
        _validateIdentifier(captionUtteranceId, 'utteranceId');
        if (utteranceSequence == null || utteranceSequence! < 0) {
          throw const FormatException(
            'utteranceSequence must be zero or greater for caption events.',
          );
        }
        if (revision == null || revision! < 0) {
          throw const FormatException('revision must be zero or greater for caption events.');
        }
        final text = translatedText?.trim() ?? '';
        if (text.isEmpty) {
          throw const FormatException('translatedText is required for caption events.');
        }
        if (translatedText != text || _containsDisplayControlCharacter(text)) {
          throw const FormatException('translatedText must be one trimmed display paragraph.');
        }
        if (text.length > maximumTextLength || (sourceText?.length ?? 0) > maximumTextLength) {
          throw const FormatException('Caption text exceeds the maximum length.');
        }
        if (isFinal == null) {
          throw const FormatException('isFinal is required for caption events.');
        }
        if (sourceStartedAt == null || !sourceStartedAt!.isUtc) {
          throw const FormatException('sourceStartedAt is required as a UTC instant for caption events.');
        }
        if (sourceStartedAt!.isAfter(producedAt.add(maximumClockSkew))) {
          throw const FormatException('sourceStartedAt is unreasonably later than producedAt.');
        }
        if (producedAt.difference(sourceStartedAt!) > maximumSourceAge) {
          throw const FormatException('sourceStartedAt is unreasonably old.');
        }
        if (clearAt == null || !clearAt!.isUtc || !clearAt!.isAfter(producedAt)) {
          throw const FormatException('clearAt must be a UTC instant after producedAt.');
        }
        if (clearAt!.difference(producedAt) > maximumDisplayDuration) {
          throw const FormatException('A caption cannot remain visible for more than two minutes.');
        }
      case CaptionEventType.clear || CaptionEventType.heartbeat:
        if (utteranceId != null ||
            utteranceSequence != null ||
            revision != null ||
            sourceText != null ||
            translatedText != null ||
            isFinal != null ||
            sourceStartedAt != null ||
            clearAt != null) {
          throw FormatException('${type.name} events cannot contain caption fields.');
        }
    }
  }
}

CaptionEventType _parseEventType(Object? value) => switch (value) {
  'caption' => CaptionEventType.caption,
  'clear' => CaptionEventType.clear,
  'heartbeat' => CaptionEventType.heartbeat,
  _ => throw FormatException('Unsupported caption event type: $value'),
};

bool _containsDisplayControlCharacter(String value) => RegExp(r'[\u0000-\u001F\u007F\u2028\u2029]').hasMatch(value);

void _validateIdentifier(String value, String fieldName) {
  final trimmed = value.trim();
  if (value != trimmed || trimmed.isEmpty || trimmed.length > 128 || !RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(trimmed)) {
    throw FormatException('$fieldName must be a non-empty safe identifier of at most 128 characters.');
  }
}

String _readString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('$key must be a string.');
  }
  return value;
}

String? _readOptionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('$key must be a string when present.');
  }
  return value;
}

int _readInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('$key must be an integer.');
  }
  return value;
}

int? _readOptionalInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! int) {
    throw FormatException('$key must be an integer when present.');
  }
  return value;
}

bool? _readOptionalBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! bool) {
    throw FormatException('$key must be a boolean when present.');
  }
  return value;
}

DateTime _readDateTime(Map<String, Object?> json, String key) {
  final value = _readString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc || !value.endsWith('Z')) {
    throw FormatException('$key must be an ISO-8601 UTC timestamp.');
  }
  return parsed;
}

DateTime? _readOptionalDateTime(Map<String, Object?> json, String key) {
  if (json[key] == null) {
    return null;
  }
  return _readDateTime(json, key);
}
