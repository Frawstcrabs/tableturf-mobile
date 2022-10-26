import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

import 'card.dart';

enum TileState {
  @JsonValue('X')
  Empty,
  @JsonValue('.')
  Unfilled,
  @JsonValue('x')
  Wall,
  @JsonValue('y')
  Yellow,
  @JsonValue('Y')
  YellowSpecial,
  @JsonValue('b')
  Blue,
  @JsonValue('B')
  BlueSpecial,
}

class TableturfTile extends ChangeNotifier {
  TileState _state;

  TableturfTile(this._state);

  TileState get state => _state;
  set state(TileState newState) {
    _state = newState;
    notifyListeners();
  }

  factory TableturfTile.fromJson(dynamic source) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
      '${TileStateEnumMap.values.join(', ')}');
  }
  return TableturfTile(TileStateEnumMap.entries
      .singleWhere((e) => e.value == source,
        orElse: () => throw ArgumentError(
        '`$source` is not one of the supported values: '
        '${TileStateEnumMap.values.join(', ')}'))
            .key);
  }
}

typedef TileGrid = List<List<TileState>>;
typedef BoardGrid = List<List<TableturfTile>>;