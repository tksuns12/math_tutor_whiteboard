import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:math_tutor_whiteboard/types/types.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
    log('Added user: ${user.id}');
    notifyListeners();
  }

  void removeUser(WhiteboardUser user) {
    users.remove(user);
    log('Removed user: ${user.id}');
    notifyListeners();
  }

  void clearUsers() {
    users.clear();
    log('Cleared users');
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
    log('Adjusted permission of user: $userID');
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
    log('Started recording');
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
    log('Stopped recording');
  }

  Future<void> pauseRecording() async {
    if (recordingState != RecordingState.recording) {
      return;
    }
    _timer?.cancel();
    await recorder?.pauseRecording();
    recordingState = RecordingState.paused;
    notifyListeners();
    log('Paused recording');
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
    await recorder?.resumeRecording();
    recordingState = RecordingState.recording;
    notifyListeners();
    log('Resumed recording');
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
    if (Platform.isAndroid) {
      final result = await _recorder.pauseRecord();
      if (result == true) {
        return;
      } else {
        throw Exception('Unable to pause recording');
      }
    }
  }

  @override
  Future<void> resumeRecording() async {
    if (Platform.isAndroid) {
      final result = await _recorder.resumeRecord();
      if (result == true) {
        return;
      } else {
        throw Exception('Unable to resume recording');
      }
    }
  }

  @override
  Future<void> startRecording() async {
    final path =
        '${(await getApplicationDocumentsDirectory()).path}/math_tutor_temp';
    final savingDirectory = Directory(path);
    if (!await savingDirectory.exists()) {
      await savingDirectory.create(recursive: true);
    }
    await _recorder.startRecordScreen(
        audioEnable: true, fileName: const Uuid().v4(), dirPathToSave: path);
  }

  @override
  Future<String> stopRecording() async {
    return (await _recorder.stopRecord())['file'].path;
  }
}
