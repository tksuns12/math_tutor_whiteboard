import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_tutor_whiteboard/states/user_list_state.dart';
import 'package:math_tutor_whiteboard/types.dart';

class UserListBottomSheet extends StatefulWidget {
  final WidgetRef ref;
  const UserListBottomSheet(this.ref, {super.key});

  @override
  State<UserListBottomSheet> createState() => _UserListBottomSheetState();
}

class _UserListBottomSheetState extends State<UserListBottomSheet> {
  var userList = <WhiteboardUser>[];

  @override
  void didChangeDependencies() {
    userList = widget.ref.watch(userListStateProvider);
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
          const SizedBox(height: 16,),
          const Text('유저 목록', style: TextStyle(fontSize: 20)),
          Expanded(
            child: ListView.builder(
              itemCount: userList.length,
              itemBuilder: _userItemBuilder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _userItemBuilder(BuildContext context, int index) {
    final user = userList[index];
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey,
        foregroundImage: CachedNetworkImageProvider(user.avatar ?? ''),
      ),
      title: Text(user.nickname),
    );
  }
}
