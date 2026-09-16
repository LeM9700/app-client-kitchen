import 'package:flutter/material.dart';

import 'package:app_client/core/theme/kitchen_motion.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';

class KitchenPageIndicator extends StatelessWidget {
  const KitchenPageIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: KitchenMotion.medium,
          curve: KitchenMotion.entranceCurve,
          width: active ? 18 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: active
                ? KitchenColors.cognac
                : KitchenColors.brown700.withValues(alpha: 0.28),
          ),
        );
      }),
    );
  }
}
