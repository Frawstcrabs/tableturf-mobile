import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/style/constants.dart';

import '../game_internals/battle.dart';
import 'tableturf_battle.dart';
import 'card_widget.dart';

class SpecialTile extends StatefulWidget {
  final Color colour;
  final double tileSize;
  const SpecialTile({required this.colour, required this.tileSize, super.key});

  @override
  State<SpecialTile> createState() => _SpecialTileState();
}

class _SpecialTileState extends State<SpecialTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introAnimation;
  late final Animation<double> introScale, introFade;

  @override
  void initState() {
    super.initState();

    _introAnimation = AnimationController(
      duration: Durations.animateInSpecialPoint,
      vsync: this
    );

    introScale = Tween(
      begin: 2.0,
      end: 1.0,
    ).chain(
      CurveTween(curve: Curves.easeOutBack)
    ).animate(_introAnimation);
    introFade = Tween(
      begin: 0.0,
      end: 1.0,
    ).chain(
        CurveTween(curve: Curves.easeOut)
    ).animate(_introAnimation);

    _introAnimation.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: introScale,
      child: FadeTransition(
        opacity: introFade,
        child: Container(
          decoration: BoxDecoration(
            color: widget.colour,
            border: Border.all(
              width: CardPatternWidget.EDGE_WIDTH,
              color: Colors.black,
            ),
          ),
          width: widget.tileSize,
          height: widget.tileSize,
        ),
      )
    );
  }
}

class SpecialMeter extends StatefulWidget {
  final TableturfPlayer player;
  final int? initialValue;
  final TextDirection direction;
  const SpecialMeter({
    super.key,
    required this.player,
    this.direction = TextDirection.ltr,
    this.initialValue,
  });

  @override
  State<SpecialMeter> createState() => _SpecialMeterState();
}

class _SpecialMeterState extends State<SpecialMeter> {
  late final ValueNotifier<int> specialNotifier;
  late final StreamSubscription<BattleEvent> battleSubscription;

  @override
  void initState() {
    super.initState();
    specialNotifier = ValueNotifier(widget.initialValue ?? 0);
    battleSubscription = TableturfBattle.listen(context, _onBattleEvent);
  }

  @override
  void dispose() {
    battleSubscription.cancel();
    super.dispose();
  }

  Future<void> _onBattleEvent(BattleEvent event) async {
    switch (event) {
      case PlayerSpecialUpdate(:final specialDiffs):
        specialNotifier.value += specialDiffs[widget.player.id]!;
    }
  }

  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (_, constraints) {
          final tileSize = constraints.maxHeight;
          return FittedBox(
            fit: BoxFit.contain,
            alignment: AlignmentDirectional.centerStart.resolve(widget.direction),
            child: ValueListenableBuilder(
              valueListenable: specialNotifier,
              builder: (_, int specialCount, __) {
                return Row(
                  textDirection: widget.direction,
                  children: [
                    for (var i = 0; i < max(specialCount, 4); i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: i < 4 ? Stack(
                          children: [
                            Container(
                              color: Color.fromRGBO(0, 0, 0, (4 - i) / 4),
                              width: tileSize,
                              height: tileSize,
                            ),
                            if (i < specialCount) SpecialTile(
                              colour: widget.player.traits.specialColour,
                              tileSize: tileSize,
                            )
                          ]
                        ) : SpecialTile(
                          colour: widget.player.traits.specialColour,
                          tileSize: tileSize,
                        ),
                      ),
                  ],
                );
              }
            ),
          );
        }
      ),
    );
  }
}
