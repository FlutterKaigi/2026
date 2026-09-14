// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_participant_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuizParticipantAccount {

 String get uid; String get signInProvider;@FirestoreDateTimeConverter() DateTime get linkedAt; String? get email; String? get accountName; String? get photoUrl;
/// Create a copy of QuizParticipantAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizParticipantAccountCopyWith<QuizParticipantAccount> get copyWith => _$QuizParticipantAccountCopyWithImpl<QuizParticipantAccount>(this as QuizParticipantAccount, _$identity);

  /// Serializes this QuizParticipantAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizParticipantAccount&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.signInProvider, signInProvider) || other.signInProvider == signInProvider)&&(identical(other.linkedAt, linkedAt) || other.linkedAt == linkedAt)&&(identical(other.email, email) || other.email == email)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,signInProvider,linkedAt,email,accountName,photoUrl);

@override
String toString() {
  return 'QuizParticipantAccount(uid: $uid, signInProvider: $signInProvider, linkedAt: $linkedAt, email: $email, accountName: $accountName, photoUrl: $photoUrl)';
}


}

/// @nodoc
abstract mixin class $QuizParticipantAccountCopyWith<$Res>  {
  factory $QuizParticipantAccountCopyWith(QuizParticipantAccount value, $Res Function(QuizParticipantAccount) _then) = _$QuizParticipantAccountCopyWithImpl;
@useResult
$Res call({
 String uid, String signInProvider,@FirestoreDateTimeConverter() DateTime linkedAt, String? email, String? accountName, String? photoUrl
});




}
/// @nodoc
class _$QuizParticipantAccountCopyWithImpl<$Res>
    implements $QuizParticipantAccountCopyWith<$Res> {
  _$QuizParticipantAccountCopyWithImpl(this._self, this._then);

  final QuizParticipantAccount _self;
  final $Res Function(QuizParticipantAccount) _then;

/// Create a copy of QuizParticipantAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? signInProvider = null,Object? linkedAt = null,Object? email = freezed,Object? accountName = freezed,Object? photoUrl = freezed,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,signInProvider: null == signInProvider ? _self.signInProvider : signInProvider // ignore: cast_nullable_to_non_nullable
as String,linkedAt: null == linkedAt ? _self.linkedAt : linkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,accountName: freezed == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizParticipantAccount].
extension QuizParticipantAccountPatterns on QuizParticipantAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizParticipantAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizParticipantAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizParticipantAccount value)  $default,){
final _that = this;
switch (_that) {
case _QuizParticipantAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizParticipantAccount value)?  $default,){
final _that = this;
switch (_that) {
case _QuizParticipantAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String signInProvider, @FirestoreDateTimeConverter()  DateTime linkedAt,  String? email,  String? accountName,  String? photoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizParticipantAccount() when $default != null:
return $default(_that.uid,_that.signInProvider,_that.linkedAt,_that.email,_that.accountName,_that.photoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String signInProvider, @FirestoreDateTimeConverter()  DateTime linkedAt,  String? email,  String? accountName,  String? photoUrl)  $default,) {final _that = this;
switch (_that) {
case _QuizParticipantAccount():
return $default(_that.uid,_that.signInProvider,_that.linkedAt,_that.email,_that.accountName,_that.photoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String signInProvider, @FirestoreDateTimeConverter()  DateTime linkedAt,  String? email,  String? accountName,  String? photoUrl)?  $default,) {final _that = this;
switch (_that) {
case _QuizParticipantAccount() when $default != null:
return $default(_that.uid,_that.signInProvider,_that.linkedAt,_that.email,_that.accountName,_that.photoUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizParticipantAccount extends QuizParticipantAccount {
  const _QuizParticipantAccount({required this.uid, required this.signInProvider, @FirestoreDateTimeConverter() required this.linkedAt, this.email, this.accountName, this.photoUrl}): super._();
  factory _QuizParticipantAccount.fromJson(Map<String, dynamic> json) => _$QuizParticipantAccountFromJson(json);

@override final  String uid;
@override final  String signInProvider;
@override@FirestoreDateTimeConverter() final  DateTime linkedAt;
@override final  String? email;
@override final  String? accountName;
@override final  String? photoUrl;

/// Create a copy of QuizParticipantAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizParticipantAccountCopyWith<_QuizParticipantAccount> get copyWith => __$QuizParticipantAccountCopyWithImpl<_QuizParticipantAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizParticipantAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizParticipantAccount&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.signInProvider, signInProvider) || other.signInProvider == signInProvider)&&(identical(other.linkedAt, linkedAt) || other.linkedAt == linkedAt)&&(identical(other.email, email) || other.email == email)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,signInProvider,linkedAt,email,accountName,photoUrl);

@override
String toString() {
  return 'QuizParticipantAccount(uid: $uid, signInProvider: $signInProvider, linkedAt: $linkedAt, email: $email, accountName: $accountName, photoUrl: $photoUrl)';
}


}

/// @nodoc
abstract mixin class _$QuizParticipantAccountCopyWith<$Res> implements $QuizParticipantAccountCopyWith<$Res> {
  factory _$QuizParticipantAccountCopyWith(_QuizParticipantAccount value, $Res Function(_QuizParticipantAccount) _then) = __$QuizParticipantAccountCopyWithImpl;
@override @useResult
$Res call({
 String uid, String signInProvider,@FirestoreDateTimeConverter() DateTime linkedAt, String? email, String? accountName, String? photoUrl
});




}
/// @nodoc
class __$QuizParticipantAccountCopyWithImpl<$Res>
    implements _$QuizParticipantAccountCopyWith<$Res> {
  __$QuizParticipantAccountCopyWithImpl(this._self, this._then);

  final _QuizParticipantAccount _self;
  final $Res Function(_QuizParticipantAccount) _then;

/// Create a copy of QuizParticipantAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? signInProvider = null,Object? linkedAt = null,Object? email = freezed,Object? accountName = freezed,Object? photoUrl = freezed,}) {
  return _then(_QuizParticipantAccount(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,signInProvider: null == signInProvider ? _self.signInProvider : signInProvider // ignore: cast_nullable_to_non_nullable
as String,linkedAt: null == linkedAt ? _self.linkedAt : linkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,accountName: freezed == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
