import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math_64.dart' show Quad;

import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:math_tutor_whiteboard/states/chat_message_state.dart';
import 'package:math_tutor_whiteboard/states/recording_state.dart';
import 'package:math_tutor_whiteboard/states/user_list_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:permission_handler/permission_handler.dart';

import 'types/recording_event.dart';
import 'types/types.dart';
import 'whiteboard_controller.dart';

class MathTutorWhiteboardImpl extends ConsumerStatefulWidget {
  final ImageProvider? preloadImage;
  final Duration? recordDuration;
  final WhiteboardMode mode;
  final Stream? inputStream;
  final void Function(dynamic data)? onOutput;
  final WhiteboardUser me;
  final void Function(RecordingEvent event) onRecordingEvent;
  final Future<bool> Function() onAttemptToClose;
  final Future<bool> Function() onAttemptToCompleteRecording;
  final Future<void> Function() onBeforeTimeLimitReached;
  final Future<void> Function() onTimeLimitReached;
  final String? hostID;
  const MathTutorWhiteboardImpl({this.hostID, 
      required this.onBeforeTimeLimitReached,
      required this.onTimeLimitReached,
      required this.onOutput,
      required this.onRecordingEvent,
      this.inputStream,
      required this.onAttemptToCompleteRecording,
      required this.onAttemptToClose,
      required this.me,
      super.key,
      this.preloadImage,
      this.recordDuration,
      required this.mode});

  @override
  ConsumerState<MathTutorWhiteboardImpl> createState() =>
      _MathTutorWhiteboardState();
}

class _MathTutorWhiteboardState extends ConsumerState<MathTutorWhiteboardImpl> {
  List<List<DrawingData>> drawingData = [];
  PenType penType = PenType.pen;
  double strokeWidth = 2;
  Color color = Colors.black;
  int limitCursor = 0;
  final screenRecorder = EdScreenRecorder();
  Timer? timer;
  final Map<int, int> deletedStrokes = {};
  StreamSubscription<BroadcastPaintData>? _inputDrawingStreamSubscription;
  StreamSubscription<File>? _inputImageStreamSubscription;
  StreamSubscription<WhiteboardChatMessage>? _inputChatStreamSubscription;
  StreamSubscription<UserEvent>? _userStreamSubscription;
  StreamSubscription<ViewportChangeEvent>? _viewportChangeStreamSubscription;
  StreamSubscription<PermissionChangeEvent>? _authorityChangeStreamSubscription;
  final transformationController = TransformationController();
  late final Size boardSize;
  ImageProvider? image;
  bool drawable = false;

  @override
  void initState() {
    /// ?????? ?????? ????????? ???????????? ?????????, ??? ???????????? ?????? ???????????????.
    if (widget.preloadImage != null) {
      image = widget.preloadImage;
    }

    // ????????? ?????? ????????? ??????????????????.
    if (widget.mode != WhiteboardMode.participant) {
      drawable = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(recordingStateProvider.notifier).initialize();
      if (widget.recordDuration != null) {
        ref
            .read(recordingStateProvider.notifier)
            .updateDuration(widget.recordDuration!);
      }
      boardSize = Size(MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.width * (16 / 9));
      // boardSize = MediaQuery.of(context).size;
      if (widget.mode != WhiteboardMode.record &&
          widget.mode != WhiteboardMode.recordTeaching) {
        ref
            .read(chatMessageStateProvider.notifier)
            .addMessage(const WhiteboardChatMessage(
              nickname: '?????????',
              message: '???????????? ?????????????????????.',
            ));
        ref.read(userListStateProvider.notifier).addUser(widget.me);
      }
    });
    if (widget.inputStream != null) {
      /// ???????????? ????????? ???????????? ????????????.
      _inputDrawingStreamSubscription = widget.inputStream
          ?.where((event) => event is BroadcastPaintData)
          .map((event) => event as BroadcastPaintData)
          .listen((_inputDrawingStreamListener));

      _inputImageStreamSubscription = widget.inputStream
          ?.where((event) => event is File)
          .map((event) => event as File)
          .listen(_inputImageStreamListener);

      _userStreamSubscription = widget.inputStream
          ?.where((event) => event is UserEvent)
          .map((event) => event as UserEvent)
          .listen((event) {
        if (event.isJoin) {
          if (event.user.id != widget.me.id) {
            Fluttertoast.showToast(msg: '${event.user.nickname}?????? ?????????????????????.');
            ref.read(userListStateProvider.notifier).addUser(event.user);
          }
        } else {
          if (event.user.id != widget.me.id) {
            Fluttertoast.showToast(msg: '${event.user.nickname}?????? ?????????????????????.');
            ref.read(userListStateProvider.notifier).removeUser(event.user);
          }
        }
      });

      _inputChatStreamSubscription = widget.inputStream
          ?.where((event) => event is WhiteboardChatMessage)
          .map((event) => event as WhiteboardChatMessage)
          .listen((event) {
        ref.read(chatMessageStateProvider.notifier).addMessage(event);
      });

      _viewportChangeStreamSubscription = widget.inputStream
          ?.where((event) => event is ViewportChangeEvent)
          .map((event) => event as ViewportChangeEvent)
          .listen((event) {
        transformationController.value = event.adjustedMatrix(boardSize);
      });
      _authorityChangeStreamSubscription = widget.inputStream
          ?.where((event) => event is PermissionChangeEvent)
          .map((event) => event as PermissionChangeEvent)
          .listen((event) {
        if (event.drawing != null) {
          setState(() {
            drawable = event.drawing!;
          });
        }
      });
    }
    super.initState();
  }

  void _inputDrawingStreamListener(BroadcastPaintData event) {
    /// Command??? clear??? ?????? ???????????? ????????????.
    if (event.command == BroadcastCommand.clear) {
      _onReceiveClear();
    } else {
      /// ????????? ????????? ???????????? ????????? limitCursor??? ???????????? ????????? limitCursor??? ????????? ?????????.
      /// ???????????? ????????? ????????? limitCursor ?????? ??? ??????????????? ???????????????.
      if (limitCursor == 0 && event.limitCursor > 1) {
        drawingData.addAll(
            List.generate(event.limitCursor - limitCursor - 1, (index) => []));
        limitCursor += event.limitCursor - limitCursor - 1;
      }

      /// ??? ????????? ???????????? null??? ?????? ????????????
      /// ?????? ????????? ????????? ?????????.
      /// ??? ???????????? drawingData??? null?????????.
      if (event.removeStrokeIndex != null) {
        setState(() {
          deletedStrokes[event.limitCursor] = event.removeStrokeIndex!;
          limitCursor = event.limitCursor;
          drawingData.add([]);
        });
      }

      /// ??? ????????? ???????????? null??? ????????????
      /// ????????? ??????????????? Redo Undo ???????????????.
      /// ????????? ????????? ?????? ???????????? drawingData??? null?????????.
      /// darwingData??? null??? ?????? ????????????
      /// ???????????? ?????? ????????? ????????? ????????? ???????????????.
      else {
        final heightCoefficient = boardSize.height / event.boardSize.height;
        final widthCoefficient = boardSize.width / event.boardSize.width;
        setState(() {
          if (event.limitCursor == limitCursor) {
            if (event.drawingData != null) {
              drawingData.last.add(event.drawingData!.copyWith(
                  point: event.drawingData!.point.copyWith(
                      x: event.drawingData!.point.x * widthCoefficient,
                      y: event.drawingData!.point.y * heightCoefficient)));
            }
          } else {
            limitCursor = event.limitCursor;
            if (event.drawingData != null) {
              drawingData.add([
                event.drawingData!.copyWith(
                    point: event.drawingData!.point.copyWith(
                        x: event.drawingData!.point.x * widthCoefficient,
                        y: event.drawingData!.point.y * heightCoefficient))
              ]);
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }

    _inputDrawingStreamSubscription?.cancel();
    _inputImageStreamSubscription?.cancel();
    _userStreamSubscription?.cancel();
    _inputChatStreamSubscription?.cancel();
    _viewportChangeStreamSubscription?.cancel();
    _authorityChangeStreamSubscription?.cancel();

    transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final result = await _onTapClose();
        return result;
      },
      child: Material(
        child: SafeArea(child: Consumer(builder: (context, ref, _) {
          final busyState = ref.watch(
              recordingStateProvider.select((value) => value.precessing));
          return Stack(
            children: [
              Column(
                children: [
                  WhiteboardController(
                    onPenSelected: _onPenSelected,
                    onTapEraser: _onTapEraser,
                    onTapUndo: _onTapUndo,
                    me: widget.me,
                    hostID: widget.hostID,
                    onTapClear: _onTapClear,
                    onTapClose: _onTapClose,
                    onColorSelected: _onColorSelected,
                    isLive: widget.mode == WhiteboardMode.liveTeaching,
                    onTapRedo: _onTapRedo,
                    penType: penType,
                    selectedColor: color,
                    isRedoable: limitCursor < drawingData.length,
                    isUndoable: limitCursor > 0,
                    strokeWidth: strokeWidth,
                    onStrokeWidthChanged: _onStrokeWidthChanged,
                    onTapRecord: _onTapRecord,
                    onTapStrokeEraser: _onTapStrokeEraswer,
                    onLoadImage: _onLoadImage,
                    onSendChatMessage: _onSendChatMessage,
                    drawable: drawable,
                    onDrawingPermissionChanged: _onDrawingPermissionChanged,
                    onMicPermissionChanged: _onMicPermissionChanged,
                  ),
                  Expanded(
                    child: _WhiteBoard(
                      onStartDrawing: _onStartDrawing,
                      deletedStrokes: deletedStrokes,
                      transformationController: transformationController,
                      onDrawing: _onDrawing,
                      onEndDrawing: _onEndDrawing,
                      drawingData: drawingData,
                      limitCursor: limitCursor,
                      onViewportChange: _onViewportChange,
                      preloadImage: image,
                      drawable: drawable,
                    ),
                  )
                ],
              ),
              if (busyState)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          );
        })),
      ),
    );
  }

  void broadcast(bool remove, DrawingData data) {}

  void _onStartDrawing() {
    if (penType != PenType.strokeEraser && drawable) {
      drawingData.add([]);
      limitCursor++;
    }
  }

  void _onEndDrawing(event) {
    _draw(event);
  }

  void _onDrawing(event) {
    _draw(event);
  }

  Future<bool> _onTapClose() async {
    if (ref.read(recordingStateProvider).recorderState ==
        RecorderState.recording) {
      _pauseRecorder();

      final result = await widget.onAttemptToClose();
      if (result) {
        if (ref.read(recordingStateProvider).recorderState ==
            RecorderState.recording) {
          await _cancelRecording();
        }
        return true;
      } else {
        _startRecording();
        return false;
      }
    } else {
      final result = await widget.onAttemptToClose();
      if (result) {
        return true;
      }
    }
    return false;
  }

  void _onTapClear() {
    setState(() {
      drawingData.clear();
      deletedStrokes.clear();
      limitCursor = 0;
      widget.onOutput?.call(BroadcastPaintData(
          drawingData: null,
          command: BroadcastCommand.clear,
          limitCursor: limitCursor,
          boardSize: boardSize));
      log('clear');
    });
  }

  void _onReceiveClear() {
    setState(() {
      drawingData.clear();
      deletedStrokes.clear();
      limitCursor = 0;
    });
  }

  void _onTapUndo() {
    setState(() {
      if (limitCursor > 0) {
        limitCursor--;
        widget.onOutput?.call(BroadcastPaintData(
            drawingData: null,
            command: BroadcastCommand.draw,
            limitCursor: limitCursor,
            boardSize: boardSize));
      }
      log('undo: $limitCursor');
    });
  }

  void _onTapEraser() {
    setState(() {
      penType = PenType.penEraser;
      log('eraser selected');
    });
  }

  void _onTapStrokeEraswer() {
    setState(() {
      penType = PenType.strokeEraser;
      log('stroke eraser selected');
    });
  }

  void _onPenSelected(PenType type) {
    setState(() {
      penType = type;
      log('pen selected: $type');
    });
  }

  void _onColorSelected(Color color) {
    setState(() {
      this.color = color;
      log('color selected: $color');
    });
  }

  void _onTapRedo() {
    if (limitCursor < drawingData.length) {
      setState(() {
        limitCursor++;
        widget.onOutput?.call(BroadcastPaintData(
            drawingData: null,
            command: BroadcastCommand.draw,
            limitCursor: limitCursor,
            boardSize: boardSize));
      });
      log('redo: $limitCursor');
    }
  }

  void _onStrokeWidthChanged(double strokeWidth) {
    setState(() {
      this.strokeWidth = strokeWidth;
      log('stroke width changed: $strokeWidth');
    });
  }

  Future<void> _onTapRecord() async {
    switch (ref.read(recordingStateProvider).recorderState) {
      case RecorderState.recording:
        _pauseRecorder();
        final result = await widget.onAttemptToCompleteRecording();
        if (result == true) {
          _stopRecording();
        }
        break;
      case RecorderState.paused:
        screenRecorder.resumeRecord();
        ref.read(recordingStateProvider.notifier).startRecording();
        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          ref.read(recordingStateProvider.notifier).tick();
        });
        break;
      case RecorderState.init:
        _startRecording();
        break;
    }
  }

  void _pauseRecorder() {
    screenRecorder.pauseRecord();
    ref.read(recordingStateProvider.notifier).pauseRecording();
    timer?.cancel();
    widget.onRecordingEvent(const RecordingEvent.pause());
  }

  Future<void> _stopRecording() async {
    await ref.read(recordingStateProvider.notifier).doAsync(
      () async {
        final res = await screenRecorder.stopRecord();
        log('stop recording: ${res['file']}');
        ref.read(recordingStateProvider.notifier).finishRecording(res['file']);
        widget.onRecordingEvent(RecordingEvent.finished(res['file']));
      },
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _startRecording() async {
    final micPermission = await Permission.microphone.request();
    final notificationPermission = await Permission.notification.request();
    if (micPermission.isGranted && notificationPermission.isGranted) {
      log('Permission granted');
      await ref.read(recordingStateProvider.notifier).doAsync(() async =>
          await screenRecorder.startRecordScreen(
              fileName: 'math_record_temp',
              audioEnable: true,
              dirPathToSave: (await getTemporaryDirectory()).path));
      widget.onRecordingEvent(const RecordingEvent.recording());
      log('start recording');
      ref.read(recordingStateProvider.notifier).startRecording();
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          ref.read(recordingStateProvider.notifier).tick();
          if (ref.read(recordingStateProvider).remainingTime == 0) {
            _pauseRecorder();
            widget.onBeforeTimeLimitReached().then((value) {
              _stopRecording();
            });
          } else if (ref.read(recordingStateProvider).remainingTime == 60 * 5) {
            widget.onBeforeTimeLimitReached();
          }
        });
      });
    }
  }

  void _draw(PointerEvent event) {
    if (drawable) {
      setState(() {
        if (penType == PenType.penEraser) {
          // ??? ????????? ????????? ????????? ?????? ???????????? ????????? ???????????????.
          drawingData.last.add(DrawingData(
              point: Point(event.localPosition.dx, event.localPosition.dy),
              color: Colors.white,
              penType: penType,
              strokeWidth: strokeWidth));
          widget.onOutput?.call(BroadcastPaintData(
              drawingData: drawingData.last.last,
              command: BroadcastCommand.draw,
              limitCursor: limitCursor,
              boardSize: boardSize));
        } else if (penType == PenType.strokeEraser) {
          /// ???????????? ????????? ????????? ????????? ?????? ?????? ?????? ??? ?????? ????????? ????????????.
          /// ????????? ????????? undo??? redo??? ????????? ????????? ????????? ????????????.
          /// ?????? [deletedStrokes] ?????? [Map]??? key-value??? {????????? cursor}-{????????? stroke??? index}??? ???????????????.
          /// ????????? limitCursor??? ???????????? ?????? [limitCursor]??? 1 ?????????????????? drawingData?????? ??? ??????????????? ???????????????.
          /// ????????? deletedStrokes??? ?????? ????????? stroke??? index??? ????????? ????????? ????????????.
          /// ?????? ????????? ??? ????????? ????????? ????????? ????????? ?????? ?????? ???????????????
          /// ????????? ????????? ???????????? ?????? ????????? ???????????? ????????? ????????????.
          for (int i = 0; i < drawingData.length; i++) {
            for (int j = 0; j < drawingData[i].length; j++) {
              if (deletedStrokes.containsValue(i) ||
                  drawingData[i][j].color == Colors.white) {
                continue;
              }
              final distance = sqrt(pow(
                      drawingData[i][j].point.x - event.localPosition.dx, 2) +
                  pow(drawingData[i][j].point.y - event.localPosition.dy, 2));
              if (distance < strokeWidth) {
                widget.onOutput?.call(BroadcastPaintData(
                    drawingData: null,
                    command: BroadcastCommand.removeStroke,
                    limitCursor: limitCursor,
                    boardSize: boardSize,
                    removeStrokeIndex: i));

                setState(() {
                  drawingData.add([]);
                  deletedStrokes[++limitCursor] = i;
                  log('Stroke Erased: $i, $limitCursor');
                });
              }
            }
          }
        } else {
          drawingData.last.add(DrawingData(
              point: Point(event.localPosition.dx, event.localPosition.dy,
                  penType == PenType.pen ? event.pressure : 0.5),
              color: color,
              penType: penType,
              strokeWidth: strokeWidth));
          widget.onOutput?.call(BroadcastPaintData(
              drawingData: drawingData.last.last,
              boardSize: boardSize,
              command: BroadcastCommand.draw,
              limitCursor: limitCursor));
        }
      });
    }
  }

  Future<void> _onLoadImage(ui.Image uiImage) async {
    setState(() {
      image = UiImageProvider(uiImage);
    });
    final file = File('${(await getTemporaryDirectory()).path}/image.png');
    final imageFile = await file.create();
    final imageByte = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    await imageFile.writeAsBytes(imageByte!.buffer.asUint8List());
    widget.onOutput?.call(imageFile);
  }

  void _inputImageStreamListener(File event) {
    setState(() {
      image = FileImage(event);
    });
  }

  void _onViewportChange(Matrix4 matrix) {
    if (drawable) {
      widget.onOutput
          ?.call(ViewportChangeEvent(matrix: matrix, boardSize: boardSize));
    }
  }

  void _onSendChatMessage(String message) {
    widget.onOutput?.call(
        WhiteboardChatMessage(message: message, nickname: widget.me.nickname));
    ref.read(chatMessageStateProvider.notifier).addMessage(
        WhiteboardChatMessage(message: message, nickname: widget.me.nickname));
  }

  void _onMicPermissionChanged(WhiteboardUser user, bool allow) {
    widget.onOutput?.call(PermissionChangeEvent(microphone: allow));
    ref
        .read(userListStateProvider.notifier)
        .updatePermission(user, PermissionChangeEvent(microphone: allow));
  }

  void _onDrawingPermissionChanged(WhiteboardUser user, bool allow) {
    widget.onOutput?.call(PermissionChangeEvent(drawing: allow));
    ref
        .read(userListStateProvider.notifier)
        .updatePermission(user, PermissionChangeEvent(drawing: allow));
  }

  _cancelRecording() async {
    await screenRecorder.stopRecord();
    widget.onRecordingEvent.call(const RecordingEvent.cancelled());
  }
}

class _WhiteBoard extends StatefulWidget {
  final void Function() onStartDrawing;
  final void Function(PointerMoveEvent event) onDrawing;
  final void Function(PointerUpEvent event) onEndDrawing;
  final void Function(Matrix4 data) onViewportChange;
  final ImageProvider? preloadImage;
  final List<List<DrawingData>> drawingData;
  final int limitCursor;
  final Map<int, int> deletedStrokes;
  final TransformationController transformationController;
  final bool drawable;
  const _WhiteBoard(
      {Key? key,
      required this.onStartDrawing,
      required this.onDrawing,
      required this.onEndDrawing,
      this.preloadImage,
      required this.drawingData,
      required this.limitCursor,
      required this.deletedStrokes,
      required this.onViewportChange,
      required this.transformationController,
      required this.drawable})
      : super(key: key);

  @override
  State<_WhiteBoard> createState() => _WhiteBoardState();
}

class _WhiteBoardState extends State<_WhiteBoard> {
  bool panMode = false;
  bool isPanning = false;
  Set<int> pointers = {};
  late final TransformationController transformationController;

  @override
  void initState() {
    transformationController = widget.transformationController;
    transformationController.addListener(() {
      if (isPanning && panMode) {
        widget.onViewportChange(transformationController.value);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
        SystemUiOverlay.bottom, //This line is used for showing the bottom bar
      ]);
    });
    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        floatingActionButton: widget.drawable
            ? FloatingActionButton.small(
                onPressed: () {
                  setState(() {
                    panMode = !panMode;
                  });
                },
                backgroundColor: Colors.black,
                child:
                    Center(child: Icon(!panMode ? Icons.pan_tool : Icons.edit)),
              )
            : null,
        body: InteractiveViewer.builder(
          panEnabled: panMode,
          scaleEnabled: false,
          onInteractionStart: (details) => isPanning = true,
          onInteractionEnd: (details) => isPanning = false,
          transformationController: transformationController,
          builder: (BuildContext context, Quad viewport) {
            return Listener(
              onPointerDown: (event) {
                pointers.add(event.pointer);
                if (pointers.length > 1) {
                  setState(() {
                    panMode = true;
                  });
                }
                if (panMode) {
                  return;
                }
                widget.onStartDrawing();
              },
              onPointerMove: (event) {
                if (panMode) {
                  return;
                }
                widget.onDrawing(event);
              },
              onPointerUp: (event) {
                pointers.clear();
                if (panMode) {
                  return;
                }
                widget.onEndDrawing(event);
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 4,
                width: MediaQuery.of(context).size.width,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                    if (widget.preloadImage != null)
                      Positioned.fill(
                          child: Image(
                        image: widget.preloadImage!,
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                      )),
                    Positioned.fill(
                        child: CustomPaint(
                      painter: _WhiteboardPainter((() {
                        /// limitCursor ????????? ?????????????????? ?????????
                        /// limitCursor ????????? key?????? [deletedStrokes]??? ???????????????
                        /// [deletedStrokes]??? value?????? ???????????? index??? ???????????????.
                        final drawingBeforeLimitCursor =
                            widget.drawingData.sublist(0, widget.limitCursor);
                        for (int i = 0;
                            i < drawingBeforeLimitCursor.length;
                            i++) {
                          for (final deleteStroke
                              in widget.deletedStrokes.entries) {
                            if (deleteStroke.key <= widget.limitCursor) {
                              drawingBeforeLimitCursor[deleteStroke.value] = [];
                            }
                          }
                        }
                        return drawingBeforeLimitCursor;
                      })()),
                      size: Size(
                          MediaQuery.of(context).size.height * 9 / (16 * 4),
                          MediaQuery.of(context).size.height),
                    ))
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _WhiteboardPainter extends CustomPainter {
  final List<List<DrawingData>> drawingData;

  _WhiteboardPainter(this.drawingData);
  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in drawingData) {
      if (stroke.isEmpty) {
        continue;
      }
      final paint = Paint()
        ..color = stroke.first.penType != PenType.highlighter
            ? stroke.first.color
            : stroke.first.color.withOpacity(0.5)
        ..strokeCap = stroke.first.penType == PenType.pen
            ? StrokeCap.round
            : StrokeCap.square
        ..style = PaintingStyle.fill
        ..strokeWidth = stroke.first.strokeWidth;
      final points = getStroke(stroke.map((e) => e.point).toList(),
          size: stroke.first.strokeWidth,
          thinning: stroke.first.penType == PenType.pen ? 0.5 : 0.0);
      final path = Path();
      if (points.isEmpty) {
        return;
      } else if (points.length == 1) {
        path.addOval(Rect.fromCircle(
            center: Offset(points[0].x, points[0].y),
            radius: stroke.first.strokeWidth));
      } else {
        path.moveTo(points[0].x, points[0].y);
        for (int i = 1; i < points.length - 1; ++i) {
          final p0 = points[i];
          final p1 = points[i + 1];
          path.quadraticBezierTo(
              p0.x, p0.y, (p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    return true;
  }
}
