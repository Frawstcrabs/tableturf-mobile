import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';

import 'cardwidget.dart';

class SpecialMeter extends StatefulWidget {
  final TableturfPlayer player;
  const SpecialMeter({required this.player, super.key});

  @override
  State<SpecialMeter> createState() => _SpecialMeterState();
}

class _SpecialMeterState extends State<SpecialMeter> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            widget.player.name,
            style: TextStyle(
                fontFamily: "Splatfont1",
                fontStyle: FontStyle.italic,
                color: Colors.white,
                fontSize: 16,
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
        AnimatedBuilder(
          animation: widget.player.special,
          builder: (_, __) {
            return Row(
              children: [
                for (var i = 0; i < widget.player.special.value; i++)
                  Container(
                    margin: EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: widget.player.traits.specialColour,
                      border: Border.all(
                        width: CardPatternWidget.TILE_EDGE,
                        color: Colors.black,
                      ),
                    ),
                    width: 12,
                    height: 12,
                  )
              ]
            );
          }
        )
      ]
    );

  }
}
