import 'package:flutter/gestures.dart';

class PointerManager {
  List<(int, PointerDeviceKind)> pointers = [];
  bool isInMultiplePointers = false;

  bool isStylusMode = false;

  void addPointer(
      {required int pointer, required PointerDeviceKind deviceKind}) {
    if (deviceKind == PointerDeviceKind.stylus ||
        deviceKind == PointerDeviceKind.invertedStylus) {
      isStylusMode = true;
      pointers.removeWhere((element) => element.$2 != deviceKind);
    }

    if (isStylusMode &&
        (deviceKind != PointerDeviceKind.stylus ||
            deviceKind != PointerDeviceKind.invertedStylus)) {
      return;
    }
    pointers.add((pointer, deviceKind));
    if (pointers.where((element) => element.$2 == deviceKind).length > 1) {
      isInMultiplePointers = true;
    }
  }

  void popPointer(
      {required int pointer, required PointerDeviceKind deviceKind}) {
    pointers.removeWhere(
        (element) => element.$1 == pointer && element.$2 == deviceKind);
    if (pointers.isEmpty) {
      isInMultiplePointers = false;
    }
    if (pointers.any((element) =>
        element.$2 == PointerDeviceKind.stylus ||
        element.$2 == PointerDeviceKind.invertedStylus)) {
      isStylusMode = true;
    } else {
      isStylusMode = false;
    }
  }
}
