import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Converts a Firestore timestamp into a [DateTime].
///
/// `cloud_firestore` returns timestamp fields as [Timestamp]. Payloads that
/// bypass the SDK (seed JSON, tests) may instead carry an [DateTime] or an
/// ISO-8601 string, so this converter accepts all three shapes.
class FirestoreDateTimeConverter implements JsonConverter<DateTime, Object?> {
  const FirestoreDateTimeConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json is Timestamp) return json.toDate();
    if (json is DateTime) return json;
    if (json is String && json.isNotEmpty) return DateTime.parse(json);
    throw FormatException('Expected a Firestore timestamp, but got: $json');
  }

  @override
  Object? toJson(DateTime object) => Timestamp.fromDate(object);
}

/// Nullable counterpart of [FirestoreDateTimeConverter].
class FirestoreNullableDateTimeConverter implements JsonConverter<DateTime?, Object?> {
  const FirestoreNullableDateTimeConverter();

  @override
  DateTime? fromJson(Object? json) => json == null ? null : const FirestoreDateTimeConverter().fromJson(json);

  @override
  Object? toJson(DateTime? object) => object == null ? null : Timestamp.fromDate(object);
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
