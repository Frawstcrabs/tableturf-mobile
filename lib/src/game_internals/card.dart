import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'tile.dart';

part "card.g.dart";

int countLayout(List<List<TileState>> pattern) {
  int layout_amount = 0;
  for (final row in pattern) {
    for (final value in row) {
      if (value != TileState.unfilled) {
        layout_amount += 1;
      }
    }
  }
  return layout_amount;
}

TileGrid getMinPattern(TileGrid pattern) {
  var retPattern = TileGrid.from(pattern.map((l) => List<TileState>.from(l)));

  // trim top edge
  while (true) {
    final edge = retPattern[0];
    if (edge.every((e) => e == TileState.unfilled)) {
      retPattern.removeAt(0);
    } else {
      break;
    }
  }

  // trim bottom edge
  while (true) {
    final edge = retPattern.last;
    if (edge.every((e) => e == TileState.unfilled)) {
      retPattern.removeLast();
    } else {
      break;
    }
  }

  // trim left edge
  while (true) {
    final edge = retPattern.map((row) => row[0]);
    if (edge.every((e) => e == TileState.unfilled)) {
      for (final row in retPattern) {
        row.removeAt(0);
      }
    } else {
      break;
    }
  }

  // trim right edge
  while (true) {
    final edge = retPattern.map((row) => row.last);
    if (edge.every((e) => e == TileState.unfilled)) {
      for (final row in retPattern) {
        row.removeLast();
      }
    } else {
      break;
    }
  }

  return retPattern;
}

@JsonSerializable()
class TableturfCardData {
  final int num;
  final String name;
  final String rarity;
  final int special;
  final TileGrid pattern;
  final TileGrid minPattern;
  final int count;
  final Coords selectPoint;

  TableturfCardData(this.num, this.name, this.rarity, this.special, this.pattern):
      count = countLayout(pattern),
      minPattern = getMinPattern(pattern),
      selectPoint = Coords(
        (getMinPattern(pattern)[0].length / 2 - 1).ceil(),
        (getMinPattern(pattern).length / 2 - 1).ceil()
      );

  factory TableturfCardData.fromJson(Map<String, dynamic> json) => _$TableturfCardFromJson(json);

  bool operator==(Object other) {
    return other is TableturfCardData && other.num == this.num;
  }

  Map<String, dynamic> toJson() => _$TableturfCardToJson(this);
}

const TileStateEnumMap = _$TileStateEnumMap;

class Coords {
  final int x, y;

  const Coords(this.x, this.y);

  bool operator==(Object other) {
    return other is Coords && other.x == x && other.y == y;
  }

  String toString() {
    return "Coords($x, $y)";
  }
}

bool cardsLoaded = false;
late final List<TableturfCardData> cards;

Future<void> loadCards() async {
  if (!cardsLoaded) {
    final List<dynamic> jsonData = jsonDecode(await rootBundle.loadString("assets/cards.json"));
    cards = jsonData.map((e) => TableturfCardData.fromJson(e as Map<String, dynamic>)).toList(growable: false);
    cardsLoaded = true;
  }
}

class TableturfCard {
  final TableturfCardData data;
  bool isPlayable = false, isPlayableSpecial = false, isHeld = false, hasBeenPlayed = false;
  TableturfCard(this.data);

  int get num => data.num;
  String get name => data.name;
  String get rarity => data.rarity;
  int get special => data.special;
  TileGrid get pattern => data.pattern;
  TileGrid get minPattern => data.minPattern;
  int get count => data.count;
  Coords get selectPoint => data.selectPoint;
}