// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_team.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuizTeamMember {

 String get uid; String get displayName;
/// Create a copy of QuizTeamMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizTeamMemberCopyWith<QuizTeamMember> get copyWith => _$QuizTeamMemberCopyWithImpl<QuizTeamMember>(this as QuizTeamMember, _$identity);

  /// Serializes this QuizTeamMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizTeamMember&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,displayName);

@override
String toString() {
  return 'QuizTeamMember(uid: $uid, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $QuizTeamMemberCopyWith<$Res>  {
  factory $QuizTeamMemberCopyWith(QuizTeamMember value, $Res Function(QuizTeamMember) _then) = _$QuizTeamMemberCopyWithImpl;
@useResult
$Res call({
 String uid, String displayName
});




}
/// @nodoc
class _$QuizTeamMemberCopyWithImpl<$Res>
    implements $QuizTeamMemberCopyWith<$Res> {
  _$QuizTeamMemberCopyWithImpl(this._self, this._then);

  final QuizTeamMember _self;
  final $Res Function(QuizTeamMember) _then;

/// Create a copy of QuizTeamMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? displayName = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizTeamMember].
extension QuizTeamMemberPatterns on QuizTeamMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizTeamMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizTeamMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizTeamMember value)  $default,){
final _that = this;
switch (_that) {
case _QuizTeamMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizTeamMember value)?  $default,){
final _that = this;
switch (_that) {
case _QuizTeamMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizTeamMember() when $default != null:
return $default(_that.uid,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String displayName)  $default,) {final _that = this;
switch (_that) {
case _QuizTeamMember():
return $default(_that.uid,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String displayName)?  $default,) {final _that = this;
switch (_that) {
case _QuizTeamMember() when $default != null:
return $default(_that.uid,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizTeamMember extends QuizTeamMember {
  const _QuizTeamMember({required this.uid, required this.displayName}): super._();
  factory _QuizTeamMember.fromJson(Map<String, dynamic> json) => _$QuizTeamMemberFromJson(json);

@override final  String uid;
@override final  String displayName;

/// Create a copy of QuizTeamMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizTeamMemberCopyWith<_QuizTeamMember> get copyWith => __$QuizTeamMemberCopyWithImpl<_QuizTeamMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizTeamMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizTeamMember&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,displayName);

@override
String toString() {
  return 'QuizTeamMember(uid: $uid, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$QuizTeamMemberCopyWith<$Res> implements $QuizTeamMemberCopyWith<$Res> {
  factory _$QuizTeamMemberCopyWith(_QuizTeamMember value, $Res Function(_QuizTeamMember) _then) = __$QuizTeamMemberCopyWithImpl;
@override @useResult
$Res call({
 String uid, String displayName
});




}
/// @nodoc
class __$QuizTeamMemberCopyWithImpl<$Res>
    implements _$QuizTeamMemberCopyWith<$Res> {
  __$QuizTeamMemberCopyWithImpl(this._self, this._then);

  final _QuizTeamMember _self;
  final $Res Function(_QuizTeamMember) _then;

/// Create a copy of QuizTeamMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? displayName = null,}) {
  return _then(_QuizTeamMember(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$QuizTeam {

 String get id; int get tableNumber; String get name; List<String> get memberUids; List<QuizTeamMember> get members; int get score; int? get rank; List<String> get perfectSponsorIds;
/// Create a copy of QuizTeam
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizTeamCopyWith<QuizTeam> get copyWith => _$QuizTeamCopyWithImpl<QuizTeam>(this as QuizTeam, _$identity);

  /// Serializes this QuizTeam to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizTeam&&(identical(other.id, id) || other.id == id)&&(identical(other.tableNumber, tableNumber) || other.tableNumber == tableNumber)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.memberUids, memberUids)&&const DeepCollectionEquality().equals(other.members, members)&&(identical(other.score, score) || other.score == score)&&(identical(other.rank, rank) || other.rank == rank)&&const DeepCollectionEquality().equals(other.perfectSponsorIds, perfectSponsorIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tableNumber,name,const DeepCollectionEquality().hash(memberUids),const DeepCollectionEquality().hash(members),score,rank,const DeepCollectionEquality().hash(perfectSponsorIds));

@override
String toString() {
  return 'QuizTeam(id: $id, tableNumber: $tableNumber, name: $name, memberUids: $memberUids, members: $members, score: $score, rank: $rank, perfectSponsorIds: $perfectSponsorIds)';
}


}

/// @nodoc
abstract mixin class $QuizTeamCopyWith<$Res>  {
  factory $QuizTeamCopyWith(QuizTeam value, $Res Function(QuizTeam) _then) = _$QuizTeamCopyWithImpl;
@useResult
$Res call({
 String id, int tableNumber, String name, List<String> memberUids, List<QuizTeamMember> members, int score, int? rank, List<String> perfectSponsorIds
});




}
/// @nodoc
class _$QuizTeamCopyWithImpl<$Res>
    implements $QuizTeamCopyWith<$Res> {
  _$QuizTeamCopyWithImpl(this._self, this._then);

  final QuizTeam _self;
  final $Res Function(QuizTeam) _then;

/// Create a copy of QuizTeam
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tableNumber = null,Object? name = null,Object? memberUids = null,Object? members = null,Object? score = null,Object? rank = freezed,Object? perfectSponsorIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tableNumber: null == tableNumber ? _self.tableNumber : tableNumber // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberUids: null == memberUids ? _self.memberUids : memberUids // ignore: cast_nullable_to_non_nullable
as List<String>,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<QuizTeamMember>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int?,perfectSponsorIds: null == perfectSponsorIds ? _self.perfectSponsorIds : perfectSponsorIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizTeam].
extension QuizTeamPatterns on QuizTeam {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizTeam value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizTeam() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizTeam value)  $default,){
final _that = this;
switch (_that) {
case _QuizTeam():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizTeam value)?  $default,){
final _that = this;
switch (_that) {
case _QuizTeam() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int tableNumber,  String name,  List<String> memberUids,  List<QuizTeamMember> members,  int score,  int? rank,  List<String> perfectSponsorIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizTeam() when $default != null:
return $default(_that.id,_that.tableNumber,_that.name,_that.memberUids,_that.members,_that.score,_that.rank,_that.perfectSponsorIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int tableNumber,  String name,  List<String> memberUids,  List<QuizTeamMember> members,  int score,  int? rank,  List<String> perfectSponsorIds)  $default,) {final _that = this;
switch (_that) {
case _QuizTeam():
return $default(_that.id,_that.tableNumber,_that.name,_that.memberUids,_that.members,_that.score,_that.rank,_that.perfectSponsorIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int tableNumber,  String name,  List<String> memberUids,  List<QuizTeamMember> members,  int score,  int? rank,  List<String> perfectSponsorIds)?  $default,) {final _that = this;
switch (_that) {
case _QuizTeam() when $default != null:
return $default(_that.id,_that.tableNumber,_that.name,_that.memberUids,_that.members,_that.score,_that.rank,_that.perfectSponsorIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizTeam extends QuizTeam {
  const _QuizTeam({required this.id, required this.tableNumber, required this.name, final  List<String> memberUids = const [], final  List<QuizTeamMember> members = const [], this.score = 0, this.rank, final  List<String> perfectSponsorIds = const []}): _memberUids = memberUids,_members = members,_perfectSponsorIds = perfectSponsorIds,super._();
  factory _QuizTeam.fromJson(Map<String, dynamic> json) => _$QuizTeamFromJson(json);

@override final  String id;
@override final  int tableNumber;
@override final  String name;
 final  List<String> _memberUids;
@override@JsonKey() List<String> get memberUids {
  if (_memberUids is EqualUnmodifiableListView) return _memberUids;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberUids);
}

 final  List<QuizTeamMember> _members;
@override@JsonKey() List<QuizTeamMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

@override@JsonKey() final  int score;
@override final  int? rank;
 final  List<String> _perfectSponsorIds;
@override@JsonKey() List<String> get perfectSponsorIds {
  if (_perfectSponsorIds is EqualUnmodifiableListView) return _perfectSponsorIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_perfectSponsorIds);
}


/// Create a copy of QuizTeam
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizTeamCopyWith<_QuizTeam> get copyWith => __$QuizTeamCopyWithImpl<_QuizTeam>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizTeamToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizTeam&&(identical(other.id, id) || other.id == id)&&(identical(other.tableNumber, tableNumber) || other.tableNumber == tableNumber)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._memberUids, _memberUids)&&const DeepCollectionEquality().equals(other._members, _members)&&(identical(other.score, score) || other.score == score)&&(identical(other.rank, rank) || other.rank == rank)&&const DeepCollectionEquality().equals(other._perfectSponsorIds, _perfectSponsorIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tableNumber,name,const DeepCollectionEquality().hash(_memberUids),const DeepCollectionEquality().hash(_members),score,rank,const DeepCollectionEquality().hash(_perfectSponsorIds));

@override
String toString() {
  return 'QuizTeam(id: $id, tableNumber: $tableNumber, name: $name, memberUids: $memberUids, members: $members, score: $score, rank: $rank, perfectSponsorIds: $perfectSponsorIds)';
}


}

/// @nodoc
abstract mixin class _$QuizTeamCopyWith<$Res> implements $QuizTeamCopyWith<$Res> {
  factory _$QuizTeamCopyWith(_QuizTeam value, $Res Function(_QuizTeam) _then) = __$QuizTeamCopyWithImpl;
@override @useResult
$Res call({
 String id, int tableNumber, String name, List<String> memberUids, List<QuizTeamMember> members, int score, int? rank, List<String> perfectSponsorIds
});




}
/// @nodoc
class __$QuizTeamCopyWithImpl<$Res>
    implements _$QuizTeamCopyWith<$Res> {
  __$QuizTeamCopyWithImpl(this._self, this._then);

  final _QuizTeam _self;
  final $Res Function(_QuizTeam) _then;

/// Create a copy of QuizTeam
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tableNumber = null,Object? name = null,Object? memberUids = null,Object? members = null,Object? score = null,Object? rank = freezed,Object? perfectSponsorIds = null,}) {
  return _then(_QuizTeam(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tableNumber: null == tableNumber ? _self.tableNumber : tableNumber // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberUids: null == memberUids ? _self._memberUids : memberUids // ignore: cast_nullable_to_non_nullable
as List<String>,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<QuizTeamMember>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int?,perfectSponsorIds: null == perfectSponsorIds ? _self._perfectSponsorIds : perfectSponsorIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
