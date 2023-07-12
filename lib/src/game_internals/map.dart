import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tableturf_mobile/src/game_internals/tile.dart';

part 'map.g.dart';

@JsonSerializable()
class TableturfMap {
  final int mapID;
  final String name;
  final TileGrid board;

  const TableturfMap({
    required this.mapID,
    required this.name,
    required this.board,
  });

  factory TableturfMap.fromJson(Map<String, dynamic> json) => _$TableturfMapFromJson(json);
  Map<String, dynamic> toJson() => _$TableturfMapToJson(this);
}

bool mapsLoaded = false;
late final List<TableturfMap> officialMaps;

Future<void> loadMaps() async {
  if (!mapsLoaded) {
    final List<dynamic> jsonData = jsonDecode(await rootBundle.loadString("assets/maps.json"));
    officialMaps = jsonData.map((e) => TableturfMap.fromJson(e as Map<String, dynamic>)).toList(growable: false);
    mapsLoaded = true;
  }
}