import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:livekit_client/livekit_client.dart';
import 'package:math_tutor_whiteboard/types/types.dart';

class LivekitService {
  late final Room room;
  final StreamController roomStreamController = StreamController.broadcast();
  get incomingStream => roomStreamController.stream;

  Future<void> joinRoom(bool isStudent, WhiteboardUser me) async {
    room = Room();
    await room.connect(
        'wss://math-tutor-hgpqkkg2.livekit.cloud',
        isStudent
            ? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2ODQ0NjIxMzUsImlzcyI6IkFQSURlWk5zYXkyRlE4ZCIsIm5hbWUiOiJzdHVkZW50IiwibmJmIjoxNjg0Mzc1NzM1LCJzdWIiOiJzdHVkZW50IiwidmlkZW8iOnsiY2FuVXBkYXRlT3duTWV0YWRhdGEiOnRydWUsInJvb20iOiJyZXN0cm9vbSIsInJvb21Kb2luIjp0cnVlfX0.RIv-X3nvn6qeoNtlOumEJ6Cgjhxx1OTQwEpHEGsuRHo'
            : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2ODQ0NjIxMTEsImlzcyI6IkFQSURlWk5zYXkyRlE4ZCIsIm5hbWUiOiJ0dXRvciIsIm5iZiI6MTY4NDM3NTcxMSwic3ViIjoidHV0b3IiLCJ2aWRlbyI6eyJjYW5VcGRhdGVPd25NZXRhZGF0YSI6dHJ1ZSwicm9vbSI6InJlc3Ryb29tIiwicm9vbUFkbWluIjp0cnVlLCJyb29tQ3JlYXRlIjp0cnVlLCJyb29tSm9pbiI6dHJ1ZX19.bQEA8cHXCx0-IE02FoPUuetFE0t5gepO4j8WT11dN9o');
    room.localParticipant?.setMetadata(me.toJson());
    await room.localParticipant?.setCameraEnabled(false);
    if (!isStudent) {
      await room.localParticipant?.publishVideoTrack(
        await LocalVideoTrack.createScreenShareTrack(
          const ScreenShareCaptureOptions(
            captureScreenAudio: false,
          ),
        ),
      );
    }
    await room.localParticipant?.setMicrophoneEnabled(true);
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
            roomStreamController.add(
              PermissionChangeEvent.fromJson(
                utf8.decoder.convert(event.data),
              ),
            );
          }
        },
      );
  }

  List<WhiteboardUser> getUserList() {
    return room.participants.values
        .map<WhiteboardUser>((e) => WhiteboardUser.fromJson(e.metadata!))
        .toList();
  }

  Future<void> changeMyMicrophone(bool bool) async {
    await room.localParticipant?.setMicrophoneEnabled(bool);
  }

  Future<void> leaveRoom() async {
    await room.disconnect();
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
          PermissionChangeEvent(drawing: bool, userID: userID).toJson(),
        ),
        destinationSids: [sid],
        topic: 'permission');
  }
}
