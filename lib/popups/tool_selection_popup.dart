import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:math_tutor_whiteboard/types.dart';

class ToolSelectionPopup extends StatefulWidget {
  final PenType initialTool;
  final double initialWidth;
  final Color initialColor;
  final void Function(double width) onStrokeWidthChanged;
  final void Function(PenType tool) onToolChanged;
  final Offset position;
  final void Function(Color color) onColorChanged;
  const ToolSelectionPopup(
      {super.key,
      required this.initialTool,
      required this.initialWidth,
      required this.onStrokeWidthChanged,
      required this.onToolChanged,
      required this.position,
      required this.onColorChanged,
      required this.initialColor});

  @override
  State<ToolSelectionPopup> createState() => _ToolSelectionPopupState();
}

class _ToolSelectionPopupState extends State<ToolSelectionPopup> {
  PenType _tool = PenType.pen;
  double _width = 5;
  Color _color = Colors.white;

  @override
  void initState() {
    _tool = widget.initialTool;
    _width = widget.initialWidth;
    _color = widget.initialColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      color: Colors.transparent,
      child: Stack(
        children: [
          const ModalBarrier(),
          Positioned(
            top: widget.position.dy,
            left: widget.position.dx,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  const Text('도구'),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PopupButton(
                          selected: _tool == PenType.pen,
                          onPressed: () {
                            setState(() {
                              _tool = PenType.pen;
                              widget.onToolChanged(_tool);
                            });
                          },
                          child: const Icon(FontAwesomeIcons.pen, size: 20)),
                      _PopupButton(
                          onPressed: () {
                            setState(() {
                              _tool = PenType.highlighter;
                              widget.onToolChanged(_tool);
                            });
                          },
                          selected: _tool == PenType.highlighter,
                          child: const Icon(FontAwesomeIcons.highlighter,
                              size: 20)),
                      _PopupButton(
                          onPressed: () {
                            setState(() {
                              _tool = PenType.strokeEraser;
                              widget.onToolChanged(_tool);
                            });
                          },
                          selected: _tool == PenType.strokeEraser,
                          child: const Icon(FontAwesomeIcons.eraser, size: 20)),
                      _PopupButton(
                        onPressed: () {
                          setState(() {
                            _tool = PenType.penEraser;
                            widget.onToolChanged(_tool);
                          });
                        },
                        selected: _tool == PenType.penEraser,
                        child: SvgPicture.asset('assets/eraser.svg',
                            package: 'math_tutor_whiteboard'),
                      )
                    ],
                  ),
                  const Divider(thickness: 1.5, color: Colors.grey),
                  const Text('굵기'),
                  SizedBox(
                    height: 30,
                    child: Center(
                      child: Container(
                          height: _width, width: 150, color: Colors.black),
                    ),
                  ),
                  Slider(
                    value: _width,
                    min: 1,
                    max: 20,
                    thumbColor: Colors.black,
                    onChanged: (value) {
                      setState(() {
                        _width = value;
                        widget.onStrokeWidthChanged(value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('색상'),
                  BlockPicker(
                    pickerColor: _color,
                    onColorChanged: (value) {
                      setState(() {
                        _color = value;
                        widget.onColorChanged(value);
                      });
                    },
                    useInShowDialog: false,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _PopupButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool selected;

  const _PopupButton(
      {super.key,
      required this.onPressed,
      required this.selected,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? Colors.grey[300] : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: child,
      ),
    );
  }
}
