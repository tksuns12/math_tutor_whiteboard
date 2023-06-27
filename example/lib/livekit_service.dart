import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:livekit_client/livekit_client.dart';
import 'package:math_tutor_whiteboard/types/types.dart';

class LivekitService {
  late final Room room;
  final StreamController roomStreamController = StreamController.broadcast();

  LivekitService({required this.onConnected});
  Stream<dynamic> get incomingStream => roomStreamController.stream;
  bool isConnected = false;
  final void Function(BatchDrawingData? preDrawnData) onConnected;
  late final WhiteboardUser me;
  Timer? batchDrawingDataTimer;

  Future<void> joinRoom(bool isStudent, WhiteboardUser me) async {
    this.me = me;
    room = Room();
    await room.connect(
        'wss://math-tutor-hgpqkkg2.livekit.cloud',
        isStudent
            ? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2ODc5MTI4MzMsImlzcyI6IkFQSUJHaFI4V1pvRWJveiIsIm5hbWUiOiJzdHVkZW50MTE5IiwibmJmIjoxNjg3ODI2NDMzLCJzdWIiOiJzdHVkZW50MTE5IiwidmlkZW8iOnsiY2FuVXBkYXRlT3duTWV0YWRhdGEiOnRydWUsInJvb20iOiJ0ZXN0cm9vbSIsInJvb21Kb2luIjp0cnVlfX0.ZmTpMbrLTTzXS0u5wVc4vlyYSZDZ7uCLf8xtwQNfpCM'
            : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2ODc5MTI4MTMsImlzcyI6IkFQSUJHaFI4V1pvRWJveiIsIm5hbWUiOiJ0dXRvcjExOSIsIm5iZiI6MTY4NzgyNjQxMywic3ViIjoidHV0b3IxMTkiLCJ2aWRlbyI6eyJjYW5VcGRhdGVPd25NZXRhZGF0YSI6dHJ1ZSwicm9vbSI6InRlc3Ryb29tIiwicm9vbUFkbWluIjp0cnVlLCJyb29tQ3JlYXRlIjp0cnVlLCJyb29tSm9pbiI6dHJ1ZX19.aBn6L5gK4QSkRwX-AHjUiEtl0DcheEdaMa43J8_oy5g');

    room.localParticipant?.setMetadata(me.toJson());
    isConnected = true;
    final anyParticipant = room.participants.values.firstOrNull;
    if (anyParticipant != null) {
      room.localParticipant?.publishData(
        [],
        destinationSids: [anyParticipant.sid],
        topic: LivekitDataTopic.requestDrawingData.toString(),
        reliability: Reliability.reliable,
      );
      batchDrawingDataTimer = Timer(
        const Duration(seconds: 3),
        () => onConnected(null),
      );
    } else {
      onConnected(null);
    }

    await room.localParticipant?.setCameraEnabled(false);
    if (!isStudent) {
      // await room.localParticipant?.publishVideoTrack(
      //   await LocalVideoTrack.createScreenShareTrack(
      //     const ScreenShareCaptureOptions(
      //       captureScreenAudio: false,
      //     ),
      //   ),
      // );
    }

    // await room.localParticipant?.setMicrophoneEnabled(
    //   true,
    //   audioCaptureOptions: const AudioCaptureOptions(highPassFilter: true),
    // );
    room.createListener()
      ..on<ParticipantMetadataUpdatedEvent>(
        (event) {
          if (event.participant.sid == room.localParticipant?.sid) return;
          roomStreamController.add(
            UserEvent(
                user: WhiteboardUser.fromJson(event.participant.metadata!),
                isJoin: true),
          );
        },
      )
      ..on<ParticipantDisconnectedEvent>((event) {
        if (event.participant.sid == room.localParticipant?.sid) return;
        roomStreamController.add(UserEvent(
            user: WhiteboardUser.fromJson(event.participant.metadata!),
            isJoin: false));
      })
      ..on<DataReceivedEvent>(
        (event) {
          final topic = LivekitDataTopic.fromString(event.topic!);
          if (topic == LivekitDataTopic.chat) {
            roomStreamController.add(
              WhiteboardChatMessage.fromJson(
                utf8.decoder.convert(event.data),
              ),
            );
          } else if (topic == LivekitDataTopic.drawing) {
            roomStreamController.add(
              BroadcastPaintData.fromJson(
                utf8.decoder.convert(event.data),
              ),
            );
          } else if (topic == LivekitDataTopic.viewport) {
            roomStreamController.add(
              ViewportChangeEvent.fromJson(
                utf8.decoder.convert(event.data),
              ),
            );
          } else if (topic == LivekitDataTopic.permission) {
            final parsedEvent = PermissionChangeEvent.fromJson(
              utf8.decoder.convert(event.data),
            );
            roomStreamController.add(
              parsedEvent,
            );
            if (parsedEvent.microphone != null) {
              room.localParticipant
                  ?.setMicrophoneEnabled(parsedEvent.microphone!);
            }
          } else if (topic == LivekitDataTopic.requestDrawingData) {
            if (event.participant != null) {
              final user =
                  WhiteboardUser.fromJson(event.participant!.metadata!);
              roomStreamController.add(RequestDrawingData(user.id));
            }
          } else if (topic == LivekitDataTopic.batchDrawingData) {
            try {
              batchDrawingDataTimer?.cancel();
              final batchDrawingData = BatchDrawingData.fromJson(
                jsonDecode(utf8.decoder.convert(event.data)),
              );
              onConnected(batchDrawingData);
            } catch (e, stackTrace) {
              log(e.toString(), stackTrace: stackTrace);
            }
          } else if (topic == LivekitDataTopic.requestPermission) {
            if (me.isHost) {
              final req = DrawingPermissionRequest.fromJson(
                utf8.decoder.convert(event.data),
              );
              roomStreamController.add(req);
            }
          } else if (topic == LivekitDataTopic.permissionGrant) {
            if (!me.isHost) {
              roomStreamController.add(DrawingPermissionTryGranting.fromJson(
                utf8.decoder.convert(event.data),
              ));
            }
          } else if (topic == LivekitDataTopic.permissionResponseForGrant) {
            if (me.isHost) {
              final req = DrawingPermissionGrantResponse.fromJson(
                utf8.decoder.convert(event.data),
              );
              changeDrawingPermission(req.userID, req.accepted);
            }
          }
        },
      );
  }

  List<WhiteboardUser> getUserList() {
    return room.participants.values
        .map<WhiteboardUser>((e) => WhiteboardUser.fromJson(e.metadata!))
        .toList();
  }

  Future<void> sendBatchDrawingData({required BatchDrawingData data}) async {
    try {
      final sid = room.participants.values
          .firstWhere(
            (element) => jsonDecode(element.metadata!)['id'] == data.userID,
          )
          .sid;
      room.localParticipant?.publishData(
        utf8.encode(jsonEncode(data.toJson())),
        destinationSids: [sid],
        reliability: Reliability.reliable,
        topic: 'batch_drawing_data',
      );
    } catch (e, stackTrace) {
      log(e.toString(), stackTrace: stackTrace);
    }
  }

  Future<void> requestDrawingData() async {
    room.localParticipant?.publishData(
      utf8.encode(
        RequestDrawingData(me.id).toJson(),
      ),
      topic: 'request_drawing',
    );
  }

  Future<void> requestPermissionChange(DrawingPermissionRequest event) async {
    room.localParticipant?.publishData(
      utf8.encode(
        event.toJson(),
      ),
      topic: 'request_permission',
    );
  }

  Future<void> changeMyMicrophone(bool bool) async {
    await room.localParticipant?.setMicrophoneEnabled(bool);
    room.localParticipant?.publishData(
      utf8.encode(
        PermissionChangeEvent(
          microphone: bool,
          userID: me.id,
        ).toJson(),
      ),
      topic: 'permission',
    );
  }

  Future<void> leaveRoom() async {
    if (isConnected) {
      await room.disconnect();
    }
  }

  Future<void> sendChatMessage(WhiteboardChatMessage event) async {
    await room.localParticipant?.publishData(
      utf8.encoder.convert(
        event.toJson(),
      ),
      topic: 'chat',
    );
  }

  void shareImageFile(File event) {
    room.localParticipant?.publishData(
      utf8.encoder.convert('https://picsum.photos/200/300'),
      topic: 'image',
    );
  }

  void sendDrawingData(BroadcastPaintData event) {
    room.localParticipant?.publishData(
      utf8.encoder.convert(
        event.toJson(),
      ),
      topic: 'drawing',
    );
  }

  void sendViewportChangeData(ViewportChangeEvent event) {
    room.localParticipant?.publishData(
      utf8.encoder.convert(
        event.toJson(),
      ),
      topic: 'viewport',
    );
  }

  void changeMicrophonePermission(String userID, bool bool) {
    final sid = room.participants.values
        .firstWhere((element) => jsonDecode(element.metadata!)['id'] == userID)
        .sid;
    room.localParticipant?.publishData(
        utf8.encoder.convert(
          PermissionChangeEvent(microphone: bool, userID: userID).toJson(),
        ),
        destinationSids: [sid],
        topic: 'permission');
  }

  void changeDrawingPermission(String userID, bool bool) {
    room.localParticipant?.publishData(
        utf8.encoder.convert(
          PermissionChangeEvent(
            drawing: bool,
            userID: userID,
          ).toJson(),
        ),
        topic: 'permission');
    roomStreamController.add(
      PermissionChangeEvent(
        drawing: bool,
        userID: userID,
      ),
    );
  }

  void respondToDrawingPermissionGrant(bool accepted) {
    room.localParticipant?.publishData(
      utf8.encoder.convert(
        DrawingPermissionGrantResponse(
          accepted: accepted,
          userID: me.id,
        ).toJson(),
      ),
      topic: LivekitDataTopic.permissionResponseForGrant.toString(),
    );
  }

  void tryGrantingDrawingPermission(String s) {
    room.localParticipant?.publishData(
      utf8.encoder.convert(DrawingPermissionTryGranting(userID: s).toJson()),
      topic: LivekitDataTopic.permissionGrant.toString(),
    );
  }
}

enum LivekitDataTopic {
  chat,
  drawing,
  viewport,
  permission,
  requestDrawingData,
  batchDrawingData,
  requestPermission,
  permissionGrant,
  permissionResponseForGrant;

  static LivekitDataTopic fromString(String string) {
    switch (string) {
      case 'chat':
        return LivekitDataTopic.chat;
      case 'drawing':
        return LivekitDataTopic.drawing;
      case 'viewport':
        return LivekitDataTopic.viewport;
      case 'permission':
        return LivekitDataTopic.permission;
      case 'request_drawing_data':
        return LivekitDataTopic.requestDrawingData;
      case 'batch_drawing_data':
        return LivekitDataTopic.batchDrawingData;
      case 'request_permission':
        return LivekitDataTopic.requestPermission;
      case 'permission_grant':
        return LivekitDataTopic.permissionGrant;
      case 'permission_response_for_grant':
        return LivekitDataTopic.permissionResponseForGrant;
      default:
        throw Exception('Invalid topic');
    }
  }

  @override
  String toString() {
    switch (this) {
      case LivekitDataTopic.chat:
        return 'chat';
      case LivekitDataTopic.drawing:
        return 'drawing';
      case LivekitDataTopic.viewport:
        return 'viewport';
      case LivekitDataTopic.permission:
        return 'permission';
      case LivekitDataTopic.requestDrawingData:
        return 'request_drawing_data';
      case LivekitDataTopic.batchDrawingData:
        return 'batch_drawing_data';
      case LivekitDataTopic.requestPermission:
        return 'request_permission';
      case LivekitDataTopic.permissionGrant:
        return 'permission_grant';
      case LivekitDataTopic.permissionResponseForGrant:
        return 'permission_response_for_grant';
    }
  }
}
