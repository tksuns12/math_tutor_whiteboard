import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_tutor_whiteboard/states/chat_message_state.dart';
import 'package:math_tutor_whiteboard/types/types.dart';

class ChatMessageBottomSheet extends ConsumerStatefulWidget {
  final void Function(String message) onSend;
  const ChatMessageBottomSheet({super.key, required this.onSend});

  @override
  ConsumerState<ChatMessageBottomSheet> createState() =>
      _ChatMessageBottomSheetState();
}

class _ChatMessageBottomSheetState
    extends ConsumerState<ChatMessageBottomSheet> {
  var chatMessages = <WhiteboardChatMessage>[];
  final scrollContrller = ScrollController();
  final textEditingController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (scrollContrller.hasClients) {
        scrollContrller.animateTo(
          scrollContrller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    scrollContrller.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
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
              child: Consumer(builder: (context, ref, _) {
                chatMessages = ref.watch(
                    chatMessageStateProvider.select((value) => value.messages));
                ref.listen(chatMessageStateProvider, (messages, message) {
                  Future.delayed(
                    const Duration(milliseconds: 300),
                    () {
                      if (scrollContrller.hasClients) {
                        scrollContrller.animateTo(
                          scrollContrller.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  );
                });
                return Scrollbar(
                  controller: scrollContrller,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: scrollContrller,
                    itemCount: chatMessages.length,
                    itemBuilder: _chatMessageItemBuilder,
                  ),
                );
              }),
            ),
            TextField(
                controller: textEditingController,
                onSubmitted: (value) {
                  widget.onSend(value);
                  textEditingController.clear();
                  Future.delayed(
                    const Duration(milliseconds: 300),
                    () => scrollContrller.animateTo(
                      scrollContrller.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                  );
                },
                decoration: InputDecoration(
                    hintText: '메시지 입력',
                    filled: true,
                    fillColor: Colors.grey[200])),
          ],
        ),
      ),
    );
  }

  Widget _chatMessageItemBuilder(BuildContext context, int index) {
    final message = chatMessages[index];
    return ListTile(
      leading: Text('${message.nickname}:'),
      dense: true,
      title: Text(message.message),
    );
  }
}
