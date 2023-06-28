import 'package:flutter/material.dart';

class SelectionButton extends StatefulWidget {
  final Future<void> Function() onSelect;
  final double designRatio;
  final Widget child;
  const SelectionButton({
    super.key,
    required this.onSelect,
    this.designRatio = 1,
    required this.child,
  });

  @override
  State<SelectionButton> createState() => SelectionButtonState();
}

class SelectionButtonState extends State<SelectionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _selectController;
  late final Animation<double> selectScale;
  late final Animation<Color?> selectColor, selectTextColor;

  @override
  void initState() {
    super.initState();

    _selectController = AnimationController(
        duration: const Duration(milliseconds: 125),
        vsync: this
    );
    const selectDownscale = 0.9;
    selectScale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: selectDownscale)
              .chain(CurveTween(curve: Curves.decelerate)),
          weight: 50
      ),
      TweenSequenceItem(
          tween: Tween(begin: selectDownscale, end: 1.025)
              .chain(CurveTween(curve: Curves.decelerate.flipped)),
          weight: 50
      ),
    ]).animate(_selectController);
    selectColor = ColorTween(
        begin: const Color.fromRGBO(71, 16, 175, 1.0),
        end: const Color.fromRGBO(167, 231, 9, 1.0)
    )
        .animate(_selectController);
    selectTextColor = ColorTween(
        begin: Colors.white,
        end: Colors.black
    )
        .animate(_selectController);
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
        await _selectController.forward(from: 0.0);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await widget.onSelect();
        _selectController.value = 0.0;
      },
      child: AnimatedBuilder(
          animation: _selectController,
          builder: (_, __) {
            final textStyle = DefaultTextStyle.of(context).style.copyWith(
                color: selectTextColor.value
            );
            return AspectRatio(
                aspectRatio: 2/1,
                child: Transform.scale(
                  scale: selectScale.value,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selectColor.value,
                        borderRadius: BorderRadius.circular(20 * widget.designRatio),
                        border: Border.all(
                          color: Colors.black,
                          width: 1.0 * widget.designRatio,
                        ),
                      ),
                      child: Center(
                          child: DefaultTextStyle(
                              style: textStyle,
                              child: widget.child
                          )
                      )
                  ),
                )
            );
          }
      ),
    );
  }
}