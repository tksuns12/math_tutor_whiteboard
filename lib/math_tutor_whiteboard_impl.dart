import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:math_tutor_whiteboard/types/features.dart';
import 'package:math_tutor_whiteboard/types/pointer_manager.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math_64.dart' show Quad;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_tutor_whiteboard/states/chat_message_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'change_notifier_builder.dart';
import 'types/types.dart';
import 'whiteboard_controller.dart';
import 'whiteboard_controller_view.dart';

class MathTutorWhiteboardImpl extends ConsumerStatefulWidget {
  final WhiteboardController? controller;
  final ImageProvider? preloadImage;
  final Stream? inputStream;
  final void Function(dynamic data)? onOutput;
  final WhiteboardUser me;
  final FutureOr<void> Function() onAttemptToClose;
  final VoidCallback onTapRecordButton;
  final void Function(File file)? onLoadNewImage;
  final Duration maxRecordingDuration;
  final Set<WhiteboardFeature> enabledFeatures;
  final String? hostID;
  final BatchDrawingData? preDrawnData;
  const MathTutorWhiteboardImpl({
    this.preDrawnData,
    this.hostID,
    required this.enabledFeatures,
    required this.maxRecordingDuration,
    required this.onLoadNewImage,
    super.key,
    this.controller,
    this.preloadImage,
    this.inputStream,
    this.onOutput,
    required this.me,
    required this.onAttemptToClose,
    required this.onTapRecordButton,
  });

  @override
  ConsumerState<MathTutorWhiteboardImpl> createState() =>
      _MathTutorWhiteboardState();
}

class _MathTutorWhiteboardState extends ConsumerState<MathTutorWhiteboardImpl> {
  Map<String, List<List<DrawingData>>> userDrawingData = {};
  PenType penType = PenType.pen;
  double strokeWidth = 2;
  Color color = Colors.black;
  Map<String, int> userLimitCursor = {};
  Timer? timer;
  final Map<String, Map<int, int>> userDeletedStrokes = {};
  StreamSubscription<BroadcastPaintData>? _inputDrawingStreamSubscription;
  StreamSubscription<ImageChangeEvent>? _inputImageStreamSubscription;
  StreamSubscription<WhiteboardChatMessage>? _inputChatStreamSubscription;
  StreamSubscription<ViewportChangeEvent>? _viewportChangeStreamSubscription;
  StreamSubscription<PermissionChangeEvent>? _authorityChangeStreamSubscription;
  StreamSubscription<LiveEndTimeChangeEvent>? _durationChangeStreamSubscription;
  StreamSubscription<RequestDrawingData>? _requestDrawingDataSubscription;
  final transformationController = TransformationController();
  late final Size boardSize;
  ImageProvider? image;
  bool drawable = true;
  late final WhiteboardController controller;
  Map<String, List<List<DrawingData>>> hydratedUserDrawingData = {};

  @override
  void initState() {
    drawable = true;
    userLimitCursor = {widget.me.id: 0};
    userDeletedStrokes.addAll({widget.me.id: {}});
    userDrawingData.addAll({widget.me.id: []});
    controller = widget.controller ??
        WhiteboardController(
            recordDuration: widget.maxRecordingDuration,
            recorder: DefaultRecorder());

    /// 만약 미리 주입된 이미지가 있다면, 그 이미지를 미리 불러옵니다.
    if (widget.preloadImage != null) {
      image = widget.preloadImage;
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.preDrawnData != null) {
        setState(() {
          userDrawingData = Map<String, List<List<DrawingData>>>.from(
              widget.preDrawnData!.drawingData);
          userLimitCursor =
              Map<String, int>.from(widget.preDrawnData!.limitCursor);
          userDeletedStrokes.clear();
          userDeletedStrokes.addAll(widget.preDrawnData!.deletedStrokes);
        });
        if (userDrawingData[widget.me.id] == null) {
          userDrawingData.addAll({widget.me.id: []});
        }
        if (userLimitCursor[widget.me.id] == null) {
          userLimitCursor.addAll({widget.me.id: 0});
        }

        if (userDeletedStrokes[widget.me.id] == null) {
          userDeletedStrokes.addAll({widget.me.id: {}});
        }
      }
      boardSize = Size(MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.width * (16 / 9));
      // boardSize = MediaQuery.of(context).size;
      if (widget.enabledFeatures.contains(WhiteboardFeature.chat)) {
        ref.read(chatMessageStateProvider.notifier).addMessage(
            WhiteboardChatMessage(
                nickname: '시스템',
                message: '채팅방에 입장하셨습니다.',
                sentAt: DateTime.now()));
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
          ?.where((event) => event is ImageChangeEvent)
          .map((event) => event as ImageChangeEvent)
          .listen(_inputImageStreamListener);

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
        if (event.drawing != null && widget.me.id == event.userID) {
          setState(() {
            drawable = event.drawing!;
          });
        }
        if (event.microphone != null && widget.me.id == event.userID) {
          controller.adjustPermissionOfUser(
              userID: event.userID!,
              permissionEvent:
                  PermissionChangeEvent(microphone: event.microphone!));
        }
        if (event.drawing != null) {
          controller.adjustPermissionOfUser(
              userID: event.userID!,
              permissionEvent: PermissionChangeEvent(drawing: event.drawing!));
        }
      });
      _durationChangeStreamSubscription = widget.inputStream
          ?.where((event) => event is LiveEndTimeChangeEvent)
          .map((event) => event as LiveEndTimeChangeEvent)
          .listen((event) {
        controller.setLiveTime(
          liveEndAt: event.endAt,
          liveEndExtraDuration: event.duration,
        );
        controller.startUpdatingLiveTime();
      });

      _requestDrawingDataSubscription = widget.inputStream
          ?.where((event) => event is RequestDrawingData)
          .map((event) => event as RequestDrawingData)
          .listen((event) {
        widget.onOutput?.call(
          BatchDrawingData(
            drawingData: userDrawingData,
            limitCursor: userLimitCursor,
            deletedStrokes: userDeletedStrokes,
            userID: event.participantID,
          ),
        );
      });
    }
    super.initState();
  }

  void _inputDrawingStreamListener(BroadcastPaintData event) {
    /// Command가 clear면 모든 데이터를 지웁니다.
    if (event.command == BroadcastCommand.clear) {
      _onReceiveClear(event.userID);
    } else {
      if (userLimitCursor[event.userID] == null) {
        userLimitCursor[event.userID] = 0;
      }

      if (userDeletedStrokes[event.userID] == null) {
        userDeletedStrokes[event.userID] = {};
      }

      if (userDrawingData[event.userID] == null) {
        userDrawingData[event.userID] = [[]];
      }

      /// 중간에 들어온 경우에는 현재의 limitCursor와 서버에서 내려준 limitCursor가 차이가 납니다.
      /// 정합성을 위해서 부족한 limit Cursor 만큼 빈 스트로크를 추가합니다.
      if (userLimitCursor[event.userID] == 0 && event.limitCursor > 1) {
        userDrawingData[event.userID]!.addAll(List.generate(
            event.limitCursor - userLimitCursor[event.userID]! - 1,
            (index) => []));
        userLimitCursor[event.userID] = event.limitCursor - 1;
      }

      /// 선 지우기 인덱스가 null이 아닌 경우에는
      /// 선을 지우는 동작을 합니다.
      /// 이 경우에는 drawingData가 null입니다.
      if (event.removeStrokeIndex != null) {
        if (userDeletedStrokes[event.userID] == null) {
          userDeletedStrokes[event.userID] = {};
        }
        setState(() {
          userDeletedStrokes[event.userID]![event.limitCursor] =
              event.removeStrokeIndex!;
          userLimitCursor[event.userID] = event.limitCursor;
          userDrawingData[event.userID]!.add([]);
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
          if (event.limitCursor == userLimitCursor[event.userID]) {
            if (event.drawingData != null) {
              userDrawingData[event.userID]!.last.add(
                    event.drawingData!.copyWith(
                      point: event.drawingData!.point.copyWith(
                          x: event.drawingData!.point.x * widthCoefficient,
                          y: event.drawingData!.point.y * heightCoefficient),
                      userID: event.userID,
                    ),
                  );
            }
          } else {
            userLimitCursor[event.userID] = event.limitCursor;
            if (event.drawingData != null) {
              if (userDrawingData[event.userID]!.length <
                  userLimitCursor[event.userID]!) {
                userDrawingData[event.userID]!.add([]);
              }

              /// 간혹 멀티 터치 오류로 limitCursor가 더하기 1을 건너뛰고 들어오는 경우가 있습니다.
              /// 원리 상 . 하나일 수밖에 없기 때문에 생략을 해도 상관이 없어서 정합성을 위해 그냥 빈 스트로크 하나를 추가하고
              /// 그 다음에 들어오는 데이터를 추가합니다.
              if (userLimitCursor[event.userID]! >
                  userDrawingData[event.userID]!.length) {
                userDrawingData[event.userID]!.add([]);
              }
              userDrawingData[event.userID]![
                  userLimitCursor[event.userID]! - 1] = [
                event.drawingData!.copyWith(
                  point: event.drawingData!.point.copyWith(
                      x: event.drawingData!.point.x * widthCoefficient,
                      y: event.drawingData!.point.y * heightCoefficient),
                  userID: event.userID,
                )
              ];
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
    _inputChatStreamSubscription?.cancel();
    _viewportChangeStreamSubscription?.cancel();
    _authorityChangeStreamSubscription?.cancel();
    _durationChangeStreamSubscription?.cancel();
    _requestDrawingDataSubscription?.cancel();

    transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(child: Consumer(builder: (context, ref, _) {
        return Column(
          children: [
            ChangeNotifierBuilder(
                notifier: controller,
                builder: (context, controller, _) {
                  if (controller != null) {
                    return WhiteboardControllerView(
                      recordable: widget.enabledFeatures
                          .contains(WhiteboardFeature.recording),
                      controller: controller,
                      onPenSelected: _onPenSelected,
                      onTapEraser: _onTapEraser,
                      onTapUndo: _onTapUndo,
                      me: widget.me,
                      onTapClear: _onTapClear,
                      hostID: widget.hostID,
                      onTapClose: widget.onAttemptToClose,
                      onColorSelected: _onColorSelected,
                      canLoadImage: widget.enabledFeatures
                          .contains(WhiteboardFeature.modifyPhoto),
                      onTapRedo: _onTapRedo,
                      penType: penType,
                      selectedColor: color,
                      isRedoable: userLimitCursor[widget.me.id]! <
                          userDrawingData[widget.me.id]!.length,
                      isUndoable: userLimitCursor[widget.me.id]! > 0,
                      strokeWidth: strokeWidth,
                      onStrokeWidthChanged: _onStrokeWidthChanged,
                      onTapRecord: widget.onTapRecordButton,
                      onTapStrokeEraser: _onTapStrokeEraswer,
                      onLoadImage: _onLoadImage,
                      onSendChatMessage: _onSendChatMessage,
                      drawable: drawable,
                      onDrawingPermissionChanged: _onDrawingPermissionChanged,
                      onMicPermissionChanged: _onMicPermissionChanged,
                      onRequestDrawingPermission: _onRequestDrawingPermission,
                    );
                  } else {
                    return const SizedBox();
                  }
                }),
            Expanded(
              child: _WhiteBoard(
                onStartDrawing: _onStartDrawing,
                userDeletedStrokes: userDeletedStrokes,
                transformationController: transformationController,
                onDrawing: _onDrawing,
                onEndDrawing: _onEndDrawing,
                userDrawingData: userDrawingData,
                userLimitCursor: userLimitCursor,
                onViewportChange: _onViewportChange,
                preloadImage: image,
                drawable: drawable,
                isSpannable:
                    widget.enabledFeatures.contains(WhiteboardFeature.span),
              ),
            )
          ],
        );
      })),
    );
  }

  void _onStartDrawing() {
    if (penType != PenType.strokeEraser) {
      // If there is redo data, delete all of them and start from there
      if (userLimitCursor[widget.me.id]! <
          userDrawingData[widget.me.id]!.length) {
        userDrawingData[widget.me.id]!.removeRange(
            userLimitCursor[widget.me.id]!,
            userDrawingData[widget.me.id]!.length);
      }
      userDrawingData[widget.me.id]!.add([]);
      userLimitCursor[widget.me.id] = userLimitCursor[widget.me.id]! + 1;
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
      setState(() {
        userDrawingData[widget.me.id]!.clear();
        userDeletedStrokes[widget.me.id]!.clear();
        userLimitCursor[widget.me.id] = 0;
        widget.onOutput?.call(BroadcastPaintData(
            drawingData: null,
            command: BroadcastCommand.clear,
            limitCursor: userLimitCursor[widget.me.id]!,
            userID: widget.me.id,
            boardSize: boardSize));
        log('clear');
      });
    });
  }

  void _onReceiveClear(String userID) {
    setState(() {
      userDrawingData[userID]?.clear();
      userDeletedStrokes[userID]?.clear();
      userLimitCursor[userID] = 0;
    });
  }

  void _onTapUndo() {
    setState(() {
      if (userLimitCursor[widget.me.id]! > 0) {
        userLimitCursor[widget.me.id] = userLimitCursor[widget.me.id]! - 1;
        widget.onOutput?.call(
          BroadcastPaintData(
            drawingData: null,
            command: BroadcastCommand.draw,
            limitCursor: userLimitCursor[widget.me.id]!,
            userID: widget.me.id,
            boardSize: boardSize,
          ),
        );
      }
      log('undo: $userLimitCursor');
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
    if (userLimitCursor[widget.me.id]! <
        userDrawingData[widget.me.id]!.length) {
      setState(() {
        userLimitCursor[widget.me.id] = userLimitCursor[widget.me.id]! + 1;

        widget.onOutput?.call(BroadcastPaintData(
            drawingData: null,
            command: BroadcastCommand.draw,
            limitCursor: userLimitCursor[widget.me.id]!,
            boardSize: boardSize,
            userID: widget.me.id));
      });
      log('redo: $userLimitCursor');
    }
  }

  void _onStrokeWidthChanged(double strokeWidth) {
    setState(() {
      this.strokeWidth = strokeWidth;
      log('stroke width changed: $strokeWidth');
    });
  }

  void _draw(PointerEvent event) {
    setState(
      () {
        if (penType == PenType.penEraser) {
          // 펜 지우개 모드일 때에는 그냥 흰색으로 똑같이 그려줍니다.
          userDrawingData[widget.me.id]!.last.add(DrawingData(
              point: Point(event.localPosition.dx, event.localPosition.dy,
                  event.pressure),
              color: Colors.white,
              userID: widget.me.id,
              penType: penType,
              strokeWidth: strokeWidth));
          widget.onOutput?.call(
            BroadcastPaintData(
              drawingData: userDrawingData[widget.me.id]!.last.last,
              command: BroadcastCommand.draw,
              limitCursor: userLimitCursor[widget.me.id]!,
              userID: widget.me.id,
              boardSize: boardSize,
            ),
          );
        } else if (penType == PenType.strokeEraser) {
          /// 선지우기 모드일 때에는 좌표가 해당 선을 스칠 때 선을 통째로 지웁니다.
          /// 지우는 방식은 undo와 redo를 위해서 실제로 지우지 않습니다.
          /// 대신 [deletedStrokes] 라는 [Map]에 key-value로 {지워진 cursor}-{지워진 stroke의 index}를 저장합니다.
          /// 그리고 limitCursor의 정합성을 위해 [limitCursor]를 1 증가시키면서 drawingData에는 빈 스트로크를 채워줍니다.
          /// 그러나 deletedStrokes에 이미 지워진 stroke의 index가 있으면 지우지 않습니다.
          /// 또한 흰색은 펜 지우개 모드가 아니면 선택할 수가 없는 색상이므로
          /// 흰색은 지우개 모드에서 그린 선으로 간주하고 지우지 않습니다.
          for (int i = 0; i < userDrawingData[widget.me.id]!.length; i++) {
            for (int j = 0; j < userDrawingData[widget.me.id]![i].length; j++) {
              if (userDeletedStrokes[widget.me.id]!.containsValue(i) ||
                  userDrawingData[widget.me.id]![i][j].color == Colors.white) {
                continue;
              }
              final distance = sqrt(pow(
                      userDrawingData[widget.me.id]![i][j].point.x -
                          event.localPosition.dx,
                      2) +
                  pow(
                      userDrawingData[widget.me.id]![i][j].point.y -
                          event.localPosition.dy,
                      2));
              if (distance < strokeWidth) {
                widget.onOutput?.call(
                  BroadcastPaintData(
                    drawingData: null,
                    command: BroadcastCommand.removeStroke,
                    limitCursor: userLimitCursor[widget.me.id]!,
                    userID: widget.me.id,
                    boardSize: boardSize,
                    removeStrokeIndex: i,
                  ),
                );

                setState(
                  () {
                    userDrawingData[widget.me.id]!.add([]);
                    userLimitCursor[widget.me.id] =
                        userLimitCursor[widget.me.id]! + 1;
                    userDeletedStrokes[widget.me.id]![
                        userLimitCursor[widget.me.id]!] = i;
                    log('Stroke Erased: $i, $userLimitCursor');
                  },
                );
              }
            }
          }
        } else {
          userDrawingData[widget.me.id]!.last.add(
                DrawingData(
                  point: Point(event.localPosition.dx, event.localPosition.dy,
                      penType == PenType.pen ? event.pressure : 0.5),
                  color: color,
                  userID: widget.me.id,
                  penType: penType,
                  strokeWidth: strokeWidth,
                ),
              );
          widget.onOutput?.call(
            BroadcastPaintData(
              drawingData: userDrawingData[widget.me.id]!.last.last,
              boardSize: boardSize,
              command: BroadcastCommand.draw,
              limitCursor: userLimitCursor[widget.me.id]!,
              userID: widget.me.id,
            ),
          );
          log('Drawn: ${BroadcastPaintData(
            drawingData: userDrawingData[widget.me.id]!.last.last,
            boardSize: boardSize,
            command: BroadcastCommand.draw,
            limitCursor: userLimitCursor[widget.me.id]!,
            userID: widget.me.id,
          ).toString()}');
        }
      },
    );
  }

  Future<void> _onLoadImage(ui.Image uiImage) async {
    setState(() {
      image = UiImageProvider(uiImage);
    });
    final file = File('${(await getTemporaryDirectory()).path}/image.png');
    final imageFile = await file.create();
    final imageByte = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    await imageFile.writeAsBytes(imageByte!.buffer.asUint8List());
    widget.onLoadNewImage?.call(imageFile);
  }

  void _inputImageStreamListener(ImageChangeEvent event) {
    setState(() {
      image = CachedNetworkImageProvider(event.imageUrl);
    });
  }

  void _onViewportChange(Matrix4 matrix) {
    widget.onOutput?.call(
      ViewportChangeEvent(
        matrix: matrix,
        boardSize: boardSize,
      ),
    );
  }

  void _onSendChatMessage(String message) {
    widget.onOutput?.call(
      WhiteboardChatMessage(
        message: message,
        nickname: widget.me.nickname,
        sentAt: DateTime.now(),
      ),
    );
    ref.read(chatMessageStateProvider.notifier).addMessage(
          WhiteboardChatMessage(
            message: message,
            nickname: widget.me.nickname,
            sentAt: DateTime.now(),
          ),
        );
  }

  void _onMicPermissionChanged(WhiteboardUser user, bool allow) {
    widget.onOutput
        ?.call(PermissionChangeEvent(microphone: allow, userID: user.id));
    controller.adjustPermissionOfUser(
        userID: user.id,
        permissionEvent:
            PermissionChangeEvent(microphone: allow, userID: user.id));
  }

  void _onDrawingPermissionChanged(WhiteboardUser user, bool allow) {
    widget.onOutput
        ?.call(PermissionChangeEvent(drawing: allow, userID: user.id));
    controller.adjustPermissionOfUser(
        userID: user.id,
        permissionEvent:
            PermissionChangeEvent(drawing: allow, userID: user.id));
  }

  void _onRequestDrawingPermission() {
    widget.onOutput?.call(
      DrawingPermissionRequest(
        nickname: widget.me.nickname,
        userID: widget.me.id,
      ),
    );
  }
}

class _WhiteBoard extends StatefulWidget {
  final void Function() onStartDrawing;
  final void Function(PointerMoveEvent event) onDrawing;
  final void Function(PointerUpEvent event) onEndDrawing;
  final void Function(Matrix4 data) onViewportChange;
  final ImageProvider? preloadImage;
  final Map<String, List<List<DrawingData>>> userDrawingData;
  final Map<String, int> userLimitCursor;
  final Map<String, Map<int, int>> userDeletedStrokes;
  final TransformationController transformationController;
  final bool drawable;
  final bool isSpannable;
  const _WhiteBoard(
      {Key? key,
      required this.onStartDrawing,
      required this.onDrawing,
      required this.onEndDrawing,
      this.preloadImage,
      required this.userDrawingData,
      required this.userLimitCursor,
      required this.userDeletedStrokes,
      required this.onViewportChange,
      required this.transformationController,
      required this.drawable,
      required this.isSpannable})
      : super(key: key);

  @override
  State<_WhiteBoard> createState() => _WhiteBoardState();
}

class _WhiteBoardState extends State<_WhiteBoard> {
  bool panMode = false;
  final pointerManager = PointerManager();
  late final TransformationController transformationController;

  @override
  void initState() {
    transformationController = widget.transformationController;
    transformationController.addListener(() {
      if (panMode && pointerManager.pointers.isNotEmpty) {
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
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: widget.drawable && widget.isSpannable
            ? FloatingActionButton.small(
                onPressed: () {
                  setState(() {
                    panMode = !panMode;
                  });
                },
                backgroundColor: Colors.black,
                child: Center(
                    child: Icon(
                  !panMode ? Icons.pan_tool : Icons.edit,
                  color: Colors.white,
                )),
              )
            : null,
        body: InteractiveViewer.builder(
          panEnabled: panMode,
          scaleEnabled: false,
          transformationController: transformationController,
          builder: (BuildContext context, Quad viewport) {
            return Listener(
              onPointerDown: (event) {
                if (widget.drawable) {
                  pointerManager.addPointer(
                    pointer: event.pointer,
                    deviceKind: event.kind,
                  );
                  if (panMode) {
                    return;
                  }
                  if (!pointerManager.isStylusMode) {
                    widget.onStartDrawing();
                  } else {
                    if (event.kind == PointerDeviceKind.invertedStylus ||
                        event.kind == PointerDeviceKind.stylus) {
                      widget.onStartDrawing();
                    }
                  }
                }
              },
              onPointerMove: (event) {
                if (widget.drawable) {
                  if (panMode || pointerManager.isInMultiplePointers) {
                    return;
                  }
                  if (!pointerManager.isStylusMode) {
                    widget.onDrawing(event);
                  } else {
                    if (event.kind == PointerDeviceKind.invertedStylus ||
                        event.kind == PointerDeviceKind.stylus) {
                      widget.onDrawing(event);
                    }
                  }
                }
              },
              onPointerUp: (event) {
                if (widget.drawable) {
                  pointerManager.popPointer(
                      pointer: event.pointer, deviceKind: event.kind);
                  if (panMode) {
                    return;
                  }
                  if (!pointerManager.isStylusMode) {
                    widget.onEndDrawing(event);
                  } else {
                    if (event.kind == PointerDeviceKind.invertedStylus ||
                        event.kind == PointerDeviceKind.stylus) {
                      widget.onEndDrawing(event);
                    }
                  }
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
                      painter: _WhiteboardPainter(_makeRealDrawingData()),
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

  Map<String, List<List<DrawingData>>> _makeRealDrawingData() {
    /// limitCursor 이전의 스트로크들만 그리되
    /// limitCursor 이전의 key값이 [deletedStrokes]에 존재한다면
    /// [deletedStrokes]의 value값에 해당하는 index를 지워줍니다.
    final Map<String, List<List<DrawingData>>> realDrawingData = {};

    /// 유저 별로 그림을 따로 그려줍니다.
    for (final drawingData in widget.userDrawingData.entries) {
      /// 유저 ID를 먼저 가져옵니다.
      final userID = drawingData.key;

      /// 해당 유저의 limitCursor 이전의 스트로크들을 가져옵니다.
      final drawingBeforeLimitCursor = widget.userDrawingData[userID]!
          .sublist(0, widget.userLimitCursor[userID]!);
      for (int i = 0; i < drawingBeforeLimitCursor.length; i++) {
        for (final deleteStroke in widget.userDeletedStrokes[userID]!.entries) {
          if (deleteStroke.key <= widget.userLimitCursor[userID]!) {
            drawingBeforeLimitCursor[deleteStroke.value] = [];
          }
        }
      }
      realDrawingData[userID] = drawingBeforeLimitCursor;
    }
    return realDrawingData;
  }
}

class _WhiteboardPainter extends CustomPainter {
  final Map<String, List<List<DrawingData>>> userDrawingData;

  _WhiteboardPainter(this.userDrawingData);
  @override
  void paint(Canvas canvas, Size size) {
    for (final drawingData in userDrawingData.values) {
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
            path.lineTo(p0.x, p0.y);
          }
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    return true;
  }
}
