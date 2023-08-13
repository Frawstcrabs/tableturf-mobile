import 'package:flutter/material.dart';

class ExactGrid extends StatelessWidget {
  final int height, width;
  final List<Widget> children;
  const ExactGrid({
    super.key,
    required this.height,
    required this.width,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < height * width; i += width)
          Expanded(
            child: Center(
              child: Row(
                children: [
                  for (int j = 0; j < width; j++)
                    Expanded(
                      child: Center(
                          child: i + j >= children.length
                              ? Container()
                              : children[i + j]
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
