// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_answer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuizAnswer {

 String get id; String get questionId; String get teamId; int? get selectedOptionIndex; String? get answeredBy;@FirestoreNullableDateTimeConverter() DateTime? get submittedAt; bool? get isCorrect;
/// Create a copy of QuizAnswer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizAnswerCopyWith<QuizAnswer> get copyWith => _$QuizAnswerCopyWithImpl<QuizAnswer>(this as QuizAnswer, _$identity);

  /// Serializes this QuizAnswer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizAnswer&&(identical(other.id, id) || other.id == id)&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.selectedOptionIndex, selectedOptionIndex) || other.selectedOptionIndex == selectedOptionIndex)&&(identical(other.answeredBy, answeredBy) || other.answeredBy == answeredBy)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.isCorrect, isCorrect) || other.isCorrect == isCorrect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,questionId,teamId,selectedOptionIndex,answeredBy,submittedAt,isCorrect);

@override
String toString() {
  return 'QuizAnswer(id: $id, questionId: $questionId, teamId: $teamId, selectedOptionIndex: $selectedOptionIndex, answeredBy: $answeredBy, submittedAt: $submittedAt, isCorrect: $isCorrect)';
}


}

/// @nodoc
abstract mixin class $QuizAnswerCopyWith<$Res>  {
  factory $QuizAnswerCopyWith(QuizAnswer value, $Res Function(QuizAnswer) _then) = _$QuizAnswerCopyWithImpl;
@useResult
$Res call({
 String id, String questionId, String teamId, int? selectedOptionIndex, String? answeredBy,@FirestoreNullableDateTimeConverter() DateTime? submittedAt, bool? isCorrect
});




}
/// @nodoc
class _$QuizAnswerCopyWithImpl<$Res>
    implements $QuizAnswerCopyWith<$Res> {
  _$QuizAnswerCopyWithImpl(this._self, this._then);

  final QuizAnswer _self;
  final $Res Function(QuizAnswer) _then;

/// Create a copy of QuizAnswer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? questionId = null,Object? teamId = null,Object? selectedOptionIndex = freezed,Object? answeredBy = freezed,Object? submittedAt = freezed,Object? isCorrect = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,selectedOptionIndex: freezed == selectedOptionIndex ? _self.selectedOptionIndex : selectedOptionIndex // ignore: cast_nullable_to_non_nullable
as int?,answeredBy: freezed == answeredBy ? _self.answeredBy : answeredBy // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isCorrect: freezed == isCorrect ? _self.isCorrect : isCorrect // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizAnswer].
extension QuizAnswerPatterns on QuizAnswer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizAnswer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizAnswer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizAnswer value)  $default,){
final _that = this;
switch (_that) {
case _QuizAnswer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizAnswer value)?  $default,){
final _that = this;
switch (_that) {
case _QuizAnswer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String questionId,  String teamId,  int? selectedOptionIndex,  String? answeredBy, @FirestoreNullableDateTimeConverter()  DateTime? submittedAt,  bool? isCorrect)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizAnswer() when $default != null:
return $default(_that.id,_that.questionId,_that.teamId,_that.selectedOptionIndex,_that.answeredBy,_that.submittedAt,_that.isCorrect);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String questionId,  String teamId,  int? selectedOptionIndex,  String? answeredBy, @FirestoreNullableDateTimeConverter()  DateTime? submittedAt,  bool? isCorrect)  $default,) {final _that = this;
switch (_that) {
case _QuizAnswer():
return $default(_that.id,_that.questionId,_that.teamId,_that.selectedOptionIndex,_that.answeredBy,_that.submittedAt,_that.isCorrect);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String questionId,  String teamId,  int? selectedOptionIndex,  String? answeredBy, @FirestoreNullableDateTimeConverter()  DateTime? submittedAt,  bool? isCorrect)?  $default,) {final _that = this;
switch (_that) {
case _QuizAnswer() when $default != null:
return $default(_that.id,_that.questionId,_that.teamId,_that.selectedOptionIndex,_that.answeredBy,_that.submittedAt,_that.isCorrect);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizAnswer extends QuizAnswer {
  const _QuizAnswer({required this.id, required this.questionId, required this.teamId, this.selectedOptionIndex, this.answeredBy, @FirestoreNullableDateTimeConverter() this.submittedAt, this.isCorrect}): super._();
  factory _QuizAnswer.fromJson(Map<String, dynamic> json) => _$QuizAnswerFromJson(json);

@override final  String id;
@override final  String questionId;
@override final  String teamId;
@override final  int? selectedOptionIndex;
@override final  String? answeredBy;
@override@FirestoreNullableDateTimeConverter() final  DateTime? submittedAt;
@override final  bool? isCorrect;

/// Create a copy of QuizAnswer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizAnswerCopyWith<_QuizAnswer> get copyWith => __$QuizAnswerCopyWithImpl<_QuizAnswer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizAnswerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizAnswer&&(identical(other.id, id) || other.id == id)&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.selectedOptionIndex, selectedOptionIndex) || other.selectedOptionIndex == selectedOptionIndex)&&(identical(other.answeredBy, answeredBy) || other.answeredBy == answeredBy)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.isCorrect, isCorrect) || other.isCorrect == isCorrect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,questionId,teamId,selectedOptionIndex,answeredBy,submittedAt,isCorrect);

@override
String toString() {
  return 'QuizAnswer(id: $id, questionId: $questionId, teamId: $teamId, selectedOptionIndex: $selectedOptionIndex, answeredBy: $answeredBy, submittedAt: $submittedAt, isCorrect: $isCorrect)';
}


}

/// @nodoc
abstract mixin class _$QuizAnswerCopyWith<$Res> implements $QuizAnswerCopyWith<$Res> {
  factory _$QuizAnswerCopyWith(_QuizAnswer value, $Res Function(_QuizAnswer) _then) = __$QuizAnswerCopyWithImpl;
@override @useResult
$Res call({
 String id, String questionId, String teamId, int? selectedOptionIndex, String? answeredBy,@FirestoreNullableDateTimeConverter() DateTime? submittedAt, bool? isCorrect
});




}
/// @nodoc
class __$QuizAnswerCopyWithImpl<$Res>
    implements _$QuizAnswerCopyWith<$Res> {
  __$QuizAnswerCopyWithImpl(this._self, this._then);

  final _QuizAnswer _self;
  final $Res Function(_QuizAnswer) _then;

/// Create a copy of QuizAnswer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? questionId = null,Object? teamId = null,Object? selectedOptionIndex = freezed,Object? answeredBy = freezed,Object? submittedAt = freezed,Object? isCorrect = freezed,}) {
  return _then(_QuizAnswer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,selectedOptionIndex: freezed == selectedOptionIndex ? _self.selectedOptionIndex : selectedOptionIndex // ignore: cast_nullable_to_non_nullable
as int?,answeredBy: freezed == answeredBy ? _self.answeredBy : answeredBy // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isCorrect: freezed == isCorrect ? _self.isCorrect : isCorrect // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
