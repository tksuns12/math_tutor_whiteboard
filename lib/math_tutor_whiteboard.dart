library math_tutor_whiteboard;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:math_tutor_whiteboard/math_tutor_whiteboard_impl.dart';
import 'package:math_tutor_whiteboard/types/features.dart';
import 'package:math_tutor_whiteboard/types/types.dart';
import 'package:math_tutor_whiteboard/whiteboard_controller.dart';

import 'dart:ui' as ui;

class MathTutorWhiteBoard extends StatelessWidget {
  final WhiteboardController? controller;
  final ui.Image? preloadImage;
  final Stream? inputStream;
  final void Function(dynamic data)? onOutput;
  final WhiteboardUser me;
  final VoidCallback onAttemptToClose;
  final VoidCallback onTapRecordButton;
  final void Function(File file)? onLoadNewImage;
  final Duration maxDuration;
  final Set<WhiteboardFeature> enabledFeatures;
  final String? hostID;
  final BatchDrawingData? preDrawnData;
  const MathTutorWhiteBoard({
    super.key,
    this.controller,
    this.preloadImage,
    this.inputStream,
    required this.onOutput,
    required this.me,
    required this.onAttemptToClose,
    required this.onTapRecordButton,
    this.onLoadNewImage,
    this.maxDuration = const Duration(minutes: 20),
    required this.enabledFeatures,
    this.hostID,
    this.preDrawnData,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
        child: MathTutorWhiteboardImpl(
      onTapRecordButton: onTapRecordButton,
      onLoadNewImage: onLoadNewImage,
      maxRecordingDuration: maxDuration,
      onOutput: onOutput,
      preloadImage: preloadImage,
      enabledFeatures: enabledFeatures,
      me: me,
      hostID: hostID,
      inputStream: inputStream,
      onAttemptToClose: onAttemptToClose,
      controller: controller,
      preDrawnData: preDrawnData,
    ));
  }
}
