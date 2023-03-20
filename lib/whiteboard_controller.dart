import 'dart:async';
import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

enum RecordingState {
  idle,
  recording,
  paused,
  completed,
  error,
}

class WhiteboardController extends ChangeNotifier {
  WhiteboardRecorder? recorder;
  Timer? _timer;
  RecordingState recordingState = RecordingState.idle;
  String? recordingPath;
  final Duration recordDuration;
  int currentSecond = 0;

  WhiteboardController({this.recorder, required this.recordDuration}) {
    currentSecond = recordDuration.inSeconds;
  }

  Future<void> startRecording() async {
    if (recordingState != RecordingState.idle) {
      return;
    }
    currentSecond = recordDuration.inSeconds;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      currentSecond--;
      if (currentSecond == 0) {
        _timer?.cancel();
      }
      notifyListeners();
    });
    await recorder?.startRecording();
    recordingState = RecordingState.recording;
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (recordingState != RecordingState.recording &&
        recordingState != RecordingState.paused) {
      return;
    }
    _timer?.cancel();
    recordingPath = (await recorder?.stopRecording());
    if (recordingPath != null) {
      recordingState = RecordingState.completed;

      notifyListeners();
    } else {
      recordingState = RecordingState.error;
      notifyListeners();
    }
  }

  Future<void> pauseRecording() async {
    if (recordingState != RecordingState.recording) {
      return;
    }
    _timer?.cancel();
    recorder?.pauseRecording();
    recordingState = RecordingState.paused;
    notifyListeners();
  }

  Future<void> resumeRecording() async {
    if (recordingState != RecordingState.paused) {
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      currentSecond--;
      if (currentSecond == 0) {
        _timer?.cancel();
      }
      notifyListeners();
    });
    recorder?.resumeRecording();
    recordingState = RecordingState.recording;
    notifyListeners();
  }
}

abstract class WhiteboardRecorder {
  Future<void> startRecording();
  Future<String> stopRecording();
  Future<void> pauseRecording();
  Future<void> resumeRecording();
}

class DefaultRecorder implements WhiteboardRecorder {
  final EdScreenRecorder _recorder = EdScreenRecorder();
  @override
  Future<void> pauseRecording() async {
    _recorder.pauseRecord();
  }

  @override
  Future<void> resumeRecording() async {
    _recorder.resumeRecord();
  }

  @override
  Future<void> startRecording() async {
    await _recorder.startRecordScreen(
        audioEnable: true,
        fileName: DateTime.now().millisecondsSinceEpoch.toString(),
        dirPathToSave: (await getTemporaryDirectory()).path);
  }

  @override
  Future<String> stopRecording() async {
    return (await _recorder.stopRecord())['file'].path;
  }
}
