import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';

import '../game_internals/battle.dart';
import '../game_internals/player.dart';
import '../game_internals/card.dart';
import '../game_internals/tile.dart';

class CardPatternWidget extends StatelessWidget {
  static const TILE_SIZE = 8.0;
  static const TILE_EDGE = 0.5;

  final List<List<TileState>> pattern;
  final PlayerTraits traits;

  const CardPatternWidget(this.pattern, this.traits, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final tileStep = TILE_SIZE - TILE_EDGE;

    return SizedBox(
      height: pattern.length * tileStep + TILE_EDGE,
      width: pattern[0].length * tileStep + TILE_EDGE,
      child: Stack(
          children: pattern.asMap().entries.expand((entry) {
            int y = entry.key;
            var row = entry.value;
            return row.asMap().entries.map((entry) {
              int x = entry.key;
              var tile = entry.value;
              return Positioned(
                  top: y * tileStep,
                  left: x * tileStep,
                  child: Container(
                    decoration: BoxDecoration(
                      color: tile == TileState.Unfilled ? palette.cardTileUnfilled
                          : tile == TileState.Yellow ? traits.normalColour
                          : tile == TileState.YellowSpecial ? traits.specialColour
                          : Colors.red,
                      border: Border.all(
                        width: TILE_EDGE,
                        color: palette.cardTileEdge,
                      ),
                    ),
                    width: TILE_SIZE,
                    height: TILE_SIZE,
                  )
              );
            }).toList(growable: false);
          }).toList(growable: false)
      ),
    );
  }
}

class CardWidget extends StatefulWidget {
  static final double CARD_HEIGHT = 110;
  static final double CARD_WIDTH = 80;
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
        : widget.battle.moveCardNotifier.value == _prevCard
        ? _buildCard(_prevCard!, Palette().cardBackgroundSelected)
        : _buildCard(_prevCard!, Palette().cardBackground);
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

  Widget _buildCard(TableturfCard card, Color background) {
    final pattern = card.pattern;

    return Container(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            width: 1.0,
            color: Palette().cardEdge,
          ),
        ),
        width: CardWidget.CARD_WIDTH,
        height: CardWidget.CARD_HEIGHT,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CardPatternWidget(pattern, const YellowTraits()),
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
                              color: Palette().tileYellowSpecial,
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
  }

  Widget _buildAwaiting(BuildContext context) {
    return Container(
      width: CardWidget.CARD_WIDTH,
      height: CardWidget.CARD_HEIGHT,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final moveCardNotifier = widget.battle.moveCardNotifier;
    var reactiveCard = ValueListenableBuilder(
      valueListenable: widget.cardNotifier,
      builder: (_, TableturfCard? card, __) => AnimatedBuilder(
          animation: moveCardNotifier,
          builder: (_, __) {
            return GestureDetector(
                child: moveCardNotifier.value != null && moveCardNotifier.value == card
                    ? _buildCard(card!, palette.cardBackgroundSelected)
                    : _buildCard(card!, palette.cardBackground),
                onTapDown: (details) {
                  if (widget.battle.yellowMoveNotifier.value != null) {
                    return;
                  }
                  moveCardNotifier.value = card;
                }
            );
          }
      )
    );
    switch (_transitionController.status) {
      case AnimationStatus.dismissed:
        return _buildAwaiting(context);
      case AnimationStatus.completed:
        return reactiveCard;
      case AnimationStatus.forward:
        return Stack(
          children: [
            _buildAwaiting(context),
            AnimatedBuilder(
              animation: _transitionController,
              child: reactiveCard,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, transitionInMove.value),
                child: Opacity(
                  opacity: transitionInFade.value,
                  child: reactiveCard,
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
              animation: _transitionController,
              child: _prevWidget,
              builder: (_, child) => Opacity(
                opacity: transitionOutFade.value,
                child: Transform.scale(
                  scale: transitionOutShrink.value,
                  child: child,
                )
              )
            ),
          ]
        );
    }
  }
}