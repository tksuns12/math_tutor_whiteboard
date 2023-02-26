import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_tutor_whiteboard/states/chat_message_state.dart';
import 'package:math_tutor_whiteboard/types.dart';

class ChatMessageBottomSheet extends StatefulWidget {
  final WidgetRef ref;
  final void Function(String message) onSend;
  const ChatMessageBottomSheet(this.ref,
      {super.key, required this.onSend});

  @override
  State<ChatMessageBottomSheet> createState() => _ChatMessageBottomSheetState();
}

class _ChatMessageBottomSheetState extends State<ChatMessageBottomSheet>
    with WidgetsBindingObserver {
  var chatMessages = <WhiteboardChatMessage>[];
  final scrollContrller = ScrollController();
  bool isViewAttached = false;
  double bottomInset = 0;
  final textEditingController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      isViewAttached = true;
      scrollContrller.animateTo(
        scrollContrller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scrollContrller.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (isViewAttached) {
      setState(() {
        bottomInset = MediaQuery.of(context).viewInsets.bottom;
      });
    }
    super.didChangeMetrics();
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
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4 + bottomInset,
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
              TextField(
                  controller: textEditingController,
                  onSubmitted: (value) {
                    widget.onSend(value);
                    textEditingController.clear();
                  },
                  decoration: InputDecoration(
                      hintText: '메시지 입력',
                      filled: true,
                      fillColor: Colors.grey[200])),
            SizedBox(
              height: bottomInset,
            )
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
