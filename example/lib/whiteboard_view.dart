import 'dart:async';
import 'dart:io';
import 'package:example/livekit_service.dart';
import 'package:flutter/material.dart';

import 'package:math_tutor_whiteboard/math_tutor_whiteboard.dart';
import 'package:math_tutor_whiteboard/types/types.dart';
import 'package:math_tutor_whiteboard/whiteboard_controller.dart';

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
  late final LivekitService service;
  late final Future initFuture;
  late final WhiteboardController controller;
  @override
  void initState() {
    if (widget.mode.isUsingWebSocket) {
      service = LivekitService();
      initFuture = (() async {
        try {
          await service.joinRoom(widget.hostID != widget.me.id, widget.me);
          controller.addUser(
            WhiteboardUser(
                isHost: widget.hostID == widget.me.id,
                nickname: widget.me.nickname,
                micEnabled: true,
                drawingEnabled: widget.hostID == widget.me.id,
                id: widget.me.id),
          );
          final whiteboardUsers = service.getUserList();
          if (whiteboardUsers.isNotEmpty) {
            for (final user in whiteboardUsers) {
              controller.addUser(user);
            }
          }
        } catch (e) {
          Navigator.of(context).pop();
        }
      })();
    }
    controller = WhiteboardController(
        recordDuration: const Duration(minutes: 20),
        recorder: DefaultRecorder());
    controller.addListener(_controllerListener);
    super.initState();
    if (widget.mode.isUsingWebSocket) {
      service.incomingStream.listen((event) {
        if (event is PermissionChangeEvent) {
          controller.adjustPermissionOfUser(
              userID: widget.me.id, permissionEvent: event);
          if (event.microphone != null) {
            service.changeMyMicrophone(event.microphone!);
          }
        } else if (event is UserEvent) {
          if (event.isJoin) {
            if (controller.users
                .any((element) => element.id == event.user.id)) {
              return;
            }
            controller.addUser(event.user);
          } else {
            controller.removeUser(event.user);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.mode.isUsingWebSocket) {
      service.leaveRoom();
    }
    controller.removeListener(_controllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: widget.mode != WhiteboardMode.liveTeaching &&
              widget.mode != WhiteboardMode.participant
          ? MathTutorWhiteBoard(
              mode: widget.mode,
              controller: controller,
              preloadImage: const NetworkImage('https://picsum.photos/640/320'),
              me: widget.me,
              hostID: widget.hostID,
              onAttemptToClose: () async {
                final result = await showDialog(
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
                if (result == true && mounted) {
                  Navigator.of(context).pop();
                }
              },
              onOutput: (data) {},
              onTapRecordButton: () async {
                switch (controller.recordingState) {
                  case RecordingState.idle:
                    controller.startRecording();
                    break;
                  case RecordingState.recording:
                    await controller.pauseRecording();
                    if (context.mounted) {
                      final result = await showDialog(
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
                      if (result == true) {
                        await controller.stopRecording();
                        if (mounted) {
                          Navigator.of(context)
                              .pop(File(controller.recordingPath!));
                        }
                      } else {
                        await controller.resumeRecording();
                      }
                    } else {
                      await controller.resumeRecording();
                    }
                    break;
                  case RecordingState.paused:
                    controller.resumeRecording();
                    break;
                  case RecordingState.completed:
                    break;
                  case RecordingState.error:
                    break;
                  default:
                }
              },
            )
          : FutureBuilder(
              future: initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  inputStream = service.incomingStream;
                  return MathTutorWhiteBoard(
                    controller: controller,
                    hostID: widget.hostID,
                    mode: widget.mode,
                    preloadImage:
                        const NetworkImage('https://picsum.photos/640/320'),
                    me: widget.me,
                    inputStream: inputStream,
                    onOutput: (event) {
                      if (event is WhiteboardChatMessage) {
                        service.sendChatMessage(event);
                      } else if (event is File) {
                        service.shareImageFile(event);
                      } else if (event is BroadcastPaintData) {
                        service.sendDrawingData(event);
                      } else if (event is ViewportChangeEvent) {
                        service.sendViewportChangeData(event);
                      } else if (event is PermissionChangeEvent) {
                        if (event.microphone != null) {
                          service.changeMicrophonePermission(
                              event.userID!, event.microphone!);
                        }
                        if (event.drawing != null) {
                          service.changeDrawingPermission(
                              event.userID!, event.drawing!);
                        }
                      } else {
                        throw UnimplementedError();
                      }
                    },
                    onAttemptToClose: () async {
                      if (controller.recordingState ==
                          RecordingState.recording) {
                        controller.pauseRecording();
                      }
                      final result = await showDialog(
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
                      if (result == true) {
                        service.leaveRoom();
                        controller.stopRecording();

                        if (mounted) {
                          Navigator.pop(context);
                        }
                      } else {
                        if (controller.recordingState ==
                            RecordingState.paused) {
                          controller.resumeRecording();
                        }
                      }
                    },
                    onTapRecordButton: () async {
                      switch (controller.recordingState) {
                        case RecordingState.idle:
                          controller.startRecording();
                          break;
                        case RecordingState.recording:
                          controller.pauseRecording();
                          final result = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Are you sure?'),
                              content: const Text(
                                  'You will lose all unsaved changes if you close the whiteboard.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                          if (result == true) {
                            await controller.stopRecording();
                            if (mounted) {
                              Navigator.of(context)
                                  .pop(File(controller.recordingPath!));
                            }
                          } else {
                            controller.resumeRecording();
                          }
                          break;
                        case RecordingState.paused:
                          controller.resumeRecording();
                          break;
                        case RecordingState.completed:
                          break;
                        case RecordingState.error:
                          break;
                        default:
                      }
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

  void _controllerListener() {}
}
