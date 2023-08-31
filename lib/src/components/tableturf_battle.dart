import 'dart:async';

import 'package:flutter/material.dart';

import '../game_internals/battle.dart';

class TableturfBattle extends InheritedWidget {
  final Stream<BattleEvent> eventStream;
  final TableturfBattleController controller;
  const TableturfBattle({
    super.key,
    required this.eventStream,
    required this.controller,
    required super.child,
  });

  static TableturfBattleController getControllerOf(BuildContext context) {
    final widget = context.getInheritedWidgetOfExactType<TableturfBattle>()!;
    return widget.controller;
  }

  static TableturfBattleController get(BuildContext context) {
    final widget = context.getInheritedWidgetOfExactType<TableturfBattle>()!;
    return widget.controller;
  }

  static StreamSubscription<BattleEvent> listen(BuildContext context, void Function(BattleEvent) onData) {
    final widget = context.getInheritedWidgetOfExactType<TableturfBattle>()!;
    return widget.eventStream.listen(onData);
  }

  @override
  bool updateShouldNotify(TableturfBattle oldWidget) => eventStream != oldWidget.eventStream;
}
