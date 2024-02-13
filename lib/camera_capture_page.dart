import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'image_crop_page.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePage();
}

class _CameraCapturePage extends State<CameraCapturePage> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  BoxConstraints? cameraPreviewContainerSize;

  @override
  void initState() {
    super.initState();
    Permission.camera.request().then((value) {
      if (value == PermissionStatus.granted) {
        () async {
          final cameras = await availableCameras();
          final firstCamera = cameras.first;

          // To display the current output from the Camera,
          // create a CameraController.
          _controller = CameraController(
              // Get a specific camera from the list of available cameras.
              firstCamera,
              // Define the resolution to use.
              ResolutionPreset.max,
              imageFormatGroup: ImageFormatGroup.jpeg);

          // Next, initialize the controller. This returns a Future.
          setState(() {
            _initializeControllerFuture = _controller.initialize();
          });
        }();
      }
    });
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              if (_initializeControllerFuture != null) _cameraPreview(),
              SafeArea(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Image.asset('assets/images/back.png',
                        width: 40, height: 40,package: 'math_tutor_whiteboard'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: AspectRatio(
                      aspectRatio: 16.0 / 9.0,
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.white, width: 2)),
                            child: Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFF500),
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ),
                          Align(
                              alignment: Alignment.topLeft,
                              child: Image.asset(
                                  'assets/images/camera_viewport_lefttop.png',package: 'math_tutor_whiteboard',)),
                          Align(
                              alignment: Alignment.topRight,
                              child: Image.asset(
                                  'assets/images/camera_viewport_righttop.png',package: 'math_tutor_whiteboard')),
                          Align(
                              alignment: Alignment.bottomLeft,
                              child: Image.asset(
                                  'assets/images/camera_viewport_leftbottom.png',package: 'math_tutor_whiteboard')),
                          Align(
                              alignment: Alignment.bottomRight,
                              child: Image.asset(
                                  'assets/images/camera_viewport_rightbottom.png',package: 'math_tutor_whiteboard')),
                        ],
                      )),
                ),
              )
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 12),
          child: Center(
              child: GestureDetector(
            onTap: _onShot,
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                  color: const Color(0xFF446D8C), borderRadius: BorderRadius.circular(33)),
              child:
                  Center(child: Image.asset('assets/images/camera_shot.png',package: 'math_tutor_whiteboard')),
            ),
          )),
        ),
      ],
    );
  }

  Widget _cameraPreview() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              debugPrint(
                  '카메라 프리뷰 사이즈 w: ${constraints.maxWidth} h: ${constraints.maxHeight}');
              cameraPreviewContainerSize = constraints;
              return Center(child: CameraPreview(_controller));
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  _onShot() async {
    try {
      final navigator = Navigator.of(context);
      await _initializeControllerFuture;
      XFile capturedImage = await _controller.takePicture();
      ui.Image? croppedImage = await _crop(File(capturedImage.path));

      if (croppedImage != null) {
        navigator.pop(croppedImage);
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<ui.Image?> _crop(File sourceFile) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => ImageCropPage(sourceFile: sourceFile),
        transitionDuration: Duration.zero,
      ),
    );
  }
}
