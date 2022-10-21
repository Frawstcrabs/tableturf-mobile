// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cards.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableturfCard _$CardFromJson(Map<String, dynamic> json) => TableturfCard(
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

Map<String, dynamic> _$CardToJson(TableturfCard instance) => <String, dynamic>{
      'num': instance.num,
      'name': instance.name,
      'rarity': instance.rarity,
      'special': instance.special,
      'pattern': instance.pattern
          .map((e) => e.map((e) => _$TileStateEnumMap[e]!).toList())
          .toList(),
    };

const _$TileStateEnumMap = {
  TileState.Empty: 'X',
  TileState.Unfilled: '.',
  TileState.Wall: 'x',
  TileState.Yellow: 'y',
  TileState.YellowSpecial: 'Y',
  TileState.Blue: 'b',
  TileState.BlueSpecial: 'B',
};
