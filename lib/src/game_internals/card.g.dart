// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableturfCardData _$TableturfCardFromJson(Map<String, dynamic> json) =>
    TableturfCardData(
      json['num'] as int,
      json['name'] as String,
      json['rarity'] as String,
      json['special'] as int,
      (json['pattern'] as List<dynamic>)
          .map((e) => (e as List<dynamic>)
              .map((e) => $enumDecode(_$TileStateEnumMap, e))
              .toList())
          .toList(),
    );

Map<String, dynamic> _$TableturfCardToJson(TableturfCardData instance) =>
    <String, dynamic>{
      'num': instance.num,
      'name': instance.name,
      'rarity': instance.rarity,
      'special': instance.special,
      'pattern': instance.pattern
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
