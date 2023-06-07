import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_tutor_whiteboard/types/types.dart';

class ChatMessageStateNotifier
    extends StateNotifier<List<WhiteboardChatMessage>> {
  ChatMessageStateNotifier() : super([]);

  DateTime? lastMessageTime;

  bool get hasNewMessage {
    if (lastMessageTime == null) {
      return false;
    }
    return (state.lastOrNull?.sentAt.isAfter(lastMessageTime!)) ?? false;
  }

  void addMessage(WhiteboardChatMessage message) {
    state = [...state, message];
  }

  void removeMessage(WhiteboardChatMessage message) {
    state =
        state.where((element) => element.nickname != message.nickname).toList();
  }
}

final chatMessageStateProvider = AutoDisposeStateNotifierProvider<
    ChatMessageStateNotifier,
    List<WhiteboardChatMessage>>((ref) => ChatMessageStateNotifier());
