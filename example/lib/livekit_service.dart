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
            ? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2ODY4NzY4NjEsImlzcyI6IkFQSURlWk5zYXkyRlE4ZCIsIm5hbWUiOiJzdHVkZW50IiwibmJmIjoxNjg2NzkwNDYxLCJzdWIiOiJzdHVkZW50IiwidmlkZW8iOnsiY2FuVXBkYXRlT3duTWV0YWRhdGEiOnRydWUsInJvb20iOiJyZXN0cm9vbSIsInJvb21Kb2luIjp0cnVlfX0.J4UkjTomUTcaywNaD-DCBMhBV7oh8I7DqYQxNQMTin0'
            : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2ODY4NzY4ODYsImlzcyI6IkFQSURlWk5zYXkyRlE4ZCIsIm5hbWUiOiJ0dXRvciIsIm5iZiI6MTY4Njc5MDQ4Niwic3ViIjoidHV0b3IiLCJ2aWRlbyI6eyJjYW5VcGRhdGVPd25NZXRhZGF0YSI6dHJ1ZSwicm9vbSI6InJlc3Ryb29tIiwicm9vbUFkbWluIjp0cnVlLCJyb29tQ3JlYXRlIjp0cnVlLCJyb29tSm9pbiI6dHJ1ZX19.f1XHUYSf7QP23Hu5ArsShHJwlnhJmYeSgtmqF6K2-ps');

    room.localParticipant?.setMetadata(me.toJson());
    isConnected = true;
    final anyParticipant = room.participants.values.firstOrNull;
    if (anyParticipant != null) {
      room.localParticipant?.publishData(
        [],
        destinationSids: [anyParticipant.sid],
        topic: 'request_drawing_data',
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
          if (event.topic == 'chat') {
            roomStreamController.add(
              WhiteboardChatMessage.fromJson(
                utf8.decoder.convert(event.data),
              ),
            );
          } else if (event.topic == 'drawing') {
            roomStreamController.add(
              BroadcastPaintData.fromJson(
                utf8.decoder.convert(event.data),
              ),
            );
          } else if (event.topic == 'viewport') {
            roomStreamController.add(
              ViewportChangeEvent.fromJson(
                utf8.decoder.convert(event.data),
              ),
            );
          } else if (event.topic == 'permission') {
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
          } else if (event.topic == 'request_drawing_data') {
            if (event.participant != null) {
              final user =
                  WhiteboardUser.fromJson(event.participant!.metadata!);
              roomStreamController.add(RequestDrawingData(user.id));
            }
          } else if (event.topic == 'batch_drawing_data') {
            try {
              batchDrawingDataTimer?.cancel();
              final batchDrawingData = BatchDrawingData.fromJson(
                utf8.decoder.convert(event.data),
              );
              onConnected(batchDrawingData);
            } catch (e, stackTrace) {
              log(e.toString(), stackTrace: stackTrace);
            }
          } else if (event.topic == 'request_permission') {
            if (me.isHost) {
              final req = DrawingPermissionRequest.fromJson(
                utf8.decoder.convert(event.data),
              );
              roomStreamController.add(req);
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
        utf8.encode(data.toJson()),
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

  Future<void> requestPermissionChange(PermissionChangeEvent event) async {
    room.localParticipant?.publishData(
      utf8.encode(
        event.toJson(),
      ),
      topic: 'request_permission',
    );
  }

  Future<void> changeMyMicrophone(bool bool) async {
    await room.localParticipant?.setMicrophoneEnabled(bool);
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
    final sid = room.participants.values
        .firstWhere((element) => jsonDecode(element.metadata!)['id'] == userID)
        .sid;
    room.localParticipant?.publishData(
        utf8.encoder.convert(
          PermissionChangeEvent(
            drawing: bool,
            userID: userID,
          ).toJson(),
        ),
        destinationSids: [sid],
        topic: 'permission');
    if (bool) {
      roomStreamController.add(
        const PermissionChangeEvent(
          drawing: false,
        ),
      );
    } else {
      roomStreamController.add(
        const PermissionChangeEvent(
          drawing: true,
        ),
      );
    }
  }
}
