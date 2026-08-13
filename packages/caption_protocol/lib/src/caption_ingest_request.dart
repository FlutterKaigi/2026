final class CaptionIngestRequest {
  CaptionIngestRequest({
    required this.roomId,
    required this.sessionId,
    required this.utteranceId,
    required this.utteranceSequence,
    required this.revision,
    required this.translatedText,
    required this.isFinal,
    required this.sourceStartedAt,
    required this.clearAfter,
    this.sourceText,
  }) {
    _validateIdentifier(roomId, 'roomId');
    _validateIdentifier(sessionId, 'sessionId');
    _validateIdentifier(utteranceId, 'utteranceId');
    if (utteranceSequence < 0) {
      throw const FormatException('utteranceSequence must be zero or greater.');
    }
    if (revision < 0) {
      throw const FormatException('revision must be zero or greater.');
    }
    if (!sourceStartedAt.isUtc) {
      throw const FormatException('sourceStartedAt must be UTC.');
    }
    if (translatedText.trim().isEmpty) {
      throw const FormatException('translatedText is required.');
    }
    if (translatedText != translatedText.trim() || _containsDisplayControlCharacter(translatedText)) {
      throw const FormatException('translatedText must be one trimmed display paragraph.');
    }
    if (translatedText.length > 1000 || (sourceText?.length ?? 0) > 1000) {
      throw const FormatException('Caption text exceeds the maximum length.');
    }
    if (clearAfter < const Duration(seconds: 1) || clearAfter > const Duration(minutes: 2)) {
      throw const FormatException('clearAfterMs must be between 1000 and 120000.');
    }
  }

  factory CaptionIngestRequest.fromJson(Map<String, Object?> json) {
    _rejectUnknownFields(json, _captionFields, 'caption ingest');
    return CaptionIngestRequest(
      roomId: _requiredString(json, 'roomId'),
      sessionId: _requiredString(json, 'sessionId'),
      utteranceId: _requiredString(json, 'utteranceId'),
      utteranceSequence: _requiredInt(json, 'utteranceSequence'),
      revision: _requiredInt(json, 'revision'),
      sourceText: _optionalString(json, 'sourceText'),
      translatedText: _requiredString(json, 'translatedText'),
      isFinal: _optionalBool(json, 'isFinal') ?? true,
      sourceStartedAt: _requiredDateTime(json, 'sourceStartedAt'),
      clearAfter: Duration(milliseconds: _optionalInt(json, 'clearAfterMs') ?? 8000),
    );
  }

  final String roomId;
  final String sessionId;
  final String utteranceId;
  final int utteranceSequence;
  final int revision;
  final String? sourceText;
  final String translatedText;
  final bool isFinal;
  final DateTime sourceStartedAt;
  final Duration clearAfter;
}

final class CaptionClearRequest {
  CaptionClearRequest({required this.roomId, required this.sessionId}) {
    _validateIdentifier(roomId, 'roomId');
    _validateIdentifier(sessionId, 'sessionId');
  }

  factory CaptionClearRequest.fromJson(Map<String, Object?> json) {
    _rejectUnknownFields(json, _clearFields, 'caption clear');
    return CaptionClearRequest(
      roomId: _requiredString(json, 'roomId'),
      sessionId: _requiredString(json, 'sessionId'),
    );
  }

  final String roomId;
  final String sessionId;
}

const _captionFields = <String>{
  'roomId',
  'sessionId',
  'utteranceId',
  'utteranceSequence',
  'revision',
  'sourceText',
  'translatedText',
  'isFinal',
  'sourceStartedAt',
  'clearAfterMs',
};
const _clearFields = <String>{'roomId', 'sessionId'};

bool _containsDisplayControlCharacter(String value) => RegExp(r'[\u0000-\u001F\u007F\u2028\u2029]').hasMatch(value);

void _rejectUnknownFields(Map<String, Object?> json, Set<String> knownFields, String payloadName) {
  final unknownFields = json.keys.toSet().difference(knownFields);
  if (unknownFields.isNotEmpty) {
    throw FormatException('Unknown $payloadName fields: ${unknownFields.join(', ')}');
  }
}

void _validateIdentifier(String value, String fieldName) {
  final trimmed = value.trim();
  if (value != trimmed || trimmed.isEmpty || trimmed.length > 128 || !RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(trimmed)) {
    throw FormatException('$fieldName must be a non-empty safe identifier of at most 128 characters.');
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('$key must be a string.');
  }
  return value;
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('$key must be a string when present.');
  }
  return value;
}

bool? _optionalBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! bool) {
    throw FormatException('$key must be a boolean when present.');
  }
  return value;
}

int? _optionalInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! int) {
    throw FormatException('$key must be an integer when present.');
  }
  return value;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('$key must be an integer.');
  }
  return value;
}

DateTime _requiredDateTime(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc || !value.endsWith('Z')) {
    throw FormatException('$key must be an ISO-8601 UTC timestamp.');
  }
  return parsed;
}
