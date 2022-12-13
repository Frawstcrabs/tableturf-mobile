import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';

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
      duration: const Duration(milliseconds: 250),
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
    return AnimatedBuilder(
      animation: _introAnimation,
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
      builder: (context, child) {
        return ScaleTransition(
          scale: introScale,
          child: FadeTransition(
            opacity: introFade,
            child: child,
          )
        );
      }
    );
  }
}

class SpecialMeter extends StatelessWidget {
  final TableturfPlayer player;
  const SpecialMeter({required this.player, super.key});

  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          color: player.traits.normalColour,
          margin: const EdgeInsets.only(right: 6),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final tileSize = constraints.maxHeight;
                    return AnimatedBuilder(
                        animation: player.special,
                        builder: (_, __) {
                          return Row(
                              children: [
                                for (var i = 0; i <
                                    max(player.special.value, 4); i++)
                                  Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    child: Stack(
                                        children: [
                                          Container(
                                            color: Color.fromRGBO(
                                                0, 0, 0, max((4 - i) / 4, 0)),
                                            width: tileSize,
                                            height: tileSize,
                                          ),
                                          if (i < player.special.value)
                                            SpecialTile(
                                              colour: player.traits
                                                  .specialColour,
                                              tileSize: tileSize,
                                            )
                                        ]
                                    ),
                                  )
                              ]
                          );
                        }
                    );
                  }
                ),
              )
            ]
          ),
        ),
      ],
    );
  }
}
