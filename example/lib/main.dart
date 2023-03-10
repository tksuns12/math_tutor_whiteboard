import 'dart:math';

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
                // Ask my id and host id first
                final myID = await showDialog(
                    context: context,
                    builder: (context) {
                      String id = '';
                      return AlertDialog(
                        title: const Text('Enter your id'),
                        content: TextField(onChanged: (value) => id = value),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, id),
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    });
                if (myID != null && mounted) {
                  final hostID = await showDialog(
                      context: context,
                      builder: (context) {
                        String id = '';
                        return AlertDialog(
                          title: const Text('host id'),
                          content: TextField(
                            onChanged: (value) => id = value,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, id),
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      });
                  if (hostID != null && mounted) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => WhiteboardView(
                          mode: myID == hostID
                              ? WhiteboardMode.liveTeaching
                              : WhiteboardMode.participant,
                          hostID: hostID,
                          me: WhiteboardUser(
                              nickname: myID,
                              isHost: myID == hostID,
                              micEnabled: true,
                              drawingEnabled: true,
                              id: myID)),
                    ));
                  }
                }
              },
              child: const Text('Realtime Mode'))
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
