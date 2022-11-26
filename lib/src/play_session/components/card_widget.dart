import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';

import '../../style/palette.dart';

import '../../game_internals/battle.dart';
import '../../game_internals/player.dart';
import '../../game_internals/card.dart';
import '../../game_internals/tile.dart';

import 'build_board_widget.dart' show getTileSize;

class CardPatternWidget extends StatelessWidget {
  static const TILE_EDGE = 0.5;

  final List<List<TileState>> pattern;
  final PlayerTraits traits;

  const CardPatternWidget(this.pattern, this.traits, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileStep = min(
          getTileSize(constraints.maxHeight, pattern.length, TILE_EDGE),
          getTileSize(constraints.maxWidth, pattern[0].length, TILE_EDGE),
        ) - TILE_EDGE;
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
                      color: tile == TileState.unfilled ? palette.cardTileUnfilled
                          : tile == TileState.yellow ? traits.normalColour
                          : tile == TileState.yellowSpecial ? traits.specialColour
                          : Colors.red,
                      border: Border.all(
                        width: TILE_EDGE,
                        color: palette.cardTileEdge,
                      ),
                    ),
                    width: tileStep + TILE_EDGE,
                    height: tileStep + TILE_EDGE,
                  )
                );
              }).toList(growable: false);
            }).toList(growable: false)
          ),
        );
      }
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
        : _buildCard(_prevCard!, Palette());
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

  Widget _buildCard(TableturfCard card, Palette palette) {
    final pattern = card.pattern;
    final moveCardNotifier = widget.battle.moveCardNotifier;

    final isSelectable = _cardIsSelectable(card);
    final isSelected = moveCardNotifier.value != null && moveCardNotifier.value == card;

    final Color background = (
        isSelected
        ? palette.cardBackgroundSelected
        : palette.cardBackgroundSelectable
    );
    final cardWidget = LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = (constraints.maxWidth / constraints.maxHeight) > 1.0;
        final cardAspectRatio = isLandscape
            ? CardWidget.CARD_HEIGHT / CardWidget.CARD_WIDTH
            : CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT;

        final countBox = AspectRatio(
            aspectRatio: 1.0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(
                      constraints.maxHeight * (20/CardWidget.CARD_HEIGHT)
                    )),
                  ),
                  child: Center(
                    child: FractionallySizedBox(
                      heightFactor: 0.95,
                      widthFactor: 0.95,
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: Text(
                            card.count.toString(),
                            style: TextStyle(
                                fontFamily: "Splatfont1",
                                color: Colors.white,
                                //fontStyle: FontStyle.italic,
                                fontSize: 12,
                                letterSpacing: 3.5
                            )
                        ),
                      ),
                    )
                  ),
                );
              }
            )
        );
        final specialCountGrid = FractionallySizedBox(
          heightFactor: isLandscape ? 0.9 : 0.7,
          widthFactor: isLandscape ? 0.7 : 0.9,
          child: GridView.count(
            crossAxisCount: isLandscape ? 2 : 5,
            padding: EdgeInsets.zero,
            //physics: const NeverScrollableScrollPhysics(),
            children: Iterable.generate(card.special, (_) {
              return AspectRatio(
                aspectRatio: 1.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Palette().tileYellowSpecial,
                    border: Border.all(
                      width: CardPatternWidget.TILE_EDGE,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(growable: false)
          ),
        );
        return AspectRatio(
          aspectRatio: cardAspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(
                    width: 1.0,
                    color: Palette().cardEdge,
                  ),
                ),
                child: Flex(
                  direction: isLandscape ? Axis.horizontal : Axis.vertical,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: Center(
                        child: FractionallySizedBox(
                          heightFactor: 0.9,
                          widthFactor: 0.9,
                          child: CardPatternWidget(pattern, const YellowTraits())
                        )
                      )
                    ),
                    Expanded(
                      child: Align(
                        alignment: isLandscape ? Alignment.centerLeft : Alignment.topCenter,
                        child: FractionallySizedBox(
                          heightFactor: isLandscape ? 0.8 : 0.9,
                          widthFactor: isLandscape ? 0.9 : 0.9,
                          child: Flex(
                            direction: isLandscape ? Axis.vertical : Axis.horizontal,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: isLandscape ? [
                              Expanded(
                                child: Center(
                                  child: specialCountGrid,
                                ),
                              ),
                              countBox,
                            ] : [
                              countBox,
                              Expanded(
                                child: Center(
                                  child: specialCountGrid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSelectable) DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 0, 0, 0.4),
                ),
              ),
            ],
          ),
        );
      }
    );

    const animationDuration = Duration(milliseconds: 140);
    const animationCurve = Curves.easeOut;
    //const Color.fromRGBO(0, 0, 0, 0.4)
    return AnimatedScale(
      duration: animationDuration,
      curve: animationCurve,
      scale: isSelected ? 1.06 : 1.0,
      child: cardWidget,
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
    var reactiveCard = AnimatedBuilder(
      animation: Listenable.merge([
        widget.cardNotifier,
        widget.battle.playerControlLock,
        widget.battle.moveSpecialNotifier,
        widget.battle.movePassNotifier,
        moveCardNotifier,
      ]),
      builder: (_, __) {
        final card = widget.cardNotifier.value!;
        return GestureDetector(
          child: _buildCard(card, palette),
          onTapDown: (details) {
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
            if (details.kind == PointerDeviceKind.touch
                && battle.moveLocationNotifier.value == null
                && !battle.movePassNotifier.value) {
              battle.moveLocationNotifier.value = Coords(
                  battle.board[0].length ~/ 2,
                  battle.board.length ~/ 2
              );
            }
          }
        );
      }
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