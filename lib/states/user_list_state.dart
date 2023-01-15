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
}

final userListStateProvider =
    StateNotifierProvider<UserListStateNotifier, List<WhiteboardUser>>(
        (ref) => UserListStateNotifier());
