import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:example/platform_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:math_tutor_whiteboard/math_tutor_whiteboard.dart';
import 'package:math_tutor_whiteboard/types/recording_event.dart';
import 'package:math_tutor_whiteboard/types/types.dart';

const kFileCode = 100;

const kDrawingCode = 200;

const kChatMessageCode = 300;

const kServerEventCode = 400;

const kViewportCode = 500;

const kUserCode = 600;

class WhiteboardView extends StatefulWidget {
  final WhiteboardMode mode;
  final WhiteboardUser me;
  final String? hostID;
  const WhiteboardView({
    Key? key,
    required this.mode,
    required this.me,
    this.hostID,
  }) : super(key: key);

  @override
  State<WhiteboardView> createState() => _WhiteboardViewState();
}

class _WhiteboardViewState extends State<WhiteboardView> {
  Stream? inputStream;
  StreamController? outputStream;
  late final MathtutorNeotechPluginPlatform channel;
  late final Future initFuture;
  @override
  void initState() {
    if (widget.mode == WhiteboardMode.liveTeaching ||
        widget.mode == WhiteboardMode.participant) {
      channel = PlatformChannelImpl();
      initFuture = (() async {
        await channel.initialize(
            userID: widget.me.id,
            nickname: widget.me.id,
            ownerID: widget.hostID!);
        if (widget.me.id == widget.hostID) {
          await channel.turnOnMicrophone(true);
        }
      })();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: widget.mode != WhiteboardMode.liveTeaching &&
              widget.mode != WhiteboardMode.participant
          ? MathTutorWhiteBoard(
              mode: widget.mode,
              preloadImage: const NetworkImage('https://picsum.photos/640/320'),
              me: widget.me,
              recordDuration: const Duration(minutes: 15),
              hostID: widget.hostID,
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
              onRecordingEvent: (RecordingEvent event) {
                log(event.toString());
                if (event is RecordingFinished) {
                  Navigator.of(context).pop();
                }
              },
              onBeforeTimeLimitReached: () {
                return showDialog(
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
              onTimeLimitReached: () {
                return showDialog(
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
            )
          : FutureBuilder(
              future: initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  inputStream = channel.incomingStream;
                  return MathTutorWhiteBoard(
                    hostID: widget.hostID,
                    onBeforeTimeLimitReached: () {
                      return showDialog(
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
                    onTimeLimitReached: () {
                      return showDialog(
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
                    mode: widget.mode,
                    preloadImage:
                        const NetworkImage('https://picsum.photos/640/320'),
                    me: widget.me,
                    inputStream: inputStream,
                    onOutput: (event) {
                      if (event is WhiteboardChatMessage) {
                        channel.sendPacket({
                          'id': widget.me.id,
                          'type': kChatMessageCode,
                          'data': event.toJson(),
                        });
                      } else if (event is File) {
                        channel.sendImage(event);
                      } else if (event is BroadcastPaintData) {
                        channel.sendPacket({
                          'id': widget.me.id,
                          'type': kDrawingCode,
                          'data': event.toJson(),
                        });
                      } else if (event is UserEvent) {
                        channel.sendPacket({
                          'id': widget.me.id,
                          'type': kUserCode,
                          'data': event,
                        });
                      } else if (event is ViewportChangeEvent) {
                        channel.sendPacket({
                          'id': widget.me.id,
                          'type': kViewportCode,
                          'data': event.toJson(),
                        });
                      } else {
                        throw UnimplementedError();
                      }
                    },
                    onRecordingEvent: (event) {
                      if (event is RecordingFinished) {
                        Navigator.of(context).pop();
                      }
                    },
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
