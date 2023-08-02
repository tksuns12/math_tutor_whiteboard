import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
  List<(int, PointerDeviceKind)> pointers = [];
  bool isInMultiplePointers = false;

  bool isStylusMode = false;

  void addPointer(
      {required int pointer, required PointerDeviceKind deviceKind}) {
    if (deviceKind == PointerDeviceKind.stylus ||
        deviceKind == PointerDeviceKind.invertedStylus) {
      isStylusMode = true;
      pointers.removeWhere((element) => element.$2 != deviceKind);
    }

    if (isStylusMode &&
        (deviceKind != PointerDeviceKind.stylus &&
            deviceKind != PointerDeviceKind.invertedStylus)) {
      return;
    }
    pointers.add((pointer, deviceKind));
    if (pointers.where((element) => element.$2 == deviceKind).length > 1) {
      isInMultiplePointers = true;
    }
  }

  void initPointer() {
    pointers = [];
    isInMultiplePointers = false;
    isStylusMode = false;
  }

  void popPointer(
      {required int pointer, required PointerDeviceKind deviceKind}) {
    pointers.removeWhere(
        (element) => element.$1 == pointer && element.$2 == deviceKind);
    if (pointers.isEmpty) {
      isInMultiplePointers = false;
    }
    if (pointers.any((element) =>
        element.$2 == PointerDeviceKind.stylus ||
        element.$2 == PointerDeviceKind.invertedStylus)) {
      isStylusMode = true;
    } else {
      isStylusMode = false;
    }
  }

  WhiteboardRecorder? recorder;
  Timer? _timer;
  RecordingState recordingState = RecordingState.idle;
  String? recordingPath;
  final Duration recordDuration;

  DateTime? liveEndAt;
  Duration? liveEndExtraDuration;
  Duration? liveDuration;

  int currentSecond = 0;
  List<WhiteboardUser> users = [];

  WhiteboardController({this.recorder, required this.recordDuration}) {
    currentSecond = recordDuration.inSeconds;
  }

  void setLiveTime(
      {required DateTime liveEndAt, required Duration liveEndExtraDuration}) {
    this.liveEndAt = liveEndAt;
    this.liveEndExtraDuration = liveEndExtraDuration;
    notifyListeners();
  }

  void startUpdatingLiveTime() {
    assert(liveEndAt != null && liveEndExtraDuration != null);
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final liveDuration = liveEndAt!
          .add(liveEndExtraDuration ?? const Duration(seconds: 0))
          .difference(now);
      this.liveDuration = liveDuration;
      notifyListeners();
    });
  }

  void updateCurrentSecond(int newSecond) {
    currentSecond = newSecond;
    notifyListeners();
  }

  void addUser(WhiteboardUser user) {
    if (users.any((element) => user.id == element.id)) {
      log('User already exists: ${user.id}');
      return;
    }
    users.add(user);
    log('Added user: ${user.id}');
    notifyListeners();
  }

  void removeUser(WhiteboardUser user) {
    users.removeWhere((element) => element.id == user.id);
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
    await recorder?.startRecording();
    currentSecond = recordDuration.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      currentSecond--;
      if (currentSecond == 0) {
        _timer?.cancel();
      }
      notifyListeners();
    });
    recordingState = RecordingState.recording;
    log('Started recording');
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (recordingState != RecordingState.recording &&
        recordingState != RecordingState.paused) {
      return;
    }
    recordingPath = (await recorder?.stopRecording());
    _timer?.cancel();
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  @override
  void dispose() {
    _timer?.cancel();
    users.clear();
    recorder = null;
    recordingPath = null;
    recordingState = RecordingState.idle;
    currentSecond = 0;
    liveEndAt = null;
    liveEndExtraDuration = null;
    liveDuration = null;
    super.dispose();
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
      audioEnable: true,
      fileName: const Uuid().v4(),
      dirPathToSave: path,
      videoBitrate: 500000,
    );
  }

  @override
  Future<String> stopRecording() async {
    final file = (await _recorder.stopRecord())['file'] as File;
    log('${file.lengthSync()}');
    return file.path;
  }
}
