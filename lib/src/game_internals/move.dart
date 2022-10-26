import '../game_internals/card.dart';
import 'player.dart';

class TableturfMove {
  final TableturfCard card;
  final int rotation;
  final int y, x;
  final bool special, pass;
  final PlayerTraits traits;

  const TableturfMove({
    required this.card,
    required this.rotation,
    required this.x,
    required this.y,
    this.traits = const YellowTraits(),
    this.special = false,
    this.pass = false,
  });
}