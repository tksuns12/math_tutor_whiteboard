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
  Future<void> initialize();
  Future<void> login(
      {required String userID,
      required String nicknamne,
      required String ownerID});
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
  final String serverHost = "demo6.gonts.net";
  final int serverPort = 27084;
  PlatformChannelImpl() {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onServerEvent') {
        onServerEventStream.add(call.arguments);
      } else {
        log('Unknown method: ${call.method}');
      }
    });
  }
  @override
  Future<void> changePermissionAudio(String userID) async {
    await methodChannel.invokeMethod('changePermissionAudio', userID);
  }

  @override
  Future<void> changePermissionDoc(String userID) async {
    await methodChannel.invokeMethod('changePermissionDoc', userID);
  }

  @override
  Future<bool> getPermissionAudio(String userID) async {
    return await methodChannel.invokeMethod('getPermissionAudio', userID);
  }

  @override
  Future<bool> getPermissionDoc(String userID) async {
    return await methodChannel.invokeMethod('getPermissionDoc', userID);
  }

  @override
  Future<List<String>> getUserList() async {
    return await methodChannel.invokeMethod('getUserList');
  }

  @override
  Future<void> initialize() async {
    await methodChannel.invokeMethod('initialize', {
      'host': serverHost,
      'port': serverPort,
    });
  }

  @override
  Future<bool> isMicrophoneOn() async {
    return await methodChannel.invokeMethod('isMicrophoneOn');
  }

  @override
  Future<void> login(
      {required String userID,
      required String nicknamne,
      required String ownerID}) async {
    await methodChannel.invokeMethod('login', {
      'userID': userID,
      'nickname': nicknamne,
      'ownerID': ownerID,
    });
    this.userID = userID;
    hostID = ownerID;
  }

  @override
  Future<void> logout() async {
    await methodChannel.invokeMethod('logout');
  }

  @override
  Future<void> sendPacket(Map data) async {
    await methodChannel
        .invokeMethod('sendPacket', {'type': kDrawingCode, 'data': data});
  }

  @override
  Future<void> turnOnMicrophone(bool on) async {
    await methodChannel.invokeMethod('turnOnMicrophone', {'on':on});
  }

  @override
  Future<void> sendImage(File file) async {
    await methodChannel.invokeMethod('sendImage', {'filePath':file.path});
  }

  @override
  Future<void> sendMessage(WhiteboardChatMessage message) async {
    await methodChannel.invokeMethod(
        'sendPacket', {'type': kChatMessageCode, 'data': message.toJson()});
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
