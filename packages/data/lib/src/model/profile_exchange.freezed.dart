// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_exchange.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileExchange {

/// The other attendee's uid, which is also the document id.
 String get id;@FirestoreDateTimeConverter() DateTime get createdAt; ProfileExchangeOrigin get origin;/// Present only until the `onDocumentCreated` trigger verifies a `scan`
/// write and clears it, so a validated token is never kept around.
 String? get token;/// Free-form note visible only to the owner of this subcollection.
 String? get note;
/// Create a copy of ProfileExchange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileExchangeCopyWith<ProfileExchange> get copyWith => _$ProfileExchangeCopyWithImpl<ProfileExchange>(this as ProfileExchange, _$identity);

  /// Serializes this ProfileExchange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileExchange&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.token, token) || other.token == token)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,origin,token,note);

@override
String toString() {
  return 'ProfileExchange(id: $id, createdAt: $createdAt, origin: $origin, token: $token, note: $note)';
}


}

/// @nodoc
abstract mixin class $ProfileExchangeCopyWith<$Res>  {
  factory $ProfileExchangeCopyWith(ProfileExchange value, $Res Function(ProfileExchange) _then) = _$ProfileExchangeCopyWithImpl;
@useResult
$Res call({
 String id,@FirestoreDateTimeConverter() DateTime createdAt, ProfileExchangeOrigin origin, String? token, String? note
});




}
/// @nodoc
class _$ProfileExchangeCopyWithImpl<$Res>
    implements $ProfileExchangeCopyWith<$Res> {
  _$ProfileExchangeCopyWithImpl(this._self, this._then);

  final ProfileExchange _self;
  final $Res Function(ProfileExchange) _then;

/// Create a copy of ProfileExchange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,Object? origin = null,Object? token = freezed,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as ProfileExchangeOrigin,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileExchange].
extension ProfileExchangePatterns on ProfileExchange {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileExchange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileExchange() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileExchange value)  $default,){
final _that = this;
switch (_that) {
case _ProfileExchange():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileExchange value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileExchange() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @FirestoreDateTimeConverter()  DateTime createdAt,  ProfileExchangeOrigin origin,  String? token,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileExchange() when $default != null:
return $default(_that.id,_that.createdAt,_that.origin,_that.token,_that.note);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @FirestoreDateTimeConverter()  DateTime createdAt,  ProfileExchangeOrigin origin,  String? token,  String? note)  $default,) {final _that = this;
switch (_that) {
case _ProfileExchange():
return $default(_that.id,_that.createdAt,_that.origin,_that.token,_that.note);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @FirestoreDateTimeConverter()  DateTime createdAt,  ProfileExchangeOrigin origin,  String? token,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _ProfileExchange() when $default != null:
return $default(_that.id,_that.createdAt,_that.origin,_that.token,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileExchange extends ProfileExchange {
  const _ProfileExchange({required this.id, @FirestoreDateTimeConverter() required this.createdAt, required this.origin, this.token, this.note}): super._();
  factory _ProfileExchange.fromJson(Map<String, dynamic> json) => _$ProfileExchangeFromJson(json);

/// The other attendee's uid, which is also the document id.
@override final  String id;
@override@FirestoreDateTimeConverter() final  DateTime createdAt;
@override final  ProfileExchangeOrigin origin;
/// Present only until the `onDocumentCreated` trigger verifies a `scan`
/// write and clears it, so a validated token is never kept around.
@override final  String? token;
/// Free-form note visible only to the owner of this subcollection.
@override final  String? note;

/// Create a copy of ProfileExchange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileExchangeCopyWith<_ProfileExchange> get copyWith => __$ProfileExchangeCopyWithImpl<_ProfileExchange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileExchangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileExchange&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.token, token) || other.token == token)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,origin,token,note);

@override
String toString() {
  return 'ProfileExchange(id: $id, createdAt: $createdAt, origin: $origin, token: $token, note: $note)';
}


}

/// @nodoc
abstract mixin class _$ProfileExchangeCopyWith<$Res> implements $ProfileExchangeCopyWith<$Res> {
  factory _$ProfileExchangeCopyWith(_ProfileExchange value, $Res Function(_ProfileExchange) _then) = __$ProfileExchangeCopyWithImpl;
@override @useResult
$Res call({
 String id,@FirestoreDateTimeConverter() DateTime createdAt, ProfileExchangeOrigin origin, String? token, String? note
});




}
/// @nodoc
class __$ProfileExchangeCopyWithImpl<$Res>
    implements _$ProfileExchangeCopyWith<$Res> {
  __$ProfileExchangeCopyWithImpl(this._self, this._then);

  final _ProfileExchange _self;
  final $Res Function(_ProfileExchange) _then;

/// Create a copy of ProfileExchange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = null,Object? origin = null,Object? token = freezed,Object? note = freezed,}) {
  return _then(_ProfileExchange(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as ProfileExchangeOrigin,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
