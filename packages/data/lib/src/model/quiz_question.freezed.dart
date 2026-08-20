// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_question.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuizQuestion {

 String get id; String get sponsorId; int get order;/// 問題文（日英）。参加者アプリでは端末ロケールで出し分ける。
 LocaleMap get title;/// 選択肢（日英）。並び順が回答の index に対応する。
 List<LocaleMap> get options; int get durationSeconds; QuizQuestionStatus get status;@FirestoreNullableDateTimeConverter() DateTime? get openedAt;@FirestoreNullableDateTimeConverter() DateTime? get closesAt; int? get correctOptionIndex;/// 解説（日英）。正解発表時に secret からコピーされる。
 LocaleMap? get explanation;
/// Create a copy of QuizQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizQuestionCopyWith<QuizQuestion> get copyWith => _$QuizQuestionCopyWithImpl<QuizQuestion>(this as QuizQuestion, _$identity);

  /// Serializes this QuizQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.sponsorId, sponsorId) || other.sponsorId == sponsorId)&&(identical(other.order, order) || other.order == order)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.options, options)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.status, status) || other.status == status)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt)&&(identical(other.correctOptionIndex, correctOptionIndex) || other.correctOptionIndex == correctOptionIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sponsorId,order,title,const DeepCollectionEquality().hash(options),durationSeconds,status,openedAt,closesAt,correctOptionIndex,explanation);

@override
String toString() {
  return 'QuizQuestion(id: $id, sponsorId: $sponsorId, order: $order, title: $title, options: $options, durationSeconds: $durationSeconds, status: $status, openedAt: $openedAt, closesAt: $closesAt, correctOptionIndex: $correctOptionIndex, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class $QuizQuestionCopyWith<$Res>  {
  factory $QuizQuestionCopyWith(QuizQuestion value, $Res Function(QuizQuestion) _then) = _$QuizQuestionCopyWithImpl;
@useResult
$Res call({
 String id, String sponsorId, int order, LocaleMap title, List<LocaleMap> options, int durationSeconds, QuizQuestionStatus status,@FirestoreNullableDateTimeConverter() DateTime? openedAt,@FirestoreNullableDateTimeConverter() DateTime? closesAt, int? correctOptionIndex, LocaleMap? explanation
});


$LocaleMapCopyWith<$Res> get title;$LocaleMapCopyWith<$Res>? get explanation;

}
/// @nodoc
class _$QuizQuestionCopyWithImpl<$Res>
    implements $QuizQuestionCopyWith<$Res> {
  _$QuizQuestionCopyWithImpl(this._self, this._then);

  final QuizQuestion _self;
  final $Res Function(QuizQuestion) _then;

/// Create a copy of QuizQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sponsorId = null,Object? order = null,Object? title = null,Object? options = null,Object? durationSeconds = null,Object? status = null,Object? openedAt = freezed,Object? closesAt = freezed,Object? correctOptionIndex = freezed,Object? explanation = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sponsorId: null == sponsorId ? _self.sponsorId : sponsorId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as LocaleMap,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<LocaleMap>,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuizQuestionStatus,openedAt: freezed == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,correctOptionIndex: freezed == correctOptionIndex ? _self.correctOptionIndex : correctOptionIndex // ignore: cast_nullable_to_non_nullable
as int?,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as LocaleMap?,
  ));
}
/// Create a copy of QuizQuestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res> get title {
  
  return $LocaleMapCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of QuizQuestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res>? get explanation {
    if (_self.explanation == null) {
    return null;
  }

  return $LocaleMapCopyWith<$Res>(_self.explanation!, (value) {
    return _then(_self.copyWith(explanation: value));
  });
}
}


/// Adds pattern-matching-related methods to [QuizQuestion].
extension QuizQuestionPatterns on QuizQuestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizQuestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizQuestion value)  $default,){
final _that = this;
switch (_that) {
case _QuizQuestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _QuizQuestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sponsorId,  int order,  LocaleMap title,  List<LocaleMap> options,  int durationSeconds,  QuizQuestionStatus status, @FirestoreNullableDateTimeConverter()  DateTime? openedAt, @FirestoreNullableDateTimeConverter()  DateTime? closesAt,  int? correctOptionIndex,  LocaleMap? explanation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizQuestion() when $default != null:
return $default(_that.id,_that.sponsorId,_that.order,_that.title,_that.options,_that.durationSeconds,_that.status,_that.openedAt,_that.closesAt,_that.correctOptionIndex,_that.explanation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sponsorId,  int order,  LocaleMap title,  List<LocaleMap> options,  int durationSeconds,  QuizQuestionStatus status, @FirestoreNullableDateTimeConverter()  DateTime? openedAt, @FirestoreNullableDateTimeConverter()  DateTime? closesAt,  int? correctOptionIndex,  LocaleMap? explanation)  $default,) {final _that = this;
switch (_that) {
case _QuizQuestion():
return $default(_that.id,_that.sponsorId,_that.order,_that.title,_that.options,_that.durationSeconds,_that.status,_that.openedAt,_that.closesAt,_that.correctOptionIndex,_that.explanation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sponsorId,  int order,  LocaleMap title,  List<LocaleMap> options,  int durationSeconds,  QuizQuestionStatus status, @FirestoreNullableDateTimeConverter()  DateTime? openedAt, @FirestoreNullableDateTimeConverter()  DateTime? closesAt,  int? correctOptionIndex,  LocaleMap? explanation)?  $default,) {final _that = this;
switch (_that) {
case _QuizQuestion() when $default != null:
return $default(_that.id,_that.sponsorId,_that.order,_that.title,_that.options,_that.durationSeconds,_that.status,_that.openedAt,_that.closesAt,_that.correctOptionIndex,_that.explanation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizQuestion extends QuizQuestion {
  const _QuizQuestion({required this.id, required this.sponsorId, required this.order, required this.title, final  List<LocaleMap> options = const [], this.durationSeconds = 180, required this.status, @FirestoreNullableDateTimeConverter() this.openedAt, @FirestoreNullableDateTimeConverter() this.closesAt, this.correctOptionIndex, this.explanation}): _options = options,super._();
  factory _QuizQuestion.fromJson(Map<String, dynamic> json) => _$QuizQuestionFromJson(json);

@override final  String id;
@override final  String sponsorId;
@override final  int order;
/// 問題文（日英）。参加者アプリでは端末ロケールで出し分ける。
@override final  LocaleMap title;
/// 選択肢（日英）。並び順が回答の index に対応する。
 final  List<LocaleMap> _options;
/// 選択肢（日英）。並び順が回答の index に対応する。
@override@JsonKey() List<LocaleMap> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override@JsonKey() final  int durationSeconds;
@override final  QuizQuestionStatus status;
@override@FirestoreNullableDateTimeConverter() final  DateTime? openedAt;
@override@FirestoreNullableDateTimeConverter() final  DateTime? closesAt;
@override final  int? correctOptionIndex;
/// 解説（日英）。正解発表時に secret からコピーされる。
@override final  LocaleMap? explanation;

/// Create a copy of QuizQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizQuestionCopyWith<_QuizQuestion> get copyWith => __$QuizQuestionCopyWithImpl<_QuizQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.sponsorId, sponsorId) || other.sponsorId == sponsorId)&&(identical(other.order, order) || other.order == order)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.status, status) || other.status == status)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt)&&(identical(other.correctOptionIndex, correctOptionIndex) || other.correctOptionIndex == correctOptionIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sponsorId,order,title,const DeepCollectionEquality().hash(_options),durationSeconds,status,openedAt,closesAt,correctOptionIndex,explanation);

@override
String toString() {
  return 'QuizQuestion(id: $id, sponsorId: $sponsorId, order: $order, title: $title, options: $options, durationSeconds: $durationSeconds, status: $status, openedAt: $openedAt, closesAt: $closesAt, correctOptionIndex: $correctOptionIndex, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class _$QuizQuestionCopyWith<$Res> implements $QuizQuestionCopyWith<$Res> {
  factory _$QuizQuestionCopyWith(_QuizQuestion value, $Res Function(_QuizQuestion) _then) = __$QuizQuestionCopyWithImpl;
@override @useResult
$Res call({
 String id, String sponsorId, int order, LocaleMap title, List<LocaleMap> options, int durationSeconds, QuizQuestionStatus status,@FirestoreNullableDateTimeConverter() DateTime? openedAt,@FirestoreNullableDateTimeConverter() DateTime? closesAt, int? correctOptionIndex, LocaleMap? explanation
});


@override $LocaleMapCopyWith<$Res> get title;@override $LocaleMapCopyWith<$Res>? get explanation;

}
/// @nodoc
class __$QuizQuestionCopyWithImpl<$Res>
    implements _$QuizQuestionCopyWith<$Res> {
  __$QuizQuestionCopyWithImpl(this._self, this._then);

  final _QuizQuestion _self;
  final $Res Function(_QuizQuestion) _then;

/// Create a copy of QuizQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sponsorId = null,Object? order = null,Object? title = null,Object? options = null,Object? durationSeconds = null,Object? status = null,Object? openedAt = freezed,Object? closesAt = freezed,Object? correctOptionIndex = freezed,Object? explanation = freezed,}) {
  return _then(_QuizQuestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sponsorId: null == sponsorId ? _self.sponsorId : sponsorId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as LocaleMap,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<LocaleMap>,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuizQuestionStatus,openedAt: freezed == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,correctOptionIndex: freezed == correctOptionIndex ? _self.correctOptionIndex : correctOptionIndex // ignore: cast_nullable_to_non_nullable
as int?,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as LocaleMap?,
  ));
}

/// Create a copy of QuizQuestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res> get title {
  
  return $LocaleMapCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of QuizQuestion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocaleMapCopyWith<$Res>? get explanation {
    if (_self.explanation == null) {
    return null;
  }

  return $LocaleMapCopyWith<$Res>(_self.explanation!, (value) {
    return _then(_self.copyWith(explanation: value));
  });
}
}

// dart format on
