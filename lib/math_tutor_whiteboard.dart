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
  final StreamController<BroadcastData> drawingStream;
  final String myID;
  final Stream<BroadcastData>? inputDrawingStream;
  final Stream<WhiteboardChatMessage>? chatStream;
  final Stream<WhiteboardUser>? userJoinStream;
  final Stream<WhiteboardUser>? userLeaveStream;
  final void Function(File file)? onRecordingFinished;
  final Future<bool> Function() onAttemptToClose;
  final Stream<File> inputImageStream;
  final StreamController<File> outputImageStream;
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
    required this.drawingStream,
    required this.inputImageStream,
    required this.outputImageStream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
        child: MathTutorWhiteboardImpl(
      myID: myID,
      chatStream: chatStream,
      inputDrawingStream: inputDrawingStream,
      userJoinStream: userJoinStream,
      userLeaveStream: userLeaveStream,
      mode: mode,
      onRecordingFinished: onRecordingFinished,
      preloadImage: preloadImage,
      inputImageStream: inputImageStream,
      outputImageStream: outputImageStream,
      recordDuration: recordDuration,
      outputDrawingStream: drawingStream,
      onAttemptToClose: onAttemptToClose,
    ));
  }
}
