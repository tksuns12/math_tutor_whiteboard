import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:math_tutor_whiteboard/states/chat_message_state.dart';
import 'package:math_tutor_whiteboard/whiteboard_controller.dart';
import 'popups/chat_message_bottom_sheet.dart';
import 'popups/media_source_selection_bottom_sheet.dart';
import 'popups/tool_selection_popup.dart';
import 'popups/user_list_bottom_sheet.dart';
import 'types/types.dart';
import 'dart:ui' as ui;

class WhiteboardControllerView extends ConsumerStatefulWidget {
  final bool canLoadImage;
  final void Function(PenType type) onPenSelected;
  final VoidCallback onTapEraser;
  final VoidCallback onTapUndo;
  final VoidCallback onTapClear;
  final VoidCallback onTapClose;
  final void Function(String message) onSendChatMessage;
  final void Function(Color color) onColorSelected;
  final Color selectedColor;
  final PenType penType;
  final VoidCallback onTapRedo;
  final bool isUndoable;
  final bool isRedoable;
  final double strokeWidth;
  final void Function(double strokeWidth) onStrokeWidthChanged;
  final VoidCallback onTapRecord;
  final VoidCallback onTapStrokeEraser;
  final bool drawable;
  final void Function(ui.Image file) onLoadImage;
  final void Function(WhiteboardUser user, bool allow) onMicPermissionChanged;
  final void Function(WhiteboardUser user, bool allow)
      onDrawingPermissionChanged;
  final WhiteboardUser me;
  final String? hostID;
  final WhiteboardController controller;
  final bool recordable;

  const WhiteboardControllerView(
      {required this.recordable,
      required this.controller,
      required this.me,
      this.hostID,
      required this.onMicPermissionChanged,
      required this.onDrawingPermissionChanged,
      required this.drawable,
      required this.onSendChatMessage,
      required this.onLoadImage,
      required this.onTapStrokeEraser,
      super.key,
      required this.onPenSelected,
      required this.onTapEraser,
      required this.onTapUndo,
      required this.onTapClear,
      required this.onTapClose,
      required this.onColorSelected,
      required this.canLoadImage,
      required this.selectedColor,
      required this.penType,
      required this.onTapRedo,
      required this.isUndoable,
      required this.isRedoable,
      required this.strokeWidth,
      required this.onStrokeWidthChanged,
      required this.onTapRecord});

  @override
  ConsumerState<WhiteboardControllerView> createState() =>
      _WhiteboardControllerState();
}

class _WhiteboardControllerState
    extends ConsumerState<WhiteboardControllerView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey))),
      padding: EdgeInsets.only(
          top: 8 / 360 * MediaQuery.of(context).size.width,
          bottom: 8 / 360 * MediaQuery.of(context).size.width),
      child: Row(
        children: [
          SizedBox(
            width: 72 / 360 * MediaQuery.of(context).size.width,
            child: widget.recordable
                ? RecordButton(
                    isRecording: widget.controller.recordingState ==
                        RecordingState.recording,
                    onTap: widget.onTapRecord,
                    remainingTime: widget.controller.currentSecond,
                  )
                : widget.controller.liveEndAt == null
                    ? const SizedBox()
                    : TimeIndicator(
                        remainingTime: widget.controller.liveDuration ??
                            const Duration(minutes: 20),
                      ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.drawable)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.grey[350],
                          borderRadius: BorderRadius.circular(34)),
                      padding: EdgeInsets.symmetric(
                          vertical:
                              4 / 360 * MediaQuery.of(context).size.width),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((widget.hostID == widget.me.id ||
                              !widget.canLoadImage))
                            InkWell(
                              onTap: () {
                                // Show modal bottom sheet to choose camera or gallery
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      MediaSourceSelectionBottomSheet(
                                          onImageSelected: widget.onLoadImage),
                                );
                              },
                              child: SvgPicture.asset(
                                'assets/file.svg',
                                package: 'math_tutor_whiteboard',
                              ),
                            ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            child: _toolButtonBuilder(),
                            onTapUp: (detail) => showToolSelectionPopup(
                                context, detail.globalPosition),
                          ),
                          InkWell(
                            onTap: widget.onTapClear,
                            child: SvgPicture.asset(
                              'assets/clear_all.svg',
                              package: 'math_tutor_whiteboard',
                            ),
                          ),
                          InkWell(
                            onTap: widget.onTapUndo,
                            child: Icon(Icons.undo,
                                color: widget.isUndoable
                                    ? Colors.black
                                    : Colors.grey),
                          ),
                          InkWell(
                            onTap: widget.onTapRedo,
                            child: Icon(Icons.redo,
                                color: widget.isRedoable
                                    ? Colors.black
                                    : Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 7 / 360 * MediaQuery.of(context).size.width),
                  child: Builder(
                    builder: (context) {
                      final chatUserListState = widget.controller.users;
                      if (chatUserListState.isEmpty) {
                        return const SizedBox();
                      } else {
                        return InkWell(
                          onTap: () => showUserlistModalBottomSheet(context),
                          child: SvgPicture.asset(
                            'assets/user.svg',
                            package: 'math_tutor_whiteboard',
                          ),
                        );
                      }
                    },
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final chatMessageState =
                        ref.watch(chatMessageStateProvider);
                    if (chatMessageState.isEmpty) {
                      return const SizedBox();
                    } else {
                      return InkWell(
                        onTap: () => showChatModalBottomSheet(context),
                        child: SvgPicture.asset(
                          'assets/chat.svg',
                          package: 'math_tutor_whiteboard',
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 14 / 360 * MediaQuery.of(context).size.width),
          InkWell(
            onTap: widget.onTapClose,
            child: SvgPicture.asset('assets/ex.svg',
                package: "math_tutor_whiteboard"),
          ),
          SizedBox(width: 14 / 360 * MediaQuery.of(context).size.width),
        ],
      ),
    );
  }

  _toolButtonBuilder() {
    switch (widget.penType) {
      case PenType.highlighter:
        return Icon(FontAwesomeIcons.highlighter,
            color: widget.selectedColor, size: 20);
      case PenType.pen:
        return Icon(FontAwesomeIcons.pen,
            color: widget.selectedColor, size: 20);
      case PenType.strokeEraser:
        return const Icon(
          FontAwesomeIcons.eraser,
          size: 20,
        );
      case PenType.penEraser:
        return SvgPicture.asset('assets/eraser.svg',
            package: 'math_tutor_whiteboard');
      default:
    }
  }

  showToolSelectionPopup(BuildContext context, Offset position) {
    return Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ToolSelectionPopup(
          initialTool: widget.penType,
          onColorChanged: widget.onColorSelected,
          initialWidth: widget.strokeWidth,
          onStrokeWidthChanged: widget.onStrokeWidthChanged,
          initialColor: widget.selectedColor,
          onToolChanged: widget.onPenSelected,
          position: position,
        );
      },
    ));
  }

  showUserlistModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => UserListBottomSheet(
        onChangeDrawPermission: widget.onDrawingPermissionChanged,
        controller: widget.controller,
        onChangeMicPermission: widget.onMicPermissionChanged,
        hostID: widget.hostID!,
        me: widget.me,
      ),
      isScrollControlled: true,
    );
  }

  showChatModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: ChatMessageBottomSheet(
          onSend: widget.onSendChatMessage,
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class TimeIndicator extends StatelessWidget {
  final Duration remainingTime;

  const TimeIndicator({super.key, required this.remainingTime});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${(remainingTime.inMinutes).toString().padLeft(2, '0')}:${(remainingTime.inSeconds - remainingTime.inMinutes * 60).toString().padLeft(2, '0')}',
      textAlign: TextAlign.center,
      style: const TextStyle(
          fontSize: 11, color: Color(0xff7d7d7d), fontWeight: FontWeight.w300),
    );
  }
}

class RecordButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onTap;
  final int? remainingTime;
  const RecordButton({
    Key? key,
    required this.isRecording,
    required this.onTap,
    this.remainingTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
              isRecording ? 'assets/stop.svg' : 'assets/record.svg',
              package: 'math_tutor_whiteboard'),
          if (remainingTime != null) ...[
            const SizedBox(
              height: 3,
            ),
            Text(
              '${(remainingTime! ~/ 60).toString().padLeft(2, '0')}:${(remainingTime! % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xff7d7d7d),
                  fontWeight: FontWeight.w300),
            )
          ]
        ],
      ),
    );
  }
}
