import 'package:freezed_annotation/freezed_annotation.dart';

/// Converts a Firestore timestamp into a [DateTime].
///
/// `FirebaseDataClient` already decodes `timestampValue` into a [DateTime],
/// but payloads that bypass the client (seed JSON, raw REST responses) may
/// still carry ISO-8601 strings. This converter accepts both shapes so the
/// same model can be built from either source.
class FirestoreDateTimeConverter implements JsonConverter<DateTime, Object?> {
  const FirestoreDateTimeConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json is DateTime) return json;
    if (json is String && json.isNotEmpty) return DateTime.parse(json);
    throw FormatException('Expected a Firestore timestamp, but got: $json');
  }

  @override
  Object? toJson(DateTime object) => object.toIso8601String();
}

/// Nullable counterpart of [FirestoreDateTimeConverter].
class FirestoreNullableDateTimeConverter
    implements JsonConverter<DateTime?, Object?> {
  const FirestoreNullableDateTimeConverter();

  @override
  DateTime? fromJson(Object? json) =>
      json == null ? null : const FirestoreDateTimeConverter().fromJson(json);

  @override
  Object? toJson(DateTime? object) => object?.toIso8601String();
}

/// Converts a Firestore string field into a [Uri].
///
/// Accepts an already-parsed [Uri] as well as a non-empty string, mirroring
/// [FirestoreDateTimeConverter]'s tolerance for both decoded and raw values.
class FirestoreUriConverter implements JsonConverter<Uri, Object?> {
  const FirestoreUriConverter();

  @override
  Uri fromJson(Object? json) {
    if (json is Uri) return json;
    if (json is String && json.isNotEmpty) return Uri.parse(json);
    throw FormatException('Expected a URI string, but got: $json');
  }

  @override
  Object? toJson(Uri object) => object.toString();
}

/// Nullable counterpart of [FirestoreUriConverter].
class FirestoreNullableUriConverter implements JsonConverter<Uri?, Object?> {
  const FirestoreNullableUriConverter();

  @override
  Uri? fromJson(Object? json) =>
      json == null ? null : const FirestoreUriConverter().fromJson(json);

  @override
  Object? toJson(Uri? object) => object?.toString();
}
