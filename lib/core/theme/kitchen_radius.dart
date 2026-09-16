import 'package:flutter/material.dart';

abstract final class KitchenRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 34;
  static const double pill = 999;

  static BorderRadius get button => BorderRadius.circular(22);
  static BorderRadius get field => BorderRadius.circular(20);
  static BorderRadius get card => BorderRadius.circular(26);
}
