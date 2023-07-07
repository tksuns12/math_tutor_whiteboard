import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:math_tutor_whiteboard/types/types.dart';

class ChatMessageStateNotifier extends StateNotifier<ChatState> {
  ChatMessageStateNotifier()
      : super(const ChatState(seeingChat: false, messages: []));

  void addMessage(WhiteboardChatMessage message) {
    state = state.copyWith(
        messages: [...state.messages, message],
        lastMessageTime: state.seeingChat ? message.sentAt : null);
  }

  void checkLastMessageTime() {
    state = state.copyWith(lastMessageTime: DateTime.now());
  }

  void removeMessage(WhiteboardChatMessage message) {
    state = state.copyWith(
        messages: state.messages
            .where((element) => element.nickname != message.nickname)
            .toList());
  }

  void setSeeingChat(bool bool) {
    state = state.copyWith(seeingChat: bool);
  }
}

final chatMessageStateProvider =
    AutoDisposeStateNotifierProvider<ChatMessageStateNotifier, ChatState>(
        (ref) => ChatMessageStateNotifier());

class ChatState extends Equatable {
  final List<WhiteboardChatMessage> messages;
  final DateTime? lastMessageTime;
  final bool seeingChat;
  const ChatState({
    required this.seeingChat,
    required this.messages,
    this.lastMessageTime,
  });
  bool get hasNewMessage {
    if (lastMessageTime == null) {
      return messages.length > 2;
    }
    return (messages.lastOrNull?.sentAt.isAfter(lastMessageTime!)) ?? true;
  }

  @override
  List<Object?> get props => [
        messages,
        lastMessageTime,
        seeingChat,
      ];

  ChatState copyWith({
    List<WhiteboardChatMessage>? messages,
    DateTime? lastMessageTime,
    bool? seeingChat,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      seeingChat: seeingChat ?? this.seeingChat,
    );
  }
}
