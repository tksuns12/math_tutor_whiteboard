library math_tutor_whiteboard;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_tutor_whiteboard/math_tutor_whiteboard_impl.dart';
import 'package:math_tutor_whiteboard/types/recording_event.dart';
import 'package:math_tutor_whiteboard/types/types.dart';

class MathTutorWhiteBoard extends StatelessWidget {
  final ImageProvider? preloadImage;
  final Duration? recordDuration;
  final WhiteboardMode mode;
  final Stream? inputStream;
  final void Function(dynamic data)? onOutput;
  final WhiteboardUser me;
  final void Function(RecordingEvent event) onRecordingEvent;
  final Future<bool> Function() onAttemptToClose;
  final Future<bool> Function() onAttemptToCompleteRecording;
  final Future<void> Function() onBeforeTimeLimitReached;
  final Future<void> Function() onTimeLimitReached;
  const MathTutorWhiteBoard({
    Key? key,
    this.preloadImage,
    this.recordDuration,
    required this.mode,
    required this.me,
    required this.onAttemptToClose,
    required this.onAttemptToCompleteRecording,
    this.inputStream,
    required this.onOutput,
    required this.onRecordingEvent,
    required this.onBeforeTimeLimitReached,
    required this.onTimeLimitReached,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
        child: MathTutorWhiteboardImpl(
            onBeforeTimeLimitReached: onBeforeTimeLimitReached,
            onTimeLimitReached: onTimeLimitReached,
            onOutput: onOutput,
            onRecordingEvent: onRecordingEvent,
            preloadImage: preloadImage,
            recordDuration: recordDuration,
            mode: mode,
            me: me,
            inputStream: inputStream,
            onAttemptToClose: onAttemptToClose,
            onAttemptToCompleteRecording: onAttemptToCompleteRecording));
  }
}
