// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Session {

 String get id; LocaleMap get title; LocaleMap get description; String get primaryLocale;@FirestoreDateTimeConverter() DateTime get startsAt;@FirestoreDateTimeConverter() DateTime get endsAt; String get venueId; List<String> get speakerIds; bool get isLightningTalk; bool get isBeginnersLightningTalk; bool get isHandsOn; String? get sessionizeUrl;@FirestoreDateTimeConverter() DateTime get createdAt;@FirestoreDateTimeConverter() DateTime get updatedAt;
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionCopyWith<Session> get copyWith => _$SessionCopyWithImpl<Session>(this as Session, _$identity);

  /// Serializes this Session to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Session&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.primaryLocale, primaryLocale) || other.primaryLocale == primaryLocale)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.venueId, venueId) || other.venueId == venueId)&&const DeepCollectionEquality().equals(other.speakerIds, speakerIds)&&(identical(other.isLightningTalk, isLightningTalk) || other.isLightningTalk == isLightningTalk)&&(identical(other.isBeginnersLightningTalk, isBeginnersLightningTalk) || other.isBeginnersLightningTalk == isBeginnersLightningTalk)&&(identical(other.isHandsOn, isHandsOn) || other.isHandsOn == isHandsOn)&&(identical(other.sessionizeUrl, sessionizeUrl) || other.sessionizeUrl == sessionizeUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,primaryLocale,startsAt,endsAt,venueId,const DeepCollectionEquality().hash(speakerIds),isLightningTalk,isBeginnersLightningTalk,isHandsOn,sessionizeUrl,createdAt,updatedAt);

@override
String toString() {
  return 'Session(id: $id, title: $title, description: $description, primaryLocale: $primaryLocale, startsAt: $startsAt, endsAt: $endsAt, venueId: $venueId, speakerIds: $speakerIds, isLightningTalk: $isLightningTalk, isBeginnersLightningTalk: $isBeginnersLightningTalk, isHandsOn: $isHandsOn, sessionizeUrl: $sessionizeUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SessionCopyWith<$Res>  {
  factory $SessionCopyWith(Session value, $Res Function(Session) _then) = _$SessionCopyWithImpl;
@useResult
$Res call({
 String id, LocaleMap title, LocaleMap description, String primaryLocale,@FirestoreDateTimeConverter() DateTime startsAt,@FirestoreDateTimeConverter() DateTime endsAt, String venueId, List<String> speakerIds, bool isLightningTalk, bool isBeginnersLightningTalk, bool isHandsOn, String? sessionizeUrl,@FirestoreDateTimeConverter() DateTime createdAt,@FirestoreDateTimeConverter() DateTime updatedAt
});


$LocaleMapCopyWith<$Res> get title;$LocaleMapCopyWith<$Res> get description;

}
/// @nodoc
class _$SessionCopyWithImpl<$Res>
    implements $SessionCopyWith<$Res> {
  _$SessionCopyWithImpl(this._self, this._then);

  final Session _self;
  final $Res Function(Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? primaryLocale = null,Object? startsAt = null,Object? endsAt = null,Object? venueId = null,Object? speakerIds = null,Object? isLightningTalk = null,Object? isBeginnersLightningTalk = null,Object? isHandsOn = null,Object? sessionizeUrl = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as LocaleMap,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as LocaleMap,primaryLocale: null == primaryLocale ? _self.primaryLocale : primaryLocale // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,venueId: null == venueId ? _self.venueId : venueId // ignore: cast_nullable_to_non_nullable
as String,speakerIds: null == speakerIds ? _self.speakerIds : speakerIds // ignore: cast_nullable_to_non_nullable
as List<String>,isLightningTalk: null == isLightningTalk ? _self.isLightningTalk : isLightningTalk // ignore: cast_nullable_to_non_nullable
as bool,isBeginnersLightningTalk: null == isBeginnersLightningTalk ? _self.isBeginnersLightningTalk : isBeginnersLightningTalk // ignore: cast_nullable_to_non_nullable
as bool,isHandsOn: null == isHandsOn ? _self.isHandsOn : isHandsOn // ignore: cast_nullable_to_non_nullable
as bool,sessionizeUrl: freezed == sessionizeUrl ? _self.sessionizeUrl : sessionizeUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res> get title {
  
  return $LocaleMapCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res> get description {
  
  return $LocaleMapCopyWith<$Res>(_self.description, (value) {
    return _then(_self.copyWith(description: value));
  });
}
}


/// Adds pattern-matching-related methods to [Session].
extension SessionPatterns on Session {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Session value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Session value)  $default,){
final _that = this;
switch (_that) {
case _Session():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Session value)?  $default,){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  LocaleMap title,  LocaleMap description,  String primaryLocale, @FirestoreDateTimeConverter()  DateTime startsAt, @FirestoreDateTimeConverter()  DateTime endsAt,  String venueId,  List<String> speakerIds,  bool isLightningTalk,  bool isBeginnersLightningTalk,  bool isHandsOn,  String? sessionizeUrl, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.primaryLocale,_that.startsAt,_that.endsAt,_that.venueId,_that.speakerIds,_that.isLightningTalk,_that.isBeginnersLightningTalk,_that.isHandsOn,_that.sessionizeUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  LocaleMap title,  LocaleMap description,  String primaryLocale, @FirestoreDateTimeConverter()  DateTime startsAt, @FirestoreDateTimeConverter()  DateTime endsAt,  String venueId,  List<String> speakerIds,  bool isLightningTalk,  bool isBeginnersLightningTalk,  bool isHandsOn,  String? sessionizeUrl, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Session():
return $default(_that.id,_that.title,_that.description,_that.primaryLocale,_that.startsAt,_that.endsAt,_that.venueId,_that.speakerIds,_that.isLightningTalk,_that.isBeginnersLightningTalk,_that.isHandsOn,_that.sessionizeUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  LocaleMap title,  LocaleMap description,  String primaryLocale, @FirestoreDateTimeConverter()  DateTime startsAt, @FirestoreDateTimeConverter()  DateTime endsAt,  String venueId,  List<String> speakerIds,  bool isLightningTalk,  bool isBeginnersLightningTalk,  bool isHandsOn,  String? sessionizeUrl, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.primaryLocale,_that.startsAt,_that.endsAt,_that.venueId,_that.speakerIds,_that.isLightningTalk,_that.isBeginnersLightningTalk,_that.isHandsOn,_that.sessionizeUrl,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Session extends Session {
  const _Session({required this.id, required this.title, required this.description, required this.primaryLocale, @FirestoreDateTimeConverter() required this.startsAt, @FirestoreDateTimeConverter() required this.endsAt, required this.venueId, final  List<String> speakerIds = const [], this.isLightningTalk = false, this.isBeginnersLightningTalk = false, this.isHandsOn = false, this.sessionizeUrl, @FirestoreDateTimeConverter() required this.createdAt, @FirestoreDateTimeConverter() required this.updatedAt}): _speakerIds = speakerIds,super._();
  factory _Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

@override final  String id;
@override final  LocaleMap title;
@override final  LocaleMap description;
@override final  String primaryLocale;
@override@FirestoreDateTimeConverter() final  DateTime startsAt;
@override@FirestoreDateTimeConverter() final  DateTime endsAt;
@override final  String venueId;
 final  List<String> _speakerIds;
@override@JsonKey() List<String> get speakerIds {
  if (_speakerIds is EqualUnmodifiableListView) return _speakerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_speakerIds);
}

@override@JsonKey() final  bool isLightningTalk;
@override@JsonKey() final  bool isBeginnersLightningTalk;
@override@JsonKey() final  bool isHandsOn;
@override final  String? sessionizeUrl;
@override@FirestoreDateTimeConverter() final  DateTime createdAt;
@override@FirestoreDateTimeConverter() final  DateTime updatedAt;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionCopyWith<_Session> get copyWith => __$SessionCopyWithImpl<_Session>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Session&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.primaryLocale, primaryLocale) || other.primaryLocale == primaryLocale)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.venueId, venueId) || other.venueId == venueId)&&const DeepCollectionEquality().equals(other._speakerIds, _speakerIds)&&(identical(other.isLightningTalk, isLightningTalk) || other.isLightningTalk == isLightningTalk)&&(identical(other.isBeginnersLightningTalk, isBeginnersLightningTalk) || other.isBeginnersLightningTalk == isBeginnersLightningTalk)&&(identical(other.isHandsOn, isHandsOn) || other.isHandsOn == isHandsOn)&&(identical(other.sessionizeUrl, sessionizeUrl) || other.sessionizeUrl == sessionizeUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,primaryLocale,startsAt,endsAt,venueId,const DeepCollectionEquality().hash(_speakerIds),isLightningTalk,isBeginnersLightningTalk,isHandsOn,sessionizeUrl,createdAt,updatedAt);

@override
String toString() {
  return 'Session(id: $id, title: $title, description: $description, primaryLocale: $primaryLocale, startsAt: $startsAt, endsAt: $endsAt, venueId: $venueId, speakerIds: $speakerIds, isLightningTalk: $isLightningTalk, isBeginnersLightningTalk: $isBeginnersLightningTalk, isHandsOn: $isHandsOn, sessionizeUrl: $sessionizeUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SessionCopyWith<$Res> implements $SessionCopyWith<$Res> {
  factory _$SessionCopyWith(_Session value, $Res Function(_Session) _then) = __$SessionCopyWithImpl;
@override @useResult
$Res call({
 String id, LocaleMap title, LocaleMap description, String primaryLocale,@FirestoreDateTimeConverter() DateTime startsAt,@FirestoreDateTimeConverter() DateTime endsAt, String venueId, List<String> speakerIds, bool isLightningTalk, bool isBeginnersLightningTalk, bool isHandsOn, String? sessionizeUrl,@FirestoreDateTimeConverter() DateTime createdAt,@FirestoreDateTimeConverter() DateTime updatedAt
});


@override $LocaleMapCopyWith<$Res> get title;@override $LocaleMapCopyWith<$Res> get description;

}
/// @nodoc
class __$SessionCopyWithImpl<$Res>
    implements _$SessionCopyWith<$Res> {
  __$SessionCopyWithImpl(this._self, this._then);

  final _Session _self;
  final $Res Function(_Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? primaryLocale = null,Object? startsAt = null,Object? endsAt = null,Object? venueId = null,Object? speakerIds = null,Object? isLightningTalk = null,Object? isBeginnersLightningTalk = null,Object? isHandsOn = null,Object? sessionizeUrl = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Session(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as LocaleMap,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as LocaleMap,primaryLocale: null == primaryLocale ? _self.primaryLocale : primaryLocale // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,venueId: null == venueId ? _self.venueId : venueId // ignore: cast_nullable_to_non_nullable
as String,speakerIds: null == speakerIds ? _self._speakerIds : speakerIds // ignore: cast_nullable_to_non_nullable
as List<String>,isLightningTalk: null == isLightningTalk ? _self.isLightningTalk : isLightningTalk // ignore: cast_nullable_to_non_nullable
as bool,isBeginnersLightningTalk: null == isBeginnersLightningTalk ? _self.isBeginnersLightningTalk : isBeginnersLightningTalk // ignore: cast_nullable_to_non_nullable
as bool,isHandsOn: null == isHandsOn ? _self.isHandsOn : isHandsOn // ignore: cast_nullable_to_non_nullable
as bool,sessionizeUrl: freezed == sessionizeUrl ? _self.sessionizeUrl : sessionizeUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res> get title {
  
  return $LocaleMapCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of Session
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
