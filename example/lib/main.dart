import 'dart:io';
import 'dart:math';
import 'package:example/whiteboard_view.dart';
import 'package:flutter/material.dart';
import 'package:math_tutor_whiteboard/types/types.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

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
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Permission.microphone.request();
      await Permission.photos.request();
      await Permission.bluetoothConnect.request();
    });
    super.initState();
  }

  File? recordedFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (recordedFile != null) ...[
            TextButton(
                onPressed: () async {
                  await recordedFile!.delete();
                  setState(() {
                    recordedFile = null;
                  });
                },
                child: const Text('Delete recorded file')),
            TextButton(
                onPressed: () {
                  final controller = VideoPlayerController.file(recordedFile!)
                    ..initialize();
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return SafeArea(
                        child: Scaffold(
                      appBar: AppBar(),
                      body: Column(
                        children: [
                          Expanded(child: VideoPlayer(controller)),
                          // PlayerControllers
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  controller.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                                onPressed: () {
                                  controller.value.isPlaying
                                      ? controller.pause()
                                      : controller.play();
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  controller.value.isLooping
                                      ? Icons.loop
                                      : Icons.loop_outlined,
                                ),
                                onPressed: () {
                                  controller.value.isLooping
                                      ? controller.setLooping(false)
                                      : controller.setLooping(true);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ));
                  }));
                },
                child: const Text('Play Video')),
          ],
          ElevatedButton(
              onPressed: () async {
                final result =
                    await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => WhiteboardView(
                      mode: WhiteboardMode.record,
                      me: WhiteboardUser(
                          nickname: const Uuid().v4(),
                          micEnabled: true,
                          drawingEnabled: true,
                          id: const Uuid().v4(),
                          isHost: Random().nextBool())),
                ));
                setState(() {
                  recordedFile = result;
                });
              },
              child: const Text('Record Mode')),
          ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WhiteboardView(
                      mode: WhiteboardMode.liveTeaching,
                      hostID: 'tutor119',
                      me: WhiteboardUser(
                        nickname: '튜터',
                        isHost: true,
                        micEnabled: true,
                        drawingEnabled: true,
                        id: 'tutor119',
                      ),
                    ),
                  ),
                );
                setState(() {
                  recordedFile = result;
                });
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
                      isHost: false,
                      micEnabled: true,
                      drawingEnabled: false,
                      id: 'student119',
                    ),
                  ),
                ));
              },
              child: const Text('Realtime Mode as Student')),
        ],
      ),
    ));
  }
}
