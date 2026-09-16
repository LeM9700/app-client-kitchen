import 'package:flutter/material.dart';

import 'package:app_client/core/theme/kitchen_tokens.dart';

abstract final class KitchenShadows {
  static const List<BoxShadow> raised = [
    BoxShadow(
      color: KitchenColors.warmShadow,
      blurRadius: 18,
      offset: Offset(8, 10),
    ),
    BoxShadow(
      color: KitchenColors.warmHighlight,
      blurRadius: 12,
      offset: Offset(-5, -6),
    ),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x2A2D1B13),
      blurRadius: 14,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> pressed = [
    BoxShadow(
      color: Color(0x302D1B13),
      blurRadius: 7,
      offset: Offset(2, 3),
    ),
  ];
}
