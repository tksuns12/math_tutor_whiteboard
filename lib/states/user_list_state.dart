import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_tutor_whiteboard/types.dart';

class UserListStateNotifier extends StateNotifier<List<WhiteboardUser>> {
  UserListStateNotifier() : super([]);

  void addUser(WhiteboardUser user) {
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
