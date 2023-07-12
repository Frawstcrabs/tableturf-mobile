import 'dart:ui';

class Shaders {
  static late FragmentProgram dashedLine;
  static late FragmentProgram specialFire;

  static Future<void> loadPrograms() async {
    dashedLine = await FragmentProgram.fromAsset("assets/shaders/dashed_line.frag");
    specialFire = await FragmentProgram.fromAsset("assets/shaders/special_fire.frag");
  }
}