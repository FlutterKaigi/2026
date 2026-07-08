// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_question_secret.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuizQuestionSecret {

 int get correctOptionIndex; String get explanation;
/// Create a copy of QuizQuestionSecret
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizQuestionSecretCopyWith<QuizQuestionSecret> get copyWith => _$QuizQuestionSecretCopyWithImpl<QuizQuestionSecret>(this as QuizQuestionSecret, _$identity);

  /// Serializes this QuizQuestionSecret to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizQuestionSecret&&(identical(other.correctOptionIndex, correctOptionIndex) || other.correctOptionIndex == correctOptionIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,correctOptionIndex,explanation);

@override
String toString() {
  return 'QuizQuestionSecret(correctOptionIndex: $correctOptionIndex, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class $QuizQuestionSecretCopyWith<$Res>  {
  factory $QuizQuestionSecretCopyWith(QuizQuestionSecret value, $Res Function(QuizQuestionSecret) _then) = _$QuizQuestionSecretCopyWithImpl;
@useResult
$Res call({
 int correctOptionIndex, String explanation
});




}
/// @nodoc
class _$QuizQuestionSecretCopyWithImpl<$Res>
    implements $QuizQuestionSecretCopyWith<$Res> {
  _$QuizQuestionSecretCopyWithImpl(this._self, this._then);

  final QuizQuestionSecret _self;
  final $Res Function(QuizQuestionSecret) _then;

/// Create a copy of QuizQuestionSecret
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? correctOptionIndex = null,Object? explanation = null,}) {
  return _then(_self.copyWith(
correctOptionIndex: null == correctOptionIndex ? _self.correctOptionIndex : correctOptionIndex // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizQuestionSecret].
extension QuizQuestionSecretPatterns on QuizQuestionSecret {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizQuestionSecret value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizQuestionSecret() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizQuestionSecret value)  $default,){
final _that = this;
switch (_that) {
case _QuizQuestionSecret():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizQuestionSecret value)?  $default,){
final _that = this;
switch (_that) {
case _QuizQuestionSecret() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int correctOptionIndex,  String explanation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizQuestionSecret() when $default != null:
return $default(_that.correctOptionIndex,_that.explanation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int correctOptionIndex,  String explanation)  $default,) {final _that = this;
switch (_that) {
case _QuizQuestionSecret():
return $default(_that.correctOptionIndex,_that.explanation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int correctOptionIndex,  String explanation)?  $default,) {final _that = this;
switch (_that) {
case _QuizQuestionSecret() when $default != null:
return $default(_that.correctOptionIndex,_that.explanation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizQuestionSecret extends QuizQuestionSecret {
  const _QuizQuestionSecret({required this.correctOptionIndex, required this.explanation}): super._();
  factory _QuizQuestionSecret.fromJson(Map<String, dynamic> json) => _$QuizQuestionSecretFromJson(json);

@override final  int correctOptionIndex;
@override final  String explanation;

/// Create a copy of QuizQuestionSecret
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizQuestionSecretCopyWith<_QuizQuestionSecret> get copyWith => __$QuizQuestionSecretCopyWithImpl<_QuizQuestionSecret>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizQuestionSecretToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizQuestionSecret&&(identical(other.correctOptionIndex, correctOptionIndex) || other.correctOptionIndex == correctOptionIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,correctOptionIndex,explanation);

@override
String toString() {
  return 'QuizQuestionSecret(correctOptionIndex: $correctOptionIndex, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class _$QuizQuestionSecretCopyWith<$Res> implements $QuizQuestionSecretCopyWith<$Res> {
  factory _$QuizQuestionSecretCopyWith(_QuizQuestionSecret value, $Res Function(_QuizQuestionSecret) _then) = __$QuizQuestionSecretCopyWithImpl;
@override @useResult
$Res call({
 int correctOptionIndex, String explanation
});




}
/// @nodoc
class __$QuizQuestionSecretCopyWithImpl<$Res>
    implements _$QuizQuestionSecretCopyWith<$Res> {
  __$QuizQuestionSecretCopyWithImpl(this._self, this._then);

  final _QuizQuestionSecret _self;
  final $Res Function(_QuizQuestionSecret) _then;

/// Create a copy of QuizQuestionSecret
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? correctOptionIndex = null,Object? explanation = null,}) {
  return _then(_QuizQuestionSecret(
correctOptionIndex: null == correctOptionIndex ? _self.correctOptionIndex : correctOptionIndex // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
