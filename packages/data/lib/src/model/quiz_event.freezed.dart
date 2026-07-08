// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuizEvent {

 String get id; LocaleMap get title; QuizEventStatus get status; String? get currentQuestionId; List<String> get sponsorIds;@FirestoreDateTimeConverter() DateTime get createdAt;@FirestoreDateTimeConverter() DateTime get updatedAt;
/// Create a copy of QuizEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizEventCopyWith<QuizEvent> get copyWith => _$QuizEventCopyWithImpl<QuizEvent>(this as QuizEvent, _$identity);

  /// Serializes this QuizEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.currentQuestionId, currentQuestionId) || other.currentQuestionId == currentQuestionId)&&const DeepCollectionEquality().equals(other.sponsorIds, sponsorIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,status,currentQuestionId,const DeepCollectionEquality().hash(sponsorIds),createdAt,updatedAt);

@override
String toString() {
  return 'QuizEvent(id: $id, title: $title, status: $status, currentQuestionId: $currentQuestionId, sponsorIds: $sponsorIds, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $QuizEventCopyWith<$Res>  {
  factory $QuizEventCopyWith(QuizEvent value, $Res Function(QuizEvent) _then) = _$QuizEventCopyWithImpl;
@useResult
$Res call({
 String id, LocaleMap title, QuizEventStatus status, String? currentQuestionId, List<String> sponsorIds,@FirestoreDateTimeConverter() DateTime createdAt,@FirestoreDateTimeConverter() DateTime updatedAt
});


$LocaleMapCopyWith<$Res> get title;

}
/// @nodoc
class _$QuizEventCopyWithImpl<$Res>
    implements $QuizEventCopyWith<$Res> {
  _$QuizEventCopyWithImpl(this._self, this._then);

  final QuizEvent _self;
  final $Res Function(QuizEvent) _then;

/// Create a copy of QuizEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? status = null,Object? currentQuestionId = freezed,Object? sponsorIds = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as LocaleMap,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuizEventStatus,currentQuestionId: freezed == currentQuestionId ? _self.currentQuestionId : currentQuestionId // ignore: cast_nullable_to_non_nullable
as String?,sponsorIds: null == sponsorIds ? _self.sponsorIds : sponsorIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of QuizEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res> get title {
  
  return $LocaleMapCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}
}


/// Adds pattern-matching-related methods to [QuizEvent].
extension QuizEventPatterns on QuizEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizEvent value)  $default,){
final _that = this;
switch (_that) {
case _QuizEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizEvent value)?  $default,){
final _that = this;
switch (_that) {
case _QuizEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  LocaleMap title,  QuizEventStatus status,  String? currentQuestionId,  List<String> sponsorIds, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizEvent() when $default != null:
return $default(_that.id,_that.title,_that.status,_that.currentQuestionId,_that.sponsorIds,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  LocaleMap title,  QuizEventStatus status,  String? currentQuestionId,  List<String> sponsorIds, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _QuizEvent():
return $default(_that.id,_that.title,_that.status,_that.currentQuestionId,_that.sponsorIds,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  LocaleMap title,  QuizEventStatus status,  String? currentQuestionId,  List<String> sponsorIds, @FirestoreDateTimeConverter()  DateTime createdAt, @FirestoreDateTimeConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _QuizEvent() when $default != null:
return $default(_that.id,_that.title,_that.status,_that.currentQuestionId,_that.sponsorIds,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizEvent extends QuizEvent {
  const _QuizEvent({required this.id, required this.title, required this.status, this.currentQuestionId, final  List<String> sponsorIds = const [], @FirestoreDateTimeConverter() required this.createdAt, @FirestoreDateTimeConverter() required this.updatedAt}): _sponsorIds = sponsorIds,super._();
  factory _QuizEvent.fromJson(Map<String, dynamic> json) => _$QuizEventFromJson(json);

@override final  String id;
@override final  LocaleMap title;
@override final  QuizEventStatus status;
@override final  String? currentQuestionId;
 final  List<String> _sponsorIds;
@override@JsonKey() List<String> get sponsorIds {
  if (_sponsorIds is EqualUnmodifiableListView) return _sponsorIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sponsorIds);
}

@override@FirestoreDateTimeConverter() final  DateTime createdAt;
@override@FirestoreDateTimeConverter() final  DateTime updatedAt;

/// Create a copy of QuizEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizEventCopyWith<_QuizEvent> get copyWith => __$QuizEventCopyWithImpl<_QuizEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.currentQuestionId, currentQuestionId) || other.currentQuestionId == currentQuestionId)&&const DeepCollectionEquality().equals(other._sponsorIds, _sponsorIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,status,currentQuestionId,const DeepCollectionEquality().hash(_sponsorIds),createdAt,updatedAt);

@override
String toString() {
  return 'QuizEvent(id: $id, title: $title, status: $status, currentQuestionId: $currentQuestionId, sponsorIds: $sponsorIds, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$QuizEventCopyWith<$Res> implements $QuizEventCopyWith<$Res> {
  factory _$QuizEventCopyWith(_QuizEvent value, $Res Function(_QuizEvent) _then) = __$QuizEventCopyWithImpl;
@override @useResult
$Res call({
 String id, LocaleMap title, QuizEventStatus status, String? currentQuestionId, List<String> sponsorIds,@FirestoreDateTimeConverter() DateTime createdAt,@FirestoreDateTimeConverter() DateTime updatedAt
});


@override $LocaleMapCopyWith<$Res> get title;

}
/// @nodoc
class __$QuizEventCopyWithImpl<$Res>
    implements _$QuizEventCopyWith<$Res> {
  __$QuizEventCopyWithImpl(this._self, this._then);

  final _QuizEvent _self;
  final $Res Function(_QuizEvent) _then;

/// Create a copy of QuizEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? status = null,Object? currentQuestionId = freezed,Object? sponsorIds = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_QuizEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as LocaleMap,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuizEventStatus,currentQuestionId: freezed == currentQuestionId ? _self.currentQuestionId : currentQuestionId // ignore: cast_nullable_to_non_nullable
as String?,sponsorIds: null == sponsorIds ? _self._sponsorIds : sponsorIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of QuizEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res> get title {
  
  return $LocaleMapCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}
}

// dart format on
