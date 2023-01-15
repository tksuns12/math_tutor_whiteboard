import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_tutor_whiteboard/states/chat_message_state.dart';
import 'package:math_tutor_whiteboard/types.dart';

class ChatMessageBottomSheet extends StatefulWidget {
  final WidgetRef ref;
  const ChatMessageBottomSheet(this.ref, {super.key});

  @override
  State<ChatMessageBottomSheet> createState() => _ChatMessageBottomSheetState();
}

class _ChatMessageBottomSheetState extends State<ChatMessageBottomSheet> {
  var chatMessages = <WhiteboardChatMessage>[];
  final scrollContrller = ScrollController();
  bool isViewAttached = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      isViewAttached = true;scrollContrller.animateTo(
          scrollContrller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    chatMessages = widget.ref.watch(chatMessageStateProvider);
    if (isViewAttached) {
      if (scrollContrller.position.maxScrollExtent - scrollContrller.offset <=
          50) {
        scrollContrller.animateTo(
          scrollContrller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 16,
          ),
          const Text('채팅', style: TextStyle(fontSize: 20)),
          Expanded(
            child: ListView.builder(
              controller: scrollContrller,
              itemCount: chatMessages.length,
              itemBuilder: _chatMessageItemBuilder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatMessageItemBuilder(BuildContext context, int index) {
    final message = chatMessages[index];
    return ListTile(
      leading: Text('${message.nickname}:'),
      title: Text(message.message),
    );
  }
}
