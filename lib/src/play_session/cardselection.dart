import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';

import '../game_internals/battle.dart';
import '../game_internals/move.dart';

import 'cardwidget.dart';
import 'flip_card.dart';
import 'textwidget.dart';

class SpeenWidget extends StatefulWidget {
  const SpeenWidget({super.key});

  @override
  State<SpeenWidget> createState() => _SpeenWidgetState();
}

class _SpeenWidgetState extends State<SpeenWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000)
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * pi,
            child: child,
          );
        },
        child: Image.asset(
          "assets/images/loading.png",
          width: 48,
          height: 48,
        )
    );
  }
}

class CardSelectionWidget extends StatefulWidget {
  final ValueNotifier<TableturfMove?> moveNotifier;
  final TableturfBattle battle;
  final Color tileColour, tileSpecialColour;

  const CardSelectionWidget({
    super.key,
    required this.moveNotifier,
    required this.battle,
    required this.tileColour,
    required this.tileSpecialColour,
  });

  @override
  State<CardSelectionWidget> createState() => _CardSelectionWidgetState();
}

class _CardSelectionWidgetState extends State<CardSelectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _confirmController;
  late AnimationController _flipController;
  late Animation<double> confirmMoveIn, confirmMoveOut, confirmFadeIn, confirmFadeOut;
  Widget _prevFront = Container();

  @override
  void initState() {
    super.initState();
    widget.moveNotifier.addListener(onMoveChange);
    widget.battle.revealCardsNotifier.addListener(onRevealCardsChange);
    _confirmController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    confirmMoveIn = Tween<double>(
      begin: -50,
      end: 0,
    ).animate(
        CurvedAnimation(
          parent: _confirmController,
          curve: Curves.easeInBack.flipped,
        )
    );
    confirmMoveOut = Tween<double>(
      begin: 50,
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
  }

  @override
  void dispose() {
    widget.moveNotifier.removeListener(onMoveChange);
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> onMoveChange() async {
    if (widget.moveNotifier.value == null) {
      try {
        final fut = _confirmController.reverse(from: 1.0).orCancel;
        setState(() {});
        await fut;
      } catch (err) {}
      _flipController.value = 0.0;
    } else {
      final fut = _confirmController.forward(from: 0.0);
      setState(() {});
      await fut;
    }
  }

  void onRevealCardsChange() {
    final isRevealed = widget.battle.revealCardsNotifier.value;
    if (isRevealed) {
      _flipController.forward(from: 0.0);
      //setState(() {});
    }
  }

  Widget _buildAwaiting(BuildContext context) {
    final palette = context.watch<Palette>();
    return Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(32, 32, 32, 0.8),
        border: Border.all(
          width: 1.0,
          color: palette.cardEdge,
        ),
      ),
      width: CardWidget.CARD_WIDTH,
      height: CardWidget.CARD_HEIGHT,
      child: Center(child: SpeenWidget()),
    );
  }

  Widget _buildCardBack(BuildContext context) {
    final palette = context.watch<Palette>();
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackgroundSelected,
        border: Border.all(
          width: 1.0,
          color: palette.cardEdge,
        ),
      ),
      width: CardWidget.CARD_WIDTH,
      height: CardWidget.CARD_HEIGHT,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: buildTextWidget("Selected"),
        ),
      ),
    );
  }

  Widget _buildCardFront(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.moveNotifier,
        builder: (_, TableturfMove? move, __) {
          final palette = context.watch<Palette>();
          if (move == null) {
            return _prevFront;
          }
          final background = !move.special
              ? palette.cardBackgroundSelected
              : Colors.red; //Color.fromRGBO(229, 229, 57, 1);
          final card = move.card;
          var cardFront = Container(
              decoration: BoxDecoration(
                color: background,
                border: Border.all(
                  width: 1.0,
                  color: palette.cardEdge,
                ),
              ),
              width: CardWidget.CARD_WIDTH,
              height: CardWidget.CARD_HEIGHT,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CardPatternWidget(card.pattern, move.traits),
                  Container(
                    margin: EdgeInsets.only(left: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: Stack(
                            children: [
                              Container(
                                  height: 24,
                                  width: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.all(Radius.circular(4)),
                                  )
                              ),
                              SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Center(
                                      child: Text(
                                          card.count.toString(),
                                          style: TextStyle(
                                              fontFamily: "Splatfont1",
                                              color: Colors.white,
                                              //fontStyle: FontStyle.italic,
                                              fontSize: 12,
                                              letterSpacing: 3.5
                                          )
                                      )
                                  )
                              )
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 3),
                          child: Row(
                              children: Iterable.generate(card.special, (_) {
                                return Container(
                                  margin: EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: move.traits.specialColour,
                                    border: Border.all(
                                      width: CardPatternWidget.TILE_EDGE,
                                      color: Colors.black,
                                    ),
                                  ),
                                  width: CardPatternWidget.TILE_SIZE,
                                  height: CardPatternWidget.TILE_SIZE,
                                );
                              }).toList(growable: false)
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              )
          );
          late final newFront;
          if (move.pass) {
            newFront = Stack(
                children: [
                  cardFront,
                  Container(
                      height: CardWidget.CARD_HEIGHT,
                      width: CardWidget.CARD_WIDTH,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(0, 0, 0, 0.4),
                      ),
                      child: Center(
                          child: buildTextWidget("Pass")
                      )
                  )
                ]
            );
          } else {
            newFront = cardFront;
          }
          _prevFront = newFront;
          return newFront;
        }
    );
  }

  Widget _buildCard(BuildContext context) {
    final front = _buildCardFront(context);
    final back = _buildCardBack(context);
    return AnimatedBuilder(
        animation: _flipController,
        builder: (_, __) => FlipCard(
          skew: (1 - _flipController.value),
          front: front,
          back: back,
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_confirmController.status) {
      case AnimationStatus.dismissed:
        return _buildAwaiting(context);
      case AnimationStatus.completed:
        return _buildCard(context);
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
                          offset: Offset(0, confirmMoveIn.value),
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
                          offset: Offset(confirmMoveOut.value, 0),
                          child: child
                      )
                  )
              )
            ]
        );
    }
  }
}

class CardSelectionConfirmButton extends StatefulWidget {
  final TableturfBattle battle;

  const CardSelectionConfirmButton({
    super.key,
    required this.battle,
  });

  @override
  State<CardSelectionConfirmButton> createState() => _CardSelectionConfirmButtonState();
}

class _CardSelectionConfirmButtonState extends State<CardSelectionConfirmButton> {
  bool active = true;

  @override
  void initState() {
    super.initState();
    widget.battle.yellowMoveNotifier.addListener(onMoveChange);
  }

  @override
  void dispose() {
    widget.battle.yellowMoveNotifier.removeListener(onMoveChange);
    super.dispose();
  }

  void onMoveChange() {
    setState(() {
      active = widget.battle.yellowMoveNotifier.value == null;
    });
  }

  void _confirmMove() {
    widget.battle.confirmMove();
  }

  Widget _buildButton(BuildContext context) {
    final palette = context.watch<Palette>();
    return Container(
      decoration: BoxDecoration(
        color: palette.buttonSelected,
        border: Border.all(
          width: 1.0,
          color: palette.cardEdge,
        ),
      ),
      width: CardWidget.CARD_WIDTH,
      height: CardWidget.CARD_HEIGHT,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: buildTextWidget("Confirm"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final selectionWidget = CardSelectionWidget(
      battle: widget.battle,
      moveNotifier: widget.battle.yellowMoveNotifier,
      tileColour: palette.tileYellow,
      tileSpecialColour: palette.tileYellowSpecial,
    );
    return Stack(
        children: [
          selectionWidget,
          !active ? Container() : ValueListenableBuilder(
              valueListenable: widget.battle.moveIsValidNotifier,
              child: GestureDetector(
                onTap: _confirmMove,
                child: _buildButton(context),
              ),
              builder: (_, bool highlight, button) => AnimatedOpacity(
                opacity: highlight ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: button,
              )
          )
        ]
    );
  }
}