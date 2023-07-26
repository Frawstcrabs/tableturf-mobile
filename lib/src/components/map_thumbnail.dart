import 'package:flutter/material.dart';

import '../game_internals/map.dart';
import '../style/constants.dart';
import 'board_widget.dart';

class MapThumbnail extends StatelessWidget {
  final TableturfMap map;
  const MapThumbnail({
    super.key,
    required this.map,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Palette.mapThumbnailBorder,
            width: 3.0,
          ),
          borderRadius: BorderRadius.circular(15.0),
          color: Palette.mapThumbnailBackground,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.9,
          widthFactor: 0.9,
          child: Center(
              child: CustomPaint(
                painter: BoardPainter(
                  board: map.board,
                ),
                child: AspectRatio(
                  aspectRatio: map.board[0].length / map.board.length,
                ),
                isComplex: true,
              )
          ),
        )
    );
  }
}