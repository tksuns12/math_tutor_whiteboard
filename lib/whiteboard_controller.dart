import 'dart:async';
import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:flutter/material.dart';
import 'package:math_tutor_whiteboard/types/types.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screen_recorder/flutter_screen_recorder.dart';

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
  List<WhiteboardUser> users = [];

  WhiteboardController({this.recorder, required this.recordDuration}) {
    currentSecond = recordDuration.inSeconds;
  }

  void addUser(WhiteboardUser user) {
    users.add(user);
    notifyListeners();
  }

  void removeUser(WhiteboardUser user) {
    users.remove(user);
    notifyListeners();
  }

  void clearUsers() {
    users.clear();
    notifyListeners();
  }

  void adjustPermissionOfUser(
      {required String userID,
      required PermissionChangeEvent permissionEvent}) {
    final index = users.indexWhere((element) => element.id == userID);
    if (index != -1) {
      users[index] = users[index].copyWith(
          drawingEnabled: permissionEvent.drawing,
          micEnabled: permissionEvent.microphone);
      notifyListeners();
    }
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

class NewDefaultRecorder implements WhiteboardRecorder {
  final FlutterScreenRecorder _recorder = FlutterScreenRecorder();
  @override
  Future<void> pauseRecording() async {
    final result = await _recorder.pauseRecordScreen();
    if (result) {
      return;
    } else {
      throw Exception('Failed to pause recording');
    }
  }

  @override
  Future<void> resumeRecording() async {
    final result = await _recorder.resumeRecordScreen();
    if (result) {
      return;
    } else {
      throw Exception('Failed to resume recording');
    }
  }

  @override
  Future<void> startRecording() async {
    final result =
        await _recorder.startRecordScreen(DateTime.now().toIso8601String());
    if (!result) {
      throw Exception('Failed to start recording');
    }
  }

  @override
  Future<String> stopRecording() async {
    return await _recorder.stopRecordScreen();
  }
}
