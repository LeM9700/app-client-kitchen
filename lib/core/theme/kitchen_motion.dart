import 'package:flutter/animation.dart';

abstract final class KitchenMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 900);
  static const Duration background = Duration(seconds: 12);

  static const Curve pressCurve = Curves.easeOutCubic;
  static const Curve entranceCurve = Curves.easeOutCubic;
}
