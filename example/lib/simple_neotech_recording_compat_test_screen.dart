import 'dart:developer';

import 'package:example/platform_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:math_tutor_whiteboard/whiteboard_controller.dart';

class SimpleNeotechRecordingCompatibilityTestScreen extends StatefulWidget {
  const SimpleNeotechRecordingCompatibilityTestScreen({super.key});

  @override
  State<SimpleNeotechRecordingCompatibilityTestScreen> createState() =>
      _SimpleNeotechRecordingCompatibilityTestScreenState();
}

class _SimpleNeotechRecordingCompatibilityTestScreenState
    extends State<SimpleNeotechRecordingCompatibilityTestScreen> {
  bool isRecording = false;
  bool isInitialized = false;
  final recorder = DefaultRecorder();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: Column(
      children: [
        ElevatedButton(
            onPressed: () async {
              if (isInitialized) {
                return;
              }
              final channel = PlatformChannelImpl();
              await channel.initialize(userID: 'sdfsdf', ownerID: 'asdofuiao');
              await channel.login();
              setState(() {
                isInitialized = true;
              });
              log('login done');
            },
            child: Text(isInitialized ? 'Initialized!' : 'Init Neotech')),
        ElevatedButton(
          onPressed: () async {
            if (isRecording) {
              log(await recorder.stopRecording());
              setState(() {
                isRecording = false;
              });
            } else {
              await recorder.startRecording();
              setState(() {
                isRecording = true;
              });
            }
          },
          child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
        ),
      ],
    )));
  }
}
