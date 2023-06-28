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

TileGrid rotatePattern(TileGrid pattern, int rotation) {
  TileGrid ret = [];
  rotation %= 4;

  final lengthY = pattern.length;
  final lengthX = pattern[0].length;

  switch (rotation) {
    case 0:
      for (var y = 0; y < lengthY; y++) {
        ret.add([]);
        for (var x = 0; x < lengthX; x++) {
          ret.last.add(pattern[y][x]);
        }
      }
      break;
    case 1:
      for (var y = 0; y < lengthX; y++) {
        ret.add([]);
        for (var x = lengthY - 1; x >= 0; x--) {
          ret.last.add(pattern[x][y]);
        }
      }
      break;
    case 2:
      for (var y = lengthY - 1; y >= 0; y--) {
        ret.add([]);
        for (var x = lengthX - 1; x >= 0; x--) {
          ret.last.add(pattern[y][x]);
        }
      }
      break;
    case 3:
      for (var y = lengthX - 1; y >= 0; y--) {
        ret.add([]);
        for (var x = 0; x < lengthY; x++) {
          ret.last.add(pattern[x][y]);
        }
      }
      break;
  }
  return ret;
}

Coords rotatePatternPoint(Coords point, int height, int width, int rot) {
  final edgeEdgeOffset = height.isEven && width.isEven ? -1 : 0;
  rot %= 4;
  switch (rot) {
    case 0:
      return point;
    case 1:
      return Coords(height-point.y - 1 + edgeEdgeOffset, point.x);
    case 2:
      return Coords(width-point.x - 1 + edgeEdgeOffset, height-point.y - 1 + edgeEdgeOffset);
    case 3:
      return Coords(point.y, width-point.x - 1 + edgeEdgeOffset);
    default:
      throw Exception("unreachable");
  }
}

@JsonSerializable()
class TableturfCardData {
  final int num;
  final String name, displayName;
  final String rarity;
  final int special;
  final TileGrid pattern;
  final TileGrid minPattern;
  final int count;
  final Coords selectPoint;
  final String designSprite;

  TableturfCardData(
      this.num,
      this.name,
      this.rarity,
      this.special,
      this.pattern,
      [String? design]
  ):
      designSprite = design ?? "assets/images/card_illustrations/${num}.png",
      displayName = {
        31: "E-liter 4K\nScope",
        32: "Bamboozler\n14 Mk I",
        36: "Sloshing\nMachine",
        42: "Ballpoint\nSplatling",
        47: "Dualie\nSquelchers",
        48: "Dark Tetra\nDualies",
        51: "Undercover\nBrella",
      }[num] ?? name,
      count = countLayout(pattern),
      minPattern = getMinPattern(pattern),
      selectPoint = (() {
        final minPattern = getMinPattern(pattern);
        return Coords(
          (minPattern[0].length / 2 - 1).ceil(),
          (minPattern.length / 2 - 1).ceil()
        );
      }());

  factory TableturfCardData.fromJson(Map<String, dynamic> json) => _$TableturfCardFromJson(json);

  bool operator==(Object other) {
    return other is TableturfCardData && other.num == this.num;
  }

  int get hashCode => num.hashCode;

  Map<String, dynamic> toJson() => _$TableturfCardToJson(this);
}

const TileStateEnumMap = _$TileStateEnumMap;

class Coords {
  final int x, y;

  const Coords(this.x, this.y);

  bool operator==(Object other) {
    return other is Coords && other.x == x && other.y == y;
  }

  int get hashCode {
    // jenkins hash functions
    // stolen unashamedly from the library `quiver`
    int _combine(int hash, int value) {
      hash = 0x1fffffff & (hash + value);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      return hash ^ (hash >> 6);
    }

    int _finish(int hash) {
      hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
      hash = hash ^ (hash >> 11);
      return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    }

    return _finish(_combine(_combine(0, x.hashCode), y.hashCode));
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
  String get designSprite => data.designSprite;
}