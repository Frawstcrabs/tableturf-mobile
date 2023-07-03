// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableturfCardIdentifier _$TableturfCardIdentifierFromJson(
        Map<String, dynamic> json) =>
    TableturfCardIdentifier(
      json['num'] as int,
      $enumDecode(_$TableturfCardTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$TableturfCardIdentifierToJson(
        TableturfCardIdentifier instance) =>
    <String, dynamic>{
      'num': instance.num,
      'type': _$TableturfCardTypeEnumMap[instance.type]!,
    };

const _$TableturfCardTypeEnumMap = {
  TableturfCardType.official: 'official',
  TableturfCardType.custom: 'custom',
  TableturfCardType.randomiser: 'randomiser',
};

TableturfCardData _$TableturfCardDataFromJson(Map<String, dynamic> json) =>
    TableturfCardData(
      json['num'] as int,
      json['name'] as String,
      json['rarity'] as String,
      json['special'] as int,
      (json['pattern'] as List<dynamic>)
          .map((e) =>
              (e as List<dynamic>).map((e) => TileState.fromJson(e)).toList())
          .toList(),
      json['displayName'] as String?,
      $enumDecode(_$TableturfCardTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$TableturfCardDataToJson(TableturfCardData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'displayName': instance.displayName,
      'rarity': instance.rarity,
      'special': instance.special,
      'pattern': instance.pattern
          .map((e) => e.map((e) => _$TileStateEnumMap[e]!).toList())
          .toList(),
      'num': instance.num,
      'type': _$TableturfCardTypeEnumMap[instance.type]!,
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
