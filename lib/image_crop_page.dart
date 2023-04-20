import 'dart:io';
import 'dart:ui' as ui;

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';

class ImageCropPage extends StatefulWidget {
  final File sourceFile;

  const ImageCropPage({required this.sourceFile, super.key});

  @override
  State<ImageCropPage> createState() => _ImageCropPage();
}

class _ImageCropPage extends State<ImageCropPage> {
  CropController? controller;

  @override
  void initState() {
    super.initState();

    () async {
      var decodedImage =
          await decodeImageFromList(widget.sourceFile.readAsBytesSync());
      double initialHeight =
          (decodedImage.width * 0.9 * 9.0 / 16.0) / decodedImage.height;
      setState(() {
        controller = CropController(
            aspectRatio: null,
            defaultCrop: Rect.fromCenter(
                center: const Offset(0.5, 0.5),
                width: 0.9,
                height: initialHeight));
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: controller == null
                    ? const SizedBox()
                    : CropImage(
                        controller: controller,
                        gridColor: const Color(0xFFFFF500),
                        gridCornerSize: 18,
                        gridThinWidth: 1,
                        minimumImageSize: 1,
                        image: Image.file(widget.sourceFile)),
              ),
              SafeArea(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Image.asset('assets/images/back.png',
                        width: 40,
                        height: 40,
                        package: 'math_tutor_whiteboard'),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 12),
          child: Center(
              child: GestureDetector(
            onTap: _onOk,
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                  color: const Color(0xFF446D8C),
                  borderRadius: BorderRadius.circular(33)),
              child: Center(
                  child: Image.asset('assets/images/camera_shot.png',
                      package: 'math_tutor_whiteboard')),
            ),
          )),
        ),
      ],
    );
  }

  _onOk() async {
    if (controller != null) {
      final navigator = Navigator.of(context);
      ui.Image croppedImage =
          await controller!.croppedBitmap(quality: FilterQuality.low);
      navigator.pop(croppedImage);
    }
  }
}
