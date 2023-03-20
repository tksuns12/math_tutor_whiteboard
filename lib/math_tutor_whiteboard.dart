library math_tutor_whiteboard;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:math_tutor_whiteboard/math_tutor_whiteboard_impl.dart';
import 'package:math_tutor_whiteboard/types/types.dart';
import 'package:math_tutor_whiteboard/whiteboard_controller.dart';

class MathTutorWhiteBoard extends StatelessWidget {
  final WhiteboardController? controller;
  final ImageProvider? preloadImage;
  final WhiteboardMode mode;
  final Stream? inputStream;
  final void Function(dynamic data)? onOutput;
  final WhiteboardUser me;
  final VoidCallback onAttemptToClose;
  final VoidCallback onTapRecordButton;
  final String? hostID;
  final Future<InitialUserListEvent> Function()? onGetInitialUserList;
  const MathTutorWhiteBoard({
    Key? key,
    this.controller,
    this.preloadImage,
    required this.mode,
    this.inputStream,
    required this.onOutput,
    required this.me,
    required this.onAttemptToClose,
    required this.onTapRecordButton,
    this.hostID,
    this.onGetInitialUserList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
        child: MathTutorWhiteboardImpl(
            onTapRecordButton: onTapRecordButton,
            onOutput: onOutput,
            hostID: hostID,
            preloadImage: preloadImage,
            onGetInitialUserList: onGetInitialUserList,
            mode: mode,
            me: me,
            inputStream: inputStream,
            onAttemptToClose: onAttemptToClose,
            controller: controller));
  }
}
