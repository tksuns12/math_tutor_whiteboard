import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:math_tutor_whiteboard/types/types.dart';

class UserListStateNotifier extends StateNotifier<List<WhiteboardUser>> {
  UserListStateNotifier() : super([]);

  void addUser(WhiteboardUser user) {
    if (state.any((element) => element.id == user.id)) {
      Fluttertoast.showToast(msg: "비정상 종료된 ${user.nickname}님이 재접속했습니다.");
      return;
    }
    state = [...state, user];
  }

  void removeUser(WhiteboardUser user) {
    state = state.where((element) => element.id != user.id).toList();
  }

  void updatePermission(WhiteboardUser user, PermissionChangeEvent event) {
    state = state.map((element) {
      if (element.id == user.id) {
        var copyElement = element.copyWith();
        if (event.drawing != null) {
          copyElement = copyElement.copyWith(drawingEnabled: event.drawing);
        }
        if (event.microphone != null) {
          copyElement = copyElement.copyWith(micEnabled: event.microphone);
        }
        return copyElement;
      }
      return element;
    }).toList();
  }
}

final userListStateProvider =
    StateNotifierProvider<UserListStateNotifier, List<WhiteboardUser>>(
        (ref) => UserListStateNotifier());
