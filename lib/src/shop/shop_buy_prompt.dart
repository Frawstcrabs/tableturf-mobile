

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/audio/sounds.dart';
import '../components/selection_button.dart';


typedef DesignRatioBuilder = Widget Function(BuildContext, double);

class _ShopBuyPrompt extends StatefulWidget {
  final DesignRatioBuilder builder;
  final Completer<bool> completer;
  const _ShopBuyPrompt({
    required this.builder,
    required this.completer,
  });

  @override
  State<_ShopBuyPrompt> createState() => _ShopBuyPromptState();
}

class _ShopBuyPromptState extends State<_ShopBuyPrompt>
    with TickerProviderStateMixin {
  late final AnimationController _promptController;
  late final Animation<double> promptFade, promptScale, promptRotate;
  late final Animation<Offset> promptOffset;

  @override
  void initState() {
    super.initState();
    _promptController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
    );
    promptFade = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0),
          weight: 50,
      ),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0),
          weight: 35,
      ),
      TweenSequenceItem(
          tween: ConstantTween(0.0),
          weight: 15,
      ),
    ]).animate(_promptController);
    promptScale = TweenSequence([
      TweenSequenceItem(
          tween: ConstantTween(1.0),
          weight: 50,
      ),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.9),
          weight: 50,
      ),
    ]).animate(_promptController);
    promptOffset = TweenSequence([
      TweenSequenceItem(
          tween: Tween(
            begin: Offset(0.0, -0.15),
            end: Offset(0.0, 0.03),
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 42,
      ),
      TweenSequenceItem(
          tween: Tween(
            begin: Offset(0.0, 0.03),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 8,
      ),
      TweenSequenceItem(
          tween: ConstantTween(Offset.zero),
          weight: 50,
      ),
    ]).animate(_promptController);
    const defaultRotate = -0.0025;
    promptRotate = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: -(defaultRotate * 2), end: defaultRotate),
          weight: 50
      ),
      TweenSequenceItem(
          tween: ConstantTween(defaultRotate),
          weight: 50
      ),
    ]).animate(_promptController);

    onEnter();
  }

  Future<void> onEnter() async {
    await _promptController.animateTo(0.5);
  }

  Future<void> onExit(bool ret) async {
    if (ret) {
      await _promptController.forward();
      widget.completer.complete(ret);
    } else {
      widget.completer.complete(ret);
      await _promptController.forward();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final promptBox = FractionallySizedBox(
      heightFactor: isLandscape ? 0.5 : null,
      widthFactor: isLandscape ? null : 0.8,
      child: AspectRatio(
        aspectRatio: 4/3,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const designWidth = 646;
            final designRatio = constraints.maxWidth / designWidth;
            final content = DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(60 * designRatio),
              ),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Center(
                    child: widget.builder(context, designRatio),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: 1/3,
                      child: Center(
                        child: FractionallySizedBox(
                          heightFactor: 0.7,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(5 * designRatio),
                                  child: Center(
                                    child: SelectionButton(
                                      onPressEnd: () => onExit(true),
                                      designRatio: designRatio,
                                      child: Text("Yeah!"),
                                      sfx: SfxType.menuButtonPress,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(5 * designRatio),
                                  child: Center(
                                    child: SelectionButton(
                                      onPressEnd: () => onExit(false),
                                      designRatio: designRatio,
                                      child: Text("Nah"),
                                      sfx: SfxType.menuButtonPress,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
            return DefaultTextStyle(
              style: TextStyle(
                fontFamily: "Splatfont2",
                color: Colors.white,
                fontSize: 25 * designRatio,
              ),
              child: SlideTransition(
                position: promptOffset,
                child: ScaleTransition(
                  scale: promptScale,
                  child: RotationTransition(
                    turns: promptRotate,
                    child: content,
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
        await onExit(false);
        return false;
      },
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onExit(false),
            child: SizedBox.expand(),
          ),
          FadeTransition(
            opacity: promptFade,
            child: Center(
              child: promptBox,
            ),
          ),
        ],
      ),
    );
  }
}


Future<bool> showShopBuyPrompt(BuildContext context, {
  required DesignRatioBuilder builder,
}) async {
  final Completer<bool> completer = Completer();
  Navigator.of(context).push(PageRouteBuilder<bool>(
    opaque: false,
    pageBuilder: (_, __, ___) {
      return _ShopBuyPrompt(
        builder: builder,
        completer: completer,
      );
    }
  ));
  return completer.future;
}