// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StaffMember {

 String get id; String get name; String get iconUrl; String? get greeting; List<SnsLink> get snsLinks; int get order;@FirestoreDateTimeConverter() DateTime get createdAt;@FirestoreDateTimeConverter() DateTime get updatedAt;
/// Create a copy of StaffMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffMemberCopyWith<StaffMember> get copyWith => _$StaffMemberCopyWithImpl<StaffMember>(this as StaffMember, _$identity);

  /// Serializes this StaffMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffMember&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl)&&(identical(other.greeting, greeting) || other.greeting == greeting)&&const DeepCollectionEquality().equals(other.snsLinks, snsLinks)&&(identical(other.order, order) || other.order == order)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconUrl,greeting,const DeepCollectionEquality().hash(snsLinks),order,createdAt,updatedAt);

@override
String toString() {
  return 'StaffMember(id: $id, name: $name, iconUrl: $iconUrl, greeting: $greeting, snsLinks: $snsLinks, order: $order, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $StaffMemberCopyWith<$Res>  {
  factory $StaffMemberCopyWith(StaffMember value, $Res Function(StaffMember) _then) = _$StaffMemberCopyWithImpl;
@useResult
$Res call({
 String id, String name, String iconUrl, String? greeting, List<SnsLink> snsLinks, int order,@FirestoreDateTimeConverter() DateTime createdAt,@FirestoreDateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class _$StaffMemberCopyWithImpl<$Res>
    implements $StaffMemberCopyWith<$Res> {
  _$StaffMemberCopyWithImpl(this._self, this._then);

  final StaffMember _self;
  final $Res Function(StaffMember) _then;

/// Create a copy of StaffMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? iconUrl = null,Object? greeting = freezed,Object? snsLinks = null,Object? order = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconUrl: null == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String,greeting: freezed == greeting ? _self.greeting : greeting // ignore: cast_nullable_to_non_nullable
as String?,snsLinks: null == snsLinks ? _self.snsLinks : snsLinks // ignore: cast_nullable_to_non_nullable
as List<SnsLink>,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffMember].
extension StaffMemberPatterns on StaffMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffMember value)  $default,){
final _that = this;
switch (_that) {
case _StaffMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffMember value)?  $default,){
final _that = this;
switch (_that) {
case _StaffMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String iconUrl,  String? greeting,  List<SnsLink> snsLinks,  int order, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffMember() when $default != null:
return $default(_that.id,_that.name,_that.iconUrl,_that.greeting,_that.snsLinks,_that.order,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String iconUrl,  String? greeting,  List<SnsLink> snsLinks,  int order, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _StaffMember():
return $default(_that.id,_that.name,_that.iconUrl,_that.greeting,_that.snsLinks,_that.order,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String iconUrl,  String? greeting,  List<SnsLink> snsLinks,  int order, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _StaffMember() when $default != null:
return $default(_that.id,_that.name,_that.iconUrl,_that.greeting,_that.snsLinks,_that.order,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffMember extends StaffMember {
  const _StaffMember({required this.id, required this.name, required this.iconUrl, this.greeting, final  List<SnsLink> snsLinks = const [], required this.order, @FirestoreDateTimeConverter() required this.createdAt, @FirestoreDateTimeConverter() required this.updatedAt}): _snsLinks = snsLinks,super._();
  factory _StaffMember.fromJson(Map<String, dynamic> json) => _$StaffMemberFromJson(json);

@override final  String id;
@override final  String name;
@override final  String iconUrl;
@override final  String? greeting;
 final  List<SnsLink> _snsLinks;
@override@JsonKey() List<SnsLink> get snsLinks {
  if (_snsLinks is EqualUnmodifiableListView) return _snsLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_snsLinks);
}

@override final  int order;
@override@FirestoreDateTimeConverter() final  DateTime createdAt;
@override@FirestoreDateTimeConverter() final  DateTime updatedAt;

/// Create a copy of StaffMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffMemberCopyWith<_StaffMember> get copyWith => __$StaffMemberCopyWithImpl<_StaffMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffMember&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl)&&(identical(other.greeting, greeting) || other.greeting == greeting)&&const DeepCollectionEquality().equals(other._snsLinks, _snsLinks)&&(identical(other.order, order) || other.order == order)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconUrl,greeting,const DeepCollectionEquality().hash(_snsLinks),order,createdAt,updatedAt);

@override
String toString() {
  return 'StaffMember(id: $id, name: $name, iconUrl: $iconUrl, greeting: $greeting, snsLinks: $snsLinks, order: $order, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$StaffMemberCopyWith<$Res> implements $StaffMemberCopyWith<$Res> {
  factory _$StaffMemberCopyWith(_StaffMember value, $Res Function(_StaffMember) _then) = __$StaffMemberCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String iconUrl, String? greeting, List<SnsLink> snsLinks, int order,@FirestoreDateTimeConverter() DateTime createdAt,@FirestoreDateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class __$StaffMemberCopyWithImpl<$Res>
    implements _$StaffMemberCopyWith<$Res> {
  __$StaffMemberCopyWithImpl(this._self, this._then);

  final _StaffMember _self;
  final $Res Function(_StaffMember) _then;

/// Create a copy of StaffMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? iconUrl = null,Object? greeting = freezed,Object? snsLinks = null,Object? order = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_StaffMember(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconUrl: null == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String,greeting: freezed == greeting ? _self.greeting : greeting // ignore: cast_nullable_to_non_nullable
as String?,snsLinks: null == snsLinks ? _self._snsLinks : snsLinks // ignore: cast_nullable_to_non_nullable
as List<SnsLink>,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
