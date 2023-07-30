import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/settings/settings.dart';
import 'package:tableturf_mobile/src/style/shaders.dart';

import '../game_internals/card.dart';
import '../style/constants.dart';

import '../game_internals/battle.dart';
import '../game_internals/tile.dart';

class BoardPainter extends CustomPainter {
  static const EDGE_WIDTH = 0.5;

  final TileGrid board;
  final Listenable? repaint;
  final double? tileSideLength;
  final ValueListenable<bool>? specialButtonOn;
  final ui.Image? normalInk, specialInk, wallTile;

  BoardPainter({
    required this.board,
    this.repaint,
    this.specialButtonOn,
    this.tileSideLength,
    this.normalInk,
    this.specialInk,
    this.wallTile,
  }): super(repaint: Listenable.merge([specialButtonOn, repaint]));

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter;
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter
      ..strokeWidth = EDGE_WIDTH
      ..color = Palette.tileEdge;
    // draw

    final tileSideLength = this.tileSideLength ?? min(
      size.height / board.length,
      size.width / board[0].length,
    );
    final specialButtonOn = this.specialButtonOn?.value ?? false;
    for (var y = 0; y < board.length; y++) {
      for (var x = 0; x < board[0].length; x++) {
        final state = board[y][x];
        final tileRect = Rect.fromLTWH(
            x * tileSideLength,
            y * tileSideLength,
            tileSideLength,
            tileSideLength
        );

        switch (state) {
          case TileState.empty:
            // draw nothing
            break;
          case TileState.unfilled:
            bodyPaint.color = Palette.tileUnfilled;
            if (specialButtonOn) {
              bodyPaint.color = Color.alphaBlend(
                const Color.fromRGBO(0, 0, 0, 0.4),
                bodyPaint.color,
              );
            }
            canvas.drawRect(tileRect, bodyPaint);
            canvas.drawRect(tileRect, edgePaint);
            break;
          case TileState.wall:
            final wallImage = wallTile;
            if (wallImage == null) {
              bodyPaint.color = Palette.tileWall;
              if (specialButtonOn) {
                bodyPaint.color = Color.alphaBlend(
                  const Color.fromRGBO(0, 0, 0, 0.4),
                  bodyPaint.color,
                );
              }
              canvas.drawRect(tileRect, bodyPaint);
              canvas.drawRect(tileRect, edgePaint);
            } else {
              paintImage(
                canvas: canvas,
                rect: tileRect,
                image: wallImage,
                colorFilter: specialButtonOn ? null : ColorFilter.mode(
                  const Color.fromRGBO(0, 0, 0, 0.4),
                  BlendMode.srcATop,
                )
              );
            }
            break;
          case TileState.yellow:
          case TileState.blue:
            final normalImage = normalInk;
            bodyPaint.color = state.isYellow
                ? const Color.fromRGBO(238, 249, 2, 1.0)
                : Palette.tileBlue;
            if (normalImage == null) {
              if (specialButtonOn) {
                bodyPaint.color = Color.alphaBlend(
                  const Color.fromRGBO(0, 0, 0, 0.4),
                  bodyPaint.color,
                );
              }
              canvas.drawRect(tileRect, bodyPaint);
              canvas.drawRect(tileRect, edgePaint);
            } else {
              paintImage(
                canvas: canvas,
                rect: tileRect,
                image: normalImage,
                colorFilter: ColorFilter.mode(
                  bodyPaint.color,
                  BlendMode.dstOver,
                )
              );
              if (specialButtonOn) {
                canvas.drawRect(tileRect, bodyPaint..color = const Color.fromRGBO(0, 0, 0, 0.4));
              }
            }
            break;
          case TileState.yellowSpecial:
          case TileState.blueSpecial:
            final specialImage = specialInk;
            bodyPaint.color = state.isYellow
                ? Palette.tileYellowSpecial
                : Palette.tileBlueSpecial;
            if (specialImage == null) {
              canvas.drawRect(tileRect, bodyPaint);
              canvas.drawRect(tileRect, edgePaint);
            } else {
              paintImage(
                canvas: canvas,
                rect: tileRect,
                image: specialImage,
                colorFilter: ColorFilter.mode(
                  bodyPaint.color,
                  BlendMode.dstOver,
                )
              );
            }
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return (
      this.board != oldDelegate.board
        || this.tileSideLength != oldDelegate.tileSideLength
        || this.specialButtonOn != oldDelegate.specialButtonOn
        || this.repaint != oldDelegate.repaint
        || this.normalInk != oldDelegate.normalInk
        || this.specialInk != oldDelegate.specialInk
        || this.wallTile != oldDelegate.wallTile
    );
  }
}

class BoardFlashPainter extends CustomPainter {
  final Animation<double> flashAnimation;
  final ValueListenable<Set<Coords>> flashTilesNotifier;
  final double tileSideLength;

  BoardFlashPainter(this.flashAnimation, this.flashTilesNotifier, this.tileSideLength):
    super(repaint: Listenable.merge([flashAnimation, flashTilesNotifier]))
  ;

  @override
  void paint(Canvas canvas, Size size) {
    if (flashAnimation.value == 0.0) return;
    final flashTiles = flashTilesNotifier.value;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter
      ..color = Colors.white.withOpacity(flashAnimation.value);
    for (final coords in flashTiles) {
      final tileRect = Rect.fromLTWH(
        coords.x * tileSideLength,
        coords.y * tileSideLength,
        tileSideLength,
        tileSideLength
      );
      canvas.drawRect(tileRect, paint);
    }
  }

  @override
  bool shouldRepaint(BoardFlashPainter oldDelegate) {
    return (
      this.tileSideLength != oldDelegate.tileSideLength
        || this.flashTilesNotifier != oldDelegate.flashTilesNotifier
    );
  }
}

class BoardSpecialPainter extends CustomPainter {
  final TileGrid board;
  final double? tileSideLength;
  final ValueListenable<Set<Coords>> activatedSpecialsNotifier;
  final Animation<double> flameAnimation;
  final ui.Image fireMask, fireEffect;

  BoardSpecialPainter({
    required this.board,
    required this.fireMask,
    required this.fireEffect,
    required this.activatedSpecialsNotifier,
    required this.flameAnimation,
    this.tileSideLength,
  }): super(repaint: Listenable.merge([flameAnimation, activatedSpecialsNotifier]));

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final activatedSpecials = activatedSpecialsNotifier.value;
    final settings = Settings();

    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter;
    final tileSideLength = this.tileSideLength ?? min(
      size.height / board.length,
      size.width / board[0].length,
    );

    final shader = Shaders.specialFire.fragmentShader();
    for (final coords in activatedSpecials) {
      final x = coords.x;
      final y = coords.y;
      final state = board[y][x];
      bodyPaint.color = state == TileState.yellowSpecial ? Palette.tileYellowSpecialCenter
          : state == TileState.blueSpecial ? Palette.tileBlueSpecialCenter
          : throw Exception("Invalid tile colour given for special: ${state.name}");
      canvas.drawCircle(
          Offset(
            (x + 0.5) * tileSideLength,
            (y + 0.5) * tileSideLength,
          ),
          tileSideLength / 3,
          bodyPaint
      );
      if (settings.continuousAnimation.value) {
        final flameRect = Rect.fromLTWH(
            (x - 0.5) * tileSideLength,
            (y - 1.0) * tileSideLength,
            tileSideLength * 2,
            tileSideLength * 2
        );
        final flameColor = state == TileState.yellowSpecial ? Palette.tileYellowSpecialFlame
            : state == TileState.blueSpecial ? Palette.tileBlueSpecialFlame
            : Color.fromRGBO(0, 0, 0, 1);
        shader.setImageSampler(0, fireMask);
        shader.setImageSampler(1, fireEffect);
        shader.setFloat(0, flameRect.left);
        shader.setFloat(1, flameRect.top);
        shader.setFloat(2, flameRect.width);
        shader.setFloat(3, flameRect.height);
        shader.setFloat(4, (flameColor.red / 255.0) * flameColor.opacity);
        shader.setFloat(5, (flameColor.green / 255.0) * flameColor.opacity);
        shader.setFloat(6, (flameColor.blue / 255.0) * flameColor.opacity);
        shader.setFloat(7, flameColor.opacity);
        shader.setFloat(8, flameAnimation.value);
        final shaderPaint = Paint()
          ..shader = shader;
        canvas.drawRect(
          flameRect,
          shaderPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BoardSpecialPainter other) {
    return (
        this.board != other.board
        || this.tileSideLength != other.tileSideLength
        || this.flameAnimation != other.flameAnimation
        || this.activatedSpecialsNotifier != other.activatedSpecialsNotifier
        || this.fireEffect != other.fireEffect
        || this.fireMask != other.fireMask
    );
  }
}

class BoardWidget extends StatefulWidget {
  final TableturfBattle battle;
  final double tileSize;

  const BoardWidget(this.battle, {
    super.key,
    required this.tileSize,
  });

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with TickerProviderStateMixin {
  late final AnimationController _flashController;
  late final AnimationController _flameController;
  late final Animation<double> flashOpacity;
  final ValueNotifier<bool> showSpecialDarken = ValueNotifier(false);
  late AssetImage _normalInkImage, _specialInkImage, _wallTileImage, _maskImage, _effectImage;
  ImageStream? _normalInkStream, _specialInkStream, _wallTileStream, _maskStream, _effectStream;
  ImageInfo? _normalInkInfo, _specialInkInfo, _wallTileInfo, _maskInfo, _effectInfo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _normalInkImage = AssetImage("assets/images/normal_ink.png");
    _specialInkImage = AssetImage("assets/images/special_ink.png");
    _wallTileImage = AssetImage("assets/images/wall.png");
    _maskImage = AssetImage("assets/images/fire_mask3.png");
    _effectImage = AssetImage("assets/images/fire_noise.jpg");
    // We call _getImage here because createLocalImageConfiguration() needs to
    // be called again if the dependencies changed, in case the changes relate
    // to the DefaultAssetBundle, MediaQuery, etc, which that method uses.
    _getImage();
  }

  @override
  void didUpdateWidget(BoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _getImage() {
    final ImageStream? oldMaskStream = _maskStream;
    _maskStream = _maskImage.resolve(createLocalImageConfiguration(context));
    if (_maskStream!.key != oldMaskStream?.key) {
      // If the keys are the same, then we got the same image back, and so we don't
      // need to update the listeners. If the key changed, though, we must make sure
      // to switch our listeners to the new image stream.
      final ImageStreamListener listener = ImageStreamListener(_updateMaskImage);
      oldMaskStream?.removeListener(listener);
      _maskStream!.addListener(listener);
    }
    final ImageStream? oldEffectStream = _effectStream;
    _effectStream = _effectImage.resolve(createLocalImageConfiguration(context));
    if (_effectStream!.key != oldEffectStream?.key) {
      // If the keys are the same, then we got the same image back, and so we don't
      // need to update the listeners. If the key changed, though, we must make sure
      // to switch our listeners to the new image stream.
      final ImageStreamListener listener = ImageStreamListener(_updateEffectImage);
      oldEffectStream?.removeListener(listener);
      _effectStream!.addListener(listener);
    }
    final ImageStream? oldNormalInkStream = _normalInkStream;
    _normalInkStream = _normalInkImage.resolve(createLocalImageConfiguration(context));
    if (_normalInkStream!.key != oldNormalInkStream?.key) {
      // If the keys are the same, then we got the same image back, and so we don't
      // need to update the listeners. If the key changed, though, we must make sure
      // to switch our listeners to the new image stream.
      final ImageStreamListener listener = ImageStreamListener(_updateNormalInkImage);
      oldNormalInkStream?.removeListener(listener);
      _normalInkStream!.addListener(listener);
    }
    final ImageStream? oldSpecialInkStream = _specialInkStream;
    _specialInkStream = _specialInkImage.resolve(createLocalImageConfiguration(context));
    if (_specialInkStream!.key != oldSpecialInkStream?.key) {
      // If the keys are the same, then we got the same image back, and so we don't
      // need to update the listeners. If the key changed, though, we must make sure
      // to switch our listeners to the new image stream.
      final ImageStreamListener listener = ImageStreamListener(_updateSpecialInkImage);
      oldSpecialInkStream?.removeListener(listener);
      _specialInkStream!.addListener(listener);
    }
    final ImageStream? oldWallTileStream = _wallTileStream;
    _wallTileStream = _wallTileImage.resolve(createLocalImageConfiguration(context));
    if (_wallTileStream!.key != oldWallTileStream?.key) {
      // If the keys are the same, then we got the same image back, and so we don't
      // need to update the listeners. If the key changed, though, we must make sure
      // to switch our listeners to the new image stream.
      final ImageStreamListener listener = ImageStreamListener(_updateWallTileImage);
      oldWallTileStream?.removeListener(listener);
      _wallTileStream!.addListener(listener);
    }
  }

  void _updateMaskImage(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      // Trigger a build whenever the image changes.
      _maskInfo?.dispose();
      _maskInfo = imageInfo;
    });
  }

  void _updateEffectImage(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      // Trigger a build whenever the image changes.
      _effectInfo?.dispose();
      _effectInfo = imageInfo;
    });
  }

  void _updateNormalInkImage(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      // Trigger a build whenever the image changes.
      _normalInkInfo?.dispose();
      _normalInkInfo = imageInfo;
    });
  }

  void _updateSpecialInkImage(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      // Trigger a build whenever the image changes.
      _specialInkInfo?.dispose();
      _specialInkInfo = imageInfo;
    });
  }

  void _updateWallTileImage(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      // Trigger a build whenever the image changes.
      _wallTileInfo?.dispose();
      _wallTileInfo = imageInfo;
    });
  }

  @override
  void initState() {
    _flashController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this
    );
    _flameController = AnimationController(
        duration: const Duration(milliseconds: 900),
        vsync: this
    );
    _flashController.value = 1.0;
    flashOpacity = Tween(
      begin: 1.0,
      end: 0.0
    ).animate(_flashController);

    widget.battle.boardChangeNotifier.addListener(_runFlash);
    widget.battle.activatedSpecialsNotifier.addListener(_runFlameAnimation);
    widget.battle.moveSpecialNotifier.addListener(_checkSpecialDarken);
    widget.battle.revealCardsNotifier.addListener(_clearSpecialDarken);
    _runFlameAnimation();
    super.initState();
  }

  void _runFlash() {
    _flashController.forward(from: 0.0);
  }

  void _runFlameAnimation() {
    final settings = Settings();
    if (!settings.continuousAnimation.value) {
      return;
    }
    if (widget.battle.activatedSpecialsNotifier.value.isNotEmpty) {
      _flameController.repeat();
    } else {
      _flameController.stop();
      _flameController.value = 0.0;
    }
  }

  void _checkSpecialDarken() {
    showSpecialDarken.value = widget.battle.moveSpecialNotifier.value;
  }

  void _clearSpecialDarken() {
    showSpecialDarken.value = false;
  }

  @override
  void dispose() {
    widget.battle.boardChangeNotifier.removeListener(_runFlash);
    widget.battle.activatedSpecialsNotifier.removeListener(_runFlameAnimation);
    _flashController.dispose();
    _flameController.dispose();
    _maskStream?.removeListener(ImageStreamListener(_updateMaskImage));
    _maskInfo?.dispose();
    _maskInfo = null;
    _effectStream?.removeListener(ImageStreamListener(_updateEffectImage));
    _effectInfo?.dispose();
    _effectInfo = null;
    _normalInkStream?.removeListener(ImageStreamListener(_updateNormalInkImage));
    _normalInkInfo?.dispose();
    _normalInkInfo = null;
    _specialInkStream?.removeListener(ImageStreamListener(_updateSpecialInkImage));
    _specialInkInfo?.dispose();
    _specialInkInfo = null;
    _wallTileStream?.removeListener(ImageStreamListener(_updateWallTileImage));
    _wallTileInfo?.dispose();
    _wallTileInfo = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: BoardPainter(
              board: widget.battle.board,
              tileSideLength: widget.tileSize,
              specialButtonOn: showSpecialDarken,
              repaint: widget.battle.boardChangeNotifier,
              //normalInk: _normalInkInfo?.image,
              //specialInk: _specialInkInfo?.image,
              //wallTile: _wallTileInfo?.image,
            ),
            child: Container(),
            isComplex: true,
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: BoardFlashPainter(
              flashOpacity,
              widget.battle.boardChangeNotifier,
              widget.tileSize
            ),
            child: Container(),
            willChange: true,
          ),
        ),
        if (_maskInfo != null && _effectInfo != null)
          RepaintBoundary(
            child: CustomPaint(
              painter: BoardSpecialPainter(
                board: widget.battle.board,
                tileSideLength: widget.tileSize,
                activatedSpecialsNotifier: widget.battle.activatedSpecialsNotifier,
                flameAnimation: _flameController,
                fireMask: _maskInfo!.image,
                fireEffect: _effectInfo!.image,
              ),
              child: Container(),
              willChange: true,
            ),
          )
      ],
    );
  }
}