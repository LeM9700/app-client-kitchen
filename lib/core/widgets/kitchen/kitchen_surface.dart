import 'package:flutter/material.dart';

import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_shadows.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';

enum KitchenElevation { flat, raised, inset }

class KitchenSurface extends StatelessWidget {
  const KitchenSurface({
    super.key,
    required this.child,
    this.elevation = KitchenElevation.raised,
    this.padding,
    this.borderRadius,
    this.color,
  });

  final Widget child;
  final KitchenElevation elevation;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? KitchenRadius.card;
    final surfaceColor = color ?? KitchenColors.surface;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: surfaceColor,
        gradient:
            elevation == KitchenElevation.inset ? null : KitchenGradients.paper,
        border: Border.all(
          color: KitchenColors.whiteWarm.withValues(alpha: 0.72),
        ),
        boxShadow: switch (elevation) {
          KitchenElevation.flat => const [],
          KitchenElevation.raised => KitchenShadows.raised,
          KitchenElevation.inset => const [
              BoxShadow(
                color: Color(0x332D1B13),
                blurRadius: 12,
                offset: Offset(4, 5),
                spreadRadius: -3,
              ),
              BoxShadow(
                color: Color(0xCCFFF8EE),
                blurRadius: 8,
                offset: Offset(-3, -3),
                spreadRadius: -4,
              ),
            ],
        },
      ),
      child: child,
    );
  }
}
