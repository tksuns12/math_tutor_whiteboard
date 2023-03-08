import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
part 'recording_event.freezed.dart';

@freezed
class RecordingEvent with _$RecordingEvent {
  const factory RecordingEvent.init() = RecordingInit;
  const factory RecordingEvent.start() = RecordingStart;
  const factory RecordingEvent.pause() = RecordingPause;
  const factory RecordingEvent.resume() = RecordingResume;
  const factory RecordingEvent.finished(File recordedFile) = RecordingFinished;
  const factory RecordingEvent.failed(Object error) = RecordingFailed;
}
