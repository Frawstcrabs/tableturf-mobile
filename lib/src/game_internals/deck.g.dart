// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TableturfDeck _$TableturfDeckFromJson(Map<String, dynamic> json) =>
    TableturfDeck(
      deckID: json['deckID'] as int,
      cards: (json['cards'] as List<dynamic>)
          .map((e) => TableturfCardData.fromJson(e as Map<String, dynamic>))
          .toList(),
      name: json['name'] as String,
      cardSleeve: json['cardSleeve'] as String,
    );

Map<String, dynamic> _$TableturfDeckToJson(TableturfDeck instance) =>
    <String, dynamic>{
      'deckID': instance.deckID,
      'cards': instance.cards,
      'name': instance.name,
      'cardSleeve': instance.cardSleeve,
    };
