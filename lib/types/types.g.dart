// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_BatchDrawingData _$$_BatchDrawingDataFromJson(Map<String, dynamic> json) =>
    _$_BatchDrawingData(
      userID: json['userID'] as String,
      drawingData: (json['drawingData'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => (e as List<dynamic>)
                    .map((e) => DrawingData.fromJson(e as String))
                    .toList())
                .toList()),
      ),
      limitCursor: Map<String, int>.from(json['limitCursor'] as Map),
      deletedStrokes: (json['deletedStrokes'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as Map<String, dynamic>).map(
              (k, e) => MapEntry(int.parse(k), e as int),
            )),
      ),
    );

Map<String, dynamic> _$$_BatchDrawingDataToJson(_$_BatchDrawingData instance) =>
    <String, dynamic>{
      'userID': instance.userID,
      'drawingData': instance.drawingData,
      'limitCursor': instance.limitCursor,
      'deletedStrokes': instance.deletedStrokes.map(
          (k, e) => MapEntry(k, e.map((k, e) => MapEntry(k.toString(), e)))),
    };
