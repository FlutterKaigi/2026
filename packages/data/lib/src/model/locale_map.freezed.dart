// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'locale_map.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocaleMap {

 String get ja; String get en;
/// Create a copy of LocaleMap
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<LocaleMap> get copyWith => _$LocaleMapCopyWithImpl<LocaleMap>(this as LocaleMap, _$identity);

  /// Serializes this LocaleMap to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocaleMap&&(identical(other.ja, ja) || other.ja == ja)&&(identical(other.en, en) || other.en == en));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ja,en);

@override
String toString() {
  return 'LocaleMap(ja: $ja, en: $en)';
}


}

/// @nodoc
abstract mixin class $LocaleMapCopyWith<$Res>  {
  factory $LocaleMapCopyWith(LocaleMap value, $Res Function(LocaleMap) _then) = _$LocaleMapCopyWithImpl;
@useResult
$Res call({
 String ja, String en
});




}
/// @nodoc
class _$LocaleMapCopyWithImpl<$Res>
    implements $LocaleMapCopyWith<$Res> {
  _$LocaleMapCopyWithImpl(this._self, this._then);

  final LocaleMap _self;
  final $Res Function(LocaleMap) _then;

/// Create a copy of LocaleMap
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ja = null,Object? en = null,}) {
  return _then(_self.copyWith(
ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LocaleMap].
extension LocaleMapPatterns on LocaleMap {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocaleMap value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocaleMap() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocaleMap value)  $default,){
final _that = this;
switch (_that) {
case _LocaleMap():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocaleMap value)?  $default,){
final _that = this;
switch (_that) {
case _LocaleMap() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ja,  String en)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocaleMap() when $default != null:
return $default(_that.ja,_that.en);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ja,  String en)  $default,) {final _that = this;
switch (_that) {
case _LocaleMap():
return $default(_that.ja,_that.en);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ja,  String en)?  $default,) {final _that = this;
switch (_that) {
case _LocaleMap() when $default != null:
return $default(_that.ja,_that.en);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocaleMap implements LocaleMap {
  const _LocaleMap({required this.ja, required this.en});
  factory _LocaleMap.fromJson(Map<String, dynamic> json) => _$LocaleMapFromJson(json);

@override final  String ja;
@override final  String en;

/// Create a copy of LocaleMap
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocaleMapCopyWith<_LocaleMap> get copyWith => __$LocaleMapCopyWithImpl<_LocaleMap>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocaleMapToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocaleMap&&(identical(other.ja, ja) || other.ja == ja)&&(identical(other.en, en) || other.en == en));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ja,en);

@override
String toString() {
  return 'LocaleMap(ja: $ja, en: $en)';
}


}

/// @nodoc
abstract mixin class _$LocaleMapCopyWith<$Res> implements $LocaleMapCopyWith<$Res> {
  factory _$LocaleMapCopyWith(_LocaleMap value, $Res Function(_LocaleMap) _then) = __$LocaleMapCopyWithImpl;
@override @useResult
$Res call({
 String ja, String en
});




}
/// @nodoc
class __$LocaleMapCopyWithImpl<$Res>
    implements _$LocaleMapCopyWith<$Res> {
  __$LocaleMapCopyWithImpl(this._self, this._then);

  final _LocaleMap _self;
  final $Res Function(_LocaleMap) _then;

/// Create a copy of LocaleMap
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ja = null,Object? en = null,}) {
  return _then(_LocaleMap(
ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
