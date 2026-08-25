import 'package:flutter/material.dart';

/// Bloc de placeholder animé pour le skeleton loading.
/// Usage : remplacer un widget réel par ShimmerBlock(width: X, height: Y)
/// pendant le chargement (voir plan-19-ux-polish.md, décision n°2 —
/// HomeScreen, OrderHistoryScreen, LoyaltyScreen).
class ShimmerBlock extends StatefulWidget {
  const ShimmerBlock({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFFE5E5E5),
              Color.lerp(
                const Color(0xFFE5E5E5),
                const Color(0xFFF5F5F5),
                _animation.value,
              )!,
              const Color(0xFFE5E5E5),
            ],
            stops: [0.0, _animation.value, 1.0],
          ),
        ),
      ),
    );
  }
}
