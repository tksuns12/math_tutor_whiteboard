import 'dart:developer' as dev;
import 'dart:math';

import 'package:example/platform_channel.dart';
import 'package:example/whiteboard_view.dart';
import 'package:flutter/material.dart';
import 'package:math_tutor_whiteboard/types/types.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Tutor Whiteboard Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Math Tutor Whiteboard Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => WhiteboardView(
                      mode: WhiteboardMode.record,
                      me: WhiteboardUser(
                          nickname: const Uuid().v4(),
                          micEnabled: true,
                          drawingEnabled: true,
                          id: const Uuid().v4(),
                          isHost: Random().nextBool())),
                ));
              },
              child: const Text('Record Mode')),
          ElevatedButton(
              onPressed: () async {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const WhiteboardView(
                      mode: WhiteboardMode.liveTeaching,
                      hostID: 'tutor119',
                      me: WhiteboardUser(
                          nickname: '튜터',
                          isHost: true,
                          micEnabled: true,
                          drawingEnabled: true,
                          id: 'tutor119')),
                ));
              },
              child: const Text('Realtime Mode as Tutor')),
          ElevatedButton(
              onPressed: () async {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const WhiteboardView(
                      mode: WhiteboardMode.participant,
                      hostID: 'tutor119',
                      me: WhiteboardUser(
                          nickname: '학생',
                          isHost: true,
                          micEnabled: true,
                          drawingEnabled: true,
                          id: 'student119')),
                ));
              },
              child: const Text('Realtime Mode as Student')),
        ],
      ),
    ));
    // return Scaffold(
    //     body: MathTutorWhiteBoard(
    //   mode: WhiteboardMode.record,
    //   preloadImage: const NetworkImage('https://picsum.photos/640/320'),
    //   myID: 'MyID',
    //   onAttemptToClose: () async {
    //     print('onAttemptToClose');
    //     return true;
    //   },
    //   onAttemptToCompleteRecording: () async {
    //     print('onAttemptToCompleteRecording');
    //     return true;
    //   },
    // ));
  }
}
