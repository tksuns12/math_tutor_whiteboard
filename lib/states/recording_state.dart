import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecordingState extends Equatable {
  final bool isRecording;
  final int remainingTime;
  final int totalDuration;
  final File? result;
  final bool precessing;
  const RecordingState({
    required this.precessing,
    required this.isRecording,
    required this.remainingTime,
    required this.totalDuration,
    this.result,
  });

  @override
  List<Object?> get props =>
      [isRecording, remainingTime, totalDuration, result];

  RecordingState copyWith({
    bool? isRecording,
    int? remainingTime,
    int? totalDuration,
    File? result,
    bool? precessing,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      remainingTime: remainingTime ?? this.remainingTime,
      totalDuration: totalDuration ?? this.totalDuration,
      precessing: precessing ?? this.precessing,
      result: result ?? this.result,
    );
  }
}

class RecordingStateNotifier extends StateNotifier<RecordingState> {
  RecordingStateNotifier({
    required this.totalDuration,
  }) : super(RecordingState(
            isRecording: false,
            remainingTime: totalDuration,
            totalDuration: totalDuration,
            precessing: false));

  final int totalDuration;

  void setProcessing(bool processing) {
    state = state.copyWith(precessing: processing);
  }

  void startRecording() {
    state = state.copyWith(isRecording: true);
  }

  void tick() {
    state = state.copyWith(
      remainingTime: state.remainingTime - 1,
    );
  }

  void finishRecording(File file) {
    state = state.copyWith(result: file, isRecording: false);
  }

  void updateDuration(Duration duration) {
    state = state.copyWith(
      totalDuration: duration.inSeconds,
      remainingTime: duration.inSeconds,
    );
  }
}

final recordingStateProvider =
    StateNotifierProvider<RecordingStateNotifier, RecordingState>((ref) {
  return RecordingStateNotifier(totalDuration: 20 * 60);
});
