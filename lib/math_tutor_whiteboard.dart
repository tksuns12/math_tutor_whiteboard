library math_tutor_whiteboard;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_tutor_whiteboard/math_tutor_whiteboard_impl.dart';

import 'package:math_tutor_whiteboard/types.dart';

class MathTutorWhiteBoard extends StatelessWidget {
  final ImageProvider? preloadImage;
  final Duration? recordDuration;
  final WhiteboardMode mode;
  final StreamController<BroadcastPaintData>? drawingStream;
  final String myID;
  final Stream<BroadcastPaintData>? inputDrawingStream;
  final Stream<WhiteboardChatMessage>? chatStream;
  final Stream<WhiteboardUser>? userJoinStream;
  final Stream<WhiteboardUser>? userLeaveStream;
  final void Function(File file)? onRecordingFinished;
  final Future<bool> Function() onAttemptToClose;
  final Stream<File>? inputImageStream;
  final StreamController<File>? outputImageStream;
  final Future<bool> Function() onAttemptToCompleteRecording;
  const MathTutorWhiteBoard({
    Key? key,
    this.preloadImage,
    this.recordDuration,
    required this.mode,
    this.onRecordingFinished,
    required this.myID,
    this.inputDrawingStream,
    this.chatStream,
    this.userJoinStream,
    this.userLeaveStream,
    required this.onAttemptToClose,
    this.drawingStream,
    this.inputImageStream,
    this.outputImageStream,
    required this.onAttemptToCompleteRecording,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
        child: MathTutorWhiteboardImpl(
      myID: myID,
      mode: mode,
      onRecordingFinished: onRecordingFinished,
      preloadImage: preloadImage,
      recordDuration: recordDuration,
      onAttemptToClose: onAttemptToClose,
      onAttemptToCompleteRecording: onAttemptToCompleteRecording,
    ));
  }
}
