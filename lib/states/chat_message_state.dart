import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_tutor_whiteboard/types.dart';

class ChatMessageStateNotifier
    extends StateNotifier<List<WhiteboardChatMessage>> {
  ChatMessageStateNotifier() : super([
  ]);

  void addMessage(WhiteboardChatMessage message) {
    state = [...state, message];
  }

  void removeMessage(WhiteboardChatMessage message) {
    state =
        state.where((element) => element.nickname != message.nickname).toList();
  }
}

final chatMessageStateProvider = StateNotifierProvider<ChatMessageStateNotifier,
    List<WhiteboardChatMessage>>((ref) => ChatMessageStateNotifier());
