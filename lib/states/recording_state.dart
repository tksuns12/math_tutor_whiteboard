import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RecorderState { recording, paused, init }

class RecordingState extends Equatable {
  final RecorderState recorderState;
  final int remainingTime;
  final int totalDuration;
  final File? result;
  final bool precessing;
  const RecordingState({
    required this.precessing,
    required this.recorderState,
    required this.remainingTime,
    required this.totalDuration,
    this.result,
  });

  @override
  List<Object?> get props =>
      [recorderState, remainingTime, totalDuration, result];

  RecordingState copyWith({
    RecorderState? recorderState,
    int? remainingTime,
    int? totalDuration,
    File? result,
    bool? precessing,
  }) {
    return RecordingState(
      recorderState: recorderState ?? this.recorderState,
      remainingTime: remainingTime ?? this.remainingTime,
      totalDuration: totalDuration ?? this.totalDuration,
      precessing: precessing ?? this.precessing,
      result: result ?? this.result,
    );
  }
}

class RecordingStateNotifier extends StateNotifier<RecordingState> {
  RecordingStateNotifier({
    required this.maxDuration,
  }) : super(RecordingState(
            recorderState: RecorderState.init,
            remainingTime: maxDuration,
            totalDuration: maxDuration,
            precessing: false));

  final int maxDuration;

  void setProcessing(bool processing) {
    state = state.copyWith(precessing: processing);
  }

  void startRecording() {
    state = state.copyWith(recorderState: RecorderState.recording);
  }

  void tick() {
    state = state.copyWith(
      remainingTime: state.remainingTime - 1,
    );
  }

  void finishRecording(File file) {
    state = state.copyWith(result: file, recorderState: RecorderState.init);
  }

  void updateDuration(Duration duration) {
    state = state.copyWith(
      totalDuration: duration.inSeconds,
      remainingTime: duration.inSeconds,
    );
  }

  void pauseRecording() {
    state = state.copyWith(recorderState: RecorderState.paused);
  }

  Future<void> doAsync(AsyncCallback asyncFunc) async {
    setProcessing(true);
    return await asyncFunc().then((value) {
      setProcessing(false);
    });
  }

  void initialize() {
    state = state.copyWith(
        recorderState: RecorderState.init,
        remainingTime: maxDuration,
        totalDuration: maxDuration,
        precessing: false,
        result: null);
  }
}

final recordingStateProvider =
    AutoDisposeStateNotifierProvider<RecordingStateNotifier, RecordingState>(
        (ref) {
  return RecordingStateNotifier(maxDuration: 20 * 60);
});
