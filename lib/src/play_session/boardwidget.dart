import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../style/palette.dart';

import '../game_internals/battle.dart';
import '../game_internals/tile.dart';
import '../game_internals/card.dart';

class BoardWidget extends StatelessWidget {
  final TableturfBattle battle;
  final double tileSize;

  const BoardWidget(this.battle, {
    super.key,
    required this.tileSize,
  });

  void _updateLocation(PointerEvent details, BuildContext context) {
    if (battle.yellowMoveNotifier.value != null) {
      return;
    }
    final board = battle.board;
    final newLocation = details.localPosition;
    final boardTileStep = tileSize - BoardTile.EDGE_WIDTH;
    final newX = (newLocation.dx / boardTileStep).floor();
    final newY = (newLocation.dy / boardTileStep).floor();
    if (
    newY < 0 ||
        newY >= board.length ||
        newX < 0 ||
        newX >= board[0].length
    ) {
      battle.moveLocationNotifier.value = null;
    } else {
      final newCoords = Coords(newX, newY);
      if (battle.moveLocationNotifier.value != newCoords) {
        final audioController = AudioController();
        audioController.playSfx(SfxType.cursorMove);
      }
      battle.moveLocationNotifier.value = newCoords;
    }
  }

  void _onPointerHover(PointerEvent details, BuildContext context) {
    if (details.kind == PointerDeviceKind.mouse) {
      _updateLocation(details, context);
    }
  }

  void _onPointerMove(PointerEvent details, BuildContext context) {
    _updateLocation(details, context);
  }

  void _onPointerDown(PointerEvent details, BuildContext context) {
    if (details.kind == PointerDeviceKind.mouse) {
      battle.confirmMove();
    } else {
      _updateLocation(details, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardState = battle.board;
    final boardTileStep = tileSize - BoardTile.EDGE_WIDTH;
    final boardWidget = Stack(
      children: boardState.asMap().entries.expand((entry) {
        int y = entry.key;
        var row = entry.value;
        return row.asMap().entries.map((entry) {
          int x = entry.key;
          var tile = entry.value;
          return Positioned(
              top: y * boardTileStep,
              left: x * boardTileStep,
              child: BoardTile(tile, tileSize: tileSize)
          );
        }).toList(growable: false);
      }).toList(growable: false)
    );

    return Listener(
      onPointerDown: (details) => _onPointerDown(details, context),
      onPointerMove: (details) => _onPointerMove(details, context),
      onPointerHover: (details) => _onPointerHover(details, context),
      child: boardWidget,
    );
  }
}

class BoardTile extends StatefulWidget {
  static const EDGE_WIDTH = 0.5;
  final TableturfTile tile;
  final double tileSize;

  const BoardTile(this.tile, {
    super.key,
    required this.tileSize,
  });

  @override
  State<BoardTile> createState() => _BoardTileState();
}

class _BoardTileState extends State<BoardTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;
  late final Animation<Decoration> _flashAnimation;

  @override
  void initState() {
    _flashController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this
    );
    _flashController.value = 1.0;
    _flashAnimation = DecorationTween(
      begin: BoxDecoration(
        color: Colors.white
      ),
      end: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0)
      )
    ).animate(_flashController);

    widget.tile.addListener(_runFlash);
    super.initState();
  }

  void _runFlash() {
    _flashController.forward(from: 0.0);
    setState(() {});
  }

  @override
  void dispose() {
    widget.tile.removeListener(_runFlash);
    _flashController.dispose();
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
          width: widget.tileSize,
          height: widget.tileSize,
        ),
        AnimatedBuilder(
          animation: _flashController,
          builder: (_, __) => Container(
            width: widget.tileSize,
            height: widget.tileSize,
            decoration: _flashAnimation.value,
          )
        )
      ]
    );
  }
}