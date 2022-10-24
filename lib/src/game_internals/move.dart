import '../game_internals/card.dart';

class TableturfMove {
  final TableturfCard card;
  final int rotation;
  final int y, x;
  final bool special, pass;

  const TableturfMove({
    required this.card,
    required this.rotation,
    required this.x,
    required this.y,
    this.special = false,
    this.pass = false,
  });
}