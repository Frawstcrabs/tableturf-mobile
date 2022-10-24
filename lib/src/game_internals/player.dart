import 'package:flutter/foundation.dart';

import 'card.dart';

class TableturfPlayer {
  final List<TableturfCard> deck;
  final List<TableturfCard> hand;
  final ValueNotifier<int> special;

  TableturfPlayer({
    required this.deck,
    required this.hand,
    special = 0
  }): special = ValueNotifier(special);
}