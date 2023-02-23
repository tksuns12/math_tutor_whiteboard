import 'dart:convert';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

class DrawingData extends Equatable {
  final Point point;
  final PenType penType;
  final double strokeWidth;
  final Color color;
  const DrawingData({
    required this.point,
    required this.penType,
    required this.strokeWidth,
    required this.color,
  });

  @override
  List<Object> get props => [point, penType, strokeWidth, color];

  Map<String, dynamic> toMap() {
    return {
      'point': point.toMap(),
      'penType': penType.toMap(),
      'strokeWidth': strokeWidth,
      'color': color.value,
    };
  }

  factory DrawingData.fromMap(Map<String, dynamic> map) {
    return DrawingData(
      point: Point(map['point']['x'], map['point']['y'], map['point']['p']),
      penType: PenType.fromMap(map['penType']),
      strokeWidth: map['strokeWidth']?.toDouble() ?? 0.0,
      color: Color(map['color']),
    );
  }

  String toJson() => json.encode(toMap());

  factory DrawingData.fromJson(String source) =>
      DrawingData.fromMap(json.decode(source));

  DrawingData copyWith({
    Point? point,
    PenType? penType,
    double? strokeWidth,
    Color? color,
  }) {
    return DrawingData(
      point: point ?? this.point,
      penType: penType ?? this.penType,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      color: color ?? this.color,
    );
  }
}

enum WhiteboardMode {
  liveTeaching,
  recordTeaching,
  record,
  participant,
}

extension PointSede on Point {
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'p': p,
    };
  }

  Point copyWith({
    double? x,
    double? y,
    double? p,
  }) {
    return Point(
      x ?? this.x,
      y ?? this.y,
      p ?? this.p,
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

  factory PenType.fromMap(Map<String, dynamic> map) {
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

  factory BroadcastCommand.fromMap(Map<String, dynamic> map) {
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
  const BroadcastPaintData({
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
    };
  }

  factory BroadcastPaintData.fromMap(Map<String, dynamic> map) {
    return BroadcastPaintData(
      drawingData: map['drawingData'] == null
          ? null
          : DrawingData.fromMap(map['drawingData']),
      limitCursor: map['limitCursor']?.toInt() ?? 0,
      command: BroadcastCommand.fromMap(map['command']),
      removeStrokeIndex: map['removeStrokeIndex']?.toInt(),
      boardSize: Size(map['boardSize']['width'], map['boardSize']['height']),
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
    ];
  }
}

class WhiteboardUser extends Equatable {
  final String? avatar;
  final String nickname;
  final bool micEnabled;
  final bool chatEnabled;
  final String serverUid;
  final String id;
  const WhiteboardUser({
    this.avatar,
    required this.nickname,
    required this.micEnabled,
    required this.chatEnabled,
    required this.serverUid,
    required this.id,
  });

  @override
  List<Object?> get props {
    return [
      avatar,
      nickname,
      micEnabled,
      chatEnabled,
      serverUid,
      id,
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'avatar': avatar,
      'nickname': nickname,
      'micEnabled': micEnabled,
      'chatEnabled': chatEnabled,
      'serverUid': serverUid,
      'id': id,
    };
  }

  factory WhiteboardUser.fromMap(Map<String, dynamic> map) {
    return WhiteboardUser(
      avatar: map['avatar'],
      nickname: map['nickname'] ?? '',
      micEnabled: map['micEnabled'] ?? false,
      chatEnabled: map['chatEnabled'] ?? false,
      serverUid: map['serverUid'] ?? '',
      id: map['id'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory WhiteboardUser.fromJson(String source) =>
      WhiteboardUser.fromMap(json.decode(source));
}

class WhiteboardChatMessage extends Equatable {
  final String message;
  final String nickname;
  const WhiteboardChatMessage({
    required this.message,
    required this.nickname,
  });

  @override
  List<Object> get props => [message, nickname];

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'nickname': nickname,
    };
  }

  factory WhiteboardChatMessage.fromMap(Map<String, dynamic> map) {
    return WhiteboardChatMessage(
      message: map['message'] ?? '',
      nickname: map['nickname'] ?? '',
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

  factory ViewportChangeEvent.fromMap(Map<String, dynamic> map) {
    return ViewportChangeEvent(
      matrix: Matrix4.fromFloat64List(map['matrix']),
      boardSize: Size(map['boardSize']['width'], map['boardSize']['height']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ViewportChangeEvent.fromJson(String source) =>
      ViewportChangeEvent.fromMap(json.decode(source));
}
