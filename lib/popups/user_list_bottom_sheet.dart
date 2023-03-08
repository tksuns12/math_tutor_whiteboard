import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:math_tutor_whiteboard/states/user_list_state.dart';
import 'package:math_tutor_whiteboard/types/types.dart';

class UserListBottomSheet extends StatefulWidget {
  final WidgetRef ref;
  final void Function(WhiteboardUser user, bool allow) onChangeDrawPermission;
  final void Function(WhiteboardUser user, bool allow) onChangeMicPermission;
  const UserListBottomSheet(this.ref,
      {super.key,
      required this.onChangeDrawPermission,
      required this.onChangeMicPermission});

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
          const SizedBox(
            height: 16,
          ),
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
      dense: true,
      title: Text(user.nickname),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: SvgPicture.asset(user.drawingEnabled
                ? 'assets/permission_pencil_allowed.svg'
                : 'assets/permission_pencil_forbidden.svg'),
            onPressed: () {
              widget.onChangeDrawPermission(user, !user.drawingEnabled);
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: SvgPicture.asset(user.micEnabled
                ? 'assets/permission_mic_allowed.svg'
                : 'assets/permission_mic_forbidden.svg'),
            onPressed: () {
              widget.onChangeMicPermission(user, !user.micEnabled);
            },
          ),
        ],
      ),
    );
  }
}
