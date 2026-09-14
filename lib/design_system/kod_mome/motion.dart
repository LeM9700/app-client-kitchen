import 'package:flutter/material.dart';

import 'package:app_client/core/theme/kod_mome/kod_mome_design_pack.dart';

/// Reusable entrance animation — fade + slide-up, optionally delayed for a
/// staggered feel across a list of siblings. Built on implicit/explicit
/// Flutter animations only (no third-party motion package).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 24),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: KodMomeDesignPack.entranceDuration,
    );
    _curved = CurvedAnimation(
      parent: _controller,
      curve: KodMomeDesignPack.entranceCurve,
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) => Opacity(
        opacity: _curved.value,
        child: Transform.translate(
          offset: widget.offset * (1 - _curved.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
