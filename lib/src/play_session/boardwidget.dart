import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';

import '../game_internals/battle.dart';
import '../game_internals/tile.dart';

class BoardWidget extends StatelessWidget {
  final TableturfBattle battle;

  const BoardWidget(this.battle, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final boardState = battle.board;
    final boardTileStep = BoardTile.SIDE_LEN - BoardTile.EDGE_WIDTH;
    return Stack(
        children: boardState.asMap().entries.expand((entry) {
          int y = entry.key;
          var row = entry.value;
          return row.asMap().entries.map((entry) {
            int x = entry.key;
            var tile = entry.value;
            return Positioned(
                top: y * boardTileStep,
                left: x * boardTileStep,
                child: BoardTile(tile)
            );
          }).toList(growable: false);
        }).toList(growable: false)
    );
  }
}

class BoardTile extends StatefulWidget {
  static const SIDE_LEN = 19.0;
  static const EDGE_WIDTH = 0.5;
  final TableturfTile tile;

  const BoardTile(this.tile, {super.key});

  @override
  State<BoardTile> createState() => _BoardTileState();
}

class _BoardTileState extends State<BoardTile>
    with SingleTickerProviderStateMixin {
  late AnimationController flashController;

  @override
  void initState() {
    flashController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this
    );
    widget.tile.addListener(_runFlash);
    super.initState();
  }

  void _runFlash() {
    flashController.reverse(from: 1.0);
    setState(() {});
  }

  @override
  void dispose() {
    widget.tile.removeListener(_runFlash);
    flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final state = widget.tile.state;
    return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: state == TileState.Unfilled ? palette.tileUnfilled
                  : state == TileState.Wall ? palette.tileWall
                  : state == TileState.Yellow ? palette.tileYellow
                  : state == TileState.YellowSpecial ? palette.tileYellowSpecial
                  : state == TileState.Blue ? palette.tileBlue
                  : state == TileState.BlueSpecial ? palette.tileBlueSpecial
                  : Color.fromRGBO(0, 0, 0, 0),
              border: Border.all(
                  width: BoardTile.EDGE_WIDTH,
                  color: state == TileState.Empty
                      ? Color.fromRGBO(0, 0, 0, 0)
                      : palette.tileEdge
              ),
            ),
            width: BoardTile.SIDE_LEN,
            height: BoardTile.SIDE_LEN,
          ),
          FadeTransition(
              opacity: flashController,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                height: BoardTile.SIDE_LEN + (BoardTile.EDGE_WIDTH * 2),
                width: BoardTile.SIDE_LEN + (BoardTile.EDGE_WIDTH * 2),
              )
          )
        ]
    );
  }
}