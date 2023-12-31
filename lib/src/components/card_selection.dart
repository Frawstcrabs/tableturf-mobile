import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';

import '../game_internals/card.dart';
import 'tableturf_battle.dart';
import '../style/constants.dart';

import '../game_internals/battle.dart';
import '../game_internals/move.dart';

import 'card_widget.dart';
import 'flip_card.dart';

class SpinnerWidget extends StatefulWidget {
  final bool loop;
  const SpinnerWidget({super.key, this.loop = true});

  @override
  State<SpinnerWidget> createState() => _SpinnerWidgetState();
}

class _SpinnerWidgetState extends State<SpinnerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1000)
    );
    if (widget.loop)
      _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: RotationTransition(
        turns: _controller,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 50),
          child: FittedBox(
            child: Icon(
              Icons.refresh,
              color: Color.fromRGBO(255, 255, 255, 0.2),
            ),
          ),
        )
      ),
    );
  }
}

class CardFrontWidget extends StatelessWidget {
  final TableturfCardData card;
  final PlayerTraits traits;
  final bool isVisible;

  const CardFrontWidget({
    required this.card,
    this.traits = const YellowTraits(),
    this.isVisible = true,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sizeRatio = constraints.maxHeight/CardWidget.CARD_HEIGHT;

          final countTextStyle = TextStyle(
            fontFamily: "Splatfont1",
            fontSize: 28.0 * sizeRatio,
            letterSpacing: 5.0 * sizeRatio,
            shadows: [],
            color: Colors.white,
          );
          final cardCountText = "\u200b${card.count}";
          final cardName = card.displayName ?? card.name;
          final cardNameLines = "\n".allMatches(cardName).length + 1;

          Widget cardWidget = Stack(
            fit: StackFit.expand,
            children: [
              Image.asset("assets/images/card_components/bg_${card.rarity}_lv1.png"),
              Image.asset(
                card.designSprite,
                color: !isVisible ? Colors.black : null,
                fit: BoxFit.fill,
              ),
              Align(
                alignment: Alignment(0.0, -0.825),
                child: FractionallySizedBox(
                  heightFactor: [0.18, 0.18, 0.205][cardNameLines],
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fontSize = 44.0 * sizeRatio;
                      final textStyle = TextStyle(
                        fontFamily: {
                          "randomiser": "InklingBubble",
                        }[card.rarity] ?? "Splatfont1",
                        fontSize: fontSize,
                        height: [2.0, 2.0, 1.1][cardNameLines],
                        letterSpacing: 0.3,
                        shadows: [],
                        color: {
                          "common": const Color.fromRGBO(96, 58, 255, 1.0),
                        }[card.rarity] ?? Colors.white,
                      );


                      const maxTextWidth = 0.875;
                      final Size textSize = (TextPainter(
                        text: TextSpan(text: cardName, style: textStyle),
                        textScaleFactor: MediaQuery.of(context).textScaleFactor,
                        textDirection: TextDirection.ltr)
                          ..layout()
                      ).size;

                      var strokeText = FractionallySizedBox(
                        widthFactor: maxTextWidth,
                        child: FittedBox(
                          fit: textSize.width <= constraints.maxWidth * maxTextWidth
                              ? BoxFit.fitHeight
                              : BoxFit.fill,
                          child: Stack(
                            children: [
                              Text(
                                  cardName,
                                  textAlign: TextAlign.center,
                                  style: textStyle.copyWith(
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 7.2 * sizeRatio
                                      ..strokeJoin = StrokeJoin.round
                                      ..color = Colors.black,
                                  )
                              ),
                              Text(
                                cardName,
                                textAlign: TextAlign.center,
                                style: textStyle,
                              ),
                            ],
                          )
                        ),
                      );
                      switch (card.rarity) {
                        case "rare":
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [
                                  Color.fromRGBO(254, 210, 0, 1.0),
                                  Color.fromRGBO(255, 251, 207, 1.0),
                                  Color.fromRGBO(223, 170, 13, 1.0),
                                  Color.fromRGBO(255, 252, 209, 1.0),
                                ],
                                stops: [
                                  0.0,
                                  0.2,
                                  0.55,
                                  0.9,
                                ],
                                begin: Alignment(-1.0, 0.15),
                                end: Alignment(1.0, -0.15),
                              ).createShader(bounds);
                            },
                            child: strokeText,
                          );
                        case "fresh":
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              const boundOvershoot = 0.9;
                              return const LinearGradient(
                                colors: [
                                  Color.fromRGBO(255, 147, 221, 1.0),
                                  Color.fromRGBO(254, 245, 153, 1.0),
                                  Color.fromRGBO(198, 59, 142, 1.0),
                                  Color.fromRGBO(131, 122, 211, 1.0),
                                  Color.fromRGBO(28, 253, 194, 1.0),
                                  Color.fromRGBO(255, 149, 219, 1.0),
                                  Color.fromRGBO(255, 239, 159, 1.0),
                                ],
                                stops: [
                                  0.05,
                                  0.22,
                                  0.50,
                                  0.60,
                                  0.75,
                                  0.90,
                                  1.00,
                                ],
                                begin: Alignment(-boundOvershoot, -2.15 * boundOvershoot),
                                end: Alignment(boundOvershoot, 2.15 * boundOvershoot),
                              ).createShader(bounds);
                            },
                            child: strokeText,
                          );
                        default:
                          return strokeText;
                      }
                    }
                  ),
                )
              ),
              Align(
                alignment: Alignment(0.0, 0.95),
                child: FractionallySizedBox(
                  widthFactor: 0.95,
                  heightFactor: 0.3,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    verticalDirection: VerticalDirection.down,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Stack(
                            children: [
                              Center(child: Image.asset("assets/images/card_components/count_${card.rarity}.png")),
                              Center(
                                child: Stack(
                                  children: [
                                    Text(
                                      cardCountText,
                                      textAlign: TextAlign.center,
                                      style: countTextStyle.copyWith(
                                        foreground: Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 3.0 * sizeRatio
                                          ..strokeJoin = StrokeJoin.round
                                          ..color = {
                                            "common": const Color.fromRGBO(60, 16, 153, 1.0),
                                            "rare": const Color.fromRGBO(129, 116, 0, 1.0),
                                            "fresh": const Color.fromRGBO(48, 11, 124, 1.0),
                                          }[card.rarity] ?? Colors.black,
                                      )
                                    ),
                                    Text(
                                      cardCountText,
                                      textAlign: TextAlign.center,
                                      style: countTextStyle
                                    ),
                                  ],
                                )
                              )
                            ]
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: FractionallySizedBox(
                          widthFactor: 0.9,
                          heightFactor: 0.6,
                          child: Center(
                            child: FractionallySizedBox(
                              heightFactor: 0.5,
                              child: GridView.count(
                                crossAxisCount: 5,
                                reverse: true,
                                padding: EdgeInsets.zero,
                                crossAxisSpacing: 3.0 * sizeRatio,
                                mainAxisSpacing: 5.0 * sizeRatio,
                                children: Iterable.generate(card.special, (_) {
                                  return DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: traits.specialColour,
                                      border: Border.all(
                                        width: CardPatternWidget.EDGE_WIDTH,
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(growable: false)
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 8,
                        child: FractionallySizedBox(
                          heightFactor: 0.8,
                          widthFactor: 0.8,
                          child: Transform.rotate(
                            angle: 0.05 * pi,
                            child: CardPatternWidget(card.pattern, traits)
                          ),
                        ),
                      ),
                    ]
                  ),
                )
              ),
            ]
          );
          if (!isVisible) {
            cardWidget = ColorFiltered(
              colorFilter: ColorFilter.mode(
                const Color.fromRGBO(0, 0, 0, 0.4),
                BlendMode.srcATop,
              ),
              child: cardWidget
            );
          }
          return cardWidget;
        }
      ),
    );
  }
}

class CardSelectionWidget extends StatefulWidget {
  final TableturfPlayer player;
  final bool loopAnimation;

  const CardSelectionWidget({
    super.key,
    required this.player,
    required this.loopAnimation,
  });

  @override
  State<CardSelectionWidget> createState() => _CardSelectionWidgetState();
}


class _CardSelectionWidgetState extends State<CardSelectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _confirmController;
  late AnimationController _flipController;
  late Animation<double> confirmMoveIn, confirmMoveOut, confirmFadeIn, confirmFadeOut;
  late Animation<double> cardFlip;
  Widget _prevFront = Container();
  final ValueNotifier<TableturfMove?> moveNotifier = ValueNotifier(null);
  late final StreamSubscription<BattleEvent> battleSubscription;

  @override
  void initState() {
    super.initState();
    battleSubscription = TableturfBattle.listen(context, _onBattleEvent);
    //widget.moveNotifier.addListener(onMoveChange);
    //widget.battle.revealCardsNotifier.addListener(onRevealCardsChange);
    _confirmController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    confirmMoveIn = Tween<double>(
      begin: -0.45,
      end: 0,
    ).animate(
        CurvedAnimation(
          parent: _confirmController,
          curve: Curves.easeInBack.flipped,
        )
    );
    confirmMoveOut = Tween<double>(
      begin: 0.45,
      end: 0,
    ).animate(
        CurvedAnimation(
          parent: _confirmController,
          curve: Curves.linear,
        )
    );
    confirmFadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _confirmController,
        curve: Curves.linear,
      ),
    );
    confirmFadeOut = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _confirmController,
        curve: Interval(
          0.4, 1.0,
          curve: Curves.linear,
        ),
      ),
    );
    cardFlip = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_flipController);
  }

  @override
  void dispose() {
    battleSubscription.cancel();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onBattleEvent(BattleEvent event) async {
    switch (event) {
      case MoveConfirm(:final playerID) when playerID == widget.player.id:
        final fut = _confirmController.forward(from: 0.0);
        setState(() {});
        await fut;
      case TurnStart(:final moves):
        moveNotifier.value = moves[widget.player.id]!;
      case RevealCards():
        await _flipController.forward(from: 0.0);
      case ClearMoves():
        moveNotifier.value = null;
        final fut = _confirmController.reverse(from: 1.0);
        setState(() {});
        await fut;
        _flipController.value = 0.0;
    }
  }

  Widget _buildAwaiting(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cornerRadius = CardWidget.CORNER_RADIUS * (constraints.maxHeight/CardWidget.CARD_HEIGHT);
        return Center(
          child: AspectRatio(
            aspectRatio: CardWidget.CARD_RATIO,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.fromRGBO(32, 32, 32, 0.8),
                border: Border.all(
                  width: 1.0,
                  color: Palette.cardEdge,
                ),
                borderRadius: BorderRadius.circular(cornerRadius),
              ),
              child: Center(child: SpinnerWidget(loop: widget.loopAnimation)),
            ),
          ),
        );
      }
    );
  }

  Widget _buildCardBack(BuildContext context) {
    return Image.asset(widget.player.cardSleeve);
  }

  Widget _buildCardFront(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: moveNotifier,
      builder: (_, TableturfMove? move, __) {
        if (move == null) {
          return _prevFront;
        }
        final newFront = LayoutBuilder(
          builder: (context, constraints) {
            final cornerRadius = CardWidget.CORNER_RADIUS * (constraints.maxHeight/CardWidget.CARD_HEIGHT);
            final textStyle = DefaultTextStyle.of(context).style;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (move.special) DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    boxShadow: [
                      BoxShadow(
                        spreadRadius: 3.0,
                        blurRadius: 3.0,
                        color: move.traits.normalColour,
                      ),
                    ],
                  ),
                ),
                CardFrontWidget(
                  card: move.card.data,
                  traits: move.traits,
                ),
                if (move.special) DecoratedBox(
                  decoration: BoxDecoration(
                    color: move.traits.normalColour.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(cornerRadius),
                  ),
                ),
                if (move.pass) DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(96, 96, 96, 0.5),
                    borderRadius: BorderRadius.circular(cornerRadius),
                  ),
                  child: Center(
                    child: Text(
                      "Pass",
                      style: TextStyle(
                        fontSize: min(48.0, 80.0 * (constraints.maxHeight/CardWidget.CARD_HEIGHT)),
                        shadows: textStyle.shadows?.map((s) => s.scale(4 * (constraints.maxHeight/CardWidget.CARD_HEIGHT))).toList()
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
        _prevFront = newFront;
        return newFront;
      }
    );
  }

  Widget _buildCard(BuildContext context) {
    /*
    return FlipTransition(
      skew: _flipController,
      front: _buildCardFront(context),
      back: _buildCardBack(context),
    );
    */
    return AnimatedBuilder(
      animation: _flipController,
      child: _buildCardFront(context),
      builder: (_, child) => FlipCard(
        skew: (1 - _flipController.value),
        front: child!,
        back: _buildCardBack(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxHeight;
      switch (_confirmController.status) {
        case AnimationStatus.dismissed:
          return _buildAwaiting(context);
        case AnimationStatus.completed:
          return Stack(
            children: [
              _buildAwaiting(context),
              _buildCard(context),
            ],
          );
        case AnimationStatus.forward:
          return Stack(
            children: [
              _buildAwaiting(context),
              AnimatedBuilder(
                animation: _confirmController,
                child: _buildCard(context),
                builder: (_, child) => Opacity(
                  opacity: confirmFadeIn.value,
                  child: Transform.translate(
                    offset: Offset(0, height * confirmMoveIn.value),
                    child: child
                  )
                )
              )
            ]
          );
        case AnimationStatus.reverse:
          return Stack(
            children: [
              _buildAwaiting(context),
              AnimatedBuilder(
                animation: _confirmController,
                child: _buildCard(context),
                builder: (_, child) => Opacity(
                  opacity: confirmFadeOut.value,
                  child: Transform.translate(
                    offset: Offset(height * confirmMoveOut.value, 0),
                    child: child
                  )
                )
              )
            ]
          );
      }
    });
  }
}

class CardSelectionConfirmButton extends StatefulWidget {
  final bool loopAnimation;

  const CardSelectionConfirmButton({
    super.key,
    required this.loopAnimation,
  });

  @override
  State<CardSelectionConfirmButton> createState() => _CardSelectionConfirmButtonState();
}

class _CardSelectionConfirmButtonState extends State<CardSelectionConfirmButton> {
  late final TableturfBattleController controller;
  late final StreamSubscription<BattleEvent> battleSubscription;
  final ValueNotifier<bool> moveHasBeenPlayed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    controller = TableturfBattle.getControllerOf(context);
    battleSubscription = TableturfBattle.listen(context, _onBattleEvent);
  }

  @override
  void dispose() {
    battleSubscription.cancel();
    super.dispose();
  }

  Future<void> _onBattleEvent(BattleEvent event) async {
    switch (event) {
      case MoveConfirm(:final playerID) when playerID == controller.player.id:
        moveHasBeenPlayed.value = true;
      case TurnEnd():
        moveHasBeenPlayed.value = false;
    }
  }

  Widget _buildButton(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cornerRadius = CardWidget.CORNER_RADIUS * (constraints.maxHeight/CardWidget.CARD_HEIGHT);
      final textStyle = DefaultTextStyle.of(context).style;
      return Container(
        decoration: BoxDecoration(
          color: Palette.inGameButtonSelected,
          border: Border.all(
            width: 1.0,
            color: Palette.cardEdge,
          ),
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        child: Center(
          child: Text(
            "Confirm",
            style: TextStyle(
              fontSize: min(48.0, 80.0 * (constraints.maxHeight/CardWidget.CARD_HEIGHT)),
              shadows: textStyle.shadows?.map((s) => s.scale(4 * (constraints.maxHeight/CardWidget.CARD_HEIGHT))).toList()
            ),
          )
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectionWidget = CardSelectionWidget(
      player: controller.player,
      loopAnimation: widget.loopAnimation,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        selectionWidget,
        AnimatedBuilder(
          animation: Listenable.merge([
            controller.moveCardNotifier,
            controller.moveIsValidNotifier,
            moveHasBeenPlayed,
          ]),
          builder: (context, child) {
            final card = controller.moveCardNotifier.value?.data;
            final movePlayed = moveHasBeenPlayed.value;
            if (card == null || movePlayed) {
              return Container();
            }
            return CardFrontWidget(
              card: card,
              traits: controller.player.traits,
            );
          }
        ),
        AnimatedBuilder(
          animation: moveHasBeenPlayed,
          child: ValueListenableBuilder(
            valueListenable: controller.moveIsValidNotifier,
            child: GestureDetector(
              onTap: () => controller.confirmMove(),
              child: _buildButton(context),
            ),
            builder: (_, bool valid, button) => AnimatedOpacity(
              opacity: valid ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: button,
            ),
          ),
          builder: (context, child) {
            if (moveHasBeenPlayed.value) {
              return Container();
            }
            return child!;
          }
        ),
      ]
    );
  }
}