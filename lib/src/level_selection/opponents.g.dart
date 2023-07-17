// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opponents.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableturfOpponent _$TableturfOpponentFromJson(Map<String, dynamic> json) =>
    TableturfOpponent(
      name: json['name'] as String,
      mapID: json['mapID'] as int,
      deck: TableturfDeck.fromJson(json['deck'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TableturfOpponentToJson(TableturfOpponent instance) =>
    <String, dynamic>{
      'name': instance.name,
      'mapID': instance.mapID,
      'deck': instance.deck,
    };
