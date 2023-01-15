import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:ed_screen_recorder_v3/ed_screen_recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:math_tutor_whiteboard/states/chat_message_state.dart';
import 'package:math_tutor_whiteboard/states/recording_state.dart';
import 'package:math_tutor_whiteboard/states/user_list_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:permission_handler/permission_handler.dart';

import 'types.dart';
import 'whiteboard_controller.dart';

class MathTutorWhiteboardImpl extends ConsumerStatefulWidget {
  final ImageProvider? preloadImage;
  final Duration? recordDuration;
  final WhiteboardMode mode;
  final StreamController<BroadcastData> outputDrawingStream;
  final void Function(File file)? onRecordingFinished;
  final Stream<BroadcastData>? inputDrawingStream;
  final Stream<WhiteboardChatMessage>? chatStream;
  final Stream<WhiteboardUser>? userJoinStream;
  final Stream<WhiteboardUser>? userLeaveStream;
  final String myID;
  const MathTutorWhiteboardImpl(
      {required this.outputDrawingStream,
      required this.myID,
      this.chatStream,
      this.userJoinStream,
      this.userLeaveStream,
      this.inputDrawingStream,
      super.key,
      this.preloadImage,
      this.recordDuration,
      required this.mode,
      this.onRecordingFinished});

  @override
  ConsumerState<MathTutorWhiteboardImpl> createState() =>
      _MathTutorWhiteboardState();
}

class _MathTutorWhiteboardState extends ConsumerState<MathTutorWhiteboardImpl> {
  List<List<DrawingData>> drawingData = [];
  PenType penType = PenType.pen;
  double strokeWidth = 5;
  Color color = Colors.black;
  int limitCursor = 0;
  final screenRecorder = EdScreenRecorder();
  Timer? timer;
  final Map<int, int> deletedStrokes = {};
  StreamSubscription<BroadcastData>? _inputStreamSubscription;

  @override
  void initState() {
    if (widget.inputDrawingStream != null) {
      /// 여기서는 서버의 데이터를 받습니다.
      /// 서버에서 주는 데이터의 형식에 따라 지우고, 그리는 동작을
      /// 호스트의 동작대로 흉내냅니다.
      _inputStreamSubscription = widget.inputDrawingStream!.listen((event) {
        /// Command가 clear면 모든 데이터를 지웁니다.
        if (event.command == BroadcastCommand.clear) {
          _onTapClear();
        } else {
          /// 중간에 들어온 경우에는 현재의 limitCursor와 서버에서 내려준 limitCursor가 차이가 납니다.
          /// 정합성을 위해서 부족한 limitCursor 만큼 빈 스트로크를 추가합니다.
          if (limitCursor == 0 && event.limitCursor > 1) {
            drawingData.addAll(List.generate(
                event.limitCursor - limitCursor - 1, (index) => []));
            limitCursor += event.limitCursor - limitCursor - 1;
          }

          /// 선 지우기 인덱스가 null이 아닌 경우에는
          /// 선을 지우는 동작을 합니다.
          /// 이 경우에는 drawingData가 null입니다.
          if (event.removeStrokeIndex != null) {
            setState(() {
              deletedStrokes[event.limitCursor] = event.removeStrokeIndex!;
              limitCursor = event.limitCursor;
              drawingData.add([]);
            });
          }

          /// 선 지우기 인덱스가 null인 경우에는
          /// 그리기 동작이거나 Redo Undo 동작입니다.
          /// 그리기 동작이 아닐 경우에는 drawingData가 null입니다.
          else {
            setState(() {
              if (event.limitCursor == limitCursor) {
                if (event.drawingData != null) {
                  drawingData.last.add(event.drawingData!);
                }
              } else {
                limitCursor = event.limitCursor;
                if (event.drawingData != null) {
                  drawingData.add([event.drawingData!]);
                }
              }
            });
          }
        }
      });
    }
    if (widget.userJoinStream != null) {
      widget.userJoinStream!.listen((event) {
        if (event.serverUid != widget.myID) {
          Fluttertoast.showToast(msg: '${event.nickname}님이 입장하셨습니다.');
          ref.read(userListStateProvider.notifier).addUser(event);
        }
      });
    }
    if (widget.userLeaveStream != null) {
      widget.userLeaveStream!.listen((event) {
        if (event.serverUid != widget.myID) {
          Fluttertoast.showToast(msg: '${event.nickname}님이 퇴장하셨습니다.');
          ref.read(userListStateProvider.notifier).removeUser(event);
        }
      });
    }

    if (widget.chatStream != null) {
      ref
          .read(chatMessageStateProvider.notifier)
          .addMessage(const WhiteboardChatMessage(
            nickname: '시스템',
            message: '채팅방에 입장하셨습니다.',
          ));
      widget.chatStream!.listen((event) {
        ref.read(chatMessageStateProvider.notifier).addMessage(event);
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    if (_inputStreamSubscription != null) {
      _inputStreamSubscription!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
          child: Column(
        children: [
          WhiteboardController(
            onPenSelected: _onPenSelected,
            onTapEraser: _onTapEraser,
            onTapUndo: _onTapUndo,
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
          ),
          Expanded(
            child: _WhiteBoard(
                onStartDrawing: _onStartDrawing,
                deletedStrokes: deletedStrokes,
                onDrawing: _onDrawing,
                onEndDrawing: _onEndDrawing,
                drawingData: drawingData,
                limitCursor: limitCursor,
                preloadImage: widget.preloadImage),
          )
        ],
      )),
    );
  }

  void broadcast(bool remove, DrawingData data) {}

  void _onStartDrawing() {
    if (penType != PenType.strokeEraser) {
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

  void _onTapClose() {}

  void _onTapClear() {
    setState(() {
      drawingData.clear();
      deletedStrokes.clear();
      limitCursor = 0;
      widget.outputDrawingStream.add(BroadcastData(
        drawingData: null,
        command: BroadcastCommand.clear,
        limitCursor: limitCursor,
      ));
      log('clear');
    });
  }

  void _onTapUndo() {
    setState(() {
      if (limitCursor > 0) {
        limitCursor--;
        widget.outputDrawingStream.add(BroadcastData(
          drawingData: null,
          command: BroadcastCommand.draw,
          limitCursor: limitCursor,
        ));
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
        widget.outputDrawingStream.add(BroadcastData(
          drawingData: null,
          command: BroadcastCommand.draw,
          limitCursor: limitCursor,
        ));
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

  void _onTapRecord() {
    if (ref.read(recordingStateProvider).isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  Future<void> _stopRecording() async {
    final res = await screenRecorder.stopRecord();
    log('stop recording: ${res['file']}');
    ref.read(recordingStateProvider.notifier).finishRecording(res['file']);
    timer?.cancel();
  }

  Future<void> _startRecording() async {
    final micPermission = await Permission.microphone.request();
    final storagePermission = await Permission.storage.request();
    final notificationPermission = await Permission.notification.request();
    if (micPermission.isGranted &&
        storagePermission.isGranted &&
        notificationPermission.isGranted) {
      log('Permission granted');
      await screenRecorder.startRecordScreen(
          fileName: 'math_record_temp',
          audioEnable: true,
          dirPathToSave: (await getTemporaryDirectory()).path);
      log('start recording');
      ref.read(recordingStateProvider.notifier).startRecording();
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          ref.read(recordingStateProvider.notifier).tick();
          if (ref.read(recordingStateProvider).remainingTime == 0) {
            _stopRecording();
            // TODO: 안내 팝업 띄워줌
          } else if (ref.read(recordingStateProvider).remainingTime == 60 * 5) {
            // TODO: 안내 팝업 띄워줌
          }
        });
      });
    }
  }

  void _draw(PointerEvent event) {
    setState(() {
      if (penType == PenType.penEraser) {
        // 펜 지우개 모드일 때에는 그냥 흰색으로 똑같이 그려줍니다.
        drawingData.last.add(DrawingData(
            point: Point(event.localPosition.dx, event.localPosition.dy),
            color: Colors.white,
            penType: penType,
            strokeWidth: strokeWidth));
        widget.outputDrawingStream.add(BroadcastData(
          drawingData: drawingData.last.last,
          command: BroadcastCommand.draw,
          limitCursor: limitCursor,
        ));
      } else if (penType == PenType.strokeEraser) {
        /// 선지우기 모드일 때에는 좌표가 해당 선을 스칠 때 선을 통째로 지웁니다.
        /// 지우는 방식은 undo와 redo를 위해서 실제로 지우지 않습니다.
        /// 대신 [deletedStrokes] 라는 [Map]에 key-value로 {지워진 cursor}-{지워진 stroke의 index}를 저장합니다.
        /// 그리고 limitCursor의 정합성을 위해 [limitCursor]를 1 증가시키면서 drawingData에는 빈 스트로크를 채워줍니다.
        /// 그러나 deletedStrokes에 이미 지워진 stroke의 index가 있으면 지우지 않습니다.
        for (int i = 0; i < drawingData.length; i++) {
          for (int j = 0; j < drawingData[i].length; j++) {
            if (deletedStrokes.containsValue(i)) {
              continue;
            }
            final distance = sqrt(
                pow(drawingData[i][j].point.x - event.localPosition.dx, 2) +
                    pow(drawingData[i][j].point.y - event.localPosition.dy, 2));
            if (distance < strokeWidth) {
              widget.outputDrawingStream.add(BroadcastData(
                  drawingData: null,
                  command: BroadcastCommand.removeStroke,
                  limitCursor: limitCursor,
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
        widget.outputDrawingStream.add(BroadcastData(
            drawingData: drawingData.last.last,
            command: BroadcastCommand.draw,
            limitCursor: limitCursor));
      }
    });
  }
}

class _WhiteBoard extends StatelessWidget {
  final void Function() onStartDrawing;
  final void Function(PointerMoveEvent event) onDrawing;
  final void Function(PointerUpEvent event) onEndDrawing;
  final ImageProvider? preloadImage;
  final List<List<DrawingData>> drawingData;
  final int limitCursor;
  final Map<int, int> deletedStrokes;
  const _WhiteBoard(
      {Key? key,
      required this.onStartDrawing,
      required this.onDrawing,
      required this.onEndDrawing,
      this.preloadImage,
      required this.drawingData,
      required this.limitCursor,
      required this.deletedStrokes})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width,
              minHeight: MediaQuery.of(context).size.width * 16 / 9,
              maxHeight: MediaQuery.of(context).size.width * 16 / 9,
              maxWidth: MediaQuery.of(context).size.width),
          child: Listener(
            onPointerDown: (event) {
              onStartDrawing();
            },
            onPointerMove: onDrawing,
            onPointerUp: onEndDrawing,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                  ),
                ),
                if (preloadImage != null)
                  Positioned(
                      top: 0,
                      child: Image(
                        image: preloadImage!,
                        fit: BoxFit.fitWidth,
                      )),
                Positioned.fill(
                    child: CustomPaint(
                  painter: _WhiteboardPainter((() {
                    /// limitCursor 이전의 스트로크들만 그리되
                    /// limitCursor 이전의 key값이 [deletedStrokes]에 존재한다면
                    /// [deletedStrokes]의 value값에 해당하는 index를 지워줍니다.
                    final drawingBeforeLimitCursor =
                        drawingData.sublist(0, limitCursor);
                    for (int i = 0; i < drawingBeforeLimitCursor.length; i++) {
                      for (final deleteStroke in deletedStrokes.entries) {
                        if (deleteStroke.key <= limitCursor) {
                          drawingBeforeLimitCursor[deleteStroke.value] = [];
                        }
                      }
                    }
                    return drawingBeforeLimitCursor;
                  })()),
                  size: Size(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.width * 16 / 9),
                ))
              ],
            ),
          ),
        ),
      ),
    );
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
