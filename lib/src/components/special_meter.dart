import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/style/constants.dart';

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

class SpecialMeter extends StatelessWidget {
  final TableturfPlayer player;
  final TextDirection direction;
  const SpecialMeter({
    super.key,
    required this.player,
    this.direction = TextDirection.ltr,
  });

  Widget build(BuildContext context) {
    return Row(
      textDirection: direction,
      children: [
        Container(
          width: 5,
          color: player.traits.normalColour,
          margin: direction == TextDirection.ltr
            ? const EdgeInsets.only(right: 6)
            : const EdgeInsets.only(left: 6)
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: direction,
            children: [
              Expanded(
                flex: 5,
                child: FittedBox(
                  fit: BoxFit.fitHeight,
                  child: Text(
                    player.name,
                    style: TextStyle(
                      fontFamily: "Splatfont1",
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: 0.6,
                      shadows: [
                        Shadow(
                          color: Color.fromRGBO(128, 128, 128, 1),
                          offset: Offset(1, 1),
                        )
                      ]
                    )
                  ),
                ),
              ),
              const Spacer(
                flex: 1,
              ),
              Expanded(
                flex: 5,
                child: RepaintBoundary(
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final tileSize = constraints.maxHeight;
                      return FittedBox(
                        fit: BoxFit.fill,
                        child: ValueListenableBuilder(
                          valueListenable: player.special,
                          builder: (_, int specialCount, __) {
                            return Row(
                              textDirection: direction,
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
                                          colour: player.traits.specialColour,
                                          tileSize: tileSize,
                                        )
                                      ]
                                    ) : SpecialTile(
                                      colour: player.traits.specialColour,
                                      tileSize: tileSize,
                                    ),
                                  )
                              ]
                            );
                          }
                        ),
                      );
                    }
                  ),
                ),
              )
            ]
          ),
        ),
      ],
    );
  }
}
