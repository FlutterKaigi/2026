// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exchange_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExchangeCode {

 String get value; DateTime get expiresAt;
/// Create a copy of ExchangeCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExchangeCodeCopyWith<ExchangeCode> get copyWith => _$ExchangeCodeCopyWithImpl<ExchangeCode>(this as ExchangeCode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExchangeCode&&(identical(other.value, value) || other.value == value)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,value,expiresAt);

@override
String toString() {
  return 'ExchangeCode(value: $value, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $ExchangeCodeCopyWith<$Res>  {
  factory $ExchangeCodeCopyWith(ExchangeCode value, $Res Function(ExchangeCode) _then) = _$ExchangeCodeCopyWithImpl;
@useResult
$Res call({
 String value, DateTime expiresAt
});




}
/// @nodoc
class _$ExchangeCodeCopyWithImpl<$Res>
    implements $ExchangeCodeCopyWith<$Res> {
  _$ExchangeCodeCopyWithImpl(this._self, this._then);

  final ExchangeCode _self;
  final $Res Function(ExchangeCode) _then;

/// Create a copy of ExchangeCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ExchangeCode].
extension ExchangeCodePatterns on ExchangeCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExchangeCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExchangeCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExchangeCode value)  $default,){
final _that = this;
switch (_that) {
case _ExchangeCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExchangeCode value)?  $default,){
final _that = this;
switch (_that) {
case _ExchangeCode() when $default != null:
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
case _ExchangeCode() when $default != null:
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
case _ExchangeCode():
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
case _ExchangeCode() when $default != null:
return $default(_that.value,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _ExchangeCode extends ExchangeCode {
  const _ExchangeCode({required this.value, required this.expiresAt}): super._();
  

@override final  String value;
@override final  DateTime expiresAt;

/// Create a copy of ExchangeCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExchangeCodeCopyWith<_ExchangeCode> get copyWith => __$ExchangeCodeCopyWithImpl<_ExchangeCode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExchangeCode&&(identical(other.value, value) || other.value == value)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,value,expiresAt);

@override
String toString() {
  return 'ExchangeCode(value: $value, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ExchangeCodeCopyWith<$Res> implements $ExchangeCodeCopyWith<$Res> {
  factory _$ExchangeCodeCopyWith(_ExchangeCode value, $Res Function(_ExchangeCode) _then) = __$ExchangeCodeCopyWithImpl;
@override @useResult
$Res call({
 String value, DateTime expiresAt
});




}
/// @nodoc
class __$ExchangeCodeCopyWithImpl<$Res>
    implements _$ExchangeCodeCopyWith<$Res> {
  __$ExchangeCodeCopyWithImpl(this._self, this._then);

  final _ExchangeCode _self;
  final $Res Function(_ExchangeCode) _then;

/// Create a copy of ExchangeCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? expiresAt = null,}) {
  return _then(_ExchangeCode(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
