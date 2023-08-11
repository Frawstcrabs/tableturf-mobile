import 'dart:math';

import 'package:flutter/material.dart';

class CardBitCounter extends StatefulWidget {
  final int cardBits;
  final int digits;
  final double designRatio;
  const CardBitCounter({
    super.key,
    required this.cardBits,
    this.digits = 4,
    required this.designRatio,
  });

  @override
  State<CardBitCounter> createState() => _CardBitCounterState();
}

class _CardBitCounterState extends State<CardBitCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController tickController;
  late ProxyAnimation digitTickerDriver;
  late List<Animation<double>> digitTickers;

  @override
  void initState() {
    super.initState();
    tickController = AnimationController(
      // duration is calculated dynamically
      vsync: this,
    );
    digitTickerDriver = ProxyAnimation(
      tickController.drive(
        ConstantTween(widget.cardBits.toDouble()),
      ),
    );

    _buildDigitTickers();
  }

  void _buildDigitTickers() {
    digitTickers = [
      for (var i = widget.digits - 1; i >= 0; i--)
        Animation.fromValueListenable(
          digitTickerDriver,
          transformer: (val) {
            final pow10i = pow(10, i);
            final digit = val / pow10i;
            final digitTest = (val + 1).floorToDouble() / pow10i;

            if ((digitTest - digitTest.truncate()) % 10 == 0) {
              // digit below this is rolling from 9 to 0
              // this digit needs to tick up with it
              final fract = val - val.truncate();
              return (digit % 10).floorToDouble() + fract;
            } else {
              // digit is staying in place
              return (digit % 10).floorToDouble();
            }
          },
        ),
    ];
  }

  @override
  void didUpdateWidget(CardBitCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cardBits != oldWidget.cardBits) {
      digitTickerDriver.parent = tickController.drive(
        Tween(
          begin: oldWidget.cardBits.toDouble(),
          end: widget.cardBits.toDouble(),
        ),
      );
      if (widget.digits != oldWidget.digits) {
        _buildDigitTickers();
      }
      final cardBitsDiff = widget.cardBits - oldWidget.cardBits;
      final durationTime = 111 * log(cardBitsDiff.abs() + 1);
      tickController.duration = Duration(
        milliseconds: durationTime.floor(),
      );
      tickController.forward(from: 0.0);
    } else if (widget.digits != oldWidget.digits) {
      _buildDigitTickers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final designRatio = widget.designRatio;
    final charHeight = 40 * designRatio;
    return RepaintBoundary(
      child: SizedBox(
        height: charHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Image.asset(
                "assets/images/card_bit.png",
              ),
            ),
            SizedBox(
              width: 5 * designRatio,
            ),
            for (var i = 0; i < widget.digits; i++)
              SizedBox(
                height: charHeight,
                width: 20 * designRatio,
                child: ClipRect(
                  clipBehavior: Clip.hardEdge,
                  child: buildTickerColumn(designRatio, i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildTickerColumn(double designRatio, int index) {
    final charHeight = 40 * designRatio;
    final digitTicker = digitTickers[index];
    const digits = "01234567890";
    return AnimatedBuilder(
      animation: digitTicker,
      child: SizedBox(
        height: charHeight * digits.length,
        child: Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [
            for (final (i, char) in digits.characters.indexed)
              Positioned(
                bottom: charHeight * i,
                left: 0,
                right: 0,
                child: buildTickerDigit(designRatio, char),
              ),
          ],
        ),
      ),
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, digitTicker.value * charHeight),
          child: child,
        );
      },
    );
  }

  Widget buildTickerDigit(double designRatio, String char) {
    return FractionalTranslation(
      translation: Offset(0, 0.15),
      child: SizedBox(
        height: 40 * designRatio,
        child: Center(
          child: Text(
            char,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32 * designRatio,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
