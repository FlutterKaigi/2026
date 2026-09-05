// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exchange_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExchangeToken {

 String get value; DateTime get expiresAt;
/// Create a copy of ExchangeToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExchangeTokenCopyWith<ExchangeToken> get copyWith => _$ExchangeTokenCopyWithImpl<ExchangeToken>(this as ExchangeToken, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExchangeToken&&(identical(other.value, value) || other.value == value)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,value,expiresAt);

@override
String toString() {
  return 'ExchangeToken(value: $value, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $ExchangeTokenCopyWith<$Res>  {
  factory $ExchangeTokenCopyWith(ExchangeToken value, $Res Function(ExchangeToken) _then) = _$ExchangeTokenCopyWithImpl;
@useResult
$Res call({
 String value, DateTime expiresAt
});




}
/// @nodoc
class _$ExchangeTokenCopyWithImpl<$Res>
    implements $ExchangeTokenCopyWith<$Res> {
  _$ExchangeTokenCopyWithImpl(this._self, this._then);

  final ExchangeToken _self;
  final $Res Function(ExchangeToken) _then;

/// Create a copy of ExchangeToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ExchangeToken].
extension ExchangeTokenPatterns on ExchangeToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExchangeToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExchangeToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExchangeToken value)  $default,){
final _that = this;
switch (_that) {
case _ExchangeToken():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExchangeToken value)?  $default,){
final _that = this;
switch (_that) {
case _ExchangeToken() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExchangeToken() when $default != null:
return $default(_that.value,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _ExchangeToken():
return $default(_that.value,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ExchangeToken() when $default != null:
return $default(_that.value,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _ExchangeToken extends ExchangeToken {
  const _ExchangeToken({required this.value, required this.expiresAt}): super._();
  

@override final  String value;
@override final  DateTime expiresAt;

/// Create a copy of ExchangeToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExchangeTokenCopyWith<_ExchangeToken> get copyWith => __$ExchangeTokenCopyWithImpl<_ExchangeToken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExchangeToken&&(identical(other.value, value) || other.value == value)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,value,expiresAt);

@override
String toString() {
  return 'ExchangeToken(value: $value, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ExchangeTokenCopyWith<$Res> implements $ExchangeTokenCopyWith<$Res> {
  factory _$ExchangeTokenCopyWith(_ExchangeToken value, $Res Function(_ExchangeToken) _then) = __$ExchangeTokenCopyWithImpl;
@override @useResult
$Res call({
 String value, DateTime expiresAt
});




}
/// @nodoc
class __$ExchangeTokenCopyWithImpl<$Res>
    implements _$ExchangeTokenCopyWith<$Res> {
  __$ExchangeTokenCopyWithImpl(this._self, this._then);

  final _ExchangeToken _self;
  final $Res Function(_ExchangeToken) _then;

/// Create a copy of ExchangeToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? expiresAt = null,}) {
  return _then(_ExchangeToken(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
