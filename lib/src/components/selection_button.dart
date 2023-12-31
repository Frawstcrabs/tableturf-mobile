import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/audio/audio_controller.dart';

import '../audio/sounds.dart';

class SelectionButton extends StatefulWidget {
  final Future<bool> Function()? onPressStart;
  final Future<void> Function()? onPressEnd;
  final SfxType? sfx;
  final double designRatio;
  final Widget child;
  const SelectionButton({
    super.key,
    this.onPressStart,
    this.onPressEnd,
    this.designRatio = 1,
    this.sfx,
    required this.child,
  });

  @override
  State<SelectionButton> createState() => SelectionButtonState();
}

class SelectionButtonState extends State<SelectionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _selectController;
  late final Animation<double> selectScale;
  late final Animation<Decoration> selectColor;
  late final Animation<TextStyle> selectTextColor;

  @override
  void initState() {
    super.initState();

    _selectController = AnimationController(
        duration: const Duration(milliseconds: 125), vsync: this);
    const selectDownscale = 0.85;
    selectScale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: selectDownscale)
              .chain(CurveTween(curve: Curves.decelerate)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: selectDownscale, end: 1.05)
              .chain(CurveTween(curve: Curves.decelerate.flipped)),
          weight: 50),
    ]).animate(_selectController);
    selectColor = _selectController.drive(
      DecorationTween(
        begin: BoxDecoration(
          color: const Color.fromRGBO(71, 16, 175, 1.0),
          borderRadius: BorderRadius.circular(20 * widget.designRatio),
          border: Border.all(
            color: Colors.black,
            width: 1.0 * widget.designRatio,
          ),
        ),
        end: BoxDecoration(
          color: const Color.fromRGBO(167, 231, 9, 1.0),
          borderRadius: BorderRadius.circular(20 * widget.designRatio),
          border: Border.all(
            color: Colors.black,
            width: 1.0 * widget.designRatio,
          ),
        ),
      ),
    );
    selectTextColor = _selectController.drive(
      TextStyleTween(
        begin: TextStyle(
          fontFamily: "Splatfont2",
          color: Colors.white,
        ),
        end: TextStyle(
          fontFamily: "Splatfont2",
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _selectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final shouldPress = await widget.onPressStart?.call() ?? true;
        if (!shouldPress) {
          return;
        }
        final audioController = AudioController();
        if (widget.sfx != null) {
          audioController.playSfx(widget.sfx!);
        }
        await _selectController.forward(from: 0.0);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await widget.onPressEnd?.call();
        _selectController.value = 0.0;
      },
      child: AspectRatio(
        aspectRatio: 2 / 1,
        child: ScaleTransition(
          scale: selectScale,
          child: DecoratedBoxTransition(
            decoration: selectColor,
            child: Center(
              child: DefaultTextStyleTransition(
                style: selectTextColor,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
