import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:math_tutor_whiteboard/camera_capture_page.dart';
import 'package:math_tutor_whiteboard/image_crop_page.dart';
import 'dart:ui' as ui;

import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class MediaSourceSelectionBottomSheet extends StatelessWidget {
  final void Function(ui.Image image) onImageSelected;
  const MediaSourceSelectionBottomSheet(
      {super.key, required this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    // Show a bottom sheet with options to select a media source: camera or gallery
    return Container(
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          color: Colors.white),
      height: 140,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('카메라'),
            onTap: () async {
              final cameraPermission = await Permission.camera.request();
              if (!cameraPermission.isGranted) {
                Fluttertoast.showToast(msg: '카메라 권한이 없습니다.');
                return;
              }
              if (context.mounted) {
                final result =
                    await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const CameraCapturePage(),
                ));
                if (result != null && context.mounted) {
                  onImageSelected(result);
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('갤러리'),
            onTap: () async {
              final permission = await AssetPicker.permissionCheck();
              if (permission != PermissionState.authorized) {
                Fluttertoast.showToast(msg: '갤러리 권한이 없습니다.');
                return;
              }
              if (context.mounted) {
                final pickedImages = await AssetPicker.pickAssets(context,
                    pickerConfig: const AssetPickerConfig(
                      maxAssets: 1,
                      requestType: RequestType.image,
                    ));
                final pickedImage = await pickedImages?.first.file;
                if (pickedImage != null && context.mounted) {
                  final result =
                      await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        ImageCropPage(sourceFile: File(pickedImage.path)),
                  ));
                  if (result != null && context.mounted) {
                    onImageSelected(result);
                    Navigator.of(context).pop();
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
