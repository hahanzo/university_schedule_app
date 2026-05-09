// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lesson_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LessonDto {

 String get groupId; String get subjectName; String get teacherName; String get teacherId; String get roomName; String get roomId; int get dayOfWeek; int get lessonNumber; String get timeStart; String get timeEnd; String get type; String get weekType; bool get isModification;
/// Create a copy of LessonDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonDtoCopyWith<LessonDto> get copyWith => _$LessonDtoCopyWithImpl<LessonDto>(this as LessonDto, _$identity);

  /// Serializes this LessonDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonDto&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.lessonNumber, lessonNumber) || other.lessonNumber == lessonNumber)&&(identical(other.timeStart, timeStart) || other.timeStart == timeStart)&&(identical(other.timeEnd, timeEnd) || other.timeEnd == timeEnd)&&(identical(other.type, type) || other.type == type)&&(identical(other.weekType, weekType) || other.weekType == weekType)&&(identical(other.isModification, isModification) || other.isModification == isModification));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupId,subjectName,teacherName,teacherId,roomName,roomId,dayOfWeek,lessonNumber,timeStart,timeEnd,type,weekType,isModification);

@override
String toString() {
  return 'LessonDto(groupId: $groupId, subjectName: $subjectName, teacherName: $teacherName, teacherId: $teacherId, roomName: $roomName, roomId: $roomId, dayOfWeek: $dayOfWeek, lessonNumber: $lessonNumber, timeStart: $timeStart, timeEnd: $timeEnd, type: $type, weekType: $weekType, isModification: $isModification)';
}


}

/// @nodoc
abstract mixin class $LessonDtoCopyWith<$Res>  {
  factory $LessonDtoCopyWith(LessonDto value, $Res Function(LessonDto) _then) = _$LessonDtoCopyWithImpl;
@useResult
$Res call({
 String groupId, String subjectName, String teacherName, String teacherId, String roomName, String roomId, int dayOfWeek, int lessonNumber, String timeStart, String timeEnd, String type, String weekType, bool isModification
});




}
/// @nodoc
class _$LessonDtoCopyWithImpl<$Res>
    implements $LessonDtoCopyWith<$Res> {
  _$LessonDtoCopyWithImpl(this._self, this._then);

  final LessonDto _self;
  final $Res Function(LessonDto) _then;

/// Create a copy of LessonDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? subjectName = null,Object? teacherName = null,Object? teacherId = null,Object? roomName = null,Object? roomId = null,Object? dayOfWeek = null,Object? lessonNumber = null,Object? timeStart = null,Object? timeEnd = null,Object? type = null,Object? weekType = null,Object? isModification = null,}) {
  return _then(_self.copyWith(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,teacherName: null == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,lessonNumber: null == lessonNumber ? _self.lessonNumber : lessonNumber // ignore: cast_nullable_to_non_nullable
as int,timeStart: null == timeStart ? _self.timeStart : timeStart // ignore: cast_nullable_to_non_nullable
as String,timeEnd: null == timeEnd ? _self.timeEnd : timeEnd // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,weekType: null == weekType ? _self.weekType : weekType // ignore: cast_nullable_to_non_nullable
as String,isModification: null == isModification ? _self.isModification : isModification // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonDto].
extension LessonDtoPatterns on LessonDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonDto value)  $default,){
final _that = this;
switch (_that) {
case _LessonDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonDto value)?  $default,){
final _that = this;
switch (_that) {
case _LessonDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String groupId,  String subjectName,  String teacherName,  String teacherId,  String roomName,  String roomId,  int dayOfWeek,  int lessonNumber,  String timeStart,  String timeEnd,  String type,  String weekType,  bool isModification)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonDto() when $default != null:
return $default(_that.groupId,_that.subjectName,_that.teacherName,_that.teacherId,_that.roomName,_that.roomId,_that.dayOfWeek,_that.lessonNumber,_that.timeStart,_that.timeEnd,_that.type,_that.weekType,_that.isModification);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String groupId,  String subjectName,  String teacherName,  String teacherId,  String roomName,  String roomId,  int dayOfWeek,  int lessonNumber,  String timeStart,  String timeEnd,  String type,  String weekType,  bool isModification)  $default,) {final _that = this;
switch (_that) {
case _LessonDto():
return $default(_that.groupId,_that.subjectName,_that.teacherName,_that.teacherId,_that.roomName,_that.roomId,_that.dayOfWeek,_that.lessonNumber,_that.timeStart,_that.timeEnd,_that.type,_that.weekType,_that.isModification);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String groupId,  String subjectName,  String teacherName,  String teacherId,  String roomName,  String roomId,  int dayOfWeek,  int lessonNumber,  String timeStart,  String timeEnd,  String type,  String weekType,  bool isModification)?  $default,) {final _that = this;
switch (_that) {
case _LessonDto() when $default != null:
return $default(_that.groupId,_that.subjectName,_that.teacherName,_that.teacherId,_that.roomName,_that.roomId,_that.dayOfWeek,_that.lessonNumber,_that.timeStart,_that.timeEnd,_that.type,_that.weekType,_that.isModification);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonDto implements LessonDto {
  const _LessonDto({required this.groupId, required this.subjectName, required this.teacherName, required this.teacherId, required this.roomName, required this.roomId, required this.dayOfWeek, required this.lessonNumber, required this.timeStart, required this.timeEnd, required this.type, required this.weekType, this.isModification = false});
  factory _LessonDto.fromJson(Map<String, dynamic> json) => _$LessonDtoFromJson(json);

@override final  String groupId;
@override final  String subjectName;
@override final  String teacherName;
@override final  String teacherId;
@override final  String roomName;
@override final  String roomId;
@override final  int dayOfWeek;
@override final  int lessonNumber;
@override final  String timeStart;
@override final  String timeEnd;
@override final  String type;
@override final  String weekType;
@override@JsonKey() final  bool isModification;

/// Create a copy of LessonDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonDtoCopyWith<_LessonDto> get copyWith => __$LessonDtoCopyWithImpl<_LessonDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonDto&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.lessonNumber, lessonNumber) || other.lessonNumber == lessonNumber)&&(identical(other.timeStart, timeStart) || other.timeStart == timeStart)&&(identical(other.timeEnd, timeEnd) || other.timeEnd == timeEnd)&&(identical(other.type, type) || other.type == type)&&(identical(other.weekType, weekType) || other.weekType == weekType)&&(identical(other.isModification, isModification) || other.isModification == isModification));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupId,subjectName,teacherName,teacherId,roomName,roomId,dayOfWeek,lessonNumber,timeStart,timeEnd,type,weekType,isModification);

@override
String toString() {
  return 'LessonDto(groupId: $groupId, subjectName: $subjectName, teacherName: $teacherName, teacherId: $teacherId, roomName: $roomName, roomId: $roomId, dayOfWeek: $dayOfWeek, lessonNumber: $lessonNumber, timeStart: $timeStart, timeEnd: $timeEnd, type: $type, weekType: $weekType, isModification: $isModification)';
}


}

/// @nodoc
abstract mixin class _$LessonDtoCopyWith<$Res> implements $LessonDtoCopyWith<$Res> {
  factory _$LessonDtoCopyWith(_LessonDto value, $Res Function(_LessonDto) _then) = __$LessonDtoCopyWithImpl;
@override @useResult
$Res call({
 String groupId, String subjectName, String teacherName, String teacherId, String roomName, String roomId, int dayOfWeek, int lessonNumber, String timeStart, String timeEnd, String type, String weekType, bool isModification
});




}
/// @nodoc
class __$LessonDtoCopyWithImpl<$Res>
    implements _$LessonDtoCopyWith<$Res> {
  __$LessonDtoCopyWithImpl(this._self, this._then);

  final _LessonDto _self;
  final $Res Function(_LessonDto) _then;

/// Create a copy of LessonDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? subjectName = null,Object? teacherName = null,Object? teacherId = null,Object? roomName = null,Object? roomId = null,Object? dayOfWeek = null,Object? lessonNumber = null,Object? timeStart = null,Object? timeEnd = null,Object? type = null,Object? weekType = null,Object? isModification = null,}) {
  return _then(_LessonDto(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,teacherName: null == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: null == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int,lessonNumber: null == lessonNumber ? _self.lessonNumber : lessonNumber // ignore: cast_nullable_to_non_nullable
as int,timeStart: null == timeStart ? _self.timeStart : timeStart // ignore: cast_nullable_to_non_nullable
as String,timeEnd: null == timeEnd ? _self.timeEnd : timeEnd // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,weekType: null == weekType ? _self.weekType : weekType // ignore: cast_nullable_to_non_nullable
as String,isModification: null == isModification ? _self.isModification : isModification // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
