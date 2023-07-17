import 'package:flutter/material.dart';

class SplashTag extends StatelessWidget {
  final String name;
  final String tagBackground;
  final String? tagIcon;

  const SplashTag({
    super.key,
    required this.name,
    this.tagBackground = "assets/images/splashtags/default.png",
    this.tagIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 700/200,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final designRatio = constraints.maxWidth / 700;
            return ClipRRect(
              borderRadius: BorderRadius.circular(15.0 * designRatio),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    tagBackground,
                    color: const Color.fromRGBO(0, 0, 0, 0.6),
                    colorBlendMode: BlendMode.srcATop,
                  ),
                  if (tagIcon != null) Image.asset(
                    tagIcon!,
                    color: const Color.fromRGBO(0, 0, 0, 0.6),
                    colorBlendMode: BlendMode.srcATop,
                    height: 200 * designRatio,
                    alignment: Alignment.centerRight,
                  ),
                  Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontFamily: "Splatfont1",
                        fontSize: 66 * designRatio,
                        color: Colors.white,
                        letterSpacing: 1.2 * designRatio,
                      )
                    )
                  )
                ]
              ),
            );
          }
        ),
      ),
    );
  }
}