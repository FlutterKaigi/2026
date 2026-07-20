// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_caption.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveCaptionRoom {

 String get id;/// Manual kill switch. Set to false by operators to hide captions even
/// while the server is connected.
 bool get enabled;/// True while a broadcaster connection is ingesting audio for this room.
 bool get isLive;/// BCP-47 tag of the language currently being transcribed (e.g. `ja-JP`).
 String? get sourceLang;/// Latest in-progress (not yet finalized) transcript, overwritten in place.
 LiveCaptionInterim? get interim;@FirestoreNullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of LiveCaptionRoom
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveCaptionRoomCopyWith<LiveCaptionRoom> get copyWith => _$LiveCaptionRoomCopyWithImpl<LiveCaptionRoom>(this as LiveCaptionRoom, _$identity);

  /// Serializes this LiveCaptionRoom to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveCaptionRoom&&(identical(other.id, id) || other.id == id)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.sourceLang, sourceLang) || other.sourceLang == sourceLang)&&(identical(other.interim, interim) || other.interim == interim)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,enabled,isLive,sourceLang,interim,updatedAt);

@override
String toString() {
  return 'LiveCaptionRoom(id: $id, enabled: $enabled, isLive: $isLive, sourceLang: $sourceLang, interim: $interim, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $LiveCaptionRoomCopyWith<$Res>  {
  factory $LiveCaptionRoomCopyWith(LiveCaptionRoom value, $Res Function(LiveCaptionRoom) _then) = _$LiveCaptionRoomCopyWithImpl;
@useResult
$Res call({
 String id, bool enabled, bool isLive, String? sourceLang, LiveCaptionInterim? interim,@FirestoreNullableDateTimeConverter() DateTime? updatedAt
});


$LiveCaptionInterimCopyWith<$Res>? get interim;

}
/// @nodoc
class _$LiveCaptionRoomCopyWithImpl<$Res>
    implements $LiveCaptionRoomCopyWith<$Res> {
  _$LiveCaptionRoomCopyWithImpl(this._self, this._then);

  final LiveCaptionRoom _self;
  final $Res Function(LiveCaptionRoom) _then;

/// Create a copy of LiveCaptionRoom
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? enabled = null,Object? isLive = null,Object? sourceLang = freezed,Object? interim = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,isLive: null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,sourceLang: freezed == sourceLang ? _self.sourceLang : sourceLang // ignore: cast_nullable_to_non_nullable
as String?,interim: freezed == interim ? _self.interim : interim // ignore: cast_nullable_to_non_nullable
as LiveCaptionInterim?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of LiveCaptionRoom
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveCaptionInterimCopyWith<$Res>? get interim {
    if (_self.interim == null) {
    return null;
  }

  return $LiveCaptionInterimCopyWith<$Res>(_self.interim!, (value) {
    return _then(_self.copyWith(interim: value));
  });
}
}


/// Adds pattern-matching-related methods to [LiveCaptionRoom].
extension LiveCaptionRoomPatterns on LiveCaptionRoom {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveCaptionRoom value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveCaptionRoom() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveCaptionRoom value)  $default,){
final _that = this;
switch (_that) {
case _LiveCaptionRoom():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveCaptionRoom value)?  $default,){
final _that = this;
switch (_that) {
case _LiveCaptionRoom() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  bool enabled,  bool isLive,  String? sourceLang,  LiveCaptionInterim? interim, @FirestoreNullableDateTimeConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveCaptionRoom() when $default != null:
return $default(_that.id,_that.enabled,_that.isLive,_that.sourceLang,_that.interim,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  bool enabled,  bool isLive,  String? sourceLang,  LiveCaptionInterim? interim, @FirestoreNullableDateTimeConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LiveCaptionRoom():
return $default(_that.id,_that.enabled,_that.isLive,_that.sourceLang,_that.interim,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  bool enabled,  bool isLive,  String? sourceLang,  LiveCaptionInterim? interim, @FirestoreNullableDateTimeConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LiveCaptionRoom() when $default != null:
return $default(_that.id,_that.enabled,_that.isLive,_that.sourceLang,_that.interim,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveCaptionRoom extends LiveCaptionRoom {
  const _LiveCaptionRoom({required this.id, this.enabled = true, this.isLive = false, this.sourceLang, this.interim, @FirestoreNullableDateTimeConverter() this.updatedAt}): super._();
  factory _LiveCaptionRoom.fromJson(Map<String, dynamic> json) => _$LiveCaptionRoomFromJson(json);

@override final  String id;
/// Manual kill switch. Set to false by operators to hide captions even
/// while the server is connected.
@override@JsonKey() final  bool enabled;
/// True while a broadcaster connection is ingesting audio for this room.
@override@JsonKey() final  bool isLive;
/// BCP-47 tag of the language currently being transcribed (e.g. `ja-JP`).
@override final  String? sourceLang;
/// Latest in-progress (not yet finalized) transcript, overwritten in place.
@override final  LiveCaptionInterim? interim;
@override@FirestoreNullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of LiveCaptionRoom
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveCaptionRoomCopyWith<_LiveCaptionRoom> get copyWith => __$LiveCaptionRoomCopyWithImpl<_LiveCaptionRoom>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveCaptionRoomToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveCaptionRoom&&(identical(other.id, id) || other.id == id)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.sourceLang, sourceLang) || other.sourceLang == sourceLang)&&(identical(other.interim, interim) || other.interim == interim)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,enabled,isLive,sourceLang,interim,updatedAt);

@override
String toString() {
  return 'LiveCaptionRoom(id: $id, enabled: $enabled, isLive: $isLive, sourceLang: $sourceLang, interim: $interim, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LiveCaptionRoomCopyWith<$Res> implements $LiveCaptionRoomCopyWith<$Res> {
  factory _$LiveCaptionRoomCopyWith(_LiveCaptionRoom value, $Res Function(_LiveCaptionRoom) _then) = __$LiveCaptionRoomCopyWithImpl;
@override @useResult
$Res call({
 String id, bool enabled, bool isLive, String? sourceLang, LiveCaptionInterim? interim,@FirestoreNullableDateTimeConverter() DateTime? updatedAt
});


@override $LiveCaptionInterimCopyWith<$Res>? get interim;

}
/// @nodoc
class __$LiveCaptionRoomCopyWithImpl<$Res>
    implements _$LiveCaptionRoomCopyWith<$Res> {
  __$LiveCaptionRoomCopyWithImpl(this._self, this._then);

  final _LiveCaptionRoom _self;
  final $Res Function(_LiveCaptionRoom) _then;

/// Create a copy of LiveCaptionRoom
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? enabled = null,Object? isLive = null,Object? sourceLang = freezed,Object? interim = freezed,Object? updatedAt = freezed,}) {
  return _then(_LiveCaptionRoom(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,isLive: null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,sourceLang: freezed == sourceLang ? _self.sourceLang : sourceLang // ignore: cast_nullable_to_non_nullable
as String?,interim: freezed == interim ? _self.interim : interim // ignore: cast_nullable_to_non_nullable
as LiveCaptionInterim?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of LiveCaptionRoom
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveCaptionInterimCopyWith<$Res>? get interim {
    if (_self.interim == null) {
    return null;
  }

  return $LiveCaptionInterimCopyWith<$Res>(_self.interim!, (value) {
    return _then(_self.copyWith(interim: value));
  });
}
}


/// @nodoc
mixin _$LiveCaptionInterim {

 String get text; String get srcLang;@FirestoreNullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of LiveCaptionInterim
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveCaptionInterimCopyWith<LiveCaptionInterim> get copyWith => _$LiveCaptionInterimCopyWithImpl<LiveCaptionInterim>(this as LiveCaptionInterim, _$identity);

  /// Serializes this LiveCaptionInterim to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveCaptionInterim&&(identical(other.text, text) || other.text == text)&&(identical(other.srcLang, srcLang) || other.srcLang == srcLang)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,srcLang,updatedAt);

@override
String toString() {
  return 'LiveCaptionInterim(text: $text, srcLang: $srcLang, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $LiveCaptionInterimCopyWith<$Res>  {
  factory $LiveCaptionInterimCopyWith(LiveCaptionInterim value, $Res Function(LiveCaptionInterim) _then) = _$LiveCaptionInterimCopyWithImpl;
@useResult
$Res call({
 String text, String srcLang,@FirestoreNullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$LiveCaptionInterimCopyWithImpl<$Res>
    implements $LiveCaptionInterimCopyWith<$Res> {
  _$LiveCaptionInterimCopyWithImpl(this._self, this._then);

  final LiveCaptionInterim _self;
  final $Res Function(LiveCaptionInterim) _then;

/// Create a copy of LiveCaptionInterim
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? srcLang = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,srcLang: null == srcLang ? _self.srcLang : srcLang // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveCaptionInterim].
extension LiveCaptionInterimPatterns on LiveCaptionInterim {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveCaptionInterim value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveCaptionInterim() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveCaptionInterim value)  $default,){
final _that = this;
switch (_that) {
case _LiveCaptionInterim():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveCaptionInterim value)?  $default,){
final _that = this;
switch (_that) {
case _LiveCaptionInterim() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  String srcLang, @FirestoreNullableDateTimeConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveCaptionInterim() when $default != null:
return $default(_that.text,_that.srcLang,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  String srcLang, @FirestoreNullableDateTimeConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LiveCaptionInterim():
return $default(_that.text,_that.srcLang,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  String srcLang, @FirestoreNullableDateTimeConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LiveCaptionInterim() when $default != null:
return $default(_that.text,_that.srcLang,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveCaptionInterim implements LiveCaptionInterim {
  const _LiveCaptionInterim({required this.text, required this.srcLang, @FirestoreNullableDateTimeConverter() this.updatedAt});
  factory _LiveCaptionInterim.fromJson(Map<String, dynamic> json) => _$LiveCaptionInterimFromJson(json);

@override final  String text;
@override final  String srcLang;
@override@FirestoreNullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of LiveCaptionInterim
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveCaptionInterimCopyWith<_LiveCaptionInterim> get copyWith => __$LiveCaptionInterimCopyWithImpl<_LiveCaptionInterim>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveCaptionInterimToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveCaptionInterim&&(identical(other.text, text) || other.text == text)&&(identical(other.srcLang, srcLang) || other.srcLang == srcLang)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,srcLang,updatedAt);

@override
String toString() {
  return 'LiveCaptionInterim(text: $text, srcLang: $srcLang, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LiveCaptionInterimCopyWith<$Res> implements $LiveCaptionInterimCopyWith<$Res> {
  factory _$LiveCaptionInterimCopyWith(_LiveCaptionInterim value, $Res Function(_LiveCaptionInterim) _then) = __$LiveCaptionInterimCopyWithImpl;
@override @useResult
$Res call({
 String text, String srcLang,@FirestoreNullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$LiveCaptionInterimCopyWithImpl<$Res>
    implements _$LiveCaptionInterimCopyWith<$Res> {
  __$LiveCaptionInterimCopyWithImpl(this._self, this._then);

  final _LiveCaptionInterim _self;
  final $Res Function(_LiveCaptionInterim) _then;

/// Create a copy of LiveCaptionInterim
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? srcLang = null,Object? updatedAt = freezed,}) {
  return _then(_LiveCaptionInterim(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,srcLang: null == srcLang ? _self.srcLang : srcLang // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$LiveCaptionSegment {

 String get id; int get seq; String get srcLang; String get srcText; String get ja; String get en; int get startMs; int get endMs;@FirestoreNullableDateTimeConverter() DateTime? get createdAt;
/// Create a copy of LiveCaptionSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveCaptionSegmentCopyWith<LiveCaptionSegment> get copyWith => _$LiveCaptionSegmentCopyWithImpl<LiveCaptionSegment>(this as LiveCaptionSegment, _$identity);

  /// Serializes this LiveCaptionSegment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveCaptionSegment&&(identical(other.id, id) || other.id == id)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.srcLang, srcLang) || other.srcLang == srcLang)&&(identical(other.srcText, srcText) || other.srcText == srcText)&&(identical(other.ja, ja) || other.ja == ja)&&(identical(other.en, en) || other.en == en)&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,seq,srcLang,srcText,ja,en,startMs,endMs,createdAt);

@override
String toString() {
  return 'LiveCaptionSegment(id: $id, seq: $seq, srcLang: $srcLang, srcText: $srcText, ja: $ja, en: $en, startMs: $startMs, endMs: $endMs, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $LiveCaptionSegmentCopyWith<$Res>  {
  factory $LiveCaptionSegmentCopyWith(LiveCaptionSegment value, $Res Function(LiveCaptionSegment) _then) = _$LiveCaptionSegmentCopyWithImpl;
@useResult
$Res call({
 String id, int seq, String srcLang, String srcText, String ja, String en, int startMs, int endMs,@FirestoreNullableDateTimeConverter() DateTime? createdAt
});




}
/// @nodoc
class _$LiveCaptionSegmentCopyWithImpl<$Res>
    implements $LiveCaptionSegmentCopyWith<$Res> {
  _$LiveCaptionSegmentCopyWithImpl(this._self, this._then);

  final LiveCaptionSegment _self;
  final $Res Function(LiveCaptionSegment) _then;

/// Create a copy of LiveCaptionSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? seq = null,Object? srcLang = null,Object? srcText = null,Object? ja = null,Object? en = null,Object? startMs = null,Object? endMs = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,srcLang: null == srcLang ? _self.srcLang : srcLang // ignore: cast_nullable_to_non_nullable
as String,srcText: null == srcText ? _self.srcText : srcText // ignore: cast_nullable_to_non_nullable
as String,ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveCaptionSegment].
extension LiveCaptionSegmentPatterns on LiveCaptionSegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveCaptionSegment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveCaptionSegment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveCaptionSegment value)  $default,){
final _that = this;
switch (_that) {
case _LiveCaptionSegment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveCaptionSegment value)?  $default,){
final _that = this;
switch (_that) {
case _LiveCaptionSegment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int seq,  String srcLang,  String srcText,  String ja,  String en,  int startMs,  int endMs, @FirestoreNullableDateTimeConverter()  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveCaptionSegment() when $default != null:
return $default(_that.id,_that.seq,_that.srcLang,_that.srcText,_that.ja,_that.en,_that.startMs,_that.endMs,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int seq,  String srcLang,  String srcText,  String ja,  String en,  int startMs,  int endMs, @FirestoreNullableDateTimeConverter()  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _LiveCaptionSegment():
return $default(_that.id,_that.seq,_that.srcLang,_that.srcText,_that.ja,_that.en,_that.startMs,_that.endMs,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int seq,  String srcLang,  String srcText,  String ja,  String en,  int startMs,  int endMs, @FirestoreNullableDateTimeConverter()  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _LiveCaptionSegment() when $default != null:
return $default(_that.id,_that.seq,_that.srcLang,_that.srcText,_that.ja,_that.en,_that.startMs,_that.endMs,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveCaptionSegment extends LiveCaptionSegment {
  const _LiveCaptionSegment({required this.id, required this.seq, required this.srcLang, required this.srcText, required this.ja, required this.en, this.startMs = 0, this.endMs = 0, @FirestoreNullableDateTimeConverter() this.createdAt}): super._();
  factory _LiveCaptionSegment.fromJson(Map<String, dynamic> json) => _$LiveCaptionSegmentFromJson(json);

@override final  String id;
@override final  int seq;
@override final  String srcLang;
@override final  String srcText;
@override final  String ja;
@override final  String en;
@override@JsonKey() final  int startMs;
@override@JsonKey() final  int endMs;
@override@FirestoreNullableDateTimeConverter() final  DateTime? createdAt;

/// Create a copy of LiveCaptionSegment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveCaptionSegmentCopyWith<_LiveCaptionSegment> get copyWith => __$LiveCaptionSegmentCopyWithImpl<_LiveCaptionSegment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveCaptionSegmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveCaptionSegment&&(identical(other.id, id) || other.id == id)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.srcLang, srcLang) || other.srcLang == srcLang)&&(identical(other.srcText, srcText) || other.srcText == srcText)&&(identical(other.ja, ja) || other.ja == ja)&&(identical(other.en, en) || other.en == en)&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,seq,srcLang,srcText,ja,en,startMs,endMs,createdAt);

@override
String toString() {
  return 'LiveCaptionSegment(id: $id, seq: $seq, srcLang: $srcLang, srcText: $srcText, ja: $ja, en: $en, startMs: $startMs, endMs: $endMs, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$LiveCaptionSegmentCopyWith<$Res> implements $LiveCaptionSegmentCopyWith<$Res> {
  factory _$LiveCaptionSegmentCopyWith(_LiveCaptionSegment value, $Res Function(_LiveCaptionSegment) _then) = __$LiveCaptionSegmentCopyWithImpl;
@override @useResult
$Res call({
 String id, int seq, String srcLang, String srcText, String ja, String en, int startMs, int endMs,@FirestoreNullableDateTimeConverter() DateTime? createdAt
});




}
/// @nodoc
class __$LiveCaptionSegmentCopyWithImpl<$Res>
    implements _$LiveCaptionSegmentCopyWith<$Res> {
  __$LiveCaptionSegmentCopyWithImpl(this._self, this._then);

  final _LiveCaptionSegment _self;
  final $Res Function(_LiveCaptionSegment) _then;

/// Create a copy of LiveCaptionSegment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? seq = null,Object? srcLang = null,Object? srcText = null,Object? ja = null,Object? en = null,Object? startMs = null,Object? endMs = null,Object? createdAt = freezed,}) {
  return _then(_LiveCaptionSegment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,srcLang: null == srcLang ? _self.srcLang : srcLang // ignore: cast_nullable_to_non_nullable
as String,srcText: null == srcText ? _self.srcText : srcText // ignore: cast_nullable_to_non_nullable
as String,ja: null == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String,en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
