import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:example/platform_channel.dart';
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
  late final MathtutorNeotechPluginPlatform channel;
  late final Future initFuture;
  late final WhiteboardController controller;
  @override
  void initState() {
    if (widget.mode == WhiteboardMode.liveTeaching ||
        widget.mode == WhiteboardMode.participant) {
      channel = PlatformChannelImpl();
      initFuture = (() async {
        try {
          await channel.initialize(
              userID: widget.me.id,
              nickname: widget.me.id,
              ownerID: widget.hostID!);
          await channel.login();

          final userList = await channel.getUserList();
          final users = jsonDecode(userList['data']) as List;
          final whiteboardUsers = users
              .map<WhiteboardUser>((e) => WhiteboardUser(
                  nickname: e['id'],
                  micEnabled: e['isAudioOn'] ?? false,
                  drawingEnabled: e['isDocOn'] ?? false,
                  id: e['id'],
                  isHost: e['id'] == widget.me.id))
              .toList();
          for (final user in whiteboardUsers) {
            controller.addUser(user);
          }
        } catch (e) {
          Navigator.of(context).pop();
        }
        if (widget.me.id == widget.hostID) {
          await channel.turnOnMicrophone(true);
        } else {
          await channel.turnOnMicrophone(false);
        }
      })();
    }
    controller = WhiteboardController(
        recordDuration: const Duration(minutes: 20),
        recorder: DefaultRecorder());
    controller.addListener(_controllerListener);
    super.initState();
    if (widget.mode == WhiteboardMode.liveTeaching ||
        widget.mode == WhiteboardMode.participant) {
      channel.incomingStream.stream.listen((event) {
        if (event is UserEvent) {
          if (event.isJoin) {
            if (controller.users.any((element) =>
                element.id.toLowerCase() == event.user.id.toLowerCase())) {
              log('비정상 종료된 ${event.user.nickname}님이 접속했습니다.');
            } else {
              controller.addUser(event.user);
              log('${event.user.nickname}님이 접속했습니다.');
            }
          } else {
            controller.removeUser(event.user);
            log('${event.user.nickname}님이 나갔습니다.');
          }
        } else if (event is PermissionChangeEvent) {
          controller.adjustPermissionOfUser(
              userID: widget.me.id, permissionEvent: event);
          if (event.microphone != null) {
            channel.turnOnMicrophone(event.microphone!);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.mode == WhiteboardMode.liveTeaching ||
        widget.mode == WhiteboardMode.participant) {
      channel.logout();
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
                    controller.pauseRecording();
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
                        Navigator.of(context).pop();
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
            )
          : FutureBuilder(
              future: initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  inputStream = channel.incomingStream.stream;
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
                      } else if (event is PermissionChangeEvent) {
                        if (event.microphone != null) {
                          channel.changePermissionAudio(event.userID!);
                        }
                        if (event.drawing != null) {
                          channel.changePermissionDoc(event.userID!);
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
                        channel.logout();
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
                              Navigator.of(context).pop();
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