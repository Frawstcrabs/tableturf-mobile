import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../level_selection/levels.dart';

part "cards.g.dart";

int countLayout(List<List<TileState>> pattern) {
  int layout_amount = 0;
  for (final row in pattern) {
    for (final value in row) {
      if (value != TileState.Unfilled) {
        layout_amount += 1;
      }
    }
  }
  return layout_amount;
}

@JsonSerializable()
class TableturfCard {
  final int num;
  final String name;
  final String rarity;
  final int special;
  final List<List<TileState>> pattern;
  final int count;

  TableturfCard(this.num, this.name, this.rarity, this.special, this.pattern):
      count = countLayout(pattern);

  factory TableturfCard.fromJson(Map<String, dynamic> json) => _$CardFromJson(json);

  Map<String, dynamic> toJson() => _$CardToJson(this);
}

bool cardsLoaded = false;
late final List<TableturfCard> cards;

Future<void> loadCards() async {
  if (!cardsLoaded) {
    final List<dynamic>jsonData = jsonDecode(await rootBundle.loadString("assets/cards.json"));
    cards = jsonData.map((e) => TableturfCard.fromJson(e as Map<String, dynamic>)).toList(growable: false);
    cardsLoaded = true;
  }
}