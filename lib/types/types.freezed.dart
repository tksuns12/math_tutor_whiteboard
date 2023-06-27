// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'types.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

BatchDrawingData _$BatchDrawingDataFromJson(Map<String, dynamic> json) {
  return _BatchDrawingData.fromJson(json);
}

/// @nodoc
mixin _$BatchDrawingData {
  String get userID => throw _privateConstructorUsedError;
  Map<String, List<List<DrawingData>>> get drawingData =>
      throw _privateConstructorUsedError;
  Map<String, int> get limitCursor => throw _privateConstructorUsedError;
  Map<String, Map<int, int>> get deletedStrokes =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BatchDrawingDataCopyWith<BatchDrawingData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BatchDrawingDataCopyWith<$Res> {
  factory $BatchDrawingDataCopyWith(
          BatchDrawingData value, $Res Function(BatchDrawingData) then) =
      _$BatchDrawingDataCopyWithImpl<$Res, BatchDrawingData>;
  @useResult
  $Res call(
      {String userID,
      Map<String, List<List<DrawingData>>> drawingData,
      Map<String, int> limitCursor,
      Map<String, Map<int, int>> deletedStrokes});
}

/// @nodoc
class _$BatchDrawingDataCopyWithImpl<$Res, $Val extends BatchDrawingData>
    implements $BatchDrawingDataCopyWith<$Res> {
  _$BatchDrawingDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userID = null,
    Object? drawingData = null,
    Object? limitCursor = null,
    Object? deletedStrokes = null,
  }) {
    return _then(_value.copyWith(
      userID: null == userID
          ? _value.userID
          : userID // ignore: cast_nullable_to_non_nullable
              as String,
      drawingData: null == drawingData
          ? _value.drawingData
          : drawingData // ignore: cast_nullable_to_non_nullable
              as Map<String, List<List<DrawingData>>>,
      limitCursor: null == limitCursor
          ? _value.limitCursor
          : limitCursor // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      deletedStrokes: null == deletedStrokes
          ? _value.deletedStrokes
          : deletedStrokes // ignore: cast_nullable_to_non_nullable
              as Map<String, Map<int, int>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_BatchDrawingDataCopyWith<$Res>
    implements $BatchDrawingDataCopyWith<$Res> {
  factory _$$_BatchDrawingDataCopyWith(
          _$_BatchDrawingData value, $Res Function(_$_BatchDrawingData) then) =
      __$$_BatchDrawingDataCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userID,
      Map<String, List<List<DrawingData>>> drawingData,
      Map<String, int> limitCursor,
      Map<String, Map<int, int>> deletedStrokes});
}

/// @nodoc
class __$$_BatchDrawingDataCopyWithImpl<$Res>
    extends _$BatchDrawingDataCopyWithImpl<$Res, _$_BatchDrawingData>
    implements _$$_BatchDrawingDataCopyWith<$Res> {
  __$$_BatchDrawingDataCopyWithImpl(
      _$_BatchDrawingData _value, $Res Function(_$_BatchDrawingData) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userID = null,
    Object? drawingData = null,
    Object? limitCursor = null,
    Object? deletedStrokes = null,
  }) {
    return _then(_$_BatchDrawingData(
      userID: null == userID
          ? _value.userID
          : userID // ignore: cast_nullable_to_non_nullable
              as String,
      drawingData: null == drawingData
          ? _value._drawingData
          : drawingData // ignore: cast_nullable_to_non_nullable
              as Map<String, List<List<DrawingData>>>,
      limitCursor: null == limitCursor
          ? _value._limitCursor
          : limitCursor // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      deletedStrokes: null == deletedStrokes
          ? _value._deletedStrokes
          : deletedStrokes // ignore: cast_nullable_to_non_nullable
              as Map<String, Map<int, int>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_BatchDrawingData implements _BatchDrawingData {
  const _$_BatchDrawingData(
      {required this.userID,
      required final Map<String, List<List<DrawingData>>> drawingData,
      required final Map<String, int> limitCursor,
      required final Map<String, Map<int, int>> deletedStrokes})
      : _drawingData = drawingData,
        _limitCursor = limitCursor,
        _deletedStrokes = deletedStrokes;

  factory _$_BatchDrawingData.fromJson(Map<String, dynamic> json) =>
      _$$_BatchDrawingDataFromJson(json);

  @override
  final String userID;
  final Map<String, List<List<DrawingData>>> _drawingData;
  @override
  Map<String, List<List<DrawingData>>> get drawingData {
    if (_drawingData is EqualUnmodifiableMapView) return _drawingData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_drawingData);
  }

  final Map<String, int> _limitCursor;
  @override
  Map<String, int> get limitCursor {
    if (_limitCursor is EqualUnmodifiableMapView) return _limitCursor;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_limitCursor);
  }

  final Map<String, Map<int, int>> _deletedStrokes;
  @override
  Map<String, Map<int, int>> get deletedStrokes {
    if (_deletedStrokes is EqualUnmodifiableMapView) return _deletedStrokes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_deletedStrokes);
  }

  @override
  String toString() {
    return 'BatchDrawingData(userID: $userID, drawingData: $drawingData, limitCursor: $limitCursor, deletedStrokes: $deletedStrokes)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_BatchDrawingData &&
            (identical(other.userID, userID) || other.userID == userID) &&
            const DeepCollectionEquality()
                .equals(other._drawingData, _drawingData) &&
            const DeepCollectionEquality()
                .equals(other._limitCursor, _limitCursor) &&
            const DeepCollectionEquality()
                .equals(other._deletedStrokes, _deletedStrokes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userID,
      const DeepCollectionEquality().hash(_drawingData),
      const DeepCollectionEquality().hash(_limitCursor),
      const DeepCollectionEquality().hash(_deletedStrokes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_BatchDrawingDataCopyWith<_$_BatchDrawingData> get copyWith =>
      __$$_BatchDrawingDataCopyWithImpl<_$_BatchDrawingData>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_BatchDrawingDataToJson(
      this,
    );
  }
}

abstract class _BatchDrawingData implements BatchDrawingData {
  const factory _BatchDrawingData(
          {required final String userID,
          required final Map<String, List<List<DrawingData>>> drawingData,
          required final Map<String, int> limitCursor,
          required final Map<String, Map<int, int>> deletedStrokes}) =
      _$_BatchDrawingData;

  factory _BatchDrawingData.fromJson(Map<String, dynamic> json) =
      _$_BatchDrawingData.fromJson;

  @override
  String get userID;
  @override
  Map<String, List<List<DrawingData>>> get drawingData;
  @override
  Map<String, int> get limitCursor;
  @override
  Map<String, Map<int, int>> get deletedStrokes;
  @override
  @JsonKey(ignore: true)
  _$$_BatchDrawingDataCopyWith<_$_BatchDrawingData> get copyWith =>
      throw _privateConstructorUsedError;
}
