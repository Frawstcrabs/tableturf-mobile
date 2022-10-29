import 'package:flutter/material.dart';

Widget buildTextWidget(String str, {double offset = 1, double fontSize = 16}) {
  return Scaffold(
    backgroundColor: Colors.transparent,
    body: Center(
      child: Text(
        str,
        style: TextStyle(
          fontFamily: "Splatfont2",
          color: Colors.white,
          fontSize: fontSize,
          letterSpacing: 0.6,
          shadows: [
            Shadow(
              color: const Color.fromRGBO(256, 256, 256, 0.4),
              offset: Offset(offset, offset),
            )
          ]
        )
      )
    ),
  );
}