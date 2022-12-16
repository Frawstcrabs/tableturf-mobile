import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/game_internals/move_selection.dart';

class MoveSelection extends InheritedWidget {
  final TableturfMoveSelection selection;
  const MoveSelection({
    Key? key,
    required Widget child,
    required TableturfMoveSelection this.selection,
  }) : super(key: key, child: child);

  static TableturfMoveSelection of(BuildContext context) {
    final MoveSelection? result =
        context.dependOnInheritedWidgetOfExactType<MoveSelection>();
    assert(result != null, 'No MoveSelection found in context');
    return result!.selection;
  }

  @override
  bool updateShouldNotify(MoveSelection old) {
    return selection != old.selection;
  }
}
