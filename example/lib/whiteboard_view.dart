import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:math_tutor_whiteboard/math_tutor_whiteboard.dart';
import 'package:math_tutor_whiteboard/types/recording_event.dart';
import 'package:math_tutor_whiteboard/types/types.dart';
import 'package:uuid/uuid.dart';

const kFileCode = 100;

const kDrawingCode = 200;

const kChatMessageCode = 300;

const kServerEventCode = 400;

const kViewportCode = 500;

const kUserCode = 600;

class WhiteboardView extends StatefulWidget {
  final WhiteboardMode mode;
  final WhiteboardUser me;
  const WhiteboardView({
    Key? key,
    required this.mode,
    required this.me,
  }) : super(key: key);

  @override
  State<WhiteboardView> createState() => _WhiteboardViewState();
}

class _WhiteboardViewState extends State<WhiteboardView> {
  Stream? inputStream;
  StreamController? outputStream;
  late final Future<WebSocket> webSocket;
  @override
  void initState() {
    if (widget.mode == WhiteboardMode.liveTeaching) {
      webSocket = WebSocket.connect('ws://ws-test-mathtutor.wimcorp.dev/ws');
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: widget.mode != WhiteboardMode.liveTeaching
          ? MathTutorWhiteBoard(
              mode: widget.mode,
              preloadImage: const NetworkImage('https://picsum.photos/640/320'),
              me: widget.me,
              recordDuration: const Duration(minutes: 15),
              onAttemptToClose: () async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Are you sure?'),
                    content: const Text(
                        'You will lose all unsaved changes if you close the whiteboard.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              onAttemptToCompleteRecording: () async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Are you sure?'),
                    content: const Text(
                        'You will lose all unsaved changes if you close the whiteboard.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              onOutput: (data) {},
              onRecordingEvent: (RecordingEvent event) {},
            )
          : FutureBuilder<WebSocket>(
              future: webSocket,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  inputStream =
                      snapshot.data!.asBroadcastStream().map((rawEvent) {
                    final event = jsonDecode(rawEvent);
                    final data = jsonDecode(event['data']);
                    final senderID = event['id'];
                    if (kDebugMode) {
                      print("Input: $event");
                    }
                    if (senderID != widget.me) {
                      switch (event['type']) {
                        case kChatMessageCode:
                          return WhiteboardChatMessage.fromMap(data);
                        case kFileCode:
                          return File(data);
                        case kDrawingCode:
                          return BroadcastPaintData.fromMap(data);
                        case kUserCode:
                          final user = WhiteboardUser(
                              nickname: data,
                              micEnabled: false,
                              drawingEnabled: true,
                              id: const Uuid().v4(),
                              isHost: false);
                          return UserEvent(user: user, isJoin: data);
                        case kViewportCode:
                          return ViewportChangeEvent.fromMap(data);
                        default:
                          return event;
                      }
                    }
                  });
                  return MathTutorWhiteBoard(
                    mode: WhiteboardMode.liveTeaching,
                    preloadImage:
                        const NetworkImage('https://picsum.photos/640/320'),
                    me: widget.me,
                    inputStream: inputStream,
                    onOutput: (event) {
                      if (kDebugMode) {
                        print("Output: $event");
                      }
                      switch (event.runtimeType) {
                        case WhiteboardChatMessage:
                          snapshot.data!.add(jsonEncode({
                            'id': widget.me.id,
                            'type': kChatMessageCode,
                            'data': (event as WhiteboardChatMessage).toJson()
                          }));
                          break;
                        case File:
                          snapshot.data!.add(jsonEncode({
                            'id': widget.me.id,
                            'type': kFileCode,
                            'data': (event as File).path,
                          }));
                          break;
                        case BroadcastPaintData:
                          snapshot.data!.add(jsonEncode({
                            'id': widget.me.id,
                            'type': kDrawingCode,
                            'data': (event as BroadcastPaintData).toJson()
                          }));
                          break;
                        case UserEvent:
                          snapshot.data!.add(jsonEncode({
                            'id': widget.me.id,
                            'type': kUserCode,
                            'data': (event as UserEvent).user.nickname,
                            'isEnter': (event).isJoin,
                          }));
                          break;
                        case ViewportChangeEvent:
                          snapshot.data!.add(jsonEncode({
                            'id': widget.me.id,
                            'type': kViewportCode,
                            'data': (event as ViewportChangeEvent).toJson()
                          }));
                          break;
                        default:
                          snapshot.data!.add(jsonEncode(event));
                      }
                    },
                    onRecordingEvent: (event) {},
                    onAttemptToClose: () async {
                      if (kDebugMode) {
                        print('onAttemptToClose');
                      }
                      return true;
                    },
                    onAttemptToCompleteRecording: () async {
                      if (kDebugMode) {
                        print('onAttemptToCompleteRecording');
                      }
                      return true;
                    },
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              }),
    );
  }
}
