import 'package:freezed_annotation/freezed_annotation.dart';

/// Converts a Firestore timestamp into a [DateTime].
///
/// `cloud_firestore` returns timestamp fields as a `Timestamp` (duck-typed
/// here via its `toDate()` method, rather than a static `cloud_firestore`
/// import — this keeps the `packages/data` model layer importable from
/// plain `dart run` scripts such as `tool/generate_news.dart`, which cannot
/// compile Flutter-framework code). Payloads that bypass the SDK (seed JSON,
/// REST fetches, tests) may instead carry a [DateTime] or an ISO-8601
/// string, so this converter accepts all three shapes.
///
/// [toJson] returns the [DateTime] as-is rather than constructing a
/// `Timestamp`: `cloud_firestore`'s write path already accepts a [DateTime]
/// in place of a `Timestamp` and converts it internally, so no import is
/// needed on this side either.
class FirestoreDateTimeConverter implements JsonConverter<DateTime, Object?> {
  const FirestoreDateTimeConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json is DateTime) return json;
    if (json is String && json.isNotEmpty) return DateTime.parse(json);
    if (json != null) {
      try {
        final dynamic maybeTimestamp = json;
        final converted = maybeTimestamp.toDate();
        if (converted is DateTime) return converted;
      } catch (_) {
        // Not a Firestore Timestamp (or similar) — fall through to the error below.
      }
    }
    throw FormatException('Expected a Firestore timestamp, but got: $json');
  }

  @override
  Object? toJson(DateTime object) => object;
}

/// Nullable counterpart of [FirestoreDateTimeConverter].
class FirestoreNullableDateTimeConverter implements JsonConverter<DateTime?, Object?> {
  const FirestoreNullableDateTimeConverter();

  @override
  DateTime? fromJson(Object? json) => json == null ? null : const FirestoreDateTimeConverter().fromJson(json);

  @override
  Object? toJson(DateTime? object) => object;
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
  Uri? fromJson(Object? json) => json == null ? null : const FirestoreUriConverter().fromJson(json);

  @override
  Object? toJson(Uri? object) => object?.toString();
}
