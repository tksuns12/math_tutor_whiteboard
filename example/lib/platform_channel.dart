import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:math_tutor_whiteboard/types/types.dart';

import 'mock/math_tutor_api_client_impl.dart';

const kFileCode = 100;

const kDrawingCode = 200;

const kChatMessageCode = 300;

const kServerEventCode = 400;

const kViewportCode = 500;

const kUserCode = 600;

const kPermissionCode = 700;

abstract class MathtutorNeotechPluginPlatform {
  Future<void> initialize(
      {File? preloadImage, required String userID, required String ownerID});
  Future<void> login();
  Future<void> logout();
  Future<void> sendPacket(Map data);
  Future<Map> getUserList();
  Future<void> changePermissionAudio(String userID);
  Future<bool> getPermissionAudio(String userID);
  Future<void> changePermissionDoc(String userID);
  Future<bool> getPermissionDoc(String userID);
  Future<void> turnOnMicrophone(bool on);
  Future<bool> isMicrophoneOn();
  Future<void> sendImage(File file);
  Future<void> sendMessage(WhiteboardChatMessage message);
  late final StreamController incomingStream;
  late final StreamController<Map> onServerEventStream;
  void dispose();
}

class PlatformChannelImpl implements MathtutorNeotechPluginPlatform {
  final methodChannel = const MethodChannel('mathtutor_neotech_plugin');
  @override
  late final onServerEventStream = StreamController<Map>.broadcast();
  late final String userID;
  late final String hostID;
  final String serverHost = "demo6.gonts.net";
  final int serverPort = 27084;
  late final DrawingBuffer buffer;
  PlatformChannelImpl() {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onServerEvent') {
        onServerEventStream.add(call.arguments);
      } else if (call.method == "onUserEvent") {
      } else if (call.method == 'onPermissionChanged') {
        onServerEventStream.add(call.arguments);
      } else if (call.method == "eventSinkAlt") {
        final event = call.arguments as Map;
        switch (event['type']) {
          case kChatMessageCode:
            incomingStream.sink
                .add(WhiteboardChatMessage.fromJson(event['data']));
            break;
          case kFileCode:
            incomingStream.sink.add(File(event['data'] as String));
            break;
          case kDrawingCode:
            incomingStream.sink.add(BroadcastPaintData.fromJson(event['data']));
            break;
          case kUserCode:
            final data = jsonDecode(event['data']);
            final api = MathTutorAPIClientImpl();
            final remoteUserData = await api.getUserThumbnails([data['id']]);

            final user = WhiteboardUser(
                nickname: remoteUserData.data.first['displayName'],
                micEnabled: data['isAudioOn'] ?? false,
                drawingEnabled: data['isDocOn'] ?? false,
                id: data['id'],
                avatar: remoteUserData.data.first['avatar'],
                isHost: data['id'] == userID);
            incomingStream.sink
                .add(UserEvent(user: user, isJoin: data['isEnter']));
            break;
          case kViewportCode:
            incomingStream.sink
                .add(ViewportChangeEvent.fromJson(event['data']));
            break;
          case kPermissionCode:
            incomingStream.sink
                .add(PermissionChangeEvent.fromMap(event['data']));
            break;
          case kServerEventCode:
            log('WhiteboardPlatformChannel | kServerEventCode: $event');
            incomingStream.sink.add(event);
            break;
          default:
            incomingStream.sink.add(event);
        }
      } else if (call.method == "onUploadComplete") {
        log('WhiteboardPlatformChannel | onUploadComplete: ${call.arguments}');
      }
    });
    buffer = DrawingBuffer((buffer) async {
      final result = await methodChannel.invokeMethod('sendPacket', {
        'type': kDrawingCode,
        'data': buffer,
      });

      log('WhiteboardPlatformChannel | sendPacket: $result');
    });
  }
  @override
  Future<void> changePermissionAudio(String userID) async {
    final reuslt = await methodChannel
        .invokeMethod('changePermissionAudio', {"userID": userID});
    log('WhiteboardPlatformChannel | changePermissionAudio: $reuslt');
  }

  @override
  Future<void> changePermissionDoc(String userID) async {
    final result = await methodChannel
        .invokeMethod('changePermissionDoc', {"userID": userID});
    log('WhiteboardPlatformChannel | changePermissionDoc: $result');
  }

  @override
  Future<bool> getPermissionAudio(String userID) async {
    final result = await methodChannel
        .invokeMethod('getPermissionAudio', {"userID": userID});
    log('WhiteboardPlatformChannel | getPermissionAudio: $result');
    return result;
  }

  @override
  Future<bool> getPermissionDoc(String userID) async {
    final result = await methodChannel
        .invokeMethod('getPermissionDoc', {"userID": userID});
    log('WhiteboardPlatformChannel | getPermissionDoc: $result');
    return result;
  }

  @override
  Future<Map> getUserList() async {
    final result = await methodChannel.invokeMethod('getUserList');
    log('WhiteboardPlatformChannel | getUserList: $result');
    return result;
  }

  @override
  Future<void> initialize(
      {File? preloadImage,
      required String userID,
      required String ownerID}) async {
    await methodChannel.invokeMethod('initialize', {
      'host': serverHost,
      'port': serverPort,
      'preloadImage': preloadImage?.path,
      'userID': userID
    });
    this.userID = userID;
    hostID = ownerID;
  }

  @override
  Future<bool> isMicrophoneOn() async {
    final result = await methodChannel.invokeMethod('isMicrophoneOn');
    log('WhiteboardPlatformChannel | isMicrophoneOn: $result');
    return result;
  }

  @override
  Future<void> login() async {
    await logout();
    final result = await methodChannel.invokeMethod('login', {
      'userID': userID,
      'ownerID': hostID,
    });
    log('WhiteboardPlatformChannel | login: $result, Data: $userID, $hostID');
  }

  @override
  Future<void> logout() async {
    final result = await methodChannel.invokeMethod('logout');
    log('WhiteboardPlatformChannel | logout: $result');
  }

  @override
  Future<void> sendPacket(Map data) async {
    buffer.add(data);
  }

  @override
  Future<void> turnOnMicrophone(bool on) async {
    final result =
        await methodChannel.invokeMethod('turnOnMicrophone', {'on': on});
    log('WhiteboardPlatformChannel | turnOnMicrophone: $result');
  }

  @override
  Future<void> sendImage(File file) async {
    final reuslt =
        await methodChannel.invokeMethod('sendImage', {'filePath': file.path});
    log('WhiteboardPlatformChannel | sendImage: $reuslt');
  }

  @override
  Future<void> sendMessage(WhiteboardChatMessage message) async {
    final reuslt = await methodChannel.invokeMethod(
        'sendPacket', {'type': kChatMessageCode, 'data': message.toMap()});
    log('WhiteboardPlatformChannel | sendMessage: $reuslt');
  }

  @override
  late final StreamController incomingStream =
      StreamController<dynamic>.broadcast();

  @override
  set onServerEventStream(StreamController<Map> onServerEventStream) {
    onServerEventStream = onServerEventStream;
  }

  @override
  set incomingStream(StreamController incomingStream) {
    incomingStream = incomingStream;
  }

  @override
  void dispose() {
    incomingStream.close();
    buffer.dispose();
  }
}

class DrawingBuffer {
  final List<Map> _buffer = [];
  final int maxBufferSize;
  final Future<void> Function(List<Map> buffer) onBufferFull;
  DrawingBuffer(this.onBufferFull, {this.maxBufferSize = 3000});
  Timer? _timer;
  int _lastTime = DateTime.now().millisecondsSinceEpoch;
    bool _isBursting = false;

  void dispose() {
    _timer?.cancel();
  }

  Future<void> _burst() async {
    if (_isBursting) return;
    _isBursting = true;

    log('Burst!');
    if (_buffer.isNotEmpty) {
      await onBufferFull(_buffer);
      _buffer.clear();
    }
    _timer?.cancel();
    _timer = null;

    _isBursting = false;
  }

  void startTimer() {
    if (_timer != null) {
      return;
    }
    _lastTime = DateTime.now().millisecondsSinceEpoch;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      final bufferSize = jsonEncode(_buffer).length;
      if (DateTime.now().millisecondsSinceEpoch - _lastTime > 1000 ||
          bufferSize > maxBufferSize - 1000) {
        await _burst();
      }
    });
  }

  Future<void> add(Map data) async {
    startTimer();
    _buffer.add(data);
  }

  List<Map> get buffer => _buffer;
}

extension IterableX<T> on Iterable<T> {
  T? get lastOr => (() {
        try {
          return last;
        } catch (e) {
          return null;
        }
      })();
  T? get firstOr => (() {
        try {
          return first;
        } catch (e) {
          return null;
        }
      })();
}
