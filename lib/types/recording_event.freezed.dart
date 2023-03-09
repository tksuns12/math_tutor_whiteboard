// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recording_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$RecordingEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function() recording,
    required TResult Function() pause,
    required TResult Function() resume,
    required TResult Function(File recordedFile) finished,
    required TResult Function() cancelled,
    required TResult Function(Object error) failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function()? recording,
    TResult? Function()? pause,
    TResult? Function()? resume,
    TResult? Function(File recordedFile)? finished,
    TResult? Function()? cancelled,
    TResult? Function(Object error)? failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function()? recording,
    TResult Function()? pause,
    TResult Function()? resume,
    TResult Function(File recordedFile)? finished,
    TResult Function()? cancelled,
    TResult Function(Object error)? failed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RecordingInit value) init,
    required TResult Function(RecordingOngoing value) recording,
    required TResult Function(RecordingPause value) pause,
    required TResult Function(RecordingResume value) resume,
    required TResult Function(RecordingFinished value) finished,
    required TResult Function(RecordingCancelled value) cancelled,
    required TResult Function(RecordingFailed value) failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RecordingInit value)? init,
    TResult? Function(RecordingOngoing value)? recording,
    TResult? Function(RecordingPause value)? pause,
    TResult? Function(RecordingResume value)? resume,
    TResult? Function(RecordingFinished value)? finished,
    TResult? Function(RecordingCancelled value)? cancelled,
    TResult? Function(RecordingFailed value)? failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RecordingInit value)? init,
    TResult Function(RecordingOngoing value)? recording,
    TResult Function(RecordingPause value)? pause,
    TResult Function(RecordingResume value)? resume,
    TResult Function(RecordingFinished value)? finished,
    TResult Function(RecordingCancelled value)? cancelled,
    TResult Function(RecordingFailed value)? failed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecordingEventCopyWith<$Res> {
  factory $RecordingEventCopyWith(
          RecordingEvent value, $Res Function(RecordingEvent) then) =
      _$RecordingEventCopyWithImpl<$Res, RecordingEvent>;
}

/// @nodoc
class _$RecordingEventCopyWithImpl<$Res, $Val extends RecordingEvent>
    implements $RecordingEventCopyWith<$Res> {
  _$RecordingEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$RecordingInitCopyWith<$Res> {
  factory _$$RecordingInitCopyWith(
          _$RecordingInit value, $Res Function(_$RecordingInit) then) =
      __$$RecordingInitCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RecordingInitCopyWithImpl<$Res>
    extends _$RecordingEventCopyWithImpl<$Res, _$RecordingInit>
    implements _$$RecordingInitCopyWith<$Res> {
  __$$RecordingInitCopyWithImpl(
      _$RecordingInit _value, $Res Function(_$RecordingInit) _then)
      : super(_value, _then);
}

/// @nodoc

class _$RecordingInit implements RecordingInit {
  const _$RecordingInit();

  @override
  String toString() {
    return 'RecordingEvent.init()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RecordingInit);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function() recording,
    required TResult Function() pause,
    required TResult Function() resume,
    required TResult Function(File recordedFile) finished,
    required TResult Function() cancelled,
    required TResult Function(Object error) failed,
  }) {
    return init();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function()? recording,
    TResult? Function()? pause,
    TResult? Function()? resume,
    TResult? Function(File recordedFile)? finished,
    TResult? Function()? cancelled,
    TResult? Function(Object error)? failed,
  }) {
    return init?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function()? recording,
    TResult Function()? pause,
    TResult Function()? resume,
    TResult Function(File recordedFile)? finished,
    TResult Function()? cancelled,
    TResult Function(Object error)? failed,
    required TResult orElse(),
  }) {
    if (init != null) {
      return init();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RecordingInit value) init,
    required TResult Function(RecordingOngoing value) recording,
    required TResult Function(RecordingPause value) pause,
    required TResult Function(RecordingResume value) resume,
    required TResult Function(RecordingFinished value) finished,
    required TResult Function(RecordingCancelled value) cancelled,
    required TResult Function(RecordingFailed value) failed,
  }) {
    return init(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RecordingInit value)? init,
    TResult? Function(RecordingOngoing value)? recording,
    TResult? Function(RecordingPause value)? pause,
    TResult? Function(RecordingResume value)? resume,
    TResult? Function(RecordingFinished value)? finished,
    TResult? Function(RecordingCancelled value)? cancelled,
    TResult? Function(RecordingFailed value)? failed,
  }) {
    return init?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RecordingInit value)? init,
    TResult Function(RecordingOngoing value)? recording,
    TResult Function(RecordingPause value)? pause,
    TResult Function(RecordingResume value)? resume,
    TResult Function(RecordingFinished value)? finished,
    TResult Function(RecordingCancelled value)? cancelled,
    TResult Function(RecordingFailed value)? failed,
    required TResult orElse(),
  }) {
    if (init != null) {
      return init(this);
    }
    return orElse();
  }
}

abstract class RecordingInit implements RecordingEvent {
  const factory RecordingInit() = _$RecordingInit;
}

/// @nodoc
abstract class _$$RecordingOngoingCopyWith<$Res> {
  factory _$$RecordingOngoingCopyWith(
          _$RecordingOngoing value, $Res Function(_$RecordingOngoing) then) =
      __$$RecordingOngoingCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RecordingOngoingCopyWithImpl<$Res>
    extends _$RecordingEventCopyWithImpl<$Res, _$RecordingOngoing>
    implements _$$RecordingOngoingCopyWith<$Res> {
  __$$RecordingOngoingCopyWithImpl(
      _$RecordingOngoing _value, $Res Function(_$RecordingOngoing) _then)
      : super(_value, _then);
}

/// @nodoc

class _$RecordingOngoing implements RecordingOngoing {
  const _$RecordingOngoing();

  @override
  String toString() {
    return 'RecordingEvent.recording()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RecordingOngoing);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function() recording,
    required TResult Function() pause,
    required TResult Function() resume,
    required TResult Function(File recordedFile) finished,
    required TResult Function() cancelled,
    required TResult Function(Object error) failed,
  }) {
    return recording();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function()? recording,
    TResult? Function()? pause,
    TResult? Function()? resume,
    TResult? Function(File recordedFile)? finished,
    TResult? Function()? cancelled,
    TResult? Function(Object error)? failed,
  }) {
    return recording?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function()? recording,
    TResult Function()? pause,
    TResult Function()? resume,
    TResult Function(File recordedFile)? finished,
    TResult Function()? cancelled,
    TResult Function(Object error)? failed,
    required TResult orElse(),
  }) {
    if (recording != null) {
      return recording();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RecordingInit value) init,
    required TResult Function(RecordingOngoing value) recording,
    required TResult Function(RecordingPause value) pause,
    required TResult Function(RecordingResume value) resume,
    required TResult Function(RecordingFinished value) finished,
    required TResult Function(RecordingCancelled value) cancelled,
    required TResult Function(RecordingFailed value) failed,
  }) {
    return recording(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RecordingInit value)? init,
    TResult? Function(RecordingOngoing value)? recording,
    TResult? Function(RecordingPause value)? pause,
    TResult? Function(RecordingResume value)? resume,
    TResult? Function(RecordingFinished value)? finished,
    TResult? Function(RecordingCancelled value)? cancelled,
    TResult? Function(RecordingFailed value)? failed,
  }) {
    return recording?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RecordingInit value)? init,
    TResult Function(RecordingOngoing value)? recording,
    TResult Function(RecordingPause value)? pause,
    TResult Function(RecordingResume value)? resume,
    TResult Function(RecordingFinished value)? finished,
    TResult Function(RecordingCancelled value)? cancelled,
    TResult Function(RecordingFailed value)? failed,
    required TResult orElse(),
  }) {
    if (recording != null) {
      return recording(this);
    }
    return orElse();
  }
}

abstract class RecordingOngoing implements RecordingEvent {
  const factory RecordingOngoing() = _$RecordingOngoing;
}

/// @nodoc
abstract class _$$RecordingPauseCopyWith<$Res> {
  factory _$$RecordingPauseCopyWith(
          _$RecordingPause value, $Res Function(_$RecordingPause) then) =
      __$$RecordingPauseCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RecordingPauseCopyWithImpl<$Res>
    extends _$RecordingEventCopyWithImpl<$Res, _$RecordingPause>
    implements _$$RecordingPauseCopyWith<$Res> {
  __$$RecordingPauseCopyWithImpl(
      _$RecordingPause _value, $Res Function(_$RecordingPause) _then)
      : super(_value, _then);
}

/// @nodoc

class _$RecordingPause implements RecordingPause {
  const _$RecordingPause();

  @override
  String toString() {
    return 'RecordingEvent.pause()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RecordingPause);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function() recording,
    required TResult Function() pause,
    required TResult Function() resume,
    required TResult Function(File recordedFile) finished,
    required TResult Function() cancelled,
    required TResult Function(Object error) failed,
  }) {
    return pause();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function()? recording,
    TResult? Function()? pause,
    TResult? Function()? resume,
    TResult? Function(File recordedFile)? finished,
    TResult? Function()? cancelled,
    TResult? Function(Object error)? failed,
  }) {
    return pause?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function()? recording,
    TResult Function()? pause,
    TResult Function()? resume,
    TResult Function(File recordedFile)? finished,
    TResult Function()? cancelled,
    TResult Function(Object error)? failed,
    required TResult orElse(),
  }) {
    if (pause != null) {
      return pause();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RecordingInit value) init,
    required TResult Function(RecordingOngoing value) recording,
    required TResult Function(RecordingPause value) pause,
    required TResult Function(RecordingResume value) resume,
    required TResult Function(RecordingFinished value) finished,
    required TResult Function(RecordingCancelled value) cancelled,
    required TResult Function(RecordingFailed value) failed,
  }) {
    return pause(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RecordingInit value)? init,
    TResult? Function(RecordingOngoing value)? recording,
    TResult? Function(RecordingPause value)? pause,
    TResult? Function(RecordingResume value)? resume,
    TResult? Function(RecordingFinished value)? finished,
    TResult? Function(RecordingCancelled value)? cancelled,
    TResult? Function(RecordingFailed value)? failed,
  }) {
    return pause?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RecordingInit value)? init,
    TResult Function(RecordingOngoing value)? recording,
    TResult Function(RecordingPause value)? pause,
    TResult Function(RecordingResume value)? resume,
    TResult Function(RecordingFinished value)? finished,
    TResult Function(RecordingCancelled value)? cancelled,
    TResult Function(RecordingFailed value)? failed,
    required TResult orElse(),
  }) {
    if (pause != null) {
      return pause(this);
    }
    return orElse();
  }
}

abstract class RecordingPause implements RecordingEvent {
  const factory RecordingPause() = _$RecordingPause;
}

/// @nodoc
abstract class _$$RecordingResumeCopyWith<$Res> {
  factory _$$RecordingResumeCopyWith(
          _$RecordingResume value, $Res Function(_$RecordingResume) then) =
      __$$RecordingResumeCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RecordingResumeCopyWithImpl<$Res>
    extends _$RecordingEventCopyWithImpl<$Res, _$RecordingResume>
    implements _$$RecordingResumeCopyWith<$Res> {
  __$$RecordingResumeCopyWithImpl(
      _$RecordingResume _value, $Res Function(_$RecordingResume) _then)
      : super(_value, _then);
}

/// @nodoc

class _$RecordingResume implements RecordingResume {
  const _$RecordingResume();

  @override
  String toString() {
    return 'RecordingEvent.resume()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RecordingResume);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function() recording,
    required TResult Function() pause,
    required TResult Function() resume,
    required TResult Function(File recordedFile) finished,
    required TResult Function() cancelled,
    required TResult Function(Object error) failed,
  }) {
    return resume();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function()? recording,
    TResult? Function()? pause,
    TResult? Function()? resume,
    TResult? Function(File recordedFile)? finished,
    TResult? Function()? cancelled,
    TResult? Function(Object error)? failed,
  }) {
    return resume?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function()? recording,
    TResult Function()? pause,
    TResult Function()? resume,
    TResult Function(File recordedFile)? finished,
    TResult Function()? cancelled,
    TResult Function(Object error)? failed,
    required TResult orElse(),
  }) {
    if (resume != null) {
      return resume();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RecordingInit value) init,
    required TResult Function(RecordingOngoing value) recording,
    required TResult Function(RecordingPause value) pause,
    required TResult Function(RecordingResume value) resume,
    required TResult Function(RecordingFinished value) finished,
    required TResult Function(RecordingCancelled value) cancelled,
    required TResult Function(RecordingFailed value) failed,
  }) {
    return resume(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RecordingInit value)? init,
    TResult? Function(RecordingOngoing value)? recording,
    TResult? Function(RecordingPause value)? pause,
    TResult? Function(RecordingResume value)? resume,
    TResult? Function(RecordingFinished value)? finished,
    TResult? Function(RecordingCancelled value)? cancelled,
    TResult? Function(RecordingFailed value)? failed,
  }) {
    return resume?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RecordingInit value)? init,
    TResult Function(RecordingOngoing value)? recording,
    TResult Function(RecordingPause value)? pause,
    TResult Function(RecordingResume value)? resume,
    TResult Function(RecordingFinished value)? finished,
    TResult Function(RecordingCancelled value)? cancelled,
    TResult Function(RecordingFailed value)? failed,
    required TResult orElse(),
  }) {
    if (resume != null) {
      return resume(this);
    }
    return orElse();
  }
}

abstract class RecordingResume implements RecordingEvent {
  const factory RecordingResume() = _$RecordingResume;
}

/// @nodoc
abstract class _$$RecordingFinishedCopyWith<$Res> {
  factory _$$RecordingFinishedCopyWith(
          _$RecordingFinished value, $Res Function(_$RecordingFinished) then) =
      __$$RecordingFinishedCopyWithImpl<$Res>;
  @useResult
  $Res call({File recordedFile});
}

/// @nodoc
class __$$RecordingFinishedCopyWithImpl<$Res>
    extends _$RecordingEventCopyWithImpl<$Res, _$RecordingFinished>
    implements _$$RecordingFinishedCopyWith<$Res> {
  __$$RecordingFinishedCopyWithImpl(
      _$RecordingFinished _value, $Res Function(_$RecordingFinished) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordedFile = null,
  }) {
    return _then(_$RecordingFinished(
      null == recordedFile
          ? _value.recordedFile
          : recordedFile // ignore: cast_nullable_to_non_nullable
              as File,
    ));
  }
}

/// @nodoc

class _$RecordingFinished implements RecordingFinished {
  const _$RecordingFinished(this.recordedFile);

  @override
  final File recordedFile;

  @override
  String toString() {
    return 'RecordingEvent.finished(recordedFile: $recordedFile)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecordingFinished &&
            (identical(other.recordedFile, recordedFile) ||
                other.recordedFile == recordedFile));
  }

  @override
  int get hashCode => Object.hash(runtimeType, recordedFile);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecordingFinishedCopyWith<_$RecordingFinished> get copyWith =>
      __$$RecordingFinishedCopyWithImpl<_$RecordingFinished>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function() recording,
    required TResult Function() pause,
    required TResult Function() resume,
    required TResult Function(File recordedFile) finished,
    required TResult Function() cancelled,
    required TResult Function(Object error) failed,
  }) {
    return finished(recordedFile);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function()? recording,
    TResult? Function()? pause,
    TResult? Function()? resume,
    TResult? Function(File recordedFile)? finished,
    TResult? Function()? cancelled,
    TResult? Function(Object error)? failed,
  }) {
    return finished?.call(recordedFile);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function()? recording,
    TResult Function()? pause,
    TResult Function()? resume,
    TResult Function(File recordedFile)? finished,
    TResult Function()? cancelled,
    TResult Function(Object error)? failed,
    required TResult orElse(),
  }) {
    if (finished != null) {
      return finished(recordedFile);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RecordingInit value) init,
    required TResult Function(RecordingOngoing value) recording,
    required TResult Function(RecordingPause value) pause,
    required TResult Function(RecordingResume value) resume,
    required TResult Function(RecordingFinished value) finished,
    required TResult Function(RecordingCancelled value) cancelled,
    required TResult Function(RecordingFailed value) failed,
  }) {
    return finished(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RecordingInit value)? init,
    TResult? Function(RecordingOngoing value)? recording,
    TResult? Function(RecordingPause value)? pause,
    TResult? Function(RecordingResume value)? resume,
    TResult? Function(RecordingFinished value)? finished,
    TResult? Function(RecordingCancelled value)? cancelled,
    TResult? Function(RecordingFailed value)? failed,
  }) {
    return finished?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RecordingInit value)? init,
    TResult Function(RecordingOngoing value)? recording,
    TResult Function(RecordingPause value)? pause,
    TResult Function(RecordingResume value)? resume,
    TResult Function(RecordingFinished value)? finished,
    TResult Function(RecordingCancelled value)? cancelled,
    TResult Function(RecordingFailed value)? failed,
    required TResult orElse(),
  }) {
    if (finished != null) {
      return finished(this);
    }
    return orElse();
  }
}

abstract class RecordingFinished implements RecordingEvent {
  const factory RecordingFinished(final File recordedFile) =
      _$RecordingFinished;

  File get recordedFile;
  @JsonKey(ignore: true)
  _$$RecordingFinishedCopyWith<_$RecordingFinished> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RecordingCancelledCopyWith<$Res> {
  factory _$$RecordingCancelledCopyWith(_$RecordingCancelled value,
          $Res Function(_$RecordingCancelled) then) =
      __$$RecordingCancelledCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RecordingCancelledCopyWithImpl<$Res>
    extends _$RecordingEventCopyWithImpl<$Res, _$RecordingCancelled>
    implements _$$RecordingCancelledCopyWith<$Res> {
  __$$RecordingCancelledCopyWithImpl(
      _$RecordingCancelled _value, $Res Function(_$RecordingCancelled) _then)
      : super(_value, _then);
}

/// @nodoc

class _$RecordingCancelled implements RecordingCancelled {
  const _$RecordingCancelled();

  @override
  String toString() {
    return 'RecordingEvent.cancelled()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RecordingCancelled);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function() recording,
    required TResult Function() pause,
    required TResult Function() resume,
    required TResult Function(File recordedFile) finished,
    required TResult Function() cancelled,
    required TResult Function(Object error) failed,
  }) {
    return cancelled();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function()? recording,
    TResult? Function()? pause,
    TResult? Function()? resume,
    TResult? Function(File recordedFile)? finished,
    TResult? Function()? cancelled,
    TResult? Function(Object error)? failed,
  }) {
    return cancelled?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function()? recording,
    TResult Function()? pause,
    TResult Function()? resume,
    TResult Function(File recordedFile)? finished,
    TResult Function()? cancelled,
    TResult Function(Object error)? failed,
    required TResult orElse(),
  }) {
    if (cancelled != null) {
      return cancelled();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RecordingInit value) init,
    required TResult Function(RecordingOngoing value) recording,
    required TResult Function(RecordingPause value) pause,
    required TResult Function(RecordingResume value) resume,
    required TResult Function(RecordingFinished value) finished,
    required TResult Function(RecordingCancelled value) cancelled,
    required TResult Function(RecordingFailed value) failed,
  }) {
    return cancelled(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RecordingInit value)? init,
    TResult? Function(RecordingOngoing value)? recording,
    TResult? Function(RecordingPause value)? pause,
    TResult? Function(RecordingResume value)? resume,
    TResult? Function(RecordingFinished value)? finished,
    TResult? Function(RecordingCancelled value)? cancelled,
    TResult? Function(RecordingFailed value)? failed,
  }) {
    return cancelled?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RecordingInit value)? init,
    TResult Function(RecordingOngoing value)? recording,
    TResult Function(RecordingPause value)? pause,
    TResult Function(RecordingResume value)? resume,
    TResult Function(RecordingFinished value)? finished,
    TResult Function(RecordingCancelled value)? cancelled,
    TResult Function(RecordingFailed value)? failed,
    required TResult orElse(),
  }) {
    if (cancelled != null) {
      return cancelled(this);
    }
    return orElse();
  }
}

abstract class RecordingCancelled implements RecordingEvent {
  const factory RecordingCancelled() = _$RecordingCancelled;
}

/// @nodoc
abstract class _$$RecordingFailedCopyWith<$Res> {
  factory _$$RecordingFailedCopyWith(
          _$RecordingFailed value, $Res Function(_$RecordingFailed) then) =
      __$$RecordingFailedCopyWithImpl<$Res>;
  @useResult
  $Res call({Object error});
}

/// @nodoc
class __$$RecordingFailedCopyWithImpl<$Res>
    extends _$RecordingEventCopyWithImpl<$Res, _$RecordingFailed>
    implements _$$RecordingFailedCopyWith<$Res> {
  __$$RecordingFailedCopyWithImpl(
      _$RecordingFailed _value, $Res Function(_$RecordingFailed) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = null,
  }) {
    return _then(_$RecordingFailed(
      null == error ? _value.error : error,
    ));
  }
}

/// @nodoc

class _$RecordingFailed implements RecordingFailed {
  const _$RecordingFailed(this.error);

  @override
  final Object error;

  @override
  String toString() {
    return 'RecordingEvent.failed(error: $error)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecordingFailed &&
            const DeepCollectionEquality().equals(other.error, error));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(error));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecordingFailedCopyWith<_$RecordingFailed> get copyWith =>
      __$$RecordingFailedCopyWithImpl<_$RecordingFailed>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function() recording,
    required TResult Function() pause,
    required TResult Function() resume,
    required TResult Function(File recordedFile) finished,
    required TResult Function() cancelled,
    required TResult Function(Object error) failed,
  }) {
    return failed(error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function()? recording,
    TResult? Function()? pause,
    TResult? Function()? resume,
    TResult? Function(File recordedFile)? finished,
    TResult? Function()? cancelled,
    TResult? Function(Object error)? failed,
  }) {
    return failed?.call(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function()? recording,
    TResult Function()? pause,
    TResult Function()? resume,
    TResult Function(File recordedFile)? finished,
    TResult Function()? cancelled,
    TResult Function(Object error)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RecordingInit value) init,
    required TResult Function(RecordingOngoing value) recording,
    required TResult Function(RecordingPause value) pause,
    required TResult Function(RecordingResume value) resume,
    required TResult Function(RecordingFinished value) finished,
    required TResult Function(RecordingCancelled value) cancelled,
    required TResult Function(RecordingFailed value) failed,
  }) {
    return failed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RecordingInit value)? init,
    TResult? Function(RecordingOngoing value)? recording,
    TResult? Function(RecordingPause value)? pause,
    TResult? Function(RecordingResume value)? resume,
    TResult? Function(RecordingFinished value)? finished,
    TResult? Function(RecordingCancelled value)? cancelled,
    TResult? Function(RecordingFailed value)? failed,
  }) {
    return failed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RecordingInit value)? init,
    TResult Function(RecordingOngoing value)? recording,
    TResult Function(RecordingPause value)? pause,
    TResult Function(RecordingResume value)? resume,
    TResult Function(RecordingFinished value)? finished,
    TResult Function(RecordingCancelled value)? cancelled,
    TResult Function(RecordingFailed value)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(this);
    }
    return orElse();
  }
}

abstract class RecordingFailed implements RecordingEvent {
  const factory RecordingFailed(final Object error) = _$RecordingFailed;

  Object get error;
  @JsonKey(ignore: true)
  _$$RecordingFailedCopyWith<_$RecordingFailed> get copyWith =>
      throw _privateConstructorUsedError;
}
