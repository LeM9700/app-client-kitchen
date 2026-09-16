import 'package:flutter/material.dart';

import 'package:app_client/core/theme/kitchen_motion.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';

class KitchenLoadingIndicator extends StatefulWidget {
  const KitchenLoadingIndicator({
    super.key,
    this.color = KitchenColors.whiteWarm,
    this.size = 34,
  });

  final Color color;
  final double size;

  @override
  State<KitchenLoadingIndicator> createState() =>
      _KitchenLoadingIndicatorState();
}

class _KitchenLoadingIndicatorState extends State<KitchenLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      return _DotRow(color: widget.color, activeIndex: 1, size: widget.size);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final activeIndex = (_controller.value * 3).floor().clamp(0, 2);
        return AnimatedSwitcher(
          duration: KitchenMotion.fast,
          child: _DotRow(
            key: ValueKey(activeIndex),
            color: widget.color,
            activeIndex: activeIndex,
            size: widget.size,
          ),
        );
      },
    );
  }
}

class _DotRow extends StatelessWidget {
  const _DotRow({
    super.key,
    required this.color,
    required this.activeIndex,
    required this.size,
  });

  final Color color;
  final int activeIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          final active = index == activeIndex;
          return AnimatedContainer(
            duration: KitchenMotion.fast,
            width: active ? 10 : 7,
            height: active ? 10 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: active ? 1 : 0.5),
            ),
          );
        }),
      ),
    );
  }
}
