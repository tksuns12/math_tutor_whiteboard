import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:math_tutor_whiteboard/change_notifier_builder.dart';
import 'package:math_tutor_whiteboard/types/types.dart';
import 'package:math_tutor_whiteboard/whiteboard_controller.dart';

class UserListBottomSheet extends StatefulWidget {
  final WhiteboardUser me;
  final String hostID;
  final void Function(WhiteboardUser user, bool allow) onChangeDrawPermission;
  final void Function(WhiteboardUser user, bool allow) onChangeMicPermission;
  final WhiteboardController controller;
  const UserListBottomSheet(
      {required this.controller,
      super.key,
      required this.onChangeDrawPermission,
      required this.onChangeMicPermission,
      required this.me,
      required this.hostID});

  @override
  State<UserListBottomSheet> createState() => _UserListBottomSheetState();
}

class _UserListBottomSheetState extends State<UserListBottomSheet> {
  List<WhiteboardUser> userList = [];

  @override
  void didChangeDependencies() {
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
          const Text('접속자', style: TextStyle(fontSize: 20)),
          Expanded(
            child: ChangeNotifierBuilder(
                notifier: widget.controller,
                builder: (context, controller, _) {
                  userList = controller?.users ?? [];
                  return ListView.separated(
                    itemCount: userList.length,
                    itemBuilder: _userItemBuilder,
                    separatorBuilder: (BuildContext context, int index) {
                      return const SizedBox(
                        height: 10,
                      );
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }

  Widget _userItemBuilder(BuildContext context, int index) {
    final user = userList[index];
    return Row(
      children: [
        const SizedBox(width: 16),
        CircleAvatar(
          backgroundColor: Colors.grey,
          foregroundImage: CachedNetworkImageProvider(
              user.avatar ?? 'https://picsum.photos/100'),
        ),
        const SizedBox(width: 8),
        Text(widget.me.id != user.id ? user.nickname : '**나**'),
        const Spacer(),
        if (widget.me.id != user.id && widget.hostID == widget.me.id) ...[
          IconButton(
            icon: SvgPicture.asset(
                user.drawingEnabled
                    ? 'assets/permission_pencil_allowed.svg'
                    : 'assets/permission_pencil_forbidden.svg',
                package: 'math_tutor_whiteboard'),
            onPressed: () {
              widget.onChangeDrawPermission(user, !user.drawingEnabled);
            },
          ),
          IconButton(
            icon: SvgPicture.asset(
              user.micEnabled
                  ? 'assets/permission_mic_allowed.svg'
                  : 'assets/permission_mic_forbidden.svg',
              package: 'math_tutor_whiteboard',
            ),
            onPressed: () {
              widget.onChangeMicPermission(user, !user.micEnabled);
            },
          )
        ],
      ],
    );
  }
}
