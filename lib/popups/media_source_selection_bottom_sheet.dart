import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:math_tutor_whiteboard/camera_capture_page.dart';
import 'package:math_tutor_whiteboard/const.dart';
import 'package:math_tutor_whiteboard/image_crop_page.dart';
import 'dart:ui' as ui;

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
              final navigator = Navigator.of(context);
              final result = await navigator.push(MaterialPageRoute(
                builder: (context) => const CameraCapturePage(),
              ));
              if (result != null) {
                onImageSelected(result);
                navigator.pop();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('갤러리'),
            onTap: () async {
              final navigator = Navigator.of(context);
              final pickedImage = await FilePicker.platform.pickFiles(
                  allowMultiple: false,
                  allowedExtensions: imageExtensions,
                  type: FileType.custom);
              if (pickedImage != null && pickedImage.files.isNotEmpty) {
                final result = await navigator.push(MaterialPageRoute(
                  builder: (context) => ImageCropPage(
                      sourceFile: File(pickedImage.files.first.path!)),
                ));
                if (result != null) {
                  onImageSelected(result);
                  navigator.pop();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
