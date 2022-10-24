// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

bool mapsLoaded = false;
late final Map<String, dynamic> maps;

Future<void> loadMaps() async {
  if (!mapsLoaded) {
    final jsonData = jsonDecode(await rootBundle.loadString("assets/maps.json"));
    maps = jsonData;
    mapsLoaded = true;
  }
}