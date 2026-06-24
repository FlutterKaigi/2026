// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sponsor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Sponsor {

 String get id; LocaleMap get name; String? get nameKana; LocaleMap get description; String get logoUrl; SponsorTier get tier; String? get xUrl; String? get websiteUrl; String? get recruitUrl; String? get jobBoardUrl;@FirestoreDateTimeConverter() DateTime get createdAt;@FirestoreDateTimeConverter() DateTime get updatedAt;
/// Create a copy of Sponsor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SponsorCopyWith<Sponsor> get copyWith => _$SponsorCopyWithImpl<Sponsor>(this as Sponsor, _$identity);

  /// Serializes this Sponsor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Sponsor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameKana, nameKana) || other.nameKana == nameKana)&&(identical(other.description, description) || other.description == description)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.xUrl, xUrl) || other.xUrl == xUrl)&&(identical(other.websiteUrl, websiteUrl) || other.websiteUrl == websiteUrl)&&(identical(other.recruitUrl, recruitUrl) || other.recruitUrl == recruitUrl)&&(identical(other.jobBoardUrl, jobBoardUrl) || other.jobBoardUrl == jobBoardUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nameKana,description,logoUrl,tier,xUrl,websiteUrl,recruitUrl,jobBoardUrl,createdAt,updatedAt);

@override
String toString() {
  return 'Sponsor(id: $id, name: $name, nameKana: $nameKana, description: $description, logoUrl: $logoUrl, tier: $tier, xUrl: $xUrl, websiteUrl: $websiteUrl, recruitUrl: $recruitUrl, jobBoardUrl: $jobBoardUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SponsorCopyWith<$Res>  {
  factory $SponsorCopyWith(Sponsor value, $Res Function(Sponsor) _then) = _$SponsorCopyWithImpl;
@useResult
$Res call({
 String id, LocaleMap name, String? nameKana, LocaleMap description, String logoUrl, SponsorTier tier, String? xUrl, String? websiteUrl, String? recruitUrl, String? jobBoardUrl,@FirestoreDateTimeConverter() DateTime createdAt,@FirestoreDateTimeConverter() DateTime updatedAt
});


$LocaleMapCopyWith<$Res> get name;$LocaleMapCopyWith<$Res> get description;

}
/// @nodoc
class _$SponsorCopyWithImpl<$Res>
    implements $SponsorCopyWith<$Res> {
  _$SponsorCopyWithImpl(this._self, this._then);

  final Sponsor _self;
  final $Res Function(Sponsor) _then;

/// Create a copy of Sponsor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nameKana = freezed,Object? description = null,Object? logoUrl = null,Object? tier = null,Object? xUrl = freezed,Object? websiteUrl = freezed,Object? recruitUrl = freezed,Object? jobBoardUrl = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as LocaleMap,nameKana: freezed == nameKana ? _self.nameKana : nameKana // ignore: cast_nullable_to_non_nullable
as String?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as LocaleMap,logoUrl: null == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as SponsorTier,xUrl: freezed == xUrl ? _self.xUrl : xUrl // ignore: cast_nullable_to_non_nullable
as String?,websiteUrl: freezed == websiteUrl ? _self.websiteUrl : websiteUrl // ignore: cast_nullable_to_non_nullable
as String?,recruitUrl: freezed == recruitUrl ? _self.recruitUrl : recruitUrl // ignore: cast_nullable_to_non_nullable
as String?,jobBoardUrl: freezed == jobBoardUrl ? _self.jobBoardUrl : jobBoardUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Sponsor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res> get name {
  
  return $LocaleMapCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of Sponsor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res> get description {
  
  return $LocaleMapCopyWith<$Res>(_self.description, (value) {
    return _then(_self.copyWith(description: value));
  });
}
}


/// Adds pattern-matching-related methods to [Sponsor].
extension SponsorPatterns on Sponsor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Sponsor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Sponsor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Sponsor value)  $default,){
final _that = this;
switch (_that) {
case _Sponsor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Sponsor value)?  $default,){
final _that = this;
switch (_that) {
case _Sponsor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  LocaleMap name,  String? nameKana,  LocaleMap description,  String logoUrl,  SponsorTier tier,  String? xUrl,  String? websiteUrl,  String? recruitUrl,  String? jobBoardUrl, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Sponsor() when $default != null:
return $default(_that.id,_that.name,_that.nameKana,_that.description,_that.logoUrl,_that.tier,_that.xUrl,_that.websiteUrl,_that.recruitUrl,_that.jobBoardUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  LocaleMap name,  String? nameKana,  LocaleMap description,  String logoUrl,  SponsorTier tier,  String? xUrl,  String? websiteUrl,  String? recruitUrl,  String? jobBoardUrl, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Sponsor():
return $default(_that.id,_that.name,_that.nameKana,_that.description,_that.logoUrl,_that.tier,_that.xUrl,_that.websiteUrl,_that.recruitUrl,_that.jobBoardUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  LocaleMap name,  String? nameKana,  LocaleMap description,  String logoUrl,  SponsorTier tier,  String? xUrl,  String? websiteUrl,  String? recruitUrl,  String? jobBoardUrl, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Sponsor() when $default != null:
return $default(_that.id,_that.name,_that.nameKana,_that.description,_that.logoUrl,_that.tier,_that.xUrl,_that.websiteUrl,_that.recruitUrl,_that.jobBoardUrl,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Sponsor extends Sponsor {
  const _Sponsor({required this.id, required this.name, this.nameKana, required this.description, required this.logoUrl, required this.tier, this.xUrl, this.websiteUrl, this.recruitUrl, this.jobBoardUrl, @FirestoreDateTimeConverter() required this.createdAt, @FirestoreDateTimeConverter() required this.updatedAt}): super._();
  factory _Sponsor.fromJson(Map<String, dynamic> json) => _$SponsorFromJson(json);

@override final  String id;
@override final  LocaleMap name;
@override final  String? nameKana;
@override final  LocaleMap description;
@override final  String logoUrl;
@override final  SponsorTier tier;
@override final  String? xUrl;
@override final  String? websiteUrl;
@override final  String? recruitUrl;
@override final  String? jobBoardUrl;
@override@FirestoreDateTimeConverter() final  DateTime createdAt;
@override@FirestoreDateTimeConverter() final  DateTime updatedAt;

/// Create a copy of Sponsor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SponsorCopyWith<_Sponsor> get copyWith => __$SponsorCopyWithImpl<_Sponsor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SponsorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Sponsor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameKana, nameKana) || other.nameKana == nameKana)&&(identical(other.description, description) || other.description == description)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.xUrl, xUrl) || other.xUrl == xUrl)&&(identical(other.websiteUrl, websiteUrl) || other.websiteUrl == websiteUrl)&&(identical(other.recruitUrl, recruitUrl) || other.recruitUrl == recruitUrl)&&(identical(other.jobBoardUrl, jobBoardUrl) || other.jobBoardUrl == jobBoardUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nameKana,description,logoUrl,tier,xUrl,websiteUrl,recruitUrl,jobBoardUrl,createdAt,updatedAt);

@override
String toString() {
  return 'Sponsor(id: $id, name: $name, nameKana: $nameKana, description: $description, logoUrl: $logoUrl, tier: $tier, xUrl: $xUrl, websiteUrl: $websiteUrl, recruitUrl: $recruitUrl, jobBoardUrl: $jobBoardUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SponsorCopyWith<$Res> implements $SponsorCopyWith<$Res> {
  factory _$SponsorCopyWith(_Sponsor value, $Res Function(_Sponsor) _then) = __$SponsorCopyWithImpl;
@override @useResult
$Res call({
 String id, LocaleMap name, String? nameKana, LocaleMap description, String logoUrl, SponsorTier tier, String? xUrl, String? websiteUrl, String? recruitUrl, String? jobBoardUrl,@FirestoreDateTimeConverter() DateTime createdAt,@FirestoreDateTimeConverter() DateTime updatedAt
});


@override $LocaleMapCopyWith<$Res> get name;@override $LocaleMapCopyWith<$Res> get description;

}
/// @nodoc
class __$SponsorCopyWithImpl<$Res>
    implements _$SponsorCopyWith<$Res> {
  __$SponsorCopyWithImpl(this._self, this._then);

  final _Sponsor _self;
  final $Res Function(_Sponsor) _then;

/// Create a copy of Sponsor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nameKana = freezed,Object? description = null,Object? logoUrl = null,Object? tier = null,Object? xUrl = freezed,Object? websiteUrl = freezed,Object? recruitUrl = freezed,Object? jobBoardUrl = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Sponsor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as LocaleMap,nameKana: freezed == nameKana ? _self.nameKana : nameKana // ignore: cast_nullable_to_non_nullable
as String?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as LocaleMap,logoUrl: null == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as SponsorTier,xUrl: freezed == xUrl ? _self.xUrl : xUrl // ignore: cast_nullable_to_non_nullable
as String?,websiteUrl: freezed == websiteUrl ? _self.websiteUrl : websiteUrl // ignore: cast_nullable_to_non_nullable
as String?,recruitUrl: freezed == recruitUrl ? _self.recruitUrl : recruitUrl // ignore: cast_nullable_to_non_nullable
as String?,jobBoardUrl: freezed == jobBoardUrl ? _self.jobBoardUrl : jobBoardUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Sponsor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res> get name {
  
  return $LocaleMapCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of Sponsor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res> get description {
  
  return $LocaleMapCopyWith<$Res>(_self.description, (value) {
    return _then(_self.copyWith(description: value));
  });
}
}

// dart format on
