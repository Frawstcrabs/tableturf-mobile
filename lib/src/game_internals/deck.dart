import 'package:json_annotation/json_annotation.dart';

import 'card.dart';

part 'deck.g.dart';

@JsonSerializable()
class TableturfDeck {
  final int deckID;
  final List<TableturfCardData> cards;
  final String name;
  final String cardSleeve;

  const TableturfDeck({
    required this.deckID,
    required this.cards,
    required this.name,
    required this.cardSleeve,
  });

  factory TableturfDeck.fromJson(Map<String, dynamic> json) => _$TableturfDeckFromJson(json);
  Map<String, dynamic> toJson() => _$TableturfDeckToJson(this);
}