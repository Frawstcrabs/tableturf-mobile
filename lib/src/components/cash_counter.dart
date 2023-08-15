import 'dart:math';

import 'package:flutter/material.dart';

class CashCounter extends StatefulWidget {
  final int cash;
  final int digits;
  final double designRatio;
  const CashCounter({
    super.key,
    required this.cash,
    this.digits = 6,
    required this.designRatio,
  });

  @override
  State<CashCounter> createState() => _CashCounterState();
}

class _CashCounterState extends State<CashCounter>
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
        ConstantTween(widget.cash.toDouble()),
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
  void didUpdateWidget(CashCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cash != oldWidget.cash) {
      digitTickerDriver.parent = tickController.drive(
        Tween(
          begin: oldWidget.cash.toDouble(),
          end: widget.cash.toDouble(),
        ),
      );
      if (widget.digits != oldWidget.digits) {
        _buildDigitTickers();
      }
      final cashDiff = widget.cash - oldWidget.cash;
      final durationTime = 118 * log(cashDiff.abs() + 1);
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
                "assets/images/cash.png",
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
