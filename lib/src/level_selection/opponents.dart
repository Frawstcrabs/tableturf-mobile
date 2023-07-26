import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';

import '../game_internals/deck.dart';

part 'opponents.g.dart';

@JsonSerializable()
class TableturfOpponent {
  final String name;
  final int mapID;
  final TableturfDeck deck;

  const TableturfOpponent({
    required this.name,
    required this.mapID,
    required this.deck,
  });

  factory TableturfOpponent.fromJson(Map<String, dynamic> json) => _$TableturfOpponentFromJson(json);

  Map<String, dynamic> toJson() => _$TableturfOpponentToJson(this);
}

bool opponentsLoaded = false;
late final List<TableturfOpponent> opponents;

Future<void> loadOpponents() async {
  if (!opponentsLoaded) {
    final List<dynamic> jsonData = jsonDecode(await rootBundle.loadString("assets/opponents.json"));
    opponents = jsonData.map((e) => TableturfOpponent.fromJson(e as Map<String, dynamic>)).toList(growable: false);
    opponentsLoaded = true;
  }
}

const Map<int, String> deckIcons = {
  -1: "babyjelly",
  -2: "cooljelly",
  -3: "aggrojelly",
  -4: "sheldon",
  -5: "gnarlyeddy",
  -6: "jellafleur",
  -7: "mrcoco",
  -8: "harmony",
  -9: "judd",
  -10: "liljudd",
  -11: "murch",
  -12: "shiver",
  -13: "frye",
  -14: "bigman",
  -15: "staff",
  -16: "cuttlefish",
  -17: "callie",
  -18: "marie",
  -19: "shelly",
  -20: "annie",
  -21: "jelonzo",
  -22: "fredcrumbs",
  -23: "spyke",
  -1000: "randomiser",
  -1001: "randomiser",
};
