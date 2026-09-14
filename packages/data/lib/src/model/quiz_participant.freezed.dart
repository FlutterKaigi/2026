// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_participant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuizParticipant {

 String get id; String get displayName;@FirestoreDateTimeConverter() DateTime get registeredAt; String? get teamId;
/// Create a copy of QuizParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizParticipantCopyWith<QuizParticipant> get copyWith => _$QuizParticipantCopyWithImpl<QuizParticipant>(this as QuizParticipant, _$identity);

  /// Serializes this QuizParticipant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.teamId, teamId) || other.teamId == teamId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,registeredAt,teamId);

@override
String toString() {
  return 'QuizParticipant(id: $id, displayName: $displayName, registeredAt: $registeredAt, teamId: $teamId)';
}


}

/// @nodoc
abstract mixin class $QuizParticipantCopyWith<$Res>  {
  factory $QuizParticipantCopyWith(QuizParticipant value, $Res Function(QuizParticipant) _then) = _$QuizParticipantCopyWithImpl;
@useResult
$Res call({
 String id, String displayName,@FirestoreDateTimeConverter() DateTime registeredAt, String? teamId
});




}
/// @nodoc
class _$QuizParticipantCopyWithImpl<$Res>
    implements $QuizParticipantCopyWith<$Res> {
  _$QuizParticipantCopyWithImpl(this._self, this._then);

  final QuizParticipant _self;
  final $Res Function(QuizParticipant) _then;

/// Create a copy of QuizParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? registeredAt = null,Object? teamId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,registeredAt: null == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as DateTime,teamId: freezed == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizParticipant].
extension QuizParticipantPatterns on QuizParticipant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizParticipant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizParticipant value)  $default,){
final _that = this;
switch (_that) {
case _QuizParticipant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _QuizParticipant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName, @FirestoreDateTimeConverter()  DateTime registeredAt,  String? teamId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizParticipant() when $default != null:
return $default(_that.id,_that.displayName,_that.registeredAt,_that.teamId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName, @FirestoreDateTimeConverter()  DateTime registeredAt,  String? teamId)  $default,) {final _that = this;
switch (_that) {
case _QuizParticipant():
return $default(_that.id,_that.displayName,_that.registeredAt,_that.teamId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName, @FirestoreDateTimeConverter()  DateTime registeredAt,  String? teamId)?  $default,) {final _that = this;
switch (_that) {
case _QuizParticipant() when $default != null:
return $default(_that.id,_that.displayName,_that.registeredAt,_that.teamId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizParticipant extends QuizParticipant {
  const _QuizParticipant({required this.id, required this.displayName, @FirestoreDateTimeConverter() required this.registeredAt, this.teamId}): super._();
  factory _QuizParticipant.fromJson(Map<String, dynamic> json) => _$QuizParticipantFromJson(json);

@override final  String id;
@override final  String displayName;
@override@FirestoreDateTimeConverter() final  DateTime registeredAt;
@override final  String? teamId;

/// Create a copy of QuizParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizParticipantCopyWith<_QuizParticipant> get copyWith => __$QuizParticipantCopyWithImpl<_QuizParticipant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizParticipantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.teamId, teamId) || other.teamId == teamId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,registeredAt,teamId);

@override
String toString() {
  return 'QuizParticipant(id: $id, displayName: $displayName, registeredAt: $registeredAt, teamId: $teamId)';
}


}

/// @nodoc
abstract mixin class _$QuizParticipantCopyWith<$Res> implements $QuizParticipantCopyWith<$Res> {
  factory _$QuizParticipantCopyWith(_QuizParticipant value, $Res Function(_QuizParticipant) _then) = __$QuizParticipantCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName,@FirestoreDateTimeConverter() DateTime registeredAt, String? teamId
});




}
/// @nodoc
class __$QuizParticipantCopyWithImpl<$Res>
    implements _$QuizParticipantCopyWith<$Res> {
  __$QuizParticipantCopyWithImpl(this._self, this._then);

  final _QuizParticipant _self;
  final $Res Function(_QuizParticipant) _then;

/// Create a copy of QuizParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? registeredAt = null,Object? teamId = freezed,}) {
  return _then(_QuizParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,registeredAt: null == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as DateTime,teamId: freezed == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
