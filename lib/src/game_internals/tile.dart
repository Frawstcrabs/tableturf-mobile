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
  BlueSpecial;

  bool get isYellow => this == TileState.Yellow || this == TileState.YellowSpecial;
  bool get isBlue => this == TileState.Blue || this == TileState.BlueSpecial;
  bool get isSpecial => this == TileState.YellowSpecial || this == TileState.BlueSpecial;
  bool get isFilled => this != TileState.Unfilled;
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