import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math_64.dart' show Quad;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:math_tutor_whiteboard/states/chat_message_state.dart';
import 'package:math_tutor_whiteboard/states/user_list_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'change_notifier_builder.dart';
import 'types/types.dart';
import 'whiteboard_controller.dart';
import 'whiteboard_controller_view.dart';

class MathTutorWhiteboardImpl extends ConsumerStatefulWidget {
  final WhiteboardController? controller;
  final ImageProvider? preloadImage;
  final WhiteboardMode mode;
  final Stream? inputStream;
  final void Function(dynamic data)? onOutput;
  final WhiteboardUser me;
  final FutureOr<void> Function() onAttemptToClose;
  final VoidCallback onTapRecordButton;
  final String? hostID;
  final Future<InitialUserListEvent> Function()? onGetInitialUserList;
  const MathTutorWhiteboardImpl({
    super.key,
    this.controller,
    this.preloadImage,
    required this.mode,
    this.inputStream,
    this.onOutput,
    required this.me,
    required this.onAttemptToClose,
    required this.onTapRecordButton,
    this.hostID,
    this.onGetInitialUserList,
  });

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
  late final WhiteboardController controller;

  @override
  void initState() {
    controller = widget.controller ??
        WhiteboardController(
            recordDuration: const Duration(minutes: 20),
            recorder: DefaultRecorder());

    /// 만약 미리 주입된 이미지가 있다면, 그 이미지를 미리 불러옵니다.
    if (widget.preloadImage != null) {
      image = widget.preloadImage;
    }

    // 모드에 따라 권한을 초기화합니다.
    if (widget.mode != WhiteboardMode.participant) {
      drawable = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      boardSize = Size(MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.width * (16 / 9));
      // boardSize = MediaQuery.of(context).size;
      if (widget.mode != WhiteboardMode.record &&
          widget.mode != WhiteboardMode.recordTeaching) {
        ref
            .read(chatMessageStateProvider.notifier)
            .addMessage(const WhiteboardChatMessage(
              nickname: '시스템',
              message: '채팅방에 입장하셨습니다.',
            ));
        ref.read(userListStateProvider.notifier).addUser(widget.me);
      }
    });
    if (widget.inputStream != null) {
      widget.inputStream?.listen((event) {
        log('Whiteboard Received Event: $event');
      });

      /// 여기서는 서버의 데이터를 받습니다.
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
            Fluttertoast.showToast(msg: '${event.user.nickname}님이 입장하셨습니다.');
            ref.read(userListStateProvider.notifier).addUser(event.user);
          }
        } else {
          if (event.user.id != widget.me.id) {
            Fluttertoast.showToast(msg: '${event.user.nickname}님이 퇴장하셨습니다.');
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
      if (widget.onGetInitialUserList != null) {
        widget.onGetInitialUserList!.call().then((value) {
          ref.read(userListStateProvider.notifier).refreshUsers(value.users);
        });
      }
    }
    super.initState();
  }

  void _inputDrawingStreamListener(BroadcastPaintData event) {
    /// Command가 clear면 모든 데이터를 지웁니다.
    if (event.command == BroadcastCommand.clear) {
      _onReceiveClear();
    } else {
      /// 중간에 들어온 경우에는 현재의 limitCursor와 서버에서 내려준 limitCursor가 차이가 납니다.
      /// 정합성을 위해서 부족한 limitCursor 만큼 빈 스트로크를 추가합니다.
      if (limitCursor == 0 && event.limitCursor > 1) {
        drawingData.addAll(
            List.generate(event.limitCursor - limitCursor - 1, (index) => []));
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
      /// darwingData가 null이 아닐 경우에는
      /// 호스트의 보드 크기를 참조해 좌표를 조정합니다.
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
        await widget.onAttemptToClose();
        return false;
      },
      child: Material(
        child: SafeArea(child: Consumer(builder: (context, ref, _) {
          return Column(
            children: [
              ChangeNotifierBuilder(
                  notifier: controller,
                  builder: (context, controller, _) {
                    if (controller != null) {
                      return WhiteboardControllerView(
                        controller: controller,
                        onPenSelected: _onPenSelected,
                        onTapEraser: _onTapEraser,
                        onTapUndo: _onTapUndo,
                        me: widget.me,
                        hostID: widget.hostID,
                        onTapClear: _onTapClear,
                        onTapClose: widget.onAttemptToClose,
                        onColorSelected: _onColorSelected,
                        isLive: widget.mode == WhiteboardMode.liveTeaching ||
                            widget.mode == WhiteboardMode.participant,
                        onTapRedo: _onTapRedo,
                        penType: penType,
                        selectedColor: color,
                        isRedoable: limitCursor < drawingData.length,
                        isUndoable: limitCursor > 0,
                        strokeWidth: strokeWidth,
                        onStrokeWidthChanged: _onStrokeWidthChanged,
                        onTapRecord: widget.onTapRecordButton,
                        onTapStrokeEraser: _onTapStrokeEraswer,
                        onLoadImage: _onLoadImage,
                        onSendChatMessage: _onSendChatMessage,
                        drawable: drawable,
                        onDrawingPermissionChanged: _onDrawingPermissionChanged,
                        onMicPermissionChanged: _onMicPermissionChanged,
                      );
                    } else {
                      return const SizedBox();
                    }
                  }),
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
          );
        })),
      ),
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

  void _draw(PointerEvent event) {
    setState(() {
      if (penType == PenType.penEraser) {
        // 펜 지우개 모드일 때에는 그냥 흰색으로 똑같이 그려줍니다.
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
        /// 선지우기 모드일 때에는 좌표가 해당 선을 스칠 때 선을 통째로 지웁니다.
        /// 지우는 방식은 undo와 redo를 위해서 실제로 지우지 않습니다.
        /// 대신 [deletedStrokes] 라는 [Map]에 key-value로 {지워진 cursor}-{지워진 stroke의 index}를 저장합니다.
        /// 그리고 limitCursor의 정합성을 위해 [limitCursor]를 1 증가시키면서 drawingData에는 빈 스트로크를 채워줍니다.
        /// 그러나 deletedStrokes에 이미 지워진 stroke의 index가 있으면 지우지 않습니다.
        /// 또한 흰색은 펜 지우개 모드가 아니면 선택할 수가 없는 색상이므로
        /// 흰색은 지우개 모드에서 그린 선으로 간주하고 지우지 않습니다.
        for (int i = 0; i < drawingData.length; i++) {
          for (int j = 0; j < drawingData[i].length; j++) {
            if (deletedStrokes.containsValue(i) ||
                drawingData[i][j].color == Colors.white) {
              continue;
            }
            final distance = sqrt(
                pow(drawingData[i][j].point.x - event.localPosition.dx, 2) +
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
    widget.onOutput
        ?.call(ViewportChangeEvent(matrix: matrix, boardSize: boardSize));
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
                if (widget.drawable) {
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
                }
              },
              onPointerMove: (event) {
                if (widget.drawable) {
                  if (panMode) {
                    return;
                  }
                  widget.onDrawing(event);
                }
              },
              onPointerUp: (event) {
                if (widget.drawable) {
                  pointers.clear();
                  if (panMode) {
                    return;
                  }
                  widget.onEndDrawing(event);
                }
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
                        /// limitCursor 이전의 스트로크들만 그리되
                        /// limitCursor 이전의 key값이 [deletedStrokes]에 존재한다면
                        /// [deletedStrokes]의 value값에 해당하는 index를 지워줍니다.
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
