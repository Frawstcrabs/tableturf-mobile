import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';

import '../style/constants.dart';

import '../game_internals/battle.dart';
import '../game_internals/player.dart';
import '../game_internals/card.dart';
import '../game_internals/tile.dart';

class CardPatternPainter extends CustomPainter {
  static const EDGE_WIDTH = 0.5;

  final List<List<TileState>> pattern;
  final PlayerTraits traits;
  final double tileSideLength;

  CardPatternPainter(this.pattern, this.traits, this.tileSideLength);

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter;
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter
      ..strokeWidth = EDGE_WIDTH
      ..color = Palette.cardTileEdge;
    // draw
    for (var y = 0; y < pattern.length; y++) {
      for (var x = 0; x < pattern[0].length; x++) {
        final state = pattern[y][x];

        bodyPaint.color = state == TileState.unfilled ? Palette.cardTileUnfilled
            : state == TileState.yellow ? traits.normalColour
            : state == TileState.yellowSpecial ? traits.specialColour
            : Colors.red;
        final tileRect = Rect.fromLTWH(
            x * tileSideLength,
            y * tileSideLength,
            tileSideLength,
            tileSideLength
        );
        canvas.drawRect(tileRect, bodyPaint);
        canvas.drawRect(tileRect, edgePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class CardPainter extends CustomPainter {
  static const EDGE_WIDTH = 0.5;
  final TableturfCardData card;
  final PlayerTraits traits;
  final ui.Image? cardImage;
  final Color? background;
  final Color? overlayColor;

  const CardPainter({
    required this.card,
    required this.traits,
    this.cardImage,
    this.background,
    this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // portrait layout
    final cardRect = Offset.zero & size;
    canvas.clipRect(cardRect);
    final bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.miter;
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter
      ..strokeWidth = EDGE_WIDTH
      ..color = Palette.cardTileEdge;
    final background = this.background ?? Palette.cardBackgroundSelectable;
    canvas.drawRect(cardRect, bodyPaint..color = background);
    canvas.drawRect(cardRect, edgePaint..color = Palette.cardEdge);

    // draw card image
    if (cardImage != null) {
      paintImage(
        canvas: canvas,
        image: cardImage!,
        rect: cardRect,
        opacity: 0.7,
        fit: BoxFit.contain,
      );
    }
    if (size.width <= size.height) {
      // portrait layout
      // draw card pattern
      final patternOrigin = size.width * (1/18);
      final tileSize = size.width * (1/9);
      edgePaint.color = Palette.cardTileEdge;
      for (var y = 0; y < card.pattern.length; y++) {
        for (var x = 0; x < card.pattern[0].length; x++) {
          final state = card.pattern[y][x];

          bodyPaint.color = state == TileState.unfilled ? Palette.cardTileUnfilled
              : state == TileState.yellow ? traits.normalColour
              : state == TileState.yellowSpecial ? traits.specialColour
              : Colors.red;
          final tileRect = Offset(patternOrigin + (x * tileSize), patternOrigin + (y * tileSize)) & Size.square(tileSize);
          canvas.drawRect(tileRect, bodyPaint);
          canvas.drawRect(tileRect, edgePaint);
        }
      }

      // draw count box
      final countBoxSize = size.height - size.width - patternOrigin;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset(patternOrigin, size.width)
            & Size.square(countBoxSize),
          Radius.circular(20 * (size.height / CardWidget.CARD_HEIGHT))
        ),
        Paint()..color = Colors.black
      );
      final textStyle = TextStyle(
        fontFamily: "Splatfont1",
        color: Colors.white,
        fontSize: 72 * (size.height / CardWidget.CARD_HEIGHT),
        letterSpacing: 18 * (size.height / CardWidget.CARD_HEIGHT),
        height: 1,
      );
      final textSpan = TextSpan(
        text: card.count.toString(),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textSize = textPainter.size;
      textPainter.paint(
        canvas,
        Offset(patternOrigin * 1.55, size.width + (patternOrigin/1.25)) + Offset(
          (countBoxSize - textSize.width) / 2,
          (countBoxSize - textSize.height) / 2,
        )
      );

      // draw special points
      final specialPointOrigin = Offset(countBoxSize + patternOrigin*1.5, size.width * 1.05);
      final specialPointSize = Size.square(countBoxSize * 0.275);
      bodyPaint.color = traits.specialColour;
      edgePaint.color = Palette.cardEdge;
      for (var i = 0; i < card.special; i++) {
        final specialPoint = (specialPointOrigin + Offset(countBoxSize * 0.3 * (i % 5), countBoxSize * 0.375 * (i ~/ 5))) & specialPointSize;
        canvas.drawRect(specialPoint, bodyPaint);
        canvas.drawRect(specialPoint, edgePaint);
      }
    } else {
      // landscape layout
      // draw card pattern
      final patternOrigin = size.height * (1/18);
      final tileSize = size.height * (1/9);
      edgePaint.color = Palette.cardTileEdge;
      for (var y = 0; y < card.pattern.length; y++) {
        for (var x = 0; x < card.pattern[0].length; x++) {
          final state = card.pattern[y][x];

          bodyPaint.color = state == TileState.unfilled ? Palette.cardTileUnfilled
              : state == TileState.yellow ? traits.normalColour
              : state == TileState.yellowSpecial ? traits.specialColour
              : Colors.red;
          final tileRect = Offset(patternOrigin + (x * tileSize), patternOrigin + (y * tileSize)) & Size.square(tileSize);
          canvas.drawRect(tileRect, bodyPaint);
          canvas.drawRect(tileRect, edgePaint);
        }
      }

      // draw count box
      final countBoxSize = size.width - size.height - patternOrigin;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Offset(size.height, size.height - countBoxSize - patternOrigin)
              & Size.square(countBoxSize),
              Radius.circular(20 * (size.height / CardWidget.CARD_HEIGHT))
          ),
          Paint()..color = Colors.black
      );
      final textStyle = TextStyle(
        fontFamily: "Splatfont1",
        color: Colors.white,
        fontSize: 72 * (size.width / CardWidget.CARD_HEIGHT),
          letterSpacing: 18 * (size.width / CardWidget.CARD_HEIGHT),
        height: 1,
      );
      final textSpan = TextSpan(
        text: card.count.toString(),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textSize = textPainter.size;
      textPainter.paint(
        canvas,
        Offset(size.height + (patternOrigin * 0.525), size.height - countBoxSize - (patternOrigin * 0.225)) + Offset(
          (countBoxSize - textSize.width) / 2,
          (countBoxSize - textSize.height) / 2,
        )
      );

      // draw special points

      final specialPointOrigin = Offset(size.height + (countBoxSize * (0.5 - 0.45)), (patternOrigin*2));
      final specialPointSize = Size.square(countBoxSize * 0.4);
      bodyPaint.color = traits.specialColour;
      edgePaint.color = Palette.cardEdge;
      for (var i = 0; i < card.special; i++) {
        final specialPoint = (specialPointOrigin + Offset(countBoxSize * 0.45 * (i % 2), countBoxSize * 0.45 * (i ~/ 2))) & specialPointSize;
        canvas.drawRect(specialPoint, bodyPaint);
        canvas.drawRect(specialPoint, edgePaint);
      }
    }
    final overlayColor = this.overlayColor;
    if (overlayColor != null && overlayColor.opacity != 0.0) {
      canvas.drawColor(overlayColor, BlendMode.srcATop);
    }
  }

  @override
  bool shouldRepaint(CardPainter other) {
    return traits != other.traits
      || card != other.card
      || cardImage != other.cardImage
      || background != other.background
      || overlayColor != other.overlayColor;
  }
}

class HandCardWidget extends StatefulWidget {
  final TableturfCardData card;
  final Color? background;
  final Color? overlayColor;
  const HandCardWidget({
    super.key,
    required this.card,
    this.background,
    this.overlayColor,
  });

  @override
  State<HandCardWidget> createState() => _HandCardWidgetState();
}

class _HandCardWidgetState extends State<HandCardWidget> {
  late AssetImage _assetImage;
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assetImage = AssetImage(widget.card.designSprite);
    // We call _getImage here because createLocalImageConfiguration() needs to
    // be called again if the dependencies changed, in case the changes relate
    // to the DefaultAssetBundle, MediaQuery, etc, which that method uses.
    _getImage();
  }

  @override
  void didUpdateWidget(HandCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.card != oldWidget.card) {
      _assetImage = AssetImage(widget.card.designSprite);
      _getImage();
    }
  }

  void _getImage() {
    final ImageStream? oldImageStream = _imageStream;
    _imageStream = _assetImage.resolve(createLocalImageConfiguration(context));
    if (_imageStream!.key != oldImageStream?.key) {
      // If the keys are the same, then we got the same image back, and so we don't
      // need to update the listeners. If the key changed, though, we must make sure
      // to switch our listeners to the new image stream.
      final ImageStreamListener listener = ImageStreamListener(_updateImage);
      oldImageStream?.removeListener(listener);
      _imageStream!.addListener(listener);
    }
  }

  void _updateImage(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      // Trigger a build whenever the image changes.
      _imageInfo?.dispose();
      _imageInfo = imageInfo;
    });
  }

  @override
  void dispose() {
    _imageStream?.removeListener(ImageStreamListener(_updateImage));
    _imageInfo?.dispose();
    _imageInfo = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        painter: CardPainter(
          card: widget.card,
          cardImage: _imageInfo?.image,
          traits: const YellowTraits(),
          background: widget.background ?? Palette.cardBackgroundSelectable,
          overlayColor: widget.overlayColor,
        ),
        child: LayoutBuilder(
          builder: (_, constraints) {
            final isPortrait = constraints.maxWidth <= constraints.maxHeight;
            return AspectRatio(aspectRatio: isPortrait ? CardWidget.CARD_RATIO : 1/CardWidget.CARD_RATIO);
          }
        ),
        isComplex: true,
      ),
    );
  }
}


class CardPatternWidget extends StatelessWidget {
  static const EDGE_WIDTH = CardPatternPainter.EDGE_WIDTH;
  final List<List<TileState>> pattern;
  final PlayerTraits traits;

  const CardPatternWidget(this.pattern, this.traits, {super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileStep = min(
          constraints.maxHeight / pattern.length,
          constraints.maxWidth / pattern[0].length,
        );
        return CustomPaint(
          painter: CardPatternPainter(pattern, traits, tileStep),
          child: SizedBox(
            height: pattern.length * tileStep + CardPatternPainter.EDGE_WIDTH,
            width: pattern[0].length * tileStep + CardPatternPainter.EDGE_WIDTH,
          ),
          isComplex: true,
        );
      }
    );
  }
}

class CardWidget extends StatefulWidget {
  static const double CARD_HEIGHT = 472;
  static const double CARD_WIDTH = 339;
  static const double CARD_RATIO = CARD_WIDTH / CARD_HEIGHT;
  static const double CORNER_RADIUS = 25;
  final ValueNotifier<TableturfCard?> cardNotifier;
  final TableturfBattle battle;

  const CardWidget({
    super.key,
    required this.cardNotifier,
    required this.battle,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _transitionController;
  late Animation<double> transitionOutShrink, transitionOutFade, transitionInMove, transitionInFade;
  late TableturfCard? _prevCard;
  Widget _prevWidget = Container();

  @override
  void initState() {
    _transitionController = AnimationController(
        duration: const Duration(milliseconds: 125),
        vsync: this
    );
    _transitionController.addStatusListener((status) {setState(() {});});
    _transitionController.value = widget.cardNotifier.value == null ? 0.0 : 1.0;
    transitionOutShrink = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(_transitionController);
    transitionOutFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_transitionController);
    transitionInFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_transitionController);
    transitionInMove = Tween<double>(
      begin: 15,
      end: 0,
    ).animate(_transitionController);

    _prevCard = widget.cardNotifier.value;
    widget.cardNotifier.addListener(onCardChange);
    super.initState();
  }

  void onCardChange() async {
    //print("on card change");
    final newCard = widget.cardNotifier.value;
    _prevWidget = _prevCard == null
        ? Container()
        : _buildCard(_prevCard!);
    try {
      if (_prevCard == null && newCard != null) {
        await _transitionController.forward(from: 0.0).orCancel;
      } else if (_prevCard != null && newCard == null) {
        await _transitionController.reverse(from: 1.0).orCancel;
      } else if (_prevCard != newCard) {
        await _transitionController.reverse(from: 1.0).orCancel;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await _transitionController.forward(from: 0.0).orCancel;
      }
    } catch (err) {}
    _prevCard = newCard;
  }

  @override
  void dispose() {
    _transitionController.dispose();
    widget.cardNotifier.removeListener(onCardChange);
    super.dispose();
  }

  bool _cardIsSelectable(TableturfCard card) {
    final battle = widget.battle;
    return battle.movePassNotifier.value ? true
      : battle.moveSpecialNotifier.value ? card.isPlayableSpecial : card.isPlayable;
  }

  Widget _buildCard(TableturfCard card) {
    final isSelectable = _cardIsSelectable(card);
    final isSelected = widget.battle.moveCardNotifier.value == card;
    final Color background = (
        isSelected
            ? Palette.cardBackgroundSelected
            : Palette.cardBackgroundSelectable
    );
    final cardWidget = HandCardWidget(
      card: card.data,
      background: background,
      overlayColor: isSelectable
        ? Colors.transparent
        : const Color.fromRGBO(0, 0, 0, 0.4),
    );

    const animationDuration = Duration(milliseconds: 140);
    const animationCurve = Curves.easeOut;
    return RepaintBoundary(
      child: AnimatedScale(
        duration: animationDuration,
        curve: animationCurve,
        scale: isSelected ? 1.06 : 1.0,
        child: cardWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moveCardNotifier = widget.battle.moveCardNotifier;
    var reactiveCard = GestureDetector(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          widget.cardNotifier,
          widget.battle.playerControlLock,
          widget.battle.moveSpecialNotifier,
          widget.battle.movePassNotifier,
          moveCardNotifier,
        ]),
        builder: (_, __) {
          return _buildCard(widget.cardNotifier.value!);
        }
      ),
      onTapDown: (details) {
        final card = widget.cardNotifier.value!;
        final battle = widget.battle;
        if (!battle.playerControlLock.value) {
          return;
        }
        if (moveCardNotifier.value != card) {
          final audioController = AudioController();
          if (!_cardIsSelectable(card)) {
            return;
          }
          if (battle.moveSpecialNotifier.value) {
            audioController.playSfx(SfxType.selectCardNormal);
          } else {
            audioController.playSfx(SfxType.selectCardNormal);
          }
          moveCardNotifier.value = card;
        }
        if (details.kind == ui.PointerDeviceKind.touch
            && battle.moveLocationNotifier.value == null
            && !battle.movePassNotifier.value) {
          battle.moveLocationNotifier.value = Coords(
              battle.board[0].length ~/ 2,
              battle.board.length ~/ 2
          );
        }
      }
    );
    switch (_transitionController.status) {
      case AnimationStatus.dismissed:
        return Container();
      case AnimationStatus.completed:
        return reactiveCard;
      case AnimationStatus.forward:
        return AnimatedBuilder(
          animation: _transitionController,
          child: reactiveCard,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, transitionInMove.value),
            child: Opacity(
              opacity: transitionInFade.value,
              child: reactiveCard,
            )
          )
        );
      case AnimationStatus.reverse:
        return AnimatedBuilder(
          animation: _transitionController,
          child: _prevWidget,
          builder: (_, child) => Opacity(
            opacity: transitionOutFade.value,
            child: Transform.scale(
              scale: transitionOutShrink.value,
              child: child,
            )
          )
        );
    }
  }
}