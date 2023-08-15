import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/audio/audio_controller.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';
import 'package:tableturf_mobile/src/components/card_selection.dart';
import 'package:tableturf_mobile/src/components/card_widget.dart';
import 'package:tableturf_mobile/src/components/cash_counter.dart';
import 'package:tableturf_mobile/src/game_internals/card.dart';
import 'package:tableturf_mobile/src/player_progress/player_progress.dart';
import 'package:tableturf_mobile/src/shop/shop_buy_prompt.dart';
import 'package:tableturf_mobile/src/style/constants.dart';

import '../components/flip_card.dart';
import '../components/selection_button.dart';

typedef CardPackEntry = ({TableturfCardData card, bool isDupe});

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final _popupBackgroundController;

  @override
  void initState() {
    super.initState();
    _popupBackgroundController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _popupBackgroundController.dispose();
    super.dispose();
  }

  Future<void> _runCardPack() async {
    final playerProgress = PlayerProgress();
    final Completer<void> completer = Completer();
    final Completer<void> animCompleter = Completer();
    final commonCards = officialCards
        .where((c) => c.rarity == "common")
        .toList();
    final rareCards = officialCards
        .where((c) => c.rarity == "rare")
        .toList();
    final freshCards = officialCards
        .where((c) => c.rarity == "fresh")
        .toList();
    const freshProbability = 0.02;
    const rareProbability = 0.1;
    final List<CardPackEntry> selectedCards = [];
    final rng = Random();
    for (var i = 0; i < 5; i++) {
      final rand = rng.nextDouble();
      if (rand < freshProbability) {
        final index = rng.nextInt(freshCards.length);
        final card = freshCards.removeAt(index);
        final isDupe = playerProgress.unlockedCards.contains(card.ident);
        selectedCards.add((card: card, isDupe: isDupe));
      } else if (rand < freshProbability + rareProbability) {
        final index = rng.nextInt(rareCards.length);
        final card = rareCards.removeAt(index);
        final isDupe = playerProgress.unlockedCards.contains(card.ident);
        selectedCards.add((card: card, isDupe: isDupe));
      } else {
        final index = rng.nextInt(commonCards.length);
        final card = commonCards.removeAt(index);
        final isDupe = playerProgress.unlockedCards.contains(card.ident);
        selectedCards.add((card: card, isDupe: isDupe));
      }
    }
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) {
        return CardPackDisplay(
          cards: selectedCards,
          completer: completer,
          animCompleter: animCompleter,
        );
      }
    ));
    await animCompleter.future;
    int cashTotal = 0;
    for (final entry in selectedCards) {
      if (entry.isDupe) {
        cashTotal += entry.card.cashValue;
      } else {
        playerProgress.unlockCard(entry.card.ident);
      }
    }
    playerProgress.cash.value += cashTotal;
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final cash = PlayerProgress().cash;
    final screen = Stack(
      fit: StackFit.passthrough,
      children: [
        Padding(
          padding: mediaQuery.padding,
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: FractionallySizedBox(
                          heightFactor: 0.5,
                          widthFactor: 0.9,
                          child: FittedBox(
                            child: ValueListenableBuilder(
                              valueListenable: cash,
                              builder: (_, cash, __) => CashCounter(
                                cash: cash,
                                designRatio: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Text(
                          "Hotlantis",
                          style: TextStyle(
                            fontFamily: "Splatfont1",
                            shadows: const [],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 4),
                  ],
                ),
              ),
              divider,
              Expanded(
                flex: 9,
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Opacity(
                        opacity: 0.25,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Transform.scale(
                            scale: 0.75,
                            alignment: Alignment.bottomLeft,
                            child: Row(
                              children: [
                                Image.asset("assets/images/character_icons/harmony.png"),
                                Text("the fuck you want", style: TextStyle(shadows: []))
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: CardWidget.CARD_RATIO,
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      children: [
                        ShopItemThumbnail(
                          cost: 1000,
                          name: "Card Pack",
                          backgroundController: _popupBackgroundController,
                          child: FittedBox(
                            child: Transform.scale(
                              scale: 0.6,
                              child: Transform.rotate(
                                angle: 0.05 * pi,
                                child: Image.asset(
                                  "assets/images/card_pack_common.png",
                                ),
                              ),
                            ),
                          ),
                          onPurchase: () async {
                            await _runCardPack();
                          },
                        ),
                        ShopItemThumbnail(
                          cost: 2000,
                          backgroundController: _popupBackgroundController,
                          name: "Custom Card",
                          child: Center(
                            child: FittedBox(
                              child: Text(
                                "dont buy this",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              divider,
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Spacer(flex: 1),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: SelectionButton(
                          child: Text("Back"),
                          designRatio: 0.5,
                          onPressEnd: () async {
                            Navigator.of(context).pop();
                            return Future<void>.delayed(
                                const Duration(milliseconds: 100));
                          },
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
        IgnorePointer(
          child: FadeTransition(
            opacity: _popupBackgroundController.drive(
              Tween(begin: 0.0, end: 1.0),
            ),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.black38,
                    Colors.black54,
                  ],
                  radius: 1.3,
                ),
              ),
              child: SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.pink[50],
        body: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: "Splatfont2",
            color: Colors.black,
            fontSize: 18,
            letterSpacing: 0.6,
            shadows: [
              Shadow(
                color: Color.fromRGBO(256, 256, 256, 0.4),
                offset: Offset(1, 1),
              ),
            ],
          ),
          child: screen,
        ),
      ),
    );
  }
}

class CardPackDisplay extends StatefulWidget {
  final List<CardPackEntry> cards;
  final Completer<void> completer, animCompleter;

  const CardPackDisplay({
    super.key,
    required this.cards,
    required this.completer,
    required this.animCompleter,
  });

  @override
  State<CardPackDisplay> createState() => _CardPackDisplayState();
}

class _CardPackDisplayState extends State<CardPackDisplay>
    with TickerProviderStateMixin {
  late final AnimationController transitionController;
  late final Animation<double> popupOpacity, popupScale, popupRotate;
  late final Animation<Offset> popupOffset;

  late final AnimationController cardController;
  late final Animation<double> cardRotate, cardFlip;

  late final AnimationController cashController;
  late final Animation<double> cashOpacity, cashScale, cardShrink, cardFade;

  late final AnimationController cashArrowController;
  late final Animation<double> cashArrowOpacity;
  late final Animation<Offset> cashArrowOffset;

  @override
  void initState() {
    super.initState();
    transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    popupOpacity = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0),
          weight: 50,
      ),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0),
          weight: 50,
      ),
    ]).animate(transitionController);
    popupScale = TweenSequence([
      TweenSequenceItem(
          tween: ConstantTween(1.0),
          weight: 50,
      ),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.9),
          weight: 50,
      ),
    ]).animate(transitionController);
    popupOffset = TweenSequence([
      TweenSequenceItem(
          tween: Tween(
            begin: Offset(0.0, 0.15),
            end: Offset(0.0, -0.03),
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 42,
      ),
      TweenSequenceItem(
          tween: Tween(
            begin: Offset(0.0, -0.03),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 8,
      ),
      TweenSequenceItem(
          tween: ConstantTween(Offset.zero),
          weight: 50,
      ),
    ]).animate(transitionController);
    popupRotate = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: -0.015, end: 0.0),
          weight: 50,
      ),
      TweenSequenceItem(
          tween: ConstantTween(0.0),
          weight: 50,
      ),
    ]).animate(transitionController);

    const timeUntilFlip = 900;
    const flipTime = 200;
    cardController = AnimationController(
      duration: const Duration(milliseconds: timeUntilFlip + flipTime),
      vsync: this,
    );
    cardRotate = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.05,
          end: 0.0,
        ).chain(CurveTween(curve: const ElasticOutCurve(2/4))),
        weight: timeUntilFlip.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: flipTime.toDouble(),
      ),
    ]).animate(cardController);
    cardFlip = TweenSequence([
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: timeUntilFlip.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ),
        weight: flipTime.toDouble(),
      ),
    ]).animate(cardController);

    cashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    const cardShrinkAmount = 0.55;
    cardShrink = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: cardShrinkAmount,
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ConstantTween(cardShrinkAmount),
        weight: 50,
      ),
    ]).animate(cashController);
    cardFade = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.7,
        ),
        weight: 50,
      ),
    ]).animate(cashController);
    cashOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ),
        weight: 50,
      ),
    ]).animate(cashController);
    cashScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween(0.7),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.7,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
    ]).animate(cashController);

    cashArrowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    cashArrowController.value = 1.0;
    cashArrowOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 15,
      ),
    ]).animate(cashArrowController);
    cashArrowOffset = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(
          begin: Offset(0, -0.05),
          end: Offset(0, 0.35),
        ),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset(0, 0.35)),
        weight: 45,
      ),
    ]).animate(cashArrowController);

    playAnimation();
  }


  @override
  void dispose() {
    transitionController.dispose();
    cardController.dispose();
    cashController.dispose();
    cashArrowController.dispose();
    super.dispose();
  }

  Future<void> playAnimation() async {
    await Future.delayed(const Duration(milliseconds: 5));
    await Future.wait<void>([
      precacheImage(AssetImage("assets/images/card_sleeves/sleeve_default.png"), context),
      for (final (card: card, isDupe: _) in widget.cards) ...[
        precacheImage(AssetImage("assets/images/card_components/bg_${card.rarity}_lv1.png"), context),
        precacheImage(AssetImage("assets/images/card_components/count_${card.rarity}.png"), context),
        precacheImage(AssetImage(card.designSprite), context),
      ]
    ]);
    transitionController.animateTo(0.5);
    final audioController = AudioController();
    audioController.playSfx(SfxType.cardPackOpen);
    await cardController.forward();
    if (widget.cards.any((e) => e.isDupe)) {
      () async {
        await Future.delayed(const Duration(milliseconds: 300));
        audioController.playSfx(SfxType.cardPackBits);
      }();
      await Future.delayed(const Duration(milliseconds: 150));
      await cashController.forward();
      widget.animCompleter.complete();
      await Future.delayed(const Duration(milliseconds: 200));
      cashArrowController.repeat();
    } else {
      widget.animCompleter.complete();
    }
  }

  Future<void> onExit() async {
    if (!widget.animCompleter.isCompleted) {
      return;
    }
    widget.completer.complete();
    transitionController.duration = const Duration(milliseconds: 280);
    await transitionController.forward();
    Navigator.of(context).pop();
  }

  Widget _buildCard(CardPackEntry entry) {
    Widget cardFront = CardFrontWidget(card: entry.card);
    if (entry.isDupe) {
      cardFront = Stack(
        children: [
          FadeTransition(
            opacity: cardFade,
            child: ScaleTransition(
              scale: cardShrink,
              alignment: Alignment.topCenter,
              child: cardFront,
            )
          ),
          Positioned.fill(
            child: Column(
              children: [
                const Spacer(flex: 20),
                Expanded(
                  flex: 8,
                  child: SlideTransition(
                    position: cashArrowOffset,
                    child: FadeTransition(
                      opacity: cashArrowOpacity,
                      child: Center(
                        child: Transform.scale(
                          scale: 0.75,
                          child: Icon(
                            Icons.arrow_downward,
                            color: Palette.tileYellow,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: FadeTransition(
                    opacity: cashOpacity,
                    child: ScaleTransition(
                      scale: cashScale,
                      child: Center(
                        child: ShopItemPrice(cost: "x ${entry.card.cashValue}"),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return RepaintBoundary(
      child: RotationTransition(
        turns: cardRotate,
        alignment: Alignment(0, -0.75),
        child: FlipTransition(
          skew: cardFlip,
          front: cardFront,
          back: Image.asset(
            "assets/images/card_sleeves/sleeve_default.png",
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final displayBox = FractionallySizedBox(
      heightFactor: isLandscape ? 0.7 : null,
      widthFactor: isLandscape ? null : 0.9,
      child: AspectRatio(
        aspectRatio: 4/3,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const designWidth = 646;
            final designRatio = constraints.maxWidth / designWidth;
            final divider = SizedBox(
              width: 40 * designRatio,
            );
            final cards = Center(
              child: FractionallySizedBox(
                heightFactor: 0.9,
                widthFactor: 0.8,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Center(
                        child: FractionallySizedBox(
                          heightFactor: 0.9,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCard(widget.cards[0]),
                              divider,
                              _buildCard(widget.cards[1]),
                              divider,
                              _buildCard(widget.cards[2]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: FractionallySizedBox(
                          heightFactor: 0.9,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCard(widget.cards[3]),
                              divider,
                              _buildCard(widget.cards[4]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
            return DefaultTextStyle(
              style: TextStyle(
                fontFamily: "Splatfont2",
                color: Colors.white,
                fontSize: 25 * designRatio,
              ),
              child: SlideTransition(
                position: popupOffset,
                child: ScaleTransition(
                  scale: popupScale,
                  child: RotationTransition(
                    turns: popupRotate,
                    child: FadeTransition(
                      opacity: popupOpacity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(60 * designRatio),
                        ),
                        child: cards,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    return WillPopScope(
      onWillPop: () async {
        onExit();
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onExit,
        child: Center(
          child: RepaintBoundary(
            child: displayBox,
          ),
        ),
      ),
    );
  }
}

class ShopItemThumbnail extends StatefulWidget {
  final int cost;
  final String name;
  final Widget child;
  final Future<void> Function()? onPurchase;
  final AnimationController backgroundController;
  const ShopItemThumbnail({
    super.key,
    required this.backgroundController,
    required this.cost,
    required this.name,
    required this.child,
    this.onPurchase,
  });

  @override
  State<ShopItemThumbnail> createState() => _ShopItemThumbnailState();
}

class _ShopItemThumbnailState extends State<ShopItemThumbnail>
    with SingleTickerProviderStateMixin {
  late final pressController = AnimationController(
    duration: const Duration(milliseconds: 50),
    vsync: this,
  );
  late final Animation<double> pressScale;

  @override
  void initState() {
    super.initState();
    const pressScaleDown = 0.9;
    pressScale = pressController.drive(
      Tween(
        begin: 1.0,
        end: pressScaleDown,
      ).chain(CurveTween(curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) async {
        pressController.forward();
      },
      onPointerUp: (_) async {
        final playerProgress = PlayerProgress();
        final cost = this.widget.cost;
        pressController.reverse();
        if (playerProgress.cash.value < cost) {
          return;
        }
        widget.backgroundController.forward();
        final purchased = await showShopBuyPrompt(
          context,
          builder: (context, designRatio) {
            return Stack(
              fit: StackFit.passthrough,
              children: [
                Padding(
                  padding: EdgeInsets.all(30 * designRatio),
                  child: FractionallySizedBox(
                    heightFactor: 0.15,
                    child: ShopItemPrice(cost: cost.toString()),
                  ),
                ),
                Align(
                  alignment: Alignment(0, -1/3),
                  child: FractionallySizedBox(
                    heightFactor: 1/2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Buy a ${widget.name}?",
                          style: TextStyle(
                            fontSize: 30 * designRatio,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
        if (purchased) {
          playerProgress.cash.value -= cost;
          await widget.onPurchase?.call();
        }
        await widget.backgroundController.reverse();
      },
      child: ScaleTransition(
        scale: pressScale,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 3.0,
            ),
            borderRadius: BorderRadius.circular(15.0),
            color: Color.alphaBlend(
              Colors.pink.withOpacity(0.2),
              Colors.grey[700]!,
            ),
          ),
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.fromLTRB(6, 2, 6, 2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              Align(
                alignment: Alignment.topLeft,
                child: FractionallySizedBox(
                  heightFactor: 1/5,
                  child: ShopItemPrice(
                    cost: widget.cost.toString(),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: 1/5,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopItemPrice extends StatelessWidget {
  const ShopItemPrice({
    super.key,
    required this.cost,
  });

  final String cost;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitHeight,
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Image.asset(
              "assets/images/cash.png",
            ),
          ),
          Text(
            cost,
            style: TextStyle(
              color: Colors.white,
              fontFamily: "Splatfont2",
              fontSize: 30,
            ),
          ),
        ],
      ),
    );
  }
}
