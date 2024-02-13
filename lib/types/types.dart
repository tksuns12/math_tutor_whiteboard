// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:flutter/foundation.dart';
part 'types.freezed.dart';
part 'types.g.dart';

class DrawingData extends Equatable {
  final PointVector point;
  final PenType penType;
  final double strokeWidth;
  final Color color;
  final String userID;
  const DrawingData({
    required this.userID,
    required this.point,
    required this.penType,
    required this.strokeWidth,
    required this.color,
  });

  @override
  List<Object> get props => [point, penType, strokeWidth, color, userID];

  Map<String, dynamic> toMap() {
    return {
      'point': point.toMap(),
      'penType': penType.toMap(),
      'strokeWidth': strokeWidth,
      'color': color.value,
      'userID': userID,
    };
  }

  factory DrawingData.fromMap(Map map) {
    return DrawingData(
      point: PointVector(map['point']['x'], map['point']['y'], map['point']['p']),
      penType: PenType.fromMap(map['penType']),
      strokeWidth: map['strokeWidth']?.toDouble() ?? 0.0,
      color: Color(map['color']),
      userID: map['userID'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DrawingData.fromJson(String source) =>
      DrawingData.fromMap(json.decode(source));

  DrawingData copyWith({
    PointVector? point,
    PenType? penType,
    double? strokeWidth,
    Color? color,
    String? userID,
  }) {
    return DrawingData(
      point: point ?? this.point,
      penType: penType ?? this.penType,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      color: color ?? this.color,
      userID: userID ?? this.userID,
    );
  }
}

enum WhiteboardMode {
  live,
  liveTeaching,
  recordTeaching,
  record,
  participant;

  bool get isUsingWebSocket =>
      this == WhiteboardMode.liveTeaching ||
      this == WhiteboardMode.live ||
      this == WhiteboardMode.participant;
}

extension PointSede on PointVector {
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'p': pressure,
    };
  }

  PointVector copyWith({
    double? x,
    double? y,
    double? p,
  }) {
    return PointVector(
      x ?? this.x,
      y ?? this.y,
      p ?? pressure,
    );
  }
}

enum PenType {
  pen,
  highlighter,
  strokeEraser,
  penEraser;

  Map<String, dynamic> toMap() {
    return {
      'type': PenType.values.indexOf(this),
    };
  }

  factory PenType.fromMap(Map map) {
    return PenType.values[map['type']];
  }
}

enum BroadcastCommand {
  draw,
  clear,
  removeStroke;

  Map<String, dynamic> toMap() {
    return {
      'type': BroadcastCommand.values.indexOf(this),
    };
  }

  factory BroadcastCommand.fromMap(Map map) {
    return BroadcastCommand.values[map['type']];
  }
}

extension SizeSerde on Size {
  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
    };
  }

  Size copyWith({
    double? width,
    double? height,
  }) {
    return Size(
      width ?? this.width,
      height ?? this.height,
    );
  }
}

class BroadcastPaintData extends Equatable {
  final DrawingData? drawingData;
  final int limitCursor;
  final BroadcastCommand command;
  final int? removeStrokeIndex;
  final Size boardSize;
  final String userID;
  const BroadcastPaintData({
    required this.userID,
    required this.boardSize,
    required this.drawingData,
    required this.limitCursor,
    required this.command,
    this.removeStrokeIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'drawingData': drawingData?.toMap(),
      'limitCursor': limitCursor,
      'command': command.toMap(),
      'removeStrokeIndex': removeStrokeIndex,
      'boardSize': boardSize.toMap(),
      'userID': userID,
    };
  }

  factory BroadcastPaintData.fromMap(Map map) {
    return BroadcastPaintData(
      drawingData: map['drawingData'] == null
          ? null
          : DrawingData.fromMap(map['drawingData']),
      limitCursor: map['limitCursor']?.toInt() ?? 0,
      command: BroadcastCommand.fromMap(map['command']),
      removeStrokeIndex: map['removeStrokeIndex']?.toInt(),
      boardSize: Size(map['boardSize']['width'], map['boardSize']['height']),
      userID: map['userID'],
    );
  }

  String toJson() => json.encode(toMap());

  factory BroadcastPaintData.fromJson(String source) =>
      BroadcastPaintData.fromMap(json.decode(source));

  @override
  List<Object?> get props {
    return [
      drawingData,
      limitCursor,
      command,
      removeStrokeIndex,
      boardSize,
    ];
  }

  @override
  String toString() {
    return 'BroadcastPaintData(drawingData: $drawingData, limitCursor: $limitCursor, command: $command, removeStrokeIndex: $removeStrokeIndex, boardSize: $boardSize)';
  }
}

class WhiteboardUser extends Equatable {
  final String? avatar;
  final String nickname;
  final bool micEnabled;
  final bool drawingEnabled;
  final String id;
  final bool isHost;
  const WhiteboardUser({
    required this.isHost,
    this.avatar,
    required this.nickname,
    required this.micEnabled,
    required this.drawingEnabled,
    required this.id,
  });

  @override
  List<Object?> get props {
    return [
      avatar,
      nickname,
      micEnabled,
      drawingEnabled,
      id,
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'avatar': avatar,
      'nickname': nickname,
      'micEnabled': micEnabled,
      'drawingEnabled': drawingEnabled,
      'id': id,
      'isHost': isHost,
    };
  }

  factory WhiteboardUser.fromMap(Map map) {
    return WhiteboardUser(
      avatar: map['avatar'],
      nickname: map['nickname'] ?? '',
      micEnabled: map['micEnabled'] ?? false,
      drawingEnabled: map['drawingEnabled'] ?? false,
      id: map['id'] ?? '',
      isHost: map['isHost'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory WhiteboardUser.fromJson(String source) =>
      WhiteboardUser.fromMap(json.decode(source));

  WhiteboardUser copyWith({
    String? avatar,
    String? nickname,
    bool? micEnabled,
    bool? drawingEnabled,
    String? id,
    bool? isHost,
  }) {
    return WhiteboardUser(
      avatar: avatar ?? this.avatar,
      nickname: nickname ?? this.nickname,
      micEnabled: micEnabled ?? this.micEnabled,
      drawingEnabled: drawingEnabled ?? this.drawingEnabled,
      id: id ?? this.id,
      isHost: isHost ?? this.isHost,
    );
  }
}

class WhiteboardChatMessage extends Equatable {
  final String message;
  final String nickname;
  final DateTime sentAt;
  const WhiteboardChatMessage({
    required this.sentAt,
    required this.message,
    required this.nickname,
  });

  @override
  List<Object> get props => [message, nickname];

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'nickname': nickname,
      'receivedAt': sentAt.toIso8601String(),
    };
  }

  factory WhiteboardChatMessage.fromMap(Map map) {
    return WhiteboardChatMessage(
      message: map['message'] ?? '',
      nickname: map['nickname'] ?? '',
      sentAt: DateTime.parse(map['receivedAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory WhiteboardChatMessage.fromJson(String source) =>
      WhiteboardChatMessage.fromMap(json.decode(source));
}

class UserEvent extends Equatable {
  final WhiteboardUser user;
  final bool isJoin;
  const UserEvent({
    required this.user,
    required this.isJoin,
  });

  @override
  List<Object> get props => [user, isJoin];
}

class ViewportChangeEvent extends Equatable {
  final Matrix4 matrix;
  final Size boardSize;
  const ViewportChangeEvent({
    required this.matrix,
    required this.boardSize,
  });

  @override
  List<Object> get props => [matrix, boardSize];

  Map<String, dynamic> toMap() {
    return {
      'matrix': matrix.storage,
      'boardSize': boardSize.toMap(),
    };
  }

  Matrix4 adjustedMatrix(Size myBoardSize) {
    // Calculate the scaling factors for the width and height
    double widthScale = myBoardSize.width / boardSize.width;
    double heightScale = myBoardSize.height / boardSize.height;

    // Calculate the new translation components
    Vector3 translation = matrix.getTranslation();
    double newTx = translation.x * widthScale;
    double newTy = translation.y * heightScale;
    final ex = matrix.getMaxScaleOnAxis();

    // Create a scaling matrix
    return Matrix4.identity()
      ..translate(newTx, newTy)
      ..scale(ex);
  }

  factory ViewportChangeEvent.fromMap(Map map) {
    return ViewportChangeEvent(
      matrix: Matrix4.fromFloat64List(Float64List.fromList(
          (map['matrix'] as List).map((e) => e as double).toList())),
      boardSize: Size(
        map['boardSize']['width'],
        map['boardSize']['height'],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory ViewportChangeEvent.fromJson(String source) =>
      ViewportChangeEvent.fromMap(json.decode(source));
}

class PermissionChangeEvent extends Equatable {
  final bool? drawing;
  final bool? microphone;
  final String? userID;
  const PermissionChangeEvent({
    this.userID,
    this.drawing,
    this.microphone,
  });

  @override
  List<Object?> get props => [drawing, microphone, userID];

  Map<String, dynamic> toMap() {
    return {
      'drawing': drawing,
      'microphone': microphone,
      'userID': userID,
    };
  }

  factory PermissionChangeEvent.fromMap(Map map) {
    return PermissionChangeEvent(
      drawing: map['drawing'],
      microphone: map['microphone'],
      userID: map['userID'],
    );
  }

  String toJson() => json.encode(toMap());

  factory PermissionChangeEvent.fromJson(String source) =>
      PermissionChangeEvent.fromMap(json.decode(source));
}

class InitialUserListEvent extends Equatable {
  final List<WhiteboardUser> users;

  const InitialUserListEvent({
    required this.users,
  });

  @override
  List<Object> get props => [users];
}

class ImageChangeEvent extends Equatable {
  final String imageUrl;

  const ImageChangeEvent(this.imageUrl);

  @override
  List<Object> get props => [imageUrl];
}

class LiveEndTimeChangeEvent extends Equatable {
  final Duration duration;
  final DateTime endAt;
  const LiveEndTimeChangeEvent({
    required this.endAt,
    required this.duration,
  });

  @override
  List<Object> get props => [duration];
}

@freezed
sealed class BatchDrawingData with _$BatchDrawingData {
  const factory BatchDrawingData({
    required String userID,
    required Map<String, List<List<DrawingData>>> drawingData,
    required Map<String, int> limitCursor,
    required Map<String, Map<int, int>> deletedStrokes,
  }) = _BatchDrawingData;

  factory BatchDrawingData.fromJson(Map<String, dynamic> json) =>
      _$_BatchDrawingData.fromJson(json);
}

class RequestDrawingData {
  final String participantID;

  RequestDrawingData(this.participantID);

  Map<String, dynamic> toMap() {
    return {
      'participantID': participantID,
    };
  }

  factory RequestDrawingData.fromMap(Map<String, dynamic> map) {
    return RequestDrawingData(
      map['participantID'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory RequestDrawingData.fromJson(String source) =>
      RequestDrawingData.fromMap(json.decode(source));
}

class DrawingPermissionRequest extends Equatable {
  final String userID;
  final String nickname;
  const DrawingPermissionRequest({
    required this.nickname,
    required this.userID,
  });

  @override
  List<Object> get props => [userID, nickname];

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'nickname': nickname,
    };
  }

  factory DrawingPermissionRequest.fromMap(Map<String, dynamic> map) {
    return DrawingPermissionRequest(
      userID: map['userID'] ?? '',
      nickname: map['nickname'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DrawingPermissionRequest.fromJson(String source) =>
      DrawingPermissionRequest.fromMap(json.decode(source));
}

class DrawingPermissionTryGranting {
  final String userID;
  DrawingPermissionTryGranting({
    required this.userID,
  });

  DrawingPermissionTryGranting copyWith({
    String? userID,
  }) {
    return DrawingPermissionTryGranting(
      userID: userID ?? this.userID,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
    };
  }

  factory DrawingPermissionTryGranting.fromMap(Map<String, dynamic> map) {
    return DrawingPermissionTryGranting(
      userID: map['userID'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DrawingPermissionTryGranting.fromJson(String source) =>
      DrawingPermissionTryGranting.fromMap(json.decode(source));

  @override
  String toString() => 'DrawingPermissionTryGranting(userID: $userID)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DrawingPermissionTryGranting && other.userID == userID;
  }

  @override
  int get hashCode => userID.hashCode;
}

class DrawingPermissionGrantResponse extends Equatable {
  final String userID;
  final bool accepted;
  const DrawingPermissionGrantResponse({
    required this.userID,
    required this.accepted,
  });

  @override
  List<Object> get props => [userID, accepted];

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'accepted': accepted,
    };
  }

  factory DrawingPermissionGrantResponse.fromMap(Map<String, dynamic> map) {
    return DrawingPermissionGrantResponse(
      userID: map['userID'] ?? '',
      accepted: map['accepted'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory DrawingPermissionGrantResponse.fromJson(String source) =>
      DrawingPermissionGrantResponse.fromMap(json.decode(source));

  DrawingPermissionGrantResponse copyWith({
    String? userID,
    bool? accepted,
  }) {
    return DrawingPermissionGrantResponse(
      userID: userID ?? this.userID,
      accepted: accepted ?? this.accepted,
    );
  }
}
