// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableturfMap _$TableturfMapFromJson(Map<String, dynamic> json) => TableturfMap(
      mapID: json['mapID'] as int,
      name: json['name'] as String,
      board: (json['board'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map(TileState.fromJson).toList())
          .toList(),
    );

Map<String, dynamic> _$TableturfMapToJson(TableturfMap instance) =>
    <String, dynamic>{
      'mapID': instance.mapID,
      'name': instance.name,
      'board': instance.board
          .map((e) => e.map((e) => _$TileStateEnumMap[e]!).toList())
          .toList(),
    };

const _$TileStateEnumMap = {
  TileState.empty: 'X',
  TileState.unfilled: '.',
  TileState.wall: 'x',
  TileState.yellow: 'y',
  TileState.yellowSpecial: 'Y',
  TileState.blue: 'b',
  TileState.blueSpecial: 'B',
};
