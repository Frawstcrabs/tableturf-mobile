import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/level_selection/opponents.dart';
import 'package:tableturf_mobile/src/play_session/components/card_selection.dart';
import 'package:tableturf_mobile/src/play_session/components/selection_button.dart';

import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../game_internals/card.dart';
import '../game_internals/tile.dart';
import '../play_session/build_game_session_page.dart';
import '../play_session/components/card_widget.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';


class DeckCardWidget extends StatelessWidget {
  final TableturfCardData? card;
  const DeckCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final card = this.card;
    if (card == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = (constraints.maxWidth / constraints.maxHeight) > 1.0;
          final cardAspectRatio = isLandscape
              ? CardWidget.CARD_HEIGHT / CardWidget.CARD_WIDTH
              : CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT;
          return AspectRatio(
            aspectRatio: cardAspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: palette.cardBackgroundSelectable,
                border: Border.all(
                  width: 1.0,
                  color: palette.cardEdge,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.add_circle_outline,
                  color: const Color.fromRGBO(255, 255, 255, 0.2),
                  size: constraints.maxHeight * (140 / CardWidget.CARD_HEIGHT),
                )
              ),
            )
          );
        }
      );
    }
    final pattern = card.pattern;
    return LayoutBuilder(
        builder: (context, constraints) {
          final cardAspectRatio = CardWidget.CARD_WIDTH / CardWidget.CARD_HEIGHT;
          final countBox = AspectRatio(
              aspectRatio: 1.0,
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(Radius.circular(
                            constraints.maxHeight * (80/CardWidget.CARD_HEIGHT)
                        )),
                      ),
                      child: Center(
                          child: FractionallySizedBox(
                            heightFactor: 0.95,
                            widthFactor: 0.95,
                            child: FittedBox(
                              fit: BoxFit.fitHeight,
                              child: Text(
                                  "${card.count}",
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
            heightFactor: false ? 0.9 : 0.7,
            widthFactor: false ? 0.7 : 0.9,
            child: GridView.count(
                crossAxisCount: false ? 2 : 5,
                padding: EdgeInsets.zero,
                //physics: const NeverScrollableScrollPhysics(),
                children: Iterable.generate(card.special, (_) {
                  return AspectRatio(
                    aspectRatio: 1.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Palette().tileYellowSpecial,
                        border: Border.all(
                          width: CardPatternWidget.EDGE_WIDTH,
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
                    color: palette.cardBackgroundSelectable,
                    border: Border.all(
                      width: 1.0,
                      color: Palette().cardEdge,
                    ),
                  ),
                ),
                Image.asset(
                  card.designSprite,
                  opacity: const AlwaysStoppedAnimation(0.7),
                ),
                Flex(
                  direction: false ? Axis.horizontal : Axis.vertical,
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
                        alignment: false ? Alignment.centerLeft : Alignment.topCenter,
                        child: FractionallySizedBox(
                          heightFactor: false ? 0.8 : 0.9,
                          widthFactor: false ? 0.9 : 0.9,
                          child: Flex(
                            direction: false ? Axis.vertical : Axis.horizontal,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: false ? [
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
              ],
            ),
          );
        }
    );
  }
}



class DeckEditorScreen extends StatefulWidget {
  final String name;
  final List<TableturfCardData?> cards;
  const DeckEditorScreen({
    super.key,
    required this.name,
    this.cards = const [
      null, null, null,
      null, null, null,
      null, null, null,
      null, null, null,
      null, null, null,
    ],
  });

  @override
  State<DeckEditorScreen> createState() => _DeckEditorScreenState();
}

class _DeckEditorScreenState extends State<DeckEditorScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);
    final screen = Column(
      children: [
        Expanded(
          flex: 1,
          child: Center(
            child: Text("Editing ${widget.name}")
          )
        ),
        Expanded(
          flex: 9,
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(10),
            childAspectRatio: CardWidget.CARD_RATIO,
            children: [
              for (final card in widget.cards)
                Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: DeckCardWidget(card: card),
                )
            ]
          )
        )
      ]
    );
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: palette.backgroundDeckEditor,
        body: DefaultTextStyle(
          style: TextStyle(
            fontFamily: "Splatfont2",
            color: Colors.black,
            fontSize: 18,
            letterSpacing: 0.6,
            shadows: [
              Shadow(
                color: const Color.fromRGBO(256, 256, 256, 0.4),
                offset: Offset(1, 1),
              )
            ]
          ),
          child: Padding(
            padding: mediaQuery.padding,
            child: Center(
              child: screen
            ),
          ),
        )
      ),
    );
  }
}
