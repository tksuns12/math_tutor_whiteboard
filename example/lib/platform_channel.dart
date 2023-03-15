import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:math_tutor_whiteboard/types/types.dart';

const kFileCode = 100;

const kDrawingCode = 200;

const kChatMessageCode = 300;

const kServerEventCode = 400;

const kViewportCode = 500;

const kUserCode = 600;

const kPermissionCode = 700;

abstract class MathtutorNeotechPluginPlatform {
  Future<void> initialize(
      {File? preloadImage,
      required String userID,
      required String nickname,
      required String ownerID});
  Future<void> login();
  Future<void> logout();
  Future<void> sendPacket(Map data);
  Future<List<String>> getUserList();
  Future<void> changePermissionAudio(String userID);
  Future<bool> getPermissionAudio(String userID);
  Future<void> changePermissionDoc(String userID);
  Future<bool> getPermissionDoc(String userID);
  Future<void> turnOnMicrophone(bool on);
  Future<bool> isMicrophoneOn();
  Future<void> sendImage(File file);
  Future<void> sendMessage(WhiteboardChatMessage message);
  Stream get incomingStream;
}

class PlatformChannelImpl implements MathtutorNeotechPluginPlatform {
  final methodChannel = const MethodChannel('mathtutor_neotech_plugin');
  final eventChannel = const EventChannel('mathtutor_neotech_plugin_event');
  final onServerEventStream = StreamController<Map>.broadcast();
  late final String userID;
  late final String hostID;
  late final String nickname;
  final String serverHost = "demo6.gonts.net";
  final int serverPort = 27084;
  PlatformChannelImpl() {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onServerEvent') {
        onServerEventStream.add(call.arguments);
      } else {
        log('WhiteboardPlatformChannel | Unknown method: ${call.method}');
      }
    });
  }
  @override
  Future<void> changePermissionAudio(String userID) async {
    final reuslt =
        await methodChannel.invokeMethod('changePermissionAudio', userID);
    log('WhiteboardPlatformChannel | changePermissionAudio: $reuslt');
  }

  @override
  Future<void> changePermissionDoc(String userID) async {
    final result =
        await methodChannel.invokeMethod('changePermissionDoc', userID);
    log('WhiteboardPlatformChannel | changePermissionDoc: $result');
  }

  @override
  Future<bool> getPermissionAudio(String userID) async {
    final result =
        await methodChannel.invokeMethod('getPermissionAudio', userID);
    log('WhiteboardPlatformChannel | getPermissionAudio: $result');
    return result;
  }

  @override
  Future<bool> getPermissionDoc(String userID) async {
    final result = await methodChannel.invokeMethod('getPermissionDoc', userID);
    log('WhiteboardPlatformChannel | getPermissionDoc: $result');
    return result;
  }

  @override
  Future<List<String>> getUserList() async {
    final result = await methodChannel.invokeMethod('getUserList');
    log('WhiteboardPlatformChannel | getUserList: $result');
    return result;
  }

  @override
  Future<void> initialize(
      {File? preloadImage,
      required String userID,
      required String nickname,
      required String ownerID}) async {
    await methodChannel.invokeMethod('initialize', {
      'host': serverHost,
      'port': serverPort,
      'preloadImage': preloadImage?.path
    });
    this.userID = userID;
    this.nickname = nickname;
    hostID = ownerID;
    await Future.delayed(const Duration(seconds: 1), () {
      login();
    });
  }

  @override
  Future<bool> isMicrophoneOn() async {
    final result = await methodChannel.invokeMethod('isMicrophoneOn');
    log('WhiteboardPlatformChannel | isMicrophoneOn: $result');
    return result;
  }

  @override
  Future<void> login() async {
    final result = await methodChannel.invokeMethod('login', {
      'userID': userID,
      'nickname': nickname,
      'ownerID': hostID,
    });
    log('WhiteboardPlatformChannel | login: $result');
  }

  @override
  Future<void> logout() async {
    final result = await methodChannel.invokeMethod('logout');
    log('WhiteboardPlatformChannel | logout: $result');
  }

  @override
  Future<void> sendPacket(Map data) async {
    final result = await methodChannel
        .invokeMethod('sendPacket', {'type': kDrawingCode, 'data': data});
    log('WhiteboardPlatformChannel | sendPacket: $result');
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
  Stream get incomingStream =>
      eventChannel.receiveBroadcastStream().asyncMap((event) async {
        switch (event['type']) {
          case kChatMessageCode:
            return WhiteboardChatMessage.fromJson(event['data']);
          case kFileCode:
            return File(event['data'] as String);
          case kDrawingCode:
            return BroadcastPaintData.fromJson(event['data']);
          case kUserCode:
            final user = WhiteboardUser(
                nickname: event['data'],
                micEnabled: true,
                drawingEnabled: false,
                id: '',
                isHost: true);
            return UserEvent(user: user, isJoin: event['isEnter']);
          case kViewportCode:
            return ViewportChangeEvent.fromJson(event['data']);
          case kPermissionCode:
            return PermissionChangeEvent.fromJson(event['data']);
          case kServerEventCode:
            log('WhiteboardPlatformChannel | kServerEventCode: $event');
            // if (event.toString().contains('초기화 성공')) {
            //   await login();
            // }
            break;
          default:
            return event;
        }
      });
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
