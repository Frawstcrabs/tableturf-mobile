import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

import 'card.dart';

enum TileState {
  @JsonValue('X')
  empty,
  @JsonValue('.')
  unfilled,
  @JsonValue('x')
  wall,
  @JsonValue('y')
  yellow,
  @JsonValue('Y')
  yellowSpecial,
  @JsonValue('b')
  blue,
  @JsonValue('B')
  blueSpecial;

  bool get isYellow => this == TileState.yellow || this == TileState.yellowSpecial;
  bool get isBlue => this == TileState.blue || this == TileState.blueSpecial;
  bool get isSpecial => this == TileState.yellowSpecial || this == TileState.blueSpecial;
  bool get isFilled => this != TileState.unfilled;
}

class TileStateNotifier extends ChangeNotifier {
  TileState _value;

  TileStateNotifier(this._value);

  TileState get value => _value;
  set value(TileState val) {
    _value = val;
    notifyListeners();
  }
}

class TableturfTile {
  final TileStateNotifier state;
  final ValueNotifier<bool> specialIsActivated = ValueNotifier(false);

  TableturfTile(TileState _state):
    state = TileStateNotifier(_state);

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