// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../game_internals/tile.dart';

bool mapsLoaded = false;
late final Map<String, TileGrid> maps;

Future<void> loadMaps() async {
  if (!mapsLoaded) {
    final Map<String, dynamic> jsonData = jsonDecode(await rootBundle.loadString("assets/maps.json"));
    maps = Map.fromEntries(
      jsonData.entries
        .map((entry) {
          return MapEntry(
            entry.key,
            entry.value.map<List<TileState>>((row) {
              return (row as List<dynamic>)
                .map(TileState.fromJson)
                .toList(growable: false);
            }).toList(growable: false)
          );
        })
    );
    mapsLoaded = true;
  }
}